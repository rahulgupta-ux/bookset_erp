import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_print_screen.dart';
import 'bulk_qr_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with AutomaticKeepAliveClientMixin {
  final stockController = TextEditingController();
  final searchController = TextEditingController();
  String searchText = "";
  String? selectedSchool;
  String? selectedClass;
  List<String> schoolList = [];
  List<String> classList = [];
  bool isLoading = false;
  String generatedQr = "";
  List<String> generatedQrs = [];

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    loadSchools();
  }

  Future<void> loadSchools() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("products")
        .get();
    final schools = snapshot.docs
        .map((doc) => doc["school"].toString())
        .toSet()
        .toList();
    setState(() {
      schoolList = schools;
    });
  }

  Future<void> loadClasses(String school) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("products")
        .where("school", isEqualTo: school)
        .get();
    final classes = snapshot.docs
        .map((doc) => doc["className"].toString())
        .toSet()
        .toList();
    setState(() {
      classList = classes;
    });
  }

  Future<void> saveInventory() async {
    final school = selectedSchool ?? "";

    final className = selectedClass ?? "";

    final stock = int.tryParse(stockController.text) ?? 0;

    if (school.isEmpty || className.isEmpty || stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Fill All Fields Correctly")),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // FIND PRODUCT
      final productSnapshot = await FirebaseFirestore.instance
          .collection("products")
          .where("school", isEqualTo: school)
          .where("className", isEqualTo: className)
          .limit(1)
          .get();

      if (productSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Product Not Found")));

        setState(() {
          isLoading = false;
        });

        return;
      }

      final product = productSnapshot.docs.first;

      final price = product["price"];

      // PARENT DOC ID
      final inventoryId =
          "${school.replaceAll(" ", "")}"
          "_"
          "${className.replaceAll(" ", "")}";

      // PARENT DOCUMENT
      final inventoryDoc = FirebaseFirestore.instance
          .collection("inventory")
          .doc(inventoryId);

      // CREATE OR UPDATE PARENT
      await inventoryDoc.set({
        "school": school,

        "className": className,

        "price": price,

        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      generatedQrs.clear();

      // CREATE QR DOCS
      for (int i = 1; i <= stock; i++) {
        final qrId =
            "${inventoryId}"
            "_"
            "${DateTime.now().millisecondsSinceEpoch}"
            "_$i";

        generatedQrs.add(qrId);

        if (i == 1) {
          generatedQr = qrId;
        }

        await inventoryDoc.collection("qrs").doc(qrId).set({
          "qrId": qrId,

          "sold": false,

          "createdAt": Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Added $stock Book Sets")));

      stockController.clear();

      setState(() {
        selectedClass = null;

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

  Future<void> refreshInventory() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {});
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
                "Inventory",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
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
                    borderSide: const BorderSide(color: Color(0xFF21262D)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF10A37F),
                      width: 2,
                    ),
                  ),
                ),
                items: schoolList.map((school) {
                  return DropdownMenuItem(value: school, child: Text(school));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSchool = value;
                    selectedClass = null;
                  });
                  loadClasses(value!);
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedClass,
                decoration: InputDecoration(
                  labelText: "Select Class",
                  filled: true,
                  fillColor: const Color(0xFF161B22),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF21262D)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF10A37F),
                      width: 2,
                    ),
                  ),
                ),
                items: classList.map((className) {
                  return DropdownMenuItem(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              _buildField(
                controller: stockController,
                label: "Number Of Book Sets",
                icon: Icons.inventory,
                isNumber: true,
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveInventory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF161B22),

                    foregroundColor: const Color(0xFF10A37F),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Save Inventory",
                          style: TextStyle(fontSize: 20),
                        ),
                ),
              ),
              const SizedBox(height: 30),
              if (generatedQr.isNotEmpty)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: QrImageView(
                        data: generatedQr,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      generatedQr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QrPrintScreen(qrId: generatedQr),
                            ),
                          );
                        },
                        child: const Text("Open Print Preview"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BulkQrScreen(qrList: generatedQrs),
                            ),
                          );
                        },
                        child: const Text("Open Bulk QR Sheet"),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 35),
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search Inventory",

                  prefixIcon: const Icon(Icons.search),

                  filled: true,

                  fillColor: const Color(0xFF161B22),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF21262D)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF10A37F),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              const Text(
                "Current Inventory",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("inventory")
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return RefreshIndicator(
                    onRefresh: refreshInventory,

                    child: ListView.builder(
                      shrinkWrap: true,

                      physics: const NeverScrollableScrollPhysics(),

                      itemCount: docs.length,

                      itemBuilder: (context, index) {
                        final item = docs[index];

                        final school = item["school"];

                        final className = item["className"];

                        final price = item["price"];

                        final inventoryId = item.id.toLowerCase();

                        if (!inventoryId.contains(searchText)) {
                          return const SizedBox();
                        }

                        return FutureBuilder(
                          future: item.reference
                              .collection("qrs")
                              .where("sold", isEqualTo: false)
                              .get(),

                          builder: (context, qrSnapshot) {
                            int availableStock = 0;

                            if (qrSnapshot.hasData) {
                              availableStock = qrSnapshot.data!.docs.length;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),

                              decoration: BoxDecoration(
                                color: const Color(0xFF161B22),

                                borderRadius: BorderRadius.circular(20),

                                border: Border.all(
                                  color: const Color(0xFF21262D),
                                ),
                              ),

                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF10A37F),

                                  child: Icon(Icons.book, color: Colors.black),
                                ),

                                title: Text(
                                  school,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                subtitle: Text(
                                  "$className\nAvailable Stock: $availableStock",
                                  style: const TextStyle(color: Colors.white70),
                                ),

                                isThreeLine: true,

                                trailing: Text(
                                  "₹$price",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
