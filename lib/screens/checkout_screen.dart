import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_set.dart';

class CheckoutScreen extends StatefulWidget {
  final int finalTotal;

  final bool soldToSchool;

  final String invoiceId;

  final List<BookSet> soldBooks;

  final int discount;

  final int originalTotal;

  const CheckoutScreen({
    super.key,

    required this.finalTotal,

    required this.soldToSchool,

    required this.invoiceId,

    required this.soldBooks,
    required this.discount,

    required this.originalTotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool isLoading = false;

  Future<void> savePayment() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Save sale
      await FirebaseFirestore.instance
          .collection("sales")
          .doc(widget.invoiceId)
          .set({
            "invoiceId": widget.invoiceId,

            "originalTotal": widget.originalTotal,

            "discount": widget.discount,

            "finalTotal": widget.finalTotal,

            "soldToSchool": widget.soldToSchool,

            "timestamp": Timestamp.now(),

            "books": widget.soldBooks.map((book) {
              return {
                "qrId": book.qrId,

                "school": book.school,

                "className": book.className,

                "originalPrice": book.price,
              };
            }).toList(),
          });

      // Mark inventory sold
      final soldPricePerBook = widget.finalTotal ~/ widget.soldBooks.length;
      for (var book in widget.soldBooks) {
        final qrQuery = await FirebaseFirestore.instance
            .collectionGroup("qrs")
            .where("qrId", isEqualTo: book.qrId)
            .limit(1)
            .get();

        if (qrQuery.docs.isEmpty) {
          continue;
        }

        await qrQuery.docs.first.reference.update({
          "sold": true,
          "soldPrice": soldPricePerBook,
          "originalPrice": book.price,
          "invoiceId": widget.invoiceId,
          "soldAt": Timestamp.now(),
          "status": "sold",
        });
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Saved Successfully")),
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pop(context, true);
        });
      }
    } on FirebaseException catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Firebase Error: ${e.message}")));
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(
              widget.invoiceId,

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Text(
              widget.soldToSchool ? "School Sale" : "Retail Sale",

              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,

                    blurRadius: 10,

                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: QrImageView(
                data:
                    "upi://pay?"
                    "pa=BHARATPE.0104724121@indus"
                    "&pn=AVNISH GUPTA"
                    "&am=${widget.finalTotal}"
                    "&cu=INR"
                    "&tn=${widget.invoiceId}",

                version: QrVersions.auto,

                size: 250,

                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "₹${widget.finalTotal}",

              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: isLoading ? null : savePayment,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,

                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Received",

                        style: TextStyle(fontSize: 22, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),

                child: const Text(
                  "Back To Scan",

                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
