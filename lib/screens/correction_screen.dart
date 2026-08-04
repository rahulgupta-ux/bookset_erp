import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'common/qr_scanner_screen.dart';

enum CorrectionMode { reconcile, recoverSold }

class CorrectionScreen extends StatefulWidget {
  const CorrectionScreen({super.key});

  @override
  State<CorrectionScreen> createState() => _CorrectionScreenState();
}

class PendingUpdate {
  final DocumentReference reference;

  final bool newSold;

  final String qrId;

  const PendingUpdate({
    required this.reference,
    required this.newSold,
    required this.qrId,
  });
}

class _CorrectionScreenState extends State<CorrectionScreen> {
  //--------------------------------------------------
  // Scanner Result
  //--------------------------------------------------
  List<ScannedQr> scannedResults = [];

  final Set<String> scannedQrs = {};

  DocumentReference? inventoryReference;
  List<QueryDocumentSnapshot> inventoryQrDocs = [];
  List<PendingUpdate> pendingUpdates = [];

  //--------------------------------------------------
  // Inventory Info
  //--------------------------------------------------

  String schoolName = "";

  String className = "";

  //--------------------------------------------------
  // Preview Values
  //--------------------------------------------------

  int totalSets = 0;

  int remainingSets = 0;

  int needUpdate = 0;

  int alreadyCorrect = 0;

  int willBecomeSold = 0;

  int recoveredSets = 0;

  //--------------------------------------------------
  // UI
  //--------------------------------------------------

  bool loading = false;
  CorrectionMode correctionMode = CorrectionMode.reconcile;

  //--------------------------------------------------
  // Scan Inventory
  //--------------------------------------------------

  bool get isReconcile => correctionMode == CorrectionMode.reconcile;

  bool get isRecovery => correctionMode == CorrectionMode.recoverSold;

  Future<void> startScanning() async {
    if (isReconcile) {
      await startReconciliation();
    } else {
      await startRecovery();
    }
  }

