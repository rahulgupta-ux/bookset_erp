import 'package:flutter/material.dart';
import 'product_manager_screen.dart';
import 'school_manager_price.dart';
import 'product_editor_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text(
          "🔒 Admin Panel",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _adminCard(
              context,
              Icons.inventory_2_rounded,
              "Product\nManager",
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductManagerScreen(),
                  ),
                );
              },
            ),

            _adminCard(
              context,
              Icons.school_rounded,
              "School\nManager",
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SchoolManagerScreen(),
                  ),
                );
              },
            ),

            _adminCard(
              context,
              Icons.qr_code_2_rounded,
              "Inventory\nTools",
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductEditorScreen(),
                  ),
                );
              },
            ),

            _adminCard(
              context,
              Icons.currency_rupee,
              "Price\nManager",
              Colors.purple,
              () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Coming Soon")));
              },
            ),

            _adminCard(context, Icons.bar_chart, "Reports", Colors.red, () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Coming Soon")));
            }),

            _adminCard(context, Icons.settings, "System", Colors.teal, () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Coming Soon")));
            }),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),

      onTap: onTap,

      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white12),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withOpacity(0.15),

              child: Icon(icon, color: color, size: 34),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
