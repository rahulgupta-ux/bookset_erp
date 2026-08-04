import 'package:flutter/material.dart';
import 'main_navigation.dart'; // or whatever your home widget file is

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
