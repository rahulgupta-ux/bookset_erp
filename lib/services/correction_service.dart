import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/common/qr_scanner_screen.dart';

class CorrectionItem {
  final DocumentReference qrReference;

  final String qrId;

  final bool oldSold;

  final bool newSold;

  const CorrectionItem({
    required this.qrReference,

    required this.qrId,

    required this.oldSold,

    required this.newSold,
  });
}

class CorrectionPreview {
  final int total;

  final int remaining;

  final int alreadyCorrect;

  final int needUpdate;

  final int willBecomeSold;

  final List<CorrectionItem> updates;

  const CorrectionPreview({
    required this.total,

    required this.remaining,

    required this.alreadyCorrect,

    required this.needUpdate,

    required this.willBecomeSold,

    required this.updates,
  });
}

class CorrectionService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> applyCorrection({required CorrectionPreview preview}) async {
    const batchLimit = 500;

    for (int i = 0; i < preview.updates.length; i += batchLimit) {
      final batch = firestore.batch();

      final chunk = preview.updates.skip(i).take(batchLimit);

      for (final item in chunk) {
        batch.update(item.qrReference, {
          "sold": item.newSold,

          "corrected": true,

          "correctedAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }
  }

  Future<CorrectionPreview> buildPreview({
    required ScannerResult result,
  }) async {
    final snapshot = await result.inventoryReference.collection("qrs").get();

    final Set<String> remainingQrs = result.scannedQrs
        .map((e) => e.qrId)
        .toSet();

    int total = 0;

    int alreadyCorrect = 0;

    int needUpdate = 0;

    int willBecomeSold = 0;

    List<CorrectionItem> updates = [];

    for (final doc in snapshot.docs) {
      total++;

      final data = doc.data();

      final qrId = data["qrId"];

      final oldSold = data["sold"] ?? false;

      final shouldBeSold = !remainingQrs.contains(qrId);

      if (shouldBeSold) {
        willBecomeSold++;
      }

      if (oldSold == shouldBeSold) {
        alreadyCorrect++;

        continue;
      }

      needUpdate++;

      updates.add(
        CorrectionItem(
          qrReference: doc.reference,

          qrId: qrId,

          oldSold: oldSold,

          newSold: shouldBeSold,
        ),
      );
    }

    return CorrectionPreview(
      total: total,

      remaining: remainingQrs.length,

      alreadyCorrect: alreadyCorrect,

      needUpdate: needUpdate,

      willBecomeSold: willBecomeSold,

      updates: updates,
    );
  }
}
