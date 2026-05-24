import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/book_set.dart';
import 'cart_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool isProcessing = false;

  List<BookSet> cartItems = [];

  double total = 0;

  final Set<String> scannedQrsInCart = {};

  final AudioPlayer player = AudioPlayer();

  final TextEditingController manualQrController = TextEditingController();

  Future<void> addItemToCart(String qrId) async {
    qrId = qrId.trim();

    if (isProcessing || qrId.isEmpty) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // Prevent duplicate cart scan
      if (scannedQrsInCart.contains(qrId)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Already In Cart")));

        return;
      }

      // SEARCH QR IN ALL qrs SUBCOLLECTIONS
      final qrQuery = await FirebaseFirestore.instance
          .collectionGroup("qrs")
          .get();

      DocumentSnapshot? qrDoc;

      for (var doc in qrQuery.docs) {
        if (doc.id == qrId) {
          qrDoc = doc;

          break;
        }
      }

      if (qrDoc == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("QR Not Found")));

        return;
      }

      final qrData = qrDoc.data() as Map<String, dynamic>;

      // CHECK SOLD
      final sold = (qrData["sold"] ?? false) as bool;

      if (sold) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Already Sold")));

        return;
      }

      // GET PARENT PRODUCT DOCUMENT

      final productDoc = await qrDoc.reference.parent.parent!.get();

      if (!productDoc.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Product Missing")));

        return;
      }

      final productData = productDoc.data()!;

      // CREATE CART ITEM
      final bookSet = BookSet(
        qrId: qrId,

        school: productData["school"],

        className: productData["className"],

        price: productData["price"],

        stock: 1,
      );

      setState(() {
        cartItems.add(bookSet);

        scannedQrsInCart.add(qrId);

        total += bookSet.price;
      });

      // BEEP SOUND
      await player.play(AssetSource('sounds/beep2.wav'));

      // VIBRATION
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 120, amplitude: 128);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added: ${bookSet.school} ${bookSet.className}"),

          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Scan Book Set",

              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Container(
              height: 350,

              width: double.infinity,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),

                child: MobileScanner(
                  onDetect: (capture) async {
                    if (isProcessing) {
                      return;
                    }

                    final barcodes = capture.barcodes;

                    for (final barcode in barcodes) {
                      final code = barcode.rawValue ?? "";

                      if (code.isNotEmpty) {
                        await addItemToCart(code);

                        break;
                      }
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Center(
              child: Text(
                "OR",

                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Enter QR ID Manually",

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: manualQrController,

              decoration: InputDecoration(
                hintText: "Enter QR ID",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),

                prefixIcon: const Icon(Icons.edit),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        await addItemToCart(manualQrController.text.trim());

                        manualQrController.clear();
                      },

                child: const Text("Add To Cart"),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),

                onPressed: () async {
                  final updatedCart = await Navigator.push<List<BookSet>>(
                    context,

                    MaterialPageRoute(
                      builder: (_) => CartScreen(cartItems: cartItems),
                    ),
                  );

                  if (updatedCart != null) {
                    setState(() {
                      cartItems = updatedCart;

                      total = cartItems.fold(
                        0,

                        (sum, item) => sum + item.price,
                      );

                      scannedQrsInCart.clear();

                      for (var item in cartItems) {
                        scannedQrsInCart.add(item.qrId);
                      }
                    });
                  }
                },

                child: Text(
                  "Go To Cart (${cartItems.length})",

                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,

                borderRadius: BorderRadius.circular(15),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Cart Summary",

                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text("Items: ${cartItems.length}"),

                  Text(
                    "Total: ₹${total.toStringAsFixed(0)}",

                    style: const TextStyle(
                      fontSize: 18,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
