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

        int soldCount = 0;

        int soldAmount = 0;

        final batchesSnapshot = await inventoryDoc.reference
            .collection("batches")
            .get();

        for (var batchDoc in batchesSnapshot.docs) {
          final soldQrSnapshot = await batchDoc.reference
              .collection("qrs")
              .where("sold", isEqualTo: true)
              .get();

          for (var qrDoc in soldQrSnapshot.docs) {
            final qrData = qrDoc.data();

            soldCount++;

            soldAmount += ((qrData["soldPrice"] ?? 0) as num).toInt();
          }
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
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Reports",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // SCHOOL DROPDOWN
              DropdownButtonFormField<String>(
                value: selectedSchool,

                decoration: InputDecoration(
                  labelText: "Select School",
                  filled: true,
                  fillColor: const Color(0xFF161B22),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF10A37F),
                      width: 1.5,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF10A37F),
                      width: 2,
                    ),
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
                    backgroundColor: const Color(0xFF161B22),

                    foregroundColor: const Color(0xFF10A37F),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    padding: const EdgeInsets.symmetric(vertical: 20),
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
                    color: const Color(0xFF161B22),

                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF21262D)),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      const Text(
                        "Total Revenue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "₹$totalRevenue",

                        style: const TextStyle(
                          color: Color(0xFF10A37F),
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
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),

                    dataTextStyle: const TextStyle(color: Colors.white70),

                    dividerThickness: 1,
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
      ),
    );
  }
}
