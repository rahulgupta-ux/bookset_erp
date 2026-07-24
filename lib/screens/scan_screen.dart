import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'dart:ui';
import 'dart:async';
import '../models/book_set.dart';
import 'cart_screen.dart';
import 'admin_panel_screen.dart';
import 'dart:collection';
// import '../services/update_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final MobileScannerController scannerController = MobileScannerController();
  double zoomScale = 0.0;

  final AudioPlayer player = AudioPlayer();

  List<BookSet> cartItems = [];

  final Queue<String> scanQueue = Queue<String>();

  bool isProcessingQueue = false;

  double total = 0;
  bool animateBox = false;
  bool scanSuccess = false;
  bool cartBounce = false;
  String statusMessage = "";

  Color statusColor = Colors.green;

  bool showStatus = false;
  bool showManualSubmit = false;
  Timer? adminTimer;
  final TextEditingController manualQrController = TextEditingController();

  final Set<String> scannedQrsInCart = {};
  final Set<String> processingQrs = {};

  String currentProcessingQr = "";

  int processedCount = 0;
  Map<String, DocumentReference> qrIndex = {};

  Future<void> loadQrIndex() async {
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

    debugPrint("QR Cache Loaded : ${qrIndex.length}");
  }

  Future<void> scanQr(String qrId) async {
    if (scannedQrsInCart.contains(qrId)) {
      await showStatusCard("Already Added", Colors.blue);
      processingQrs.remove(qrId);
      return;
    }

    try {
      // Search QR
      final qrReference = qrIndex[qrId];

      if (qrReference == null) {
        processingQrs.remove(qrId);

        await showStatusCard("QR Not Found", Colors.red);

        return;
      }

      final qrDoc = await qrReference.get();

      final qrData = qrDoc.data() as Map<String, dynamic>;

      final sold = qrData["sold"] ?? false;

      if (sold) {
        await showStatusCard("Already Sold", Colors.orange);
        processingQrs.remove(qrId);
        return;
      }

      // ------------------------------------------
      // Find Inventory Document
      // ------------------------------------------

      DocumentReference inventoryRef;

      final parentDoc = qrDoc.reference.parent.parent!;

      if (parentDoc.parent.id == "inventory") {
        // inventory/{inventoryId}/qrs/{qrId}
        inventoryRef = parentDoc;
      } else {
        // inventory/{inventoryId}/batches/{batchId}/qrs/{qrId}
        inventoryRef = parentDoc.parent.parent!;
      }

      final inventorySnapshot = await inventoryRef.get();

      final inventoryData = inventorySnapshot.data() as Map<String, dynamic>;

      final school = inventoryData["school"]?.toString() ?? "Unknown School";

      final className =
          inventoryData["className"]?.toString() ?? "Unknown Class";

      final price = (inventoryData["price"] ?? 0) as num;

      final book = BookSet(
        school: school,
        className: className,
        qrId: qrId,
        price: price.toInt(),
        stock: 1,
        inventoryId: inventorySnapshot.id,
      );

      scannedQrsInCart.add(qrId);

      setState(() {
        cartItems.add(book);
        total += price.toInt();
      });

      triggerScanSuccess();
      triggerCartBounce();

      await showStatusCard("${book.className} Added", Colors.green);
      processingQrs.remove(qrId);
    } catch (e) {
      debugPrint(e.toString());
      processingQrs.remove(qrId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void enqueueQr(String qrId) {
    qrId = qrId.trim();

    if (scannedQrsInCart.contains(qrId)) return;

    if (processingQrs.contains(qrId)) return;

    if (scanQueue.contains(qrId)) return;

    processingQrs.add(qrId);

    scanQueue.add(qrId);

    player.play(AssetSource("sounds/beep2.wav"));

    Vibration.vibrate(duration: 50);

    processQueue();
  }

  Future<void> processQueue() async {
    if (isProcessingQueue) return;

    isProcessingQueue = true;

    while (scanQueue.isNotEmpty) {
      final qrId = scanQueue.removeFirst();

      setState(() {
        currentProcessingQr = qrId;
      });

      await scanQr(qrId);

      processedCount++;

      if (mounted) {
        setState(() {});
      }
    }

    setState(() {
      currentProcessingQr = "";
    });

    isProcessingQueue = false;
  }

  Future<void> showStatusCard(String message, Color color) async {
    if (!mounted) return;

    setState(() {
      statusMessage = message;
      statusColor = color;
      showStatus = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    setState(() {
      showStatus = false;
    });
  }

  Future<void> triggerScanSuccess() async {
    setState(() {
      scanSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      scanSuccess = false;
    });
  }

  Future<void> triggerCartBounce() async {
    setState(() {
      cartBounce = true;
    });

    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    setState(() {
      cartBounce = false;
    });
  }

  @override
  void dispose() {
    scannerController.dispose();

    player.dispose();
    adminTimer?.cancel();
    super.dispose();
    manualQrController.dispose();
  }

  @override
  void initState() {
    super.initState();

    startBoxAnimation();

    loadQrIndex();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   UpdateService.checkForUpdates(context);
    // });
  }

  void startBoxAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) {
        return false;
      }

      setState(() {
        animateBox = !animateBox;
      });

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // CAMERA
            GestureDetector(
              onVerticalDragUpdate: (details) async {
                if (details.delta.dy < 0) {
                  // ZOOM IN
                  zoomScale += 0.05;
                } else {
                  // ZOOM OUT
                  zoomScale -= 0.05;
                }

                // LIMITS
                zoomScale = zoomScale.clamp(0.0, 1.0);

                await scannerController.setZoomScale(zoomScale);

                setState(() {});
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
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),

              top: showStatus ? 60 : -100,

              left: 35,

              right: 35,

              child: AnimatedOpacity(
                opacity: showStatus ? 1 : 0,

                duration: const Duration(milliseconds: 250),

                child: Material(
                  color: Colors.transparent,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),

                    decoration: BoxDecoration(
                      color: statusColor,

                      borderRadius: BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(.45),
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
                              : statusColor == Colors.orange
                              ? Icons.warning
                              : Icons.info,
                          color: Colors.white,
                        ),

                        const SizedBox(width: 12),

                        Text(
                          statusMessage,

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 125,
              right: 20,
              child: AnimatedOpacity(
                opacity: isProcessingQueue ? 1 : 0,
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
                        "⚡ Processing",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        currentProcessingQr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Waiting : ${scanQueue.length}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // DARK OVERLAY
            Container(color: Colors.black.withOpacity(0.25)),

            // SCAN BOX
            Center(
              child: Transform.translate(
                offset: const Offset(0, -70),

                child: AnimatedScale(
                  scale: animateBox ? 0.97 : 1.0,

                  duration: const Duration(milliseconds: 900),

                  curve: Curves.easeInOut,

                  child: SizedBox(
                    width: 200,

                    height: 200,

                    child: Stack(
                      children: [
                        // TOP LEFT
                        Positioned(
                          top: 0,

                          left: 0,

                          child: Container(
                            width: 30,

                            height: 30,

                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 3,
                                ),

                                left: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 3,
                                ),
                              ),
                              boxShadow: [
                                if (scanSuccess)
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.8),

                                    blurRadius: 12,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // TOP RIGHT
                        Positioned(
                          top: 0,

                          right: 0,

                          child: Container(
                            width: 30,

                            height: 30,

                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 3,
                                ),

                                right: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 3,
                                ),
                              ),
                              boxShadow: [
                                if (scanSuccess)
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.8),

                                    blurRadius: 12,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // BOTTOM LEFT
                        Positioned(
                          bottom: 0,

                          left: 0,

                          child: Container(
                            width: 30,

                            height: 30,

                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 3,
                                ),

                                left: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 3,
                                ),
                              ),
                              boxShadow: [
                                if (scanSuccess)
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.8),

                                    blurRadius: 12,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // BOTTOM RIGHT
                        Positioned(
                          bottom: 0,

                          right: 0,

                          child: Container(
                            width: 30,

                            height: 30,

                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 3,
                                ),

                                right: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 3,
                                ),
                              ),
                              boxShadow: [
                                if (scanSuccess)
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.8),

                                    blurRadius: 12,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 290,

              left: 35,

              right: 35,

              child: Column(
                children: [
                  // INPUT BOX
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),

                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),

                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: TextField(
                          controller: manualQrController,

                          style: const TextStyle(color: Colors.white),

                          onChanged: (value) {
                            setState(() {
                              showManualSubmit = value.trim().isNotEmpty;
                            });
                          },

                          decoration: const InputDecoration(
                            hintText: "Enter QR ID Manually",

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

                  const SizedBox(height: 15),

                  // SUBMIT BUTTON
                  AnimatedOpacity(
                    opacity: showManualSubmit ? 1 : 0,

                    duration: const Duration(milliseconds: 250),

                    child: showManualSubmit
                        ? GestureDetector(
                            onTap: () {
                              final qr = manualQrController.text.trim();

                              if (qr.isNotEmpty) {
                                enqueueQr(qr);

                                manualQrController.clear();

                                setState(() {
                                  showManualSubmit = false;
                                });
                              }
                            },

                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,

                                vertical: 14,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.blue,

                                borderRadius: BorderRadius.circular(18),
                              ),

                              child: const Text(
                                "Submit",

                                style: TextStyle(
                                  color: Colors.white,

                                  fontSize: 17,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),

            // TOTAL AMOUNT
            Positioned(
              top: 55,

              right: 20,

              child: GestureDetector(
                onLongPressStart: (_) {
                  adminTimer = Timer(const Duration(seconds: 1), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPanelScreen(),
                      ),
                    );
                  });
                },

                onLongPressEnd: (_) {
                  adminTimer?.cancel();
                },

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),

                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),

                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),

                      child: Text(
                        "₹${total.toInt()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // GO TO CART BUTTON
            Positioned(
              bottom: 230,

              left: 130,

              right: 130,

              child: GestureDetector(
                onTap: () async {
                  await scannerController.stop();
                  final updatedCart = await Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => CartScreen(cartItems: cartItems),
                    ),
                  );

                  if (updatedCart != null) {
                    setState(() {
                      cartItems = List<BookSet>.from(updatedCart);

                      scannedQrsInCart.clear();

                      total = 0;

                      for (var item in cartItems) {
                        scannedQrsInCart.add(item.qrId);

                        total += item.price;
                      }
                    });
                  } else {
                    await scannerController.start();
                  }
                  await scannerController.start();
                },

                child: AnimatedScale(
                  scale: cartBounce ? 2.00 : 1.0,

                  duration: const Duration(milliseconds: 3000),

                  curve: Curves.easeOut,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 1,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.75),

                          borderRadius: BorderRadius.circular(30),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),

                              blurRadius: 10,

                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              "Cart (${cartItems.length})",

                              style: const TextStyle(
                                color: Colors.white,

                                fontSize: 14,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
