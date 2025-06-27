import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as auth; // Import Firebase Auth
import 'package:library_app/firebase_options.dart';

import 'package:library_app/screens/welcome_screen.dart';
import 'package:library_app/screens/home_screen.dart'; // Import HomeScreen
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/providers/user_provider.dart'; // UserProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BookProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dapatkan status autentikasi saat ini
    final auth.FirebaseAuth firebaseAuth = auth.FirebaseAuth.instance;

    return MaterialApp(
      title: 'Library App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey, // Tambahkan ini
      // Cek apakah pengguna sudah login saat aplikasi dimulai
      home: StreamBuilder<auth.User?>(
        // Dengarkan perubahan status autentikasi
        stream: firebaseAuth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            ); // Tampilkan loading
          }
          if (snapshot.hasData) {
            // Pengguna sudah login
            return const HomeScreen();
          } else {
            // Pengguna belum login
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
