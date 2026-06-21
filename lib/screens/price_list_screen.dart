import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'check_info_screen.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});
  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController searchController = TextEditingController();
  String searchText = "";
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          110, // space for floating navigation dock
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  "Price List",

                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) => const CheckInfoScreen(),
                      ),
                    );
                  },

                  icon: const Icon(Icons.info, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search Product",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF21262D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFF10A37F),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("products")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final item = docs[index];
                      final school = item["school"].toString();
                      final className = item["className"].toString();
                      final price = item["price"] ?? 0;
                      final productId = item.id;
                      final matches =
                          school.toLowerCase().contains(searchText) ||
                          className.toLowerCase().contains(searchText);
                      if (!matches) {
                        return const SizedBox();
                      }
                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("inventory")
                            .doc(productId)
                            .collection("qrs")
                            .where("sold", isEqualTo: false)
                            .get(),

                        builder: (context, qrSnapshot) {
                          int availableStock = 0;

                          if (qrSnapshot.hasData) {
                            availableStock = qrSnapshot.data!.docs.length;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF21262D),
                              ),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF10A37F),
                                child: Icon(Icons.book, color: Colors.black),
                              ),

                              title: Text(
                                school,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              subtitle: Text(
                                "$className\nAvailable Stock: $availableStock",
                                style: const TextStyle(color: Colors.white70),
                              ),

                              isThreeLine: true,

                              trailing: Text(
                                "₹$price",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
