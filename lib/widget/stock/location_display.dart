import "package:flutter/material.dart";
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";

import "package:inventree/app_colors.dart";
import "package:inventree/barcode/barcode.dart";
import "package:inventree/barcode/purchase_order.dart";
import "package:inventree/barcode/stock.dart";
import "package:inventree/l10.dart";

import "package:inventree/inventree/stock.dart";
import "package:inventree/preferences.dart";
import "package:inventree/widget/link_icon.dart";

import "package:inventree/widget/stock/location_list.dart";
import "package:inventree/widget/progress.dart";
import "package:inventree/widget/refreshable_state.dart";
import "package:inventree/widget/snacks.dart";
import "package:inventree/widget/stock/stock_list.dart";
import "package:inventree/labels.dart";

/*
 * Widget for displaying detail view for a single StockLocation instance
 */
class LocationDisplayWidget extends StatefulWidget {
  LocationDisplayWidget(this.location, {Key? key}) : super(key: key);

  final InvenTreeStockLocation? location;

  final String title = L10().stockLocation;

  @override
  _LocationDisplayState createState() => _LocationDisplayState(location);
}

class _LocationDisplayState extends RefreshableState<LocationDisplayWidget> {
  _LocationDisplayState(this.location);

  final InvenTreeStockLocation? location;

  List<Map<String, dynamic>> labels = [];

  @override
  String getAppBarTitle() {
    return L10().stockLocation;
  }

  @override
  List<Widget> appBarActions(BuildContext context) {
    List<Widget> actions = [];

    // Add "locate" button
    if (location != null && api.supportsMixin("locate")) {
      actions.add(
        IconButton(
          icon: Icon(Icons.travel_explore),
          tooltip: L10().locateLocation,
          onPressed: () async {
            api.locateItemOrLocation(context, location: location!.pk);
          },
        ),
      );
    }

    // Add "edit" button
    if (location != null && InvenTreeStockLocation().canEdit) {
      actions.add(
        IconButton(
          icon: Icon(TablerIcons.edit),
          tooltip: L10().editLocation,
          onPressed: () {
            _editLocationDialog(context);
          },
        ),
      );
    }

    return actions;
  }

  @override
  List<SpeedDialChild> barcodeButtons(BuildContext context) {
    List<SpeedDialChild> actions = [];

    if (location != null) {
      // Scan items into this location
      if (InvenTreeStockItem().canEdit) {
        actions.add(
          SpeedDialChild(
            child: Icon(TablerIcons.qrcode),
            label: L10().barcodeScanItem,
            onTap: () {
              scanBarcode(
                context,
                handler: StockLocationScanInItemsHandler(location!),
              ).then((value) {
                refresh(context);
              });
            },
          ),
        );
      }

      if (api.supportsBarcodePOReceiveEndpoint) {
        actions.add(
          SpeedDialChild(
            child: Icon(Icons.barcode_reader),
            label: L10().scanReceivedParts,
            onTap: () async {
              scanBarcode(
                context,
                handler: POReceiveBarcodeHandler(location: location),
              );
            },
          ),
        );
      }

      // Scan this location into another one
      if (InvenTreeStockLocation().canEdit) {
        actions.add(
          SpeedDialChild(
            child: Icon(TablerIcons.qrcode),
            label: L10().transferStockLocation,
            onTap: () {
              scanBarcode(
                context,
                handler: ScanParentLocationHandler(location!),
              ).then((value) {
                refresh(context);
              });
            },
          ),
        );
      }

      // Assign or un-assign barcodes
      actions.add(
        customBarcodeAction(
          context,
          this,
          location!.customBarcode,
          "stocklocation",
          location!.pk,
        ),
      );
    }

    return actions;
  }

  @override
  List<SpeedDialChild> actionButtons(BuildContext context) {
    List<SpeedDialChild> actions = [];

    // Create new location
    if (InvenTreeStockLocation().canCreate) {
      actions.add(
        SpeedDialChild(
          child: Icon(TablerIcons.sitemap),
          label: L10().locationCreate,
          onTap: () async {
            _newLocation(context);
          },
        ),
      );
    }

    // Create new item
    if (InvenTreeStockItem().canCreate) {
      actions.add(
        SpeedDialChild(
          child: Icon(TablerIcons.packages),
          label: L10().stockItemCreate,
          onTap: () async {
            _newStockItem(context);
          },
        ),
      );
    }

    if (widget.location != null && labels.isNotEmpty) {
      actions.add(
        SpeedDialChild(
          child: Icon(TablerIcons.printer),
          label: L10().printLabel,
          onTap: () async {
            selectAndPrintLabel(
              context,
              labels,
              widget.location!.pk,
              "location",
              "location=${widget.location!.pk}",
            );
          },
        ),
      );
    }

    return actions;
  }

