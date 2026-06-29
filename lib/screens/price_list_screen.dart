import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_theme.dart';
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

  void _showBookDetails(BuildContext context, Map<String, dynamic> product) {
    final List<dynamic> books = product["books"] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * .82,
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.school, color: Colors.black),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Text(
                          product["school"] ?? "",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    product["className"] ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 25),

                  _buildInfoTile(
                    Icons.currency_rupee,
                    "Price",
                    "₹${product["price"]}",
                  ),

                  _buildInfoTile(
                    Icons.menu_book,
                    "Books",
                    "${product["totalBooks"]}",
                  ),

                  const SizedBox(height: 25),

                  Text(
                    "Books Included(${books.length})",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (books.isEmpty)
                    const Text(
                      "No books added.",
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    Column(
                      children: books.asMap().entries.map((entry) {
                        final index = entry.key;
                        final book = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.yellow.shade700
                                : AppTheme.card,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: index == 0
                                  ? Colors.amber
                                  : AppTheme.border,
                              width: index == 0 ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                color: index == 0
                                    ? Colors.black
                                    : AppTheme.primary,
                                size: 20,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  book.toString(),
                                  style: TextStyle(
                                    color: index == 0
                                        ? Colors.black
                                        : AppTheme.textPrimary,
                                    fontWeight: index == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
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
                    color: AppTheme.textPrimary,
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
                  icon: const Icon(
                    Icons.info_outline,
                    color: AppTheme.primary,
                    size: 28,
                  ),
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
                fillColor: AppTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
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
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final item = docs[index];

                      final product = item.data() as Map<String, dynamic>;

                      final school = product["school"]?.toString() ?? "";

                      final className = product["className"]?.toString() ?? "";

                      final price = product["price"] ?? 0;

                      final matches =
                          school.toLowerCase().contains(searchText) ||
                          className.toLowerCase().contains(searchText);

                      if (!matches) {
                        return const SizedBox();
                      }

                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _showBookDetails(context, product);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Icon(Icons.menu_book, color: Colors.black),
                            ),

                            title: Text(
                              school,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              className,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),

                            trailing: Text(
                              "₹$price",
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
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
