import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'dart:ui';
import '../models/book_set.dart';
import 'cart_screen.dart';
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

  bool isScanning = false;

  double total = 0;
  bool animateBox = false;
  bool scanSuccess = false;
  bool cartBounce = false;
  bool showManualSubmit = false;

  final TextEditingController manualQrController = TextEditingController();

  final Set<String> scannedQrsInCart = {};

  Future<void> scanQr(String qrId) async {
    if (isScanning) return;

    if (scannedQrsInCart.contains(qrId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Already Added")));

      return;
    }

    isScanning = true;

    try {
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

        isScanning = false;

        return;
      }

      final qrData = qrDoc.data() as Map<String, dynamic>;

      final sold = (qrData["sold"] ?? false) as bool;

      if (sold) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Already Sold")));

        isScanning = false;

        return;
      }

      final parentDoc = await qrDoc.reference.parent.parent!.get();

      final parentData = parentDoc.data() as Map<String, dynamic>;

      final price = parentData["price"] ?? 0;

      final book = BookSet(
        school: parentData["school"],

        className: parentData["className"],

        qrId: qrId,

        price: price,

        stock: 1,
      );

      scannedQrsInCart.add(qrId);

      await player.play(AssetSource('sounds/beep2.wav'));

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 80);
      }

      setState(() {
        cartItems.add(book);

        total += book.price;
      });
      triggerScanSuccess();
      triggerCartBounce();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${book.className} Added")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    await Future.delayed(const Duration(milliseconds: 800));

    isScanning = false;
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

    super.dispose();
    manualQrController.dispose();
  }

  @override
  void initState() {
    super.initState();

    startBoxAnimation();
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

                  if (code != null) {
                    scanQr(code.trim());
                  }
                },
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
                    width: 260,

                    height: 260,

                    child: Stack(
                      children: [
                        // TOP LEFT
                        Positioned(
                          top: 0,

                          left: 0,

                          child: Container(
                            width: 45,

                            height: 45,

                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 5,
                                ),

                                left: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 5,
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
                            width: 45,

                            height: 45,

                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 5,
                                ),

                                right: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 5,
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
                            width: 45,

                            height: 45,

                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 5,
                                ),

                                left: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 5,
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
                            width: 45,

                            height: 45,

                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 5,
                                ),

                                right: BorderSide(
                                  color: scanSuccess
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 5,
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
              bottom: 130,

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
                                scanQr(qr);

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

                      border: Border.all(color: Colors.white.withOpacity(0.2)),
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

            // GO TO CART BUTTON
            Positioned(
              bottom: 30,

              left: 130,

              right: 130,

              child: GestureDetector(
                onTap: () async {
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
                  }
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
