import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/book_set.dart';

import 'cart_screen.dart';

class QuickSellScreen extends StatefulWidget {
  const QuickSellScreen({super.key});

  @override
  State<QuickSellScreen> createState() => _QuickSellScreenState();
}

class _QuickSellScreenState extends State<QuickSellScreen> {
  List<BookSet> cartItems = [];

  bool isScanning = false;

  double total = 0;

  Future<void> scanQr(String qrId) async {
    if (isScanning) return;

    isScanning = true;

    final soldCheck = await FirebaseFirestore.instance
        .collection("sold_qrs")
        .doc(qrId)
        .get();

    if (soldCheck.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("QR already SOLD")));

      isScanning = false;

      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection("inventory")
        .doc(qrId)
        .get();

    if (!snapshot.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("QR not found")));

      isScanning = false;

      return;
    }

    final data = snapshot.data()!;

    final alreadyAdded = cartItems.any((item) => item.qrId == qrId);

    if (alreadyAdded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Already Added")));

      isScanning = false;

      return;
    }

    final book = BookSet(
      school: data["school"],

      className: data["className"],

      qrId: data["qrId"],

      price: data["price"],

      stock: 1,
    );

    setState(() {
      cartItems.add(book);

      total += book.price;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${book.className} Added")));

    await Future.delayed(const Duration(milliseconds: 800));

    isScanning = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quick Sell Mode"),

        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (_) => CartScreen(cartItems: cartItems),
                ),
              );
            },

            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),

                Positioned(
                  right: 0,

                  child: CircleAvatar(
                    radius: 8,

                    backgroundColor: Colors.red,

                    child: Text(
                      cartItems.length.toString(),

                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            flex: 4,

            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first;

                final code = barcode.rawValue;

                if (code != null) {
                  scanQr(code.trim());
                }
              },
            ),
          ),

          Expanded(
            flex: 2,

            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(color: Colors.blue.shade50),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Current Cart",

                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  Expanded(
                    child: ListView(
                      children: cartItems.map((item) {
                        return ListTile(
                          title: Text(item.school),

                          subtitle: Text(item.className),

                          trailing: Text("₹${item.price}"),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Total: ₹$total",

                    style: const TextStyle(
                      fontSize: 28,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
