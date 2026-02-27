import 'package:flutter/material.dart';
import 'screen/splash_screen.dart';

void main() => runApp(const DanceCountApp());

class DanceCountApp extends StatelessWidget {
  const DanceCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DanceCount',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,  // white background for Scaffold
        canvasColor: Colors.white,              // white background for drawers, menus, etc.
        primaryColor: Colors.white,              // primary background color
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          backgroundColor: Colors.white,
        ).copyWith(
          background: Colors.white,
          surface: Colors.white,                 // surface cards, dialogs etc.
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
