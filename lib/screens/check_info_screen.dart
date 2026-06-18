import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CheckInfoScreen extends StatefulWidget {
  const CheckInfoScreen({super.key});

  @override
  State<CheckInfoScreen> createState() => _CheckInfoScreenState();
}

class _CheckInfoScreenState extends State<CheckInfoScreen> {
  final TextEditingController qrController = TextEditingController();

  Map<String, dynamic>? foundBook;

  bool isLoading = false;

  bool isScanned = false;

  bool isSold = false;

  Future<void> searchBook(String qrId) async {
    if (qrId.isEmpty) return;

    setState(() {
      isLoading = true;

      foundBook = null;

      isSold = false;
    });

    final inventorySnapshot = await FirebaseFirestore.instance
        .collection("inventory")
        .doc(qrId)
        .get();

    final soldSnapshot = await FirebaseFirestore.instance
        .collection("sold_qrs")
        .doc(qrId)
        .get();

    if (inventorySnapshot.exists) {
      foundBook = inventorySnapshot.data();

      isSold = soldSnapshot.exists;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Check Book Set Info",

                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Container(
                height: 300,

                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  color: Colors.black12,
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),

                  child: MobileScanner(
                    onDetect: (capture) async {
                      if (isScanned) return;

                      final List<Barcode> barcodes = capture.barcodes;

                      for (final barcode in barcodes) {
                        final String code = barcode.rawValue ?? "";

                        if (code.isEmpty) return;

                        isScanned = true;

                        qrController.text = code;

                        await searchBook(code);

                        isScanned = false;

                        break;
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Row(
                children: [
                  Expanded(child: Divider(thickness: 1)),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),

                    child: Text(
                      "OR",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Expanded(child: Divider(thickness: 1)),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Enter QR ID Manually",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: qrController,

                decoration: InputDecoration(
                  hintText: "Enter QR ID",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),

                  prefixIcon: const Icon(Icons.qr_code),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    searchBook(qrController.text.trim());
                  },

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),

                  child: const Text(
                    "Check Info",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              if (isLoading) const Center(child: CircularProgressIndicator()),

              if (!isLoading && foundBook == null)
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.red.shade50,

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: const Text(
                    "Book Set Not Found",

                    style: TextStyle(
                      fontSize: 22,

                      fontWeight: FontWeight.bold,

                      color: Colors.red,
                    ),
                  ),
                ),

              if (!isLoading && foundBook != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      children: [
                        if (foundBook!.containsKey("imageUrl") &&
                            foundBook!["imageUrl"] != "")
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),

                            child: Image.network(
                              foundBook!["imageUrl"],

                              height: 220,

                              width: double.infinity,

                              fit: BoxFit.cover,
                            ),
                          ),

                        const SizedBox(height: 20),

                        Text(
                          foundBook!["school"],

                          style: const TextStyle(
                            fontSize: 28,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(foundBook!["className"]),

                        const SizedBox(height: 10),

                        Text("Price: ₹${foundBook!["price"]}"),

                        const SizedBox(height: 10),

                        Text("Stock: ${foundBook!["stock"]}"),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(15),

                          decoration: BoxDecoration(
                            color: isSold
                                ? Colors.red.shade50
                                : Colors.green.shade50,

                            borderRadius: BorderRadius.circular(15),
                          ),

                          child: Text(
                            isSold
                                ? "THIS BOOK SET IS SOLD"
                                : "AVAILABLE FOR SALE",

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 18,

                              fontWeight: FontWeight.bold,

                              color: isSold ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
