import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_set.dart';

class InventoryRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<BookSet?> findBookByQr(String qrId) async {
    final qrQuery = await firestore
        .collectionGroup("qrs")
        .where("qrId", isEqualTo: qrId)
        .limit(1)
        .get();

    if (qrQuery.docs.isEmpty) {
      return null;
    }

    final qrDoc = qrQuery.docs.first;

    final qrData = qrDoc.data();

    if ((qrData["sold"] ?? false)) {
      throw Exception("ALREADY_SOLD");
    }

    DocumentReference inventoryRef;

    final parentDoc = qrDoc.reference.parent.parent!;

    if (parentDoc.parent.id == "inventory") {
      inventoryRef = parentDoc;
    } else {
      inventoryRef = parentDoc.parent.parent!;
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
