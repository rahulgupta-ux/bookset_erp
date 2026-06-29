import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BulkQrScreen
    extends StatelessWidget {

  final List<String> qrList;

  const BulkQrScreen({
    super.key,
    required this.qrList,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Bulk QR Labels",
        ),
      ),

      body: Padding(

        padding:
            const EdgeInsets.all(12),

        child: GridView.builder(

          itemCount: qrList.length,

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(

            crossAxisCount: 2,

            crossAxisSpacing: 15,

            mainAxisSpacing: 15,

            childAspectRatio: 0.75,
          ),

          itemBuilder:
              (context, index) {

            final qr =
                qrList[index];

            return Container(

              padding:
                  const EdgeInsets
                      .all(10),

              decoration:
                  BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius
                        .circular(15),

                boxShadow: [

                  BoxShadow(
                    color:
                        Colors.black12,
                    blurRadius: 6,
                  ),
                ],
              ),

              child: Column(

                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [

                  QrImageView(

                    data: qr,

                    size: 120,

                    backgroundColor:
                        Colors.white,
                  ),

                  const SizedBox(
                      height: 10),

                  Text(

                    qr,

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}