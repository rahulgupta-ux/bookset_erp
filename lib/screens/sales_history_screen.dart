import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales History")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("sales")
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No Sales Yet"));
          }

          return ListView.builder(
            itemCount: docs.length,

            itemBuilder: (context, index) {
              final sale = docs[index];

              final data = sale.data();

              return Card(
                margin: const EdgeInsets.all(12),

                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt)),

                  title: Text(data["invoiceId"].toString()),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        data["soldToSchool"] == true
                            ? "School Sale"
                            : "Retail Sale",
                      ),

                      if (data["returned"] == true)
                        const Text(
                          "RETURNED",

                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),

                  trailing: Text(
                    "₹${data["amount"]}",

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  onTap: () {
                    showModalBottomSheet(
                      context: context,

                      isScrollControlled: true,

                      builder: (_) {
                        final List<dynamic> books = data["books"] ?? [];

                        return Padding(
                          padding: const EdgeInsets.all(20),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                data["invoiceId"],

                                style: const TextStyle(
                                  fontSize: 26,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Text("Total: ₹${data["amount"]}"),

                              const SizedBox(height: 10),

                              Text(
                                data["soldToSchool"] == true
                                    ? "School Sale"
                                    : "Retail Sale",
                              ),

                              const SizedBox(height: 25),

                              const Text(
                                "Books",

                                style: TextStyle(
                                  fontSize: 22,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 15),

                              ...books.map((book) {
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.menu_book),

                                    title: Text(book["school"]),

                                    subtitle: Text(book["className"]),

                                    trailing: Text("₹${book["price"]}"),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 25),

                              SizedBox(
                                width: double.infinity,

                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),

                                  onPressed: () async {
                                    for (var book in books) {
                                      final qrId = book["qrId"];

                                      await FirebaseFirestore.instance
                                          .collection("sold_qrs")
                                          .doc(qrId)
                                          .delete();

                                      final inventoryRef = FirebaseFirestore
                                          .instance
                                          .collection("inventory")
                                          .doc(qrId);

                                      await FirebaseFirestore.instance
                                          .runTransaction((transaction) async {
                                            final snapshot = await transaction
                                                .get(inventoryRef);

                                            if (!snapshot.exists) return;

                                            final currentStock =
                                                snapshot["stock"];

                                            transaction.update(inventoryRef, {
                                              "stock": currentStock + 1,
                                            });
                                          });
                                    }

                                    await FirebaseFirestore.instance
                                        .collection("refunds")
                                        .add({
                                          "invoiceId": data["invoiceId"],

                                          "amount": data["amount"],

                                          "timestamp": Timestamp.now(),
                                        });

                                    await FirebaseFirestore.instance
                                        .collection("sales")
                                        .doc(sale.id)
                                        .update({"returned": true});

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Refund Processed"),
                                      ),
                                    );
                                  },

                                  icon: const Icon(Icons.undo),

                                  label: const Text("Return / Refund"),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
