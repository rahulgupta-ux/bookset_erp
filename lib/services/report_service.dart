import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolReport {
  final Map<String, dynamic> classReport;
  final int totalRevenue;
  final int totalSetsSold;

  const SchoolReport({
    required this.classReport,
    required this.totalRevenue,
    required this.totalSetsSold,
  });
}

class DashboardReport {
  final int totalRevenue;
  final int totalSetsSold;

  const DashboardReport({
    required this.totalRevenue,
    required this.totalSetsSold,
  });
}

class ReportService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /////////////////////////////////////////////////////////////////
  /// REPORT OF ONE SCHOOL
  /////////////////////////////////////////////////////////////////

  Future<SchoolReport> generateSchoolReport(String school) async {
    final inventorySnapshot = await firestore
        .collection("inventory")
        .where("school", isEqualTo: school)
        .get();

    Map<String, dynamic> report = {};

    int revenue = 0;

    int totalSold = 0;

    for (final inventoryDoc in inventorySnapshot.docs) {
      final inventoryData = inventoryDoc.data();

      final className = inventoryData["className"] ?? "Unknown";

      final price = (inventoryData["price"] ?? 0) as num;

      final qrSnapshot = await inventoryDoc.reference
          .collection("qrs")
          .where("sold", isEqualTo: true)
          .get();

      final soldCount = qrSnapshot.docs.length;

      final amount = soldCount * price.toInt();

      final totalQrSnapshot = await inventoryDoc.reference
          .collection("qrs")
          .get();

      final totalSets = totalQrSnapshot.docs.length;

      report[className] = {
        "totalSets": totalSets,
        "count": soldCount,
        "amount": amount,
      };

      revenue += amount;

      totalSold += soldCount;
    }

    return SchoolReport(
      classReport: report,
      totalRevenue: revenue,
      totalSetsSold: totalSold,
    );
  }

  /////////////////////////////////////////////////////////////////
  /// COMPLETE ERP DASHBOARD
  /////////////////////////////////////////////////////////////////

  Future<DashboardReport> generateDashboardReport() async {
    final inventorySnapshot = await firestore.collection("inventory").get();

    int revenue = 0;

    int soldSets = 0;

    for (final inventoryDoc in inventorySnapshot.docs) {
      final inventoryData = inventoryDoc.data();

      final price = (inventoryData["price"] ?? 0) as num;

      final qrSnapshot = await inventoryDoc.reference
          .collection("qrs")
          .where("sold", isEqualTo: true)
          .get();

      final soldCount = qrSnapshot.docs.length;

      revenue += soldCount * price.toInt();

      soldSets += soldCount;
    }

    return DashboardReport(totalRevenue: revenue, totalSetsSold: soldSets);
  }
}
