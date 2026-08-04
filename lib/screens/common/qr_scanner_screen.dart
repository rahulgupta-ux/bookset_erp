import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import '../correction_screen.dart';

enum ScannerMode { sale, correction, inventory }

class ScannedQr {
  final String qrId;

  final DocumentReference qrReference;

  final DocumentReference inventoryReference;

  const ScannedQr({
    required this.qrId,
    required this.qrReference,
    required this.inventoryReference,
  });
}

class QrScannerScreen extends StatefulWidget {
  final ScannerMode mode;

  final CorrectionMode? correctionMode;

  const QrScannerScreen({super.key, required this.mode, this.correctionMode});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  //-------------------------------------------------------
  // Scanner
  //-------------------------------------------------------

  final MobileScannerController scannerController = MobileScannerController();

  final AudioPlayer player = AudioPlayer();

  double zoomScale = 0;

  //-------------------------------------------------------
  // Queue
  //-------------------------------------------------------

  final Queue<String> scanQueue = Queue();

  bool processingQueue = false;

  //-------------------------------------------------------
  // Cache
  //-------------------------------------------------------

  final Map<String, DocumentReference> qrIndex = {};

  bool cacheLoaded = false;

  //-------------------------------------------------------
  // Result
  //-------------------------------------------------------

  final List<ScannedQr> scannedQrs = [];

  final Set<String> scannedIds = {};

  //-------------------------------------------------------
  // Inventory Lock
  //-------------------------------------------------------

  DocumentReference? lockedInventory;

  //-------------------------------------------------------
  // UI
  //-------------------------------------------------------

  bool animateBox = false;

  bool scanSuccess = false;

  bool showStatus = false;

  Color statusColor = Colors.green;

  String statusMessage = "";

  String currentProcessingQr = "";

  //-------------------------------------------------------
  // Manual Entry
  //-------------------------------------------------------

  final TextEditingController manualController = TextEditingController();

  bool showManualSubmit = false;

  //-------------------------------------------------------
  // Init
  //-------------------------------------------------------

  @override
  void initState() {
    super.initState();

    initialize();

    startAnimation();
  }

  //-------------------------------------------------------
  // Dispose
  //-------------------------------------------------------

  @override
  void dispose() {
    scannerController.dispose();

    player.dispose();

    manualController.dispose();

    super.dispose();
  }

  //-------------------------------------------------------
  // Load QR Cache
  //-------------------------------------------------------

  Future<void> initialize() async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup("qrs")
        .get();

    qrIndex.clear();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final qrId = data["qrId"];

