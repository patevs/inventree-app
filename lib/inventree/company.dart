import "dart:async";

import "package:flutter/material.dart";
import "package:inventree/api.dart";
import "package:inventree/inventree/model.dart";
import "package:inventree/inventree/purchase_order.dart";
import "package:inventree/widget/company/company_detail.dart";
import "package:inventree/widget/company/supplier_part_detail.dart";

/*
 * The InvenTreeCompany class represents the Company model in the InvenTree database.
 */

class InvenTreeCompany extends InvenTreeModel {
  InvenTreeCompany() : super();

  InvenTreeCompany.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  @override
  String get URL => "company/";

  static const String MODEL_TYPE = "company";

  @override
  Future<Object?> goToDetailPage(BuildContext context) async {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CompanyDetailWidget(this)),
    );
  }

  @override
  List<String> get rolesRequired => [
    "purchase_order",
    "sales_order",
    "return_order",
  ];

  @override
  Map<String, Map<String, dynamic>> formFields() {
    Map<String, Map<String, dynamic>> fields = {
      "name": {},
      "description": {},
      "website": {},
      "is_supplier": {},
      "is_manufacturer": {},
      "is_customer": {},
      "currency": {},
    };

    if (InvenTreeAPI().supportsCompanyActiveStatus) {
      fields["active"] = {};
    }

    return fields;
  }

  String get image =>
      (jsondata["image"] ?? jsondata["thumbnail"] ?? InvenTreeAPI.staticImage)
          as String;

  String get thumbnail =>
      (jsondata["thumbnail"] ?? jsondata["image"] ?? InvenTreeAPI.staticThumb)
          as String;

  String get website => getString("website");

  String get phone => getString("phone");

  String get email => getString("email");

  bool get isSupplier => getBool("is_supplier");

  bool get isManufacturer => getBool("is_manufacturer");

  bool get isCustomer => getBool("is_customer");

  bool get active => getBool("active", backup: true);

  int get partSuppliedCount => getInt("part_supplied");

  int get partManufacturedCount => getInt("parts_manufactured");

  // Request a list of purchase orders against this company
  Future<List<InvenTreePurchaseOrder>> getPurchaseOrders({
    bool? outstanding,
  }) async {
    Map<String, String> filters = {"supplier": "${pk}"};

    if (outstanding != null) {
      filters["outstanding"] = outstanding ? "true" : "false";
    }

    final List<InvenTreeModel> results = await InvenTreePurchaseOrder().list(
      filters: filters,
    );

    List<InvenTreePurchaseOrder> orders = [];

    for (InvenTreeModel model in results) {
      if (model is InvenTreePurchaseOrder) {
        orders.add(model);
      }
    }

    return orders;
  }

  @override
  InvenTreeModel createFromJson(Map<String, dynamic> json) =>
      InvenTreeCompany.fromJson(json);
}

/*
 * Class representing an attachment file against a Company object
 */
class InvenTreeCompanyAttachment extends InvenTreeAttachment {
  InvenTreeCompanyAttachment() : super();

  InvenTreeCompanyAttachment.fromJson(Map<String, dynamic> json)
    : super.fromJson(json);

  @override
  String get REFERENCE_FIELD => "company";

  @override
  String get REF_MODEL_TYPE => "company";

  @override
  String get URL => InvenTreeAPI().supportsModernAttachments
      ? "attachment/"
      : "company/attachment/";

  @override
  InvenTreeModel createFromJson(Map<String, dynamic> json) =>
      InvenTreeCompanyAttachment.fromJson(json);
}

/*
 * The InvenTreeSupplierPart class represents the SupplierPart model in the InvenTree database
 */
class InvenTreeSupplierPart extends InvenTreeModel {
  InvenTreeSupplierPart() : super();

  InvenTreeSupplierPart.fromJson(Map<String, dynamic> json)
    : super.fromJson(json);

  @override
  String get URL => "company/part/";

  static const String MODEL_TYPE = "supplierpart";

  @override
  List<String> get rolesRequired => ["part", "purchase_order"];