  Future<void> startReconciliation() async {
    final List<ScannedQr>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          mode: ScannerMode.correction,
          correctionMode: correctionMode,
        ),
      ),
    );

    if (result == null || result.isEmpty) {
      return;
    }

    scannedResults = result;

    scannedQrs.clear();

    for (final qr in result) {
      scannedQrs.add(qr.qrId);
    }

    inventoryReference = result.first.inventoryReference;

    await loadInventoryInfo();

    await loadInventoryQrs();

    await previewReconciliation();

    setState(() {});
  }

  Future<void> startRecovery() async {
    final List<ScannedQr>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          mode: ScannerMode.correction,
          correctionMode: correctionMode,
        ),
      ),
    );

    if (result == null || result.isEmpty) {
      return;
    }

    scannedResults = result;

    scannedQrs.clear();

    pendingUpdates.clear();

    recoveredSets = result.length;

    for (final qr in result) {
      scannedQrs.add(qr.qrId);

      pendingUpdates.add(
        PendingUpdate(reference: qr.qrReference, newSold: false, qrId: qr.qrId),
      );
    }

    needUpdate = pendingUpdates.length;

    totalSets = 0;

    remainingSets = 0;

    alreadyCorrect = 0;

    willBecomeSold = 0;

    schoolName = "Multiple Inventories";

    className = "${result.length} QR Scanned";

    setState(() {});
  }

  Future<void> loadInventoryInfo() async {
    if (inventoryReference == null) {
      return;
    }

    final snapshot = await inventoryReference!.get();

    final data = snapshot.data() as Map<String, dynamic>;

    schoolName = data["school"] ?? "";

    className = data["className"] ?? "";
  }

  Future<void> loadInventoryQrs() async {
    if (inventoryReference == null) {
      return;
    }

    final snapshot = await inventoryReference!.collection("qrs").get();

    inventoryQrDocs = snapshot.docs;
  }

  //--------------------------------------------------
  // Clear
  //--------------------------------------------------

  void clearAll() {
    scannedResults.clear();

    scannedQrs.clear();

    inventoryReference = null;

    inventoryQrDocs.clear();

    pendingUpdates.clear();

    schoolName = "";

    className = "";

    totalSets = 0;

    remainingSets = 0;

    needUpdate = 0;

    alreadyCorrect = 0;

    willBecomeSold = 0;

    recoveredSets = 0;

    setState(() {});
  }

  //--------------------------------------------------
  // Placeholder
  //--------------------------------------------------

  Future<void> previewCorrection() async {
    if (isReconcile) {
      await previewReconciliation();
    } else {
      await previewRecovery();
    }
  }

  Future<void> previewReconciliation() async {
    totalSets = inventoryQrDocs.length;

    remainingSets = scannedQrs.length;

    needUpdate = 0;

    alreadyCorrect = 0;

    willBecomeSold = 0;

    recoveredSets = 0;

    pendingUpdates.clear();

    for (final doc in inventoryQrDocs) {
      final data = doc.data() as Map<String, dynamic>;

      final qrId = data["qrId"];

      final oldSold = data["sold"] ?? false;

      final shouldBeSold = !scannedQrs.contains(qrId);

      if (shouldBeSold) {
        willBecomeSold++;
      }

      if (oldSold == shouldBeSold) {
        alreadyCorrect++;
      } else {
        needUpdate++;

        pendingUpdates.add(
          PendingUpdate(
            reference: doc.reference,
            newSold: shouldBeSold,
            qrId: qrId,
          ),
        );
      }
    }

    setState(() {});
  }

  Future<void> previewRecovery() async {
    pendingUpdates.clear();

    recoveredSets = 0;

    needUpdate = 0;

    for (final qr in scannedResults) {
      final snapshot = await qr.qrReference.get();

      if (!snapshot.exists) {
        continue;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      final sold = data["sold"] ?? false;

      if (!sold) {
        continue;
      }

      recoveredSets++;

      needUpdate++;

      pendingUpdates.add(
        PendingUpdate(reference: qr.qrReference, newSold: false, qrId: qr.qrId),
      );
    }

    totalSets = 0;

    remainingSets = recoveredSets;

    alreadyCorrect = scannedResults.length - recoveredSets;

    willBecomeSold = 0;

    setState(() {});
  }

  Future<void> applyCorrection() async {
    if (isReconcile) {
      await applyReconciliation();
    } else {
      await applyRecovery();
    }
  }

  Future<void> applyReconciliation() async {
    if (pendingUpdates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nothing to update")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Reconciliation"),
        content: Text("Update ${pendingUpdates.length} QR Codes?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Apply"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await executeBatchUpdate();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Completed"),
        content: Text("${pendingUpdates.length} QR Codes updated."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> applyRecovery() async {
    if (pendingUpdates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No Sold Sets Found")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Recover Sold Sets"),
        content: Text("Recover ${pendingUpdates.length} scanned QR Codes?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Recover"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await executeBatchUpdate();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Recovery Complete"),
        content: Text(
          "${pendingUpdates.length} QR Codes recovered successfully.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> executeBatchUpdate() async {
    setState(() {
      loading = true;
    });

    final firestore = FirebaseFirestore.instance;

    const batchLimit = 500;

    for (int i = 0; i < pendingUpdates.length; i += batchLimit) {
      final batch = firestore.batch();

      final chunk = pendingUpdates.skip(i).take(batchLimit);

      for (final item in chunk) {
        batch.update(item.reference, {
          "sold": item.newSold,
          "corrected": true,
          "correctedAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }

    setState(() {
      loading = false;
    });
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Reconciliation"),

        centerTitle: true,
      ),

      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                RadioListTile<CorrectionMode>(
                  title: const Text("Inventory Reconciliation"),
                  value: CorrectionMode.reconcile,
                  groupValue: correctionMode,
                  onChanged: (value) {
                    setState(() {
                      correctionMode = value!;
                      clearAll();
                    });
                  },
                ),

                const Divider(),

                RadioListTile<CorrectionMode>(
                  title: const Text("Recover Sold Sets"),
                  value: CorrectionMode.recoverSold,
                  groupValue: correctionMode,
                  onChanged: (value) {
                    setState(() {
                      correctionMode = value!;
                      clearAll();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: startScanning,

                    icon: const Icon(Icons.qr_code_scanner),

                    label: const Text("Start Scan"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  summaryRow("School", schoolName.isEmpty ? "--" : schoolName),

                  summaryRow("Class", className.isEmpty ? "--" : className),

                  summaryRow("Scanned", scannedQrs.length.toString()),

                  summaryRow("Total Sets", totalSets.toString()),

                  summaryRow("Remaining", remainingSets.toString()),

                  summaryRow("Need Update", needUpdate.toString()),

                  summaryRow("Already Correct", alreadyCorrect.toString()),

                  if (correctionMode == CorrectionMode.reconcile)
                    summaryRow("Will Become Sold", willBecomeSold.toString())
                  else
                    summaryRow("Will Recover", needUpdate.toString()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: clearAll,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),

                    child: const Text("Clear"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: needUpdate == 0 ? null : applyCorrection,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),

                    child: Text(
                      correctionMode == CorrectionMode.reconcile
                          ? "Apply ($needUpdate)"
                          : "Recover ($needUpdate)",
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: ListView.builder(
              itemCount: scannedQrs.length,

              itemBuilder: (_, index) {
                final qr = scannedQrs.elementAt(index);

                return ListTile(
                  leading: const Icon(Icons.qr_code, color: Colors.green),

                  title: Text(qr),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // Summary Row
  //--------------------------------------------------

  Widget summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
