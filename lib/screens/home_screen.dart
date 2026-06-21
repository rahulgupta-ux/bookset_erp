import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sales_history_screen.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  double todaySales = 0;

  int booksSold = 0;

  int inventoryCount = 0;

  int recentOrders = 0;

  int schoolSales = 0;

  bool isLoading = true;

  List<Map<String, dynamic>> recentSales = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      double sales = 0;

      int soldBooks = 0;

      int schoolSaleCount = 0;

      int inventory = 0;

      List<Map<String, dynamic>> salesList = [];

      final today = DateTime.now();

      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final salesSnapshot = await FirebaseFirestore.instance
          .collection("sales")
          .where(
            "timestamp",
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where("timestamp", isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in salesSnapshot.docs) {
        final data = doc.data();

        sales += (data["amount"] ?? 0).toDouble();

        final books = data["books"] as List?;

        soldBooks += books?.length ?? 0;

        if (data["soldToSchool"] == true) {
          schoolSaleCount++;
        }

        salesList.add(data);
      }

      final inventorySnapshot = await FirebaseFirestore.instance
          .collection("inventory")
          .get();

      for (var doc in inventorySnapshot.docs) {
        final data = doc.data();

        final sold = data.containsKey("sold") ? data["sold"] : false;
        if (!sold) {
          inventory++;
        }
      }

      setState(() {
        todaySales = sales;

        booksSold = soldBooks;

        schoolSales = schoolSaleCount;

        inventoryCount = inventory;

        recentSales = salesList.reversed.take(5).toList();

        isLoading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading dashboard: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadDashboard,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    const Text(
                      "BookSet ERP",

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
                            builder: (_) => const SalesHistoryScreen(),
                          ),
                        );
                      },

                      icon: const Icon(
                        Icons.history,
                        size: 30,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: _buildCard(
                        title: "Today's Sales",

                        value: "₹${todaySales.toStringAsFixed(0)}",

                        icon: Icons.currency_rupee,

                        color: AppTheme.success,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildCard(
                        title: "Sets Sold",

                        value: "$booksSold",

                        icon: Icons.shopping_cart,

                        color: AppTheme.info,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildCard(
                        title: "School Sales",

                        value: "$schoolSales",

                        icon: Icons.school,

                        color: AppTheme.warning,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildCard(
                        title: "Available Stock",

                        value: "$inventoryCount",

                        icon: Icons.inventory,

                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Recent Sales",

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 15),

                if (recentSales.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),

                      child: Text(
                        "No Sales Today",

                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),

                ...recentSales.map((sale) {
                  return _buildRecentSale(
                    school: sale["soldToSchool"] == true
                        ? "School Sale"
                        : "Retail Sale",

                    amount: "₹${sale["amount"]}",
                  );
                }),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),

          const SizedBox(height: 15),

          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSale({required String school, required String amount}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Icon(Icons.menu_book, color: Colors.white),
        ),
        title: Text(
          school,
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        trailing: Text(
          amount,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
