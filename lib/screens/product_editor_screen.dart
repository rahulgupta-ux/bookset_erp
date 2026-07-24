import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({super.key});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final searchController = TextEditingController();

  String searchText = "";
  final priceController = TextEditingController();

  final totalBooksController = TextEditingController();

  List<TextEditingController> bookControllers = [];

  @override
  void dispose() {
    searchController.dispose();
    priceController.dispose();

    totalBooksController.dispose();

    for (var c in bookControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Editor")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },

              decoration: InputDecoration(
                hintText: "Search School or Class",

                prefixIcon: const Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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
                      final product =
                          docs[index].data() as Map<String, dynamic>;

                      final school = product["school"].toString();

                      final className = product["className"].toString();

                      final price = product["price"] ?? 0;

                      final matches =
                          school.toLowerCase().contains(searchText) ||
                          className.toLowerCase().contains(searchText);

                      if (!matches) {
                        return const SizedBox();
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),

                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.menu_book),
                          ),

                          title: Text(school),

                          subtitle: Text("Class $className"),

                          trailing: Text(
                            "₹$price",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          onTap: () {
                            priceController.text = product["price"].toString();

                            totalBooksController.text = product["totalBooks"]
                                .toString();

                            for (var c in bookControllers) {
                              c.dispose();
                            }

                            final books =
                                (product["books"] as List<dynamic>? ?? []);

                            bookControllers = books
                                .map(
                                  (e) =>
                                      TextEditingController(text: e.toString()),
                                )
                                .toList();

                            showModalBottomSheet(
                              context: context,

                              isScrollControlled: true,

                              backgroundColor: Colors.transparent,

                              builder: (_) {
                                return StatefulBuilder(
                                  builder: (context, setSheetState) {
                                    return Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          .90,

                                      decoration: const BoxDecoration(
                                        color: const Color(0xFF161B22),

                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(30),
                                        ),
                                      ),

                                      child: Padding(
                                        padding: const EdgeInsets.all(20),

                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              Center(
                                                child: Container(
                                                  width: 70,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 25),

                                              Text(
                                                school,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              Text("Class $className"),

                                              const SizedBox(height: 25),

                                              TextField(
                                                controller: priceController,

                                                keyboardType:
                                                    TextInputType.number,

                                                decoration:
                                                    const InputDecoration(
                                                      labelText: "Price",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                              ),

                                              const SizedBox(height: 20),

                                              TextField(
                                                controller:
                                                    totalBooksController,

                                                keyboardType:
                                                    TextInputType.number,

                                                decoration:
                                                    const InputDecoration(
                                                      labelText: "Total Books",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                              ),

                                              const SizedBox(height: 30),

                                              const Text(
                                                "Books",
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              const SizedBox(height: 20),

                                              ListView.builder(
                                                shrinkWrap: true,

                                                physics:
                                                    const NeverScrollableScrollPhysics(),

                                                itemCount:
                                                    bookControllers.length,

                                                itemBuilder: (context, i) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 15,
                                                        ),

                                                    child: TextField(
                                                      controller:
                                                          bookControllers[i],

                                                      decoration: InputDecoration(
                                                        labelText:
                                                            "Book ${i + 1}",

                                                        border:
                                                            const OutlineInputBorder(),

                                                        suffixIcon: IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                          ),

                                                          onPressed: () {
                                                            if (bookControllers
                                                                    .length ==
                                                                1) {
                                                              return;
                                                            }

                                                            setSheetState(() {
                                                              bookControllers[i]
                                                                  .dispose();

                                                              bookControllers
                                                                  .removeAt(i);
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),

                                              const SizedBox(height: 20),

                                              SizedBox(
                                                width: double.infinity,

                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    setSheetState(() {
                                                      bookControllers.add(
                                                        TextEditingController(),
                                                      );
                                                    });
                                                  },

                                                  icon: const Icon(Icons.add),

                                                  label: const Text("Add Book"),
                                                ),
                                              ),

                                              const SizedBox(height: 35),

                                              SizedBox(
                                                width: double.infinity,

                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 18,
                                                        ),
                                                  ),

                                                  onPressed: () async {
                                                    final books =
                                                        bookControllers
                                                            .map(
                                                              (e) =>
                                                                  e.text.trim(),
                                                            )
                                                            .where(
                                                              (e) =>
                                                                  e.isNotEmpty,
                                                            )
                                                            .toList();

                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection("products")
                                                        .doc(docs[index].id)
                                                        .update({
                                                          "price":
                                                              int.tryParse(
                                                                priceController
                                                                    .text,
                                                              ) ??
                                                              0,

                                                          "totalBooks":
                                                              books.length,

                                                          "books": books,
                                                        });

                                                    if (context.mounted) {
                                                      Navigator.pop(context);

                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Product Updated Successfully",
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },

                                                  icon: const Icon(Icons.save),

                                                  label: const Text(
                                                    "SAVE CHANGES",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 20),
                                            ],
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