  /*
   * Launch a dialog form to edit this stock location
   */
  void _editLocationDialog(BuildContext context) {
    final _loc = location;

    if (_loc == null) {
      return;
    }

    _loc.editForm(
      context,
      L10().editLocation,
      onSuccess: (data) async {
        refresh(context);
        showSnackIcon(L10().locationUpdated, success: true);
      },
    );
  }

  @override
  Future<void> onBuild(BuildContext context) async {
    refresh(context);
  }

  @override
  Future<void> request(BuildContext context) async {
    // Reload location information
    if (location != null) {
      final bool result = await location!.reload();

      if (!result) {
        Navigator.of(context).pop();
      }
    }

    List<Map<String, dynamic>> _labels = [];
    bool allowLabelPrinting = await InvenTreeSettingsManager().getBool(
      INV_ENABLE_LABEL_PRINTING,
      true,
    );
    allowLabelPrinting &= api.supportsMixin("labels");

    if (allowLabelPrinting) {
      if (widget.location != null) {
        String model_type = api.supportsModernLabelPrinting
            ? InvenTreeStockLocation.MODEL_TYPE
            : "location";
        String item_key = api.supportsModernLabelPrinting
            ? "items"
            : "location";

        _labels = await getLabelTemplates(model_type, {
          item_key: widget.location!.pk.toString(),
        });
      }
    }

    if (mounted) {
      setState(() {
        labels = _labels;
      });
    }
  }

  Future<void> _newLocation(BuildContext context) async {
    int pk = location?.pk ?? -1;

    InvenTreeStockLocation().createForm(
      context,
      L10().locationCreate,
      data: {"parent": (pk > 0) ? pk : null},
      onSuccess: (result) async {
        Map<String, dynamic> data = result as Map<String, dynamic>;

        if (data.containsKey("pk")) {
          var loc = InvenTreeStockLocation.fromJson(data);
          loc.goToDetailPage(context);
        }
      },
    );
  }

  /*
   * Launch a dialog form to create a new stock item
   */
  Future<void> _newStockItem(BuildContext context) async {
    var fields = InvenTreeStockItem().formFields();

    // Serial number field is not required here
    fields.remove("serial");

    Map<String, dynamic> data = {};

    if (location != null) {
      data["location"] = location!.pk;
    }

    InvenTreeStockItem().createForm(
      context,
      L10().stockItemCreate,
      data: data,
      fields: fields,
      onSuccess: (result) async {
        Map<String, dynamic> data = result as Map<String, dynamic>;

        if (data.containsKey("pk")) {
          var item = InvenTreeStockItem.fromJson(data);
          item.goToDetailPage(context);
        }
      },
    );
  }

  Widget locationDescriptionCard({bool includeActions = true}) {
    if (location == null) {
      return Card(
        child: ListTile(
          title: Text(
            L10().stockTopLevel,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          leading: Icon(TablerIcons.packages),
        ),
      );
    } else {
      List<Widget> children = [
        ListTile(
          title: Text("${location!.name}"),
          subtitle: Text("${location!.description}"),
          leading: location!.customIcon == null
              ? Icon(TablerIcons.packages)
              : Icon(location!.customIcon),
        ),
      ];

      if (includeActions) {
        children.add(
          ListTile(
            title: Text(L10().parentLocation),
            subtitle: Text("${location!.parentPathString}"),
            leading: Icon(TablerIcons.arrow_move_up, color: COLOR_ACTION),
            trailing: LinkIcon(),
            onTap: () async {
              int parentId = location?.parentId ?? -1;

              if (parentId < 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationDisplayWidget(null),
                  ),
                );
              } else {
                showLoadingOverlay();
                var loc = await InvenTreeStockLocation().get(parentId);
                hideLoadingOverlay();

                if (loc is InvenTreeStockLocation) {
                  loc.goToDetailPage(context);
                }
              }
            },
          ),
        );
      }

      return Card(child: Column(children: children));
    }
  }

  @override
  List<Widget> getTabIcons(BuildContext context) {
    return [Tab(text: L10().details), Tab(text: L10().stockItems)];
  }

  @override
  List<Widget> getTabs(BuildContext context) {
    return [Column(children: detailTiles()), Column(children: stockTiles())];
  }

  // Construct the "details" panel
  List<Widget> detailTiles() {
    Map<String, String> filters = {};

    int? parent = location?.pk;

    if (parent != null) {
      filters["parent"] = parent.toString();
    } else if (api.supportsNullTopLevelFiltering) {
      filters["parent"] = "null";
    }

    List<Widget> tiles = [
      locationDescriptionCard(),
      Expanded(
        child: PaginatedStockLocationList(filters, title: L10().sublocations),
        flex: 10,
      ),
    ];

    return tiles;
  }

  // Construct the "stock" panel
  List<Widget> stockTiles() {
    Map<String, String> filters = {
      "location": location?.pk.toString() ?? "null",
    };

    return [Expanded(child: PaginatedStockItemList(filters), flex: 10)];
  }
}