      if (qrId != null) {
        qrIndex[qrId] = doc.reference;
      }
    }

    if (!mounted) return;

    setState(() {
      cacheLoaded = true;
    });
  }

  //-------------------------------------------------------
  // Animation
  //-------------------------------------------------------

  void startAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return false;

      setState(() {
        animateBox = !animateBox;
      });

      return true;
    });
  }

  //-------------------------------------------------------
  // Status Card
  //-------------------------------------------------------

  Future<void> showStatusCard(String message, Color color) async {
    if (!mounted) return;

    setState(() {
      statusMessage = message;

      statusColor = color;

      showStatus = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() {
      showStatus = false;
    });
  }

  //-------------------------------------------------------
  // Scan Success
  //-------------------------------------------------------

  Future<void> triggerSuccess() async {
    setState(() {
      scanSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    setState(() {
      scanSuccess = false;
    });
  }

  //-------------------------------------------------------
  // Queue QR
  //-------------------------------------------------------

  void enqueueQr(String qrId) {
    qrId = qrId.trim();

    if (scannedIds.contains(qrId)) {
      showStatusCard("Already Scanned", Colors.orange);

      return;
    }

    if (scanQueue.contains(qrId)) {
      return;
    }

    scanQueue.add(qrId);

    player.play(AssetSource("sounds/beep2.wav"));

    Vibration.vibrate(duration: 50);

    processQueue();
  }

  //-------------------------------------------------------
  // Process Queue
  //-------------------------------------------------------

  //-------------------------------------------------------
  // Process Queue
  //-------------------------------------------------------

  Future<void> processQueue() async {
    if (processingQueue) return;

    processingQueue = true;

    while (scanQueue.isNotEmpty) {
      final qr = scanQueue.removeFirst();

      setState(() {
        currentProcessingQr = qr;
      });

      await scanQr(qr);
    }

    processingQueue = false;

    if (mounted) {
      setState(() {
        currentProcessingQr = "";
      });
    }
  }

  //////////////////////////////////////////////////////////
  // Scan QR
  //////////////////////////////////////////////////////////

  Future<void> scanQr(String qrId) async {
    try {
      //--------------------------------------------------
      // Find QR Reference
      //--------------------------------------------------

      final qrReference = qrIndex[qrId];

      if (qrReference == null) {
        await showStatusCard("QR Not Found", Colors.red);
        return;
      }

      //--------------------------------------------------
      // Read QR Document
      //--------------------------------------------------

      final qrSnapshot = await qrReference.get();

      if (!qrSnapshot.exists) {
        await showStatusCard("QR Missing", Colors.red);
        return;
      }

      final qrData = qrSnapshot.data() as Map<String, dynamic>;

      //--------------------------------------------------
      // Find Inventory Reference
      //--------------------------------------------------

      DocumentReference inventoryRef;

      final parentDoc = qrReference.parent.parent!;

      if (parentDoc.parent!.id == "inventory") {
        inventoryRef = parentDoc;
      } else {
        inventoryRef = parentDoc.parent!.parent!;
      }

      //--------------------------------------------------
      // Inventory Lock
      //--------------------------------------------------

      if (widget.mode == ScannerMode.correction &&
          widget.correctionMode == CorrectionMode.reconcile) {
        if (lockedInventory == null) {
          lockedInventory = inventoryRef;
        } else if (lockedInventory!.path != inventoryRef.path) {
          await showStatusCard("Wrong Inventory", Colors.red);
          return;
        }
      }

      //--------------------------------------------------
      // Duplicate
      //--------------------------------------------------

      if (scannedIds.contains(qrId)) {
        await showStatusCard("Already Scanned", Colors.orange);
        return;
      }

      //--------------------------------------------------
      // Save Result
      //--------------------------------------------------

      scannedIds.add(qrId);

      scannedQrs.add(
        ScannedQr(
          qrId: qrId,
          qrReference: qrReference,
          inventoryReference: inventoryRef,
        ),
      );

      await triggerSuccess();

      await showStatusCard("Scanned", Colors.green);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());

      await showStatusCard("Error", Colors.red);
    }
  }

  //////////////////////////////////////////////////////////
  // Finish Scanning
  //////////////////////////////////////////////////////////

  void finishScanning() {
    Navigator.pop(context, scannedQrs);
  }

  Widget scannerCorner({required bool top, required bool left}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(
                  color: scanSuccess ? Colors.greenAccent : Colors.white,
                  width: 4,
                )
              : BorderSide.none,
          bottom: !top
              ? BorderSide(
                  color: scanSuccess ? Colors.greenAccent : Colors.white,
                  width: 4,
                )
              : BorderSide.none,
          left: left
              ? BorderSide(
                  color: scanSuccess ? Colors.greenAccent : Colors.white,
                  width: 4,
                )
              : BorderSide.none,
          right: !left
              ? BorderSide(
                  color: scanSuccess ? Colors.greenAccent : Colors.white,
                  width: 4,
                )
              : BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!cacheLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },

        child: Stack(
          children: [
            //////////////////////////////////////////////////////
            // CAMERA
            //////////////////////////////////////////////////////
            GestureDetector(
              onVerticalDragUpdate: (details) async {
                if (details.delta.dy < 0) {
                  zoomScale += 0.05;
                } else {
                  zoomScale -= 0.05;
                }

                zoomScale = zoomScale.clamp(0.0, 1.0);

                await scannerController.setZoomScale(zoomScale);

                if (mounted) {
                  setState(() {});
                }
              },

              child: MobileScanner(
                controller: scannerController,

                onDetect: (capture) {
                  final barcode = capture.barcodes.first;

                  final code = barcode.rawValue;

                  if (code == null) return;

                  enqueueQr(code);
                },
              ),
            ),

            //////////////////////////////////////////////////////
            // STATUS CARD
            //////////////////////////////////////////////////////
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),

              top: showStatus ? 60 : -100,

              left: 35,

              right: 35,

              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),

                opacity: showStatus ? 1 : 0,

                child: Material(
                  color: Colors.transparent,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,

                      vertical: 15,
                    ),

                    decoration: BoxDecoration(
                      color: statusColor,

                      borderRadius: BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(.40),

                          blurRadius: 20,
                        ),
                      ],
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(
                          statusColor == Colors.green
                              ? Icons.check_circle
                              : statusColor == Colors.red
                              ? Icons.cancel
                              : Icons.info,

                          color: Colors.white,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          statusMessage,

                          style: const TextStyle(
                            color: Colors.white,

                            fontWeight: FontWeight.bold,

                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            //////////////////////////////////////////////////////
            // PROCESSING CARD
            //////////////////////////////////////////////////////
            Positioned(
              top: 130,

              right: 20,

              child: AnimatedOpacity(
                opacity: processingQueue ? 1 : 0,

                duration: const Duration(milliseconds: 250),

                child: Container(
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.black87,

                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(color: Colors.greenAccent),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Processing",

                        style: TextStyle(
                          color: Colors.greenAccent,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        currentProcessingQr,

                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Queue : ${scanQueue.length}",

                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            //////////////////////////////////////////////////////
            // DARK OVERLAY
            //////////////////////////////////////////////////////
            Container(color: Colors.black.withOpacity(0.25)),

            //////////////////////////////////////////////////////
            // SCANNER FRAME
            //////////////////////////////////////////////////////
            Center(
              child: Transform.translate(
                offset: const Offset(0, -70),
                child: AnimatedScale(
                  scale: animateBox ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      children: [
                        // TOP LEFT
                        Positioned(
                          top: 0,
                          left: 0,
                          child: scannerCorner(top: true, left: true),
                        ),

                        // TOP RIGHT
                        Positioned(
                          top: 0,
                          right: 0,
                          child: scannerCorner(top: true, left: false),
                        ),

                        // BOTTOM LEFT
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: scannerCorner(top: false, left: true),
                        ),

                        // BOTTOM RIGHT
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: scannerCorner(top: false, left: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            //////////////////////////////////////////////////////
            // TOP BAR
            //////////////////////////////////////////////////////
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: () async {
                        await scannerController.toggleTorch();
                      },

                      icon: const Icon(
                        Icons.flashlight_on,

                        color: Colors.white,
                      ),
                    ),

                    IconButton(
                      onPressed: () async {
                        await scannerController.switchCamera();
                      },

                      icon: const Icon(
                        Icons.flip_camera_android,

                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //////////////////////////////////////////////////////
            // INVENTORY INFO
            //////////////////////////////////////////////////////
            Positioned(
              top: 120,

              left: 20,

              child: Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.black87,

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(color: Colors.greenAccent),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Inventory",

                      style: TextStyle(
                        color: Colors.greenAccent,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.mode != ScannerMode.correction
                          ? "Disabled"
                          : widget.correctionMode == CorrectionMode.recoverSold
                          ? "All Inventories"
                          : lockedInventory == null
                          ? "Not Locked"
                          : "Locked",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            //////////////////////////////////////////////////////
            // SCAN COUNTER
            //////////////////////////////////////////////////////
            Positioned(
              bottom: 230,

              left: 20,

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: Colors.green,

                  borderRadius: BorderRadius.circular(30),
                ),

                child: Row(
                  children: [
                    const Icon(Icons.qr_code, color: Colors.white),

                    const SizedBox(width: 8),

                    Text(
                      "${scannedQrs.length} scanned",

                      style: const TextStyle(
                        color: Colors.white,

                        fontWeight: FontWeight.bold,

                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //////////////////////////////////////////////////////
            // MANUAL QR ENTRY
            //////////////////////////////////////////////////////
            Positioned(
              bottom: 135,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: manualController,

                          style: const TextStyle(color: Colors.white),

                          onChanged: (value) {
                            setState(() {
                              showManualSubmit = value.trim().isNotEmpty;
                            });
                          },

                          decoration: const InputDecoration(
                            hintText: "Enter QR manually",

                            hintStyle: TextStyle(color: Colors.white70),

                            border: InputBorder.none,

                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  AnimatedOpacity(
                    opacity: showManualSubmit ? 1 : 0,

                    duration: const Duration(milliseconds: 250),

                    child: showManualSubmit
                        ? ElevatedButton(
                            onPressed: () {
                              final qr = manualController.text.trim();

                              if (qr.isEmpty) return;

                              enqueueQr(qr);

                              manualController.clear();

                              setState(() {
                                showManualSubmit = false;
                              });
                            },

                            child: const Text("Submit"),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),

            //////////////////////////////////////////////////////
            // RECENT SCANS
            //////////////////////////////////////////////////////
            Positioned(
              bottom: 0,

              left: 0,

              right: 0,

              child: Container(
                height: 120,

                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.85),

                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),

                    topRight: Radius.circular(25),
                  ),
                ),

                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    const Text(
                      "Recent Scans",

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 16,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,

                        itemCount: scannedQrs.length,

                        itemBuilder: (_, index) {
                          final qr = scannedQrs[scannedQrs.length - index - 1];

                          return Container(
                            width: 160,

                            margin: const EdgeInsets.all(8),

                            padding: const EdgeInsets.all(10),

                            decoration: BoxDecoration(
                              color: Colors.green,

                              borderRadius: BorderRadius.circular(15),
                            ),

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                const Icon(Icons.qr_code, color: Colors.white),

                                const SizedBox(height: 6),

                                Text(
                                  qr.qrId,

                                  textAlign: TextAlign.center,

                                  style: const TextStyle(
                                    color: Colors.white,

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //////////////////////////////////////////////////////
            // FINISH BUTTON
            //////////////////////////////////////////////////////
            Positioned(
              bottom: 245,

              right: 20,

              child: FloatingActionButton.extended(
                backgroundColor: Colors.green,

                onPressed: scannedQrs.isEmpty ? null : finishScanning,

                icon: const Icon(Icons.check),

                label: Text("Finish (${scannedQrs.length})"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
