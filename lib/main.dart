import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/cart_page.dart';
import 'pages/category_page.dart';
import 'pages/scan_page.dart';
import 'pages/reminder_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PantryPal",
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF6FFDE),
      ),
      home: const LoginPage(),
      // 🔹 Optional: define named routes so you can use pushNamed if you want
      routes: {
        '/home': (_) => const HomePage(),
        '/cart': (_) => const CartPage(),
        '/scan': (_) => const ScanPage(),
        '/categories': (_) => CategoryPage(),
        '/reminder': (_) => const ReminderPage(),
      },
    );
  }
}
