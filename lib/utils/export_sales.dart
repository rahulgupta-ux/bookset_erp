import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';

Future<void> exportSales() async {
  final snapshot = await FirebaseFirestore.instance.collection("sales").get();

  List<List<dynamic>> rows = [];

  rows.add(["Invoice ID", "Amount", "Sale Type"]);

  for (var doc in snapshot.docs) {
    final data = doc.data();

    rows.add([
      data["invoiceId"],

      data["amount"],

      data["soldToSchool"] == true ? "School Sale" : "Retail Sale",
    ]);
  }

  String csvData = rows.map((row) => row.join(",")).join("\n");

  final dir = await getTemporaryDirectory();

  final file = File("${dir.path}/sales.csv");

  await file.writeAsString(csvData);

  await Share.shareXFiles([XFile(file.path)]);
}
