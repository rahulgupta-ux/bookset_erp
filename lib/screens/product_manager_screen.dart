import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductManagerScreen extends StatefulWidget {
  const ProductManagerScreen({super.key});

  @override
  State<ProductManagerScreen> createState() => _ProductManagerScreenState();
}

class _ProductManagerScreenState extends State<ProductManagerScreen> {
  final schoolController = TextEditingController();

  final schoolCodeController = TextEditingController();

  final classController = TextEditingController();

  final priceController = TextEditingController();

  final totalBooksController = TextEditingController();

  bool isLoading = false;

  List<TextEditingController> bookControllers = [TextEditingController()];

  @override
  void dispose() {
    schoolController.dispose();

    schoolCodeController.dispose();

    classController.dispose();

    priceController.dispose();

    totalBooksController.dispose();
    for (var controller in bookControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> createProduct() async {
    final school = schoolController.text.trim();

    final schoolCode = schoolCodeController.text.trim().toUpperCase();

    final className = classController.text.trim();

    final price = int.tryParse(priceController.text) ?? 0;

    final totalBooks = int.tryParse(totalBooksController.text) ?? 0;

    final books = bookControllers
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (school.isEmpty || schoolCode.isEmpty || className.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final documentId = "${schoolCode}_$className";

      await FirebaseFirestore.instance
          .collection("products")
          .doc(documentId)
          .set({
            "school": school,
            "schoolCode": schoolCode,
            "className": className,
            "price": price,
            "totalBooks": totalBooks,
            "books": books,
            "imageUrl": "",
            "createdAt": Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Created Successfully")),
      );

      schoolController.clear();
      schoolCodeController.clear();
      classController.clear();
      priceController.clear();
      totalBooksController.clear();

      for (var c in bookControllers) {
        c.dispose();
      }

      setState(() {
        bookControllers = [TextEditingController()];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Manager")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Create Product",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: schoolController,

              decoration: const InputDecoration(
                labelText: "School Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: schoolCodeController,

              decoration: const InputDecoration(
                labelText: "School Code",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: classController,

              decoration: const InputDecoration(
                labelText: "Class",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: priceController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Price",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: totalBooksController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Total Books",
                border: OutlineInputBorder(),
              ),
            ),

            const Text(
              "Books Included",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

              itemCount: bookControllers.length,

              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),

                  child: TextField(
                    controller: bookControllers[index],

                    decoration: InputDecoration(
                      labelText: "Book ${index + 1}",

                      border: const OutlineInputBorder(),

                      suffixIcon: IconButton(
                        icon: const Icon(Icons.delete),

                        onPressed: () {
                          if (bookControllers.length == 1) {
                            return;
                          }

                          setState(() {
                            bookControllers[index].dispose();

                            bookControllers.removeAt(index);
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
                  setState(() {
                    bookControllers.add(TextEditingController());
                  });
                },

                icon: const Icon(Icons.add),

                label: const Text("Add Book"),
              ),
            ),

            const SizedBox(height: 40),

            const Divider(),

            const SizedBox(height: 20),

            const Text(
              "Existing Products",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("products")
                  .orderBy("school")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No Products Found"));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final product = docs[index].data() as Map<String, dynamic>;

                    return InkWell(
                      onTap: () {
                        schoolController.text = product["school"];

                        schoolCodeController.text = product["schoolCode"];

                        classController.text = product["className"];

                        priceController.text = product["price"].toString();

                        totalBooksController.text = product["totalBooks"]
                            .toString();

                        for (var c in bookControllers) {
                          c.dispose();
                        }

                        final books = product["books"] as List<dynamic>;

                        bookControllers = books
                            .map(
                              (e) => TextEditingController(text: e.toString()),
                            )
                            .toList();

                        setState(() {});
                      },

                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),

                        child: ListTile(
                          title: Text(product["school"]),

                          subtitle: Text("Class ${product["className"]}"),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Text("₹${product["price"]}"),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),

                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection("products")
                                      .doc(docs[index].id)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: isLoading ? null : createProduct,

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),

                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        "CREATE PRODUCT",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
