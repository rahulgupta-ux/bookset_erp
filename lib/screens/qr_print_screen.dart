import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPrintScreen extends StatelessWidget {
  final String qrId;

  const QrPrintScreen({super.key, required this.qrId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Print QR")),

      body: Center(
        child: Container(
          width: 320,

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(20),

            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              QrImageView(data: qrId, size: 220, backgroundColor: Colors.white),

              const SizedBox(height: 20),

              Text(
                qrId,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 18,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Printing Feature Coming Soon"),
                      ),
                    );
                  },

                  child: const Text("Print Label"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