  @override
  Future<Object?> goToDetailPage(BuildContext context) async {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupplierPartDetailWidget(this)),
    );
  }

  @override
  Map<String, Map<String, dynamic>> formFields() {
    Map<String, Map<String, dynamic>> fields = {
      "supplier": {},
      "SKU": {},
      "link": {},
      "note": {},
      "packaging": {},
    };

    // At some point, pack_size was changed to pack_quantity
    if (InvenTreeAPI().apiVersion < 117) {
      fields["pack_size"] = {};
    } else {
      fields["pack_quantity"] = {};
    }

    if (InvenTreeAPI().supportsCompanyActiveStatus) {
      fields["active"] = {};
    }

    return fields;
  }

  @override
  Map<String, String> defaultFilters() {
    return {
      "manufacturer_detail": "true",
      "supplier_detail": "true",
      "part_detail": "true",
    };
  }

  int get manufacturerId => getInt("pk", subKey: "manufacturer_detail");

  String get manufacturerName =>
      getString("name", subKey: "manufacturer_detail");

  String get MPN => getString("MPN", subKey: "manufacturer_part_detail");

  String get manufacturerImage =>
      (jsondata["manufacturer_detail"]?["image"] ??
              jsondata["manufacturer_detail"]?["thumbnail"] ??
              InvenTreeAPI.staticThumb)
          as String;

  int get manufacturerPartId => getInt("manufacturer_part");

  int get supplierId => getInt("supplier");

  String get supplierName => getString("name", subKey: "supplier_detail");

  String get supplierImage =>
      (jsondata["supplier_detail"]?["image"] ??
              jsondata["supplier_detail"]?["thumbnail"] ??
              InvenTreeAPI.staticThumb)
          as String;

  String get SKU => getString("SKU");

  bool get active => getBool("active", backup: true);

  int get partId => getInt("part");

  String get partImage =>
      (jsondata["part_detail"]?["thumbnail"] ?? InvenTreeAPI.staticThumb)
          as String;

  String get partName => getString("name", subKey: "part_detail");

  Map<String, dynamic> get partDetail => getMap("part_detail");

  String get partDescription => getString("description", subKey: "part_detail");

  String get note => getString("note");

  String get packaging => getString("packaging");

  String get pack_quantity {
    if (InvenTreeAPI().apiVersion < 117) {
      return getString("pack_size");
    } else {
      return getString("pack_quantity");
    }
  }

  @override
  InvenTreeModel createFromJson(Map<String, dynamic> json) =>
      InvenTreeSupplierPart.fromJson(json);
}

class InvenTreeManufacturerPart extends InvenTreeModel {
  InvenTreeManufacturerPart() : super();

  InvenTreeManufacturerPart.fromJson(Map<String, dynamic> json)
    : super.fromJson(json);

  @override
  String URL = "company/part/manufacturer/";

  static const String MODEL_TYPE = "manufacturerpart";

  @override
  List<String> get rolesRequired => ["part"];

  @override
  Map<String, Map<String, dynamic>> formFields() {
    Map<String, Map<String, dynamic>> fields = {
      "manufacturer": {},
      "MPN": {},
      "link": {},
    };

    return fields;
  }

  @override
  Map<String, String> defaultFilters() {
    return {"manufacturer_detail": "true", "part_detail": "true"};
  }

  int get partId => getInt("part");

  String get partName => getString("name", subKey: "part_detail");

  String get partDescription => getString("description", subKey: "part_detail");

  String get partIPN => getString("IPN", subKey: "part_detail");

  String get partImage =>
      (jsondata["part_detail"]?["thumbnail"] ?? InvenTreeAPI.staticThumb)
          as String;

  int get manufacturerId => getInt("manufacturer");

  String get manufacturerName =>
      getString("name", subKey: "manufacturer_detail");

  String get manufacturerDescription =>
      getString("description", subKey: "manufacturer_detail");

  String get manufacturerImage =>
      (jsondata["manufacturer_detail"]?["image"] ??
              jsondata["manufacturer_detail"]?["thumbnail"] ??
              InvenTreeAPI.staticThumb)
          as String;

  String get MPN => getString("MPN");

  @override
  InvenTreeModel createFromJson(Map<String, dynamic> json) =>
      InvenTreeManufacturerPart.fromJson(json);
}
