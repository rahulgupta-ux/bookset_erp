import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});
  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchText = "";
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Price List",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
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

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),

                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.book),
                            ),

                            title: Text(school),

                            subtitle: Text(
                              "$className\nAvailable Stock: $availableStock",
                            ),

                            isThreeLine: true,

                            trailing: Text(
                              "₹$price",

                              style: const TextStyle(
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
    );
  }
}
