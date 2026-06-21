import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/update_service.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/price_list_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/update_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final updateInfo = await UpdateService.checkForUpdate();
  print("Update Available: ${updateInfo.updateAvailable}");
  print("Current Version: ${updateInfo.currentVersion}");
  print("Latest Version: ${updateInfo.latestVersion}");
  print("Update Available: ${updateInfo.updateAvailable}");

  runApp(MyApp(updateInfo: updateInfo));
}

class MyApp extends StatelessWidget {
  final UpdateInfo updateInfo;

  const MyApp({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: updateInfo.updateAvailable
          ? UpdateScreen(updateInfo: updateInfo)
          : const MainNavigation(),
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

  Widget _navItem(IconData icon, int index) {
    final selected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );

        setState(() {
          currentIndex = index;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.15)
              : Colors.transparent,

          borderRadius: BorderRadius.circular(16),
        ),

        child: Icon(
          icon,
          size: 28,
          color: selected ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      body: Stack(
        children: [
          PageView(
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            children: screens,
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.card.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(Icons.home, 0),
                    _navItem(Icons.menu_book, 1),
                    _navItem(Icons.qr_code_scanner, 2),
                    _navItem(Icons.bar_chart, 3),
                    _navItem(Icons.inventory, 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
