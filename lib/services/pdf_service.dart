import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateBatchPdf({
    required String inventoryId,
    required String batchId,
  }) async {
    final pdf = pw.Document();

    final batchDoc = await FirebaseFirestore.instance
        .collection('inventory')
        .doc(inventoryId)
        .collection('batches')
        .doc(batchId)
        .get();

    if (!batchDoc.exists) {
      throw Exception("Batch not found");
    }

    final batchData = batchDoc.data()!;

    final int price = batchData["price"] ?? 0;

    final qrSnapshot = await batchDoc.reference.collection("qrs").get();

    final qrDocs = qrSnapshot.docs;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: qrDocs.map((doc) {
                final qrId = doc["qrId"];

                return _buildLabel(qrId: qrId, price: price);
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return pdf.save();
      },
    );
  }

  static pw.Widget _buildLabel({required String qrId, required int price}) {
    return pw.Container(
      width: 160,
      height: 120,
      padding: const pw.EdgeInsets.all(6),

      decoration: pw.BoxDecoration(border: pw.Border.all()),

      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: qrId,
            width: 70,
            height: 70,
          ),

          pw.Text(
            "₹$price",
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),

          pw.Text(
            qrId,
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}
