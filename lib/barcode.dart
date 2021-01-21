import 'package:InvenTree/widget/dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//import 'package:qr_utils/qr_utils.dart';
//import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
//import 'package:barcode_scan/barcode_scan.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:InvenTree/inventree/stock.dart';
import 'package:InvenTree/inventree/part.dart';

import 'package:InvenTree/api.dart';

import 'package:InvenTree/widget/location_display.dart';
import 'package:InvenTree/widget/part_detail.dart';
import 'package:InvenTree/widget/category_display.dart';
import 'package:InvenTree/widget/stock_detail.dart';

import 'dart:convert';


class InvenTreeQRView extends StatefulWidget {

  InvenTreeQRView({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewState();
}


class _QRViewState extends State<InvenTreeQRView> {

  QRViewController _controller;

  BuildContext context;

  _QRViewState() : super();

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // Callback when the server repsonds with a match for the barcode
  Future<void> onBarcodeMatched(Map<String, dynamic> response) {
    int pk;

    print("Handle barcode:");
    print(response);

    // A stocklocation has been passed?
    if (response.containsKey('stocklocation')) {

      pk = response['stocklocation']['pk'] as int ?? null;

      if (pk != null) {
        InvenTreeStockLocation().get(context, pk).then((var loc) {
          if (loc is InvenTreeStockLocation) {
            Navigator.of(context).pop();
            Navigator.push(context, MaterialPageRoute(builder: (context) => LocationDisplayWidget(loc)));
          }
        });
      } else {
        // TODO - Show an error here!
      }

    } else if (response.containsKey('stockitem')) {

      pk = response['stockitem']['pk'] as int ?? null;

      if (pk != null) {
        InvenTreeStockItem().get(context, pk).then((var item) {
          Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(builder: (context) => StockDetailWidget(item)));
        });
      } else {
        // TODO - Show an error here!
      }
    } else if (response.containsKey('part')) {

      pk = response['part']['pk'] as int ?? null;

      if (pk != null) {
        InvenTreePart().get(context, pk).then((var part) {
          Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(builder: (context) => PartDetailWidget(part)));
        });
      } else {
        // TODO - Show an error here!
      }
    } else {
      showDialog(
          context: context,
          child: SimpleDialog(
            title: Text("Unknown response"),
            children: <Widget>[
              ListTile(
                title: Text("Response data"),
                subtitle: Text(response.toString()),
              )
            ],
          )
      );
    }
  }

  // Callback when the server responds with no match for the barcode
  Future<void> onBarcodeUnknown(Map<String, dynamic> response) {
    showErrorDialog(
        context,
        response['error'] ?? '',
        response['plugin'] ?? 'No barcode plugin information',
        error: "Barcode Error",
        icon: FontAwesomeIcons.barcode,
        onDismissed: () {
          _controller.resumeCamera();
        }
    );
  }

  // Callback when the server responds with an unhandled response
  Future<void> onBarcodeUnhandled(Map<String, dynamic> response) {
    showErrorDialog(
        context,
        "Response Data",
        response.toString(),
        error: "Unknown Response",
        onDismissed: () {
        _controller.resumeCamera();
        }
    );
  }

  Future<void> processBarcode(String barcode) async {
    if (barcode == null || barcode.isEmpty) {
      return;
    }

    print("Scanned: ${barcode}");
    showProgressDialog(context, "Querying server", "Sending barcode data to server");

    InvenTreeAPI().post("barcode/", body: {"barcode": barcode}).then((var response) {
      hideProgressDialog(context);

      print("Response:");
      print(response.body);

      if (response.statusCode != 200) {

        showErrorDialog(
          context,
          "Status Code: ${response.statusCode}",
          "${response.body.toString().split('\n').first}",
          onDismissed: () {
            _controller.resumeCamera();
          },
          error: "Server Error",
          icon: FontAwesomeIcons.server,
        );

        return;
      }

      // Decode the response
      final Map<String, dynamic> body = json.decode(response.body);

      // "Error" contained in response
      if (body.containsKey('error')) {
        onBarcodeUnknown(body);
      } else if (body.containsKey('success')) {
        onBarcodeMatched(body);
      } else {
        onBarcodeUnhandled(body);
      }

    }).timeout(
        Duration(seconds: 5)
    ).catchError((error) {
      hideProgressDialog(context);
      showErrorDialog(
        context,
        "Error",
        error.toString(),
        onDismissed: () {
          _controller.resumeCamera();
        }
      );
      return;
    });

  }

  void _onViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scandata) {
      _controller?.pauseCamera();
      processBarcode(scandata);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Save the context for later on!
    this.context = context;

    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            )
          )
        ],
      )
    );
  }
}


Future<void> scanQrCode(BuildContext context) async {

  Navigator.push(context, MaterialPageRoute(builder: (context) => InvenTreeQRView()));

  return;
}