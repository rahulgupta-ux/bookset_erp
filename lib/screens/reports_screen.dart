import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with AutomaticKeepAliveClientMixin {
  String? selectedSchool;

  bool isLoading = false;

  Map<String, dynamic> reportData = {};

  int totalRevenue = 0;

  List<String> schools = [];
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    loadSchools();
  }

  // LOAD ALL SCHOOLS
  Future<void> loadSchools() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("products")
        .get();

    final uniqueSchools = snapshot.docs
        .map((doc) => doc["school"].toString())
        .toSet()
        .toList();

    setState(() {
      schools = uniqueSchools;
    });
  }

  // GENERATE REPORT

  Future<void> generateReport() async {
    if (selectedSchool == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select School")));

      return;
    }

    setState(() {
      isLoading = true;

      reportData = {};

      totalRevenue = 0;
    });

    try {
      final inventorySnapshot = await FirebaseFirestore.instance
          .collection("inventory")
          .get();

      Map<String, dynamic> tempReport = {};

      int tempRevenue = 0;

      for (var inventoryDoc in inventorySnapshot.docs) {
        final data = inventoryDoc.data();

        final school = data["school"] ?? "";

        if (school != selectedSchool) {
          continue;
        }

        final className = data["className"] ?? "Unknown";

        final soldQrSnapshot = await inventoryDoc.reference
            .collection("qrs")
            .where("sold", isEqualTo: true)
            .get();

        int soldCount = 0;

        int soldAmount = 0;

        for (var qrDoc in soldQrSnapshot.docs) {
          final qrData = qrDoc.data();

          soldCount++;

          soldAmount += (qrData["soldPrice"] ?? 0) as int;
        }

        tempReport[className] = {"count": soldCount, "amount": soldAmount};

        tempRevenue += soldAmount;
      }

      setState(() {
        reportData = tempReport;

        totalRevenue = tempRevenue;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Reports",

              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // SCHOOL DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedSchool,

              decoration: InputDecoration(
                labelText: "Select School",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              items: schools.map((school) {
                return DropdownMenuItem(value: school, child: Text(school));
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedSchool = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // GENERATE BUTTON
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: generateReport,

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),

                child: const Text(
                  "Generate Report",

                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // LOADING
            if (isLoading) const Center(child: CircularProgressIndicator()),

            // TOTAL REVENUE
            if (!isLoading && reportData.isNotEmpty)
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.green.shade100,

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  children: [
                    const Text(
                      "Total Revenue",

                      style: TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "₹$totalRevenue",

                      style: const TextStyle(
                        fontSize: 32,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            // REPORT TABLE
            if (!isLoading && reportData.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Class")),

                    DataColumn(label: Text("Sets Sold")),

                    DataColumn(label: Text("Amount")),
                  ],

                  rows: reportData.entries.map((entry) {
                    final className = entry.key;

                    final data = entry.value;

                    return DataRow(
                      cells: [
                        DataCell(Text(className)),

                        DataCell(Text(data["count"].toString())),

                        DataCell(Text("₹${data["amount"]}")),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
