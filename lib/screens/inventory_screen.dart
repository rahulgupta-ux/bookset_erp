import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  String currentBatchId = "";
  String currentInventoryId = "";
  //List<String> generatedQrs = [];

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    loadSchools();
  }

  Future<void> loadSchools() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("products")
          .get();

      print("========== PRODUCTS ==========");
      print(snapshot.docs.length);

      for (var doc in snapshot.docs) {
        print(doc.id);
        print(doc.data());
      }

      final schools = snapshot.docs
          .map((doc) => doc["school"].toString())
          .toSet()
          .toList();

      print("Schools = $schools");

      setState(() {
        schoolList = schools;
      });
    } catch (e) {
      print("ERROR = $e");
    }
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
      // INVENTORY / PRODUCT ID
      // FIND PRODUCT FROM FIREBASE
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

      final productDoc = productSnapshot.docs.first;

      final product = productDoc.data();

      final inventoryId = productDoc.id;

      final price = product["price"];

      final schoolCode = product["schoolCode"];

      // PARENT DOC ID

      // PARENT DOCUMENT
      final inventoryDoc = FirebaseFirestore.instance
          .collection("inventory")
          .doc(inventoryId);
      final batchId = "BATCH_${DateTime.now().millisecondsSinceEpoch}";

      setState(() {
        currentBatchId = batchId;
        currentInventoryId = inventoryId;
      });

      final batchDoc = inventoryDoc.collection("batches").doc(batchId);
      final existingDoc = await inventoryDoc.get();

      int oldAvailableStock = 0;
      int oldInStock = 0;
      int nextQrNumber = 1;

      if (existingDoc.exists) {
        final data = existingDoc.data()!;

        oldAvailableStock = data["availableStock"] ?? 0;

        oldInStock = data["inStock"] ?? 0;

        nextQrNumber = data["nextQrNumber"] ?? 1;
      }
      // CREATE OR UPDATE PARENT
      await inventoryDoc.set({
        "school": school,

        "className": className,
        "schoolCode": schoolCode,

        "nextQrNumber": nextQrNumber,

        "price": price,
        "inStock": oldInStock,
        "availableStock": oldAvailableStock + stock,

        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      await batchDoc.set({
        "batchId": batchId,
        "createdAt": Timestamp.now(),
        "totalQr": stock,
        "pdfUrl": "",
        "price": price,
      });

      // CREATE QR DOCS
      for (int i = 0; i < stock; i++) {
        final serial = (nextQrNumber + i).toString().padLeft(6, '0');

        final qrId = "$schoolCode$className-$serial";

        await batchDoc.collection("qrs").doc(qrId).set({
          "qrId": qrId,
          "batchId": batchId,
          "status": "godown",
          "sold": false,
          "createdAt": Timestamp.now(),
        });

        await inventoryDoc.collection("qrs").doc(qrId).set({
          "qrId": qrId,
          "batchId": batchId,
          "school": school,
          "schoolCode": schoolCode,
          "className": className,
          "price": price,
          "status": "godown",
          "sold": false,
          "invoiceId": "",
          "createdAt": Timestamp.now(),
        });
      }

      await inventoryDoc.update({"nextQrNumber": nextQrNumber + stock});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$stock book sets added to inventory.")),
      );

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

  Future<void> transferToShop(
    String inventoryId,
    int availableStock,
    int inStock,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Transfer To Shop"),

          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter Quantity"),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(controller.text) ?? 0;

                if (qty <= 0 || qty > availableStock) {
                  return;
                }

                await FirebaseFirestore.instance
                    .collection("inventory")
                    .doc(inventoryId)
                    .update({
                      "availableStock": availableStock - qty,

                      "inStock": inStock + qty,
                    });

                Navigator.pop(context);

                setState(() {});
              },
              child: const Text("Transfer"),
            ),
          ],
        );
      },
    );
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

                        final inventoryId = item.id;

                        final inStock = item["inStock"] ?? 0;

                        final availableStock = item["availableStock"] ?? 0;

                        final searchTarget = "$school $className".toLowerCase();

                        if (!searchTarget.contains(searchText)) {
                          return const SizedBox();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),

                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),

                            borderRadius: BorderRadius.circular(20),

                            border: Border.all(color: const Color(0xFF21262D)),
                          ),

                          child: Column(
                            children: [
                              ListTile(
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

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    const SizedBox(height: 6),

                                    Text(
                                      className,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "🏪 Shop Stock : $inStock",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),

                                    Text(
                                      "📦 Godown Stock : $availableStock",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),

                                    if (inStock < 5)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),

                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),

                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(
                                            0.15,
                                          ),

                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),

                                        child: const Text(
                                          "⚠ Refill Required",
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                trailing: Text(
                                  "₹$price",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                ),

                                child: SizedBox(
                                  width: double.infinity,

                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      transferToShop(
                                        inventoryId,
                                        availableStock,
                                        inStock,
                                      );
                                    },

                                    icon: const Icon(Icons.swap_horiz),

                                    label: const Text("Transfer To Shop"),

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10A37F),

                                      foregroundColor: Colors.black,

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
