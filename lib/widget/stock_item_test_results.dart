import 'package:InvenTree/inventree/part.dart';
import 'package:InvenTree/inventree/stock.dart';
import 'package:InvenTree/inventree/model.dart';
import 'package:InvenTree/api.dart';
import 'package:InvenTree/widget/dialogs.dart';
import 'package:InvenTree/widget/fields.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:InvenTree/widget/refreshable_state.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StockItemTestResultsWidget extends StatefulWidget {

  StockItemTestResultsWidget(this.item, {Key key}) : super(key: key);

  final InvenTreeStockItem item;

  @override
  _StockItemTestResultDisplayState createState() => _StockItemTestResultDisplayState(item);
}


class _StockItemTestResultDisplayState extends RefreshableState<StockItemTestResultsWidget> {

  final _addResultKey = GlobalKey<FormState>();

  @override
  String getAppBarTitle(BuildContext context) { return "Test Results"; }

  @override
  Future<void> request(BuildContext context) async {
    await item.getTestTemplates(context);
    await item.getTestResults(context);
  }

  final InvenTreeStockItem item;

  _StockItemTestResultDisplayState(this.item);

  void addTestResult({String name = '', bool nameIsEditable = true, bool result = false, String value = '', bool valueRequired = false, bool attachmentRequired = false}) {

    showFormDialog(context, "Add Test Data",
      key: _addResultKey,
      actions: <Widget>[
        FlatButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        FlatButton(
          child: Text("Save"),
          onPressed: () {
            if (_addResultKey.currentState.validate()) {
              // TODO
            }
          },
        )
      ],
      fields: <Widget>[
        StringField(
          label: "Test Name",
          initial: name,
          isEnabled: nameIsEditable,
        ),
        CheckBoxField(
          label: "Result",
          hint: "Test passed or failed",
          initial: true,
        ),
        StringField(
          label: "Value",
          initial: value,
          allowEmpty: true,
          validator: (String value) {
            print("Value: " + value);
            if (valueRequired && (value == null || value.isEmpty)) {
              return "Value required for this test";
            }
            return null;
          },
        ),
        StringField(
          allowEmpty: true,
          label: "Notes",
        ),
      ]
    );
  }

  // Squish together templates and results
  List<InvenTreeModel> getTestResults() {
    var templates = item.testTemplates;
    var results = item.testResults;

    List<InvenTreeModel> outputs = [];

    // Add each template to the list
    for (var t in templates) {
      outputs.add(t);
    }

    // Add each result (compare to existing items / templates
    for (var result in results) {
      bool match = false;

      for (var ii = 0; ii < outputs.length; ii++) {

        // Check against templates
        if (outputs[ii] is InvenTreePartTestTemplate) {
          var t = outputs[ii] as InvenTreePartTestTemplate;

          if (result.key == t.key) {
            t.results.add(result);
            match = true;
            break;
          }
        } else if (outputs[ii] is InvenTreeStockItemTestResult) {
          var r = outputs[ii] as InvenTreeStockItemTestResult;

          if (r.key == result.key) {
            // Overwrite with a newer result
            outputs[ii] = result;
            match = true;
            break;
          }
        }
      }

      if (!match) {
        outputs.add(result);
      }
    }

    return outputs;
  }

  List<Widget> resultsList() {
    List<Widget> tiles = [];

    var results = getTestResults();

    for (var item in results) {
      if (item is InvenTreePartTestTemplate) {
        var template = item as InvenTreePartTestTemplate;

        var status = template.passFailStatus();

        FaIcon icon;

        if (status == null) {
          icon = FaIcon(FontAwesomeIcons.questionCircle,
              color: Color.fromRGBO(0, 0, 250, 0.8)
          );
        } else if (status == true) {
          icon = FaIcon(FontAwesomeIcons.checkCircle,
            color: Color.fromRGBO(0, 250, 0, 0.8)
          );
        } else {
          icon = FaIcon(FontAwesomeIcons.timesCircle,
            color: Color.fromRGBO(250, 0, 0, 0.8)
          );
        }

        String subtitle = template.latestResult()?.value ?? '';

        tiles.add(ListTile(
          title: Text("${template.testName}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: icon,
          onLongPress: () {
            addTestResult(
                name: template.testName,
                nameIsEditable: false,
                valueRequired: template.requiresValue,
                attachmentRequired: template.requiresAttachment,
            );
          }
        ));
      }

      else if (item is InvenTreeStockItemTestResult) {
        var result = item as InvenTreeStockItemTestResult;

        FaIcon icon;

        if (result.result == true) {
          icon = FaIcon(FontAwesomeIcons.checkCircle,
              color: Color.fromRGBO(0, 250, 0, 0.8)
          );
        } else {
          icon = FaIcon(FontAwesomeIcons.timesCircle,
              color: Color.fromRGBO(250, 0, 0, 0.8)
          );
        }

        tiles.add(ListTile(
          title: Text("${result.testName}"),
          subtitle: Text("${result.value}"),
          trailing: icon,
          onLongPress: () {
            addTestResult(
                name: result.testName,
                nameIsEditable: false,
                valueRequired: false,
                attachmentRequired: false
            );
          }
        ));

      }
    }

    if (tiles.isEmpty) {
      tiles.add(ListTile(
        title: Text("No test results"),
      ));
    }

    return tiles;
  }

  @override
  Widget getBody(BuildContext context) {
    return ListView(
      children: resultsList(),
    );
  }

  List<SpeedDialChild> actionButtons() {

    var buttons = List<SpeedDialChild>();

    buttons.add(SpeedDialChild(
      child: Icon(FontAwesomeIcons.plusCircle),
      label: "Add Test Result",
      onTap: () {
        addTestResult();
      },
    ));

    return buttons;
  }

  @override
  Widget getFab(BuildContext context) {
    return SpeedDial(
      visible: true,
      animatedIcon: AnimatedIcons.menu_close,
      heroTag: 'stock-item-results-tab',
      children: actionButtons(),
    );
  }
}