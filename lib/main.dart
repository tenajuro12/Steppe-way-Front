import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:travel_kz/screens/home_screen.dart';
import 'package:travel_kz/screens/login_screen.dart';
import 'package:travel_kz/screens/plan/plan_screen.dart';
import 'package:travel_kz/screens/register_screen.dart';
import 'package:travel_kz/screens/map/map_screen.dart';
import 'package:travel_kz/screens/blogs/blogs_screen.dart';  // Import the blogs screen

import 'screens/attractions/attractions_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final sessionToken = await _storage.read(key: 'session_token');
    setState(() {
      _isLoggedIn = sessionToken != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: _isLoggedIn ? '/home' : '/login',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),
        '/attractions': (context) => const AttractionsListScreen(),
        '/plan': (context) => const PlansScreen(),
        '/blogs': (context) => const BlogsScreen(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      ),
    );
  }
}