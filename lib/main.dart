import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/price_list_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/inventory_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await Firebase.initializeApp();
  

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,

      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 2;

  final List<Widget> screens = const [
    HomeScreen(),

    PriceListScreen(),

    ScanScreen(),

    ReportsScreen(),

    InventoryScreen(),
  ];

  final PageController pageController = PageController(initialPage: 2);

  @override
  void dispose() {
    pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      appBar: AppBar(
        title: const Text(""),

        centerTitle: true,

        backgroundColor: Colors.transparent,

        elevation: 0,
      ),

      backgroundColor: Colors.black,

      body: PageView(
        controller: pageController,

        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        children: screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        backgroundColor: Colors.transparent,

        elevation: 0,

        type: BottomNavigationBarType.fixed,

        showSelectedLabels: false,

        showUnselectedLabels: false,

        selectedItemColor: Colors.white,

        unselectedItemColor: Colors.white.withOpacity(0.28),

        onTap: (index) {
          pageController.animateToPage(
            index,

            duration: const Duration(milliseconds: 250),

            curve: Curves.easeInOut,
          );

          setState(() {
            currentIndex = index;
          });
        },

        items: [
          // HOME
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 250),

              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                boxShadow: currentIndex == 0
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),

                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),

              child: const Icon(Icons.home, size: 28),
            ),

            label: "",
          ),

          // PRICE LIST
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 250),

              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                boxShadow: currentIndex == 1
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),

                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),

              child: const Icon(Icons.menu_book, size: 28),
            ),

            label: "",
          ),

          // SCAN
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 250),

              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                boxShadow: currentIndex == 2
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),

                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),

              child: const Icon(Icons.qr_code_scanner, size: 30),
            ),

            label: "",
          ),

          // REPORTS
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 250),

              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                boxShadow: currentIndex == 3
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),

                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),

              child: const Icon(Icons.bar_chart, size: 28),
            ),

            label: "",
          ),

          // INVENTORY
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 250),

              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                boxShadow: currentIndex == 4
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),

                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),

              child: const Icon(Icons.inventory, size: 28),
            ),

            label: "",
          ),
        ],
      ),
    );
  }
}
