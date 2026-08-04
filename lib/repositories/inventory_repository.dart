import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_set.dart';

class InventoryRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<BookSet?> findBookByQr(
    String qrId,
    DocumentReference qrReference,
  ) async {
    final qrSnapshot = await qrReference.get();

    if (!qrSnapshot.exists) {
      return null;
    }

    final qrDoc = qrSnapshot;

    final qrData = qrDoc.data() as Map<String, dynamic>;

    if ((qrData["sold"] ?? false)) {
      throw Exception("ALREADY_SOLD");
    }

    DocumentReference inventoryRef;

    final parentDoc = qrDoc.reference.parent.parent!;

    if (parentDoc.parent!.id == "inventory") {
      inventoryRef = parentDoc;
    } else {
      inventoryRef = parentDoc.parent!.parent!;
    }

    final inventorySnapshot = await inventoryRef.get();

    final inventoryData = inventorySnapshot.data() as Map<String, dynamic>;

    return BookSet(
      school: inventoryData["school"],
      className: inventoryData["className"],
      qrId: qrId,
      price: inventoryData["price"],
      stock: 1,
      inventoryId: inventorySnapshot.id,
    );
  }
}
