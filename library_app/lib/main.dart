// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as auth; // Import ini sudah ada
import 'package:library_app/firebase_options.dart';

// Screens yang di-import
import 'package:library_app/screens/welcome_screen.dart'; // Digunakan untuk non-authenticated users
import 'package:library_app/screens/home_screen.dart'; // Digunakan untuk authenticated users
// Import providers yang diperlukan
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/providers/user_provider.dart';
import 'package:library_app/providers/notification_provider.dart';

// Jika Anda punya Shared Preferences, uncomment baris ini dan inisialisasi di main()
// import 'package:shared_preferences/shared_preferences.dart';
// late SharedPreferences sharedPreferences; // Jika Anda menggunakan SharedPreferences secara global

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Jika Anda menggunakan SharedPreferences secara global, uncomment ini
  // sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BookProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        // Tambahkan provider lain di sini jika ada (sesuai yang Anda miliki di repositori GitHub Anda):
        // ChangeNotifierProvider(create: (context) => CategoryProvider()),
        // ChangeNotifierProvider(create: (context) => TransactionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(
      context,
    ); // Listen: true (default) is fine here
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    final String? userId =
        userProvider.userId; // Menggunakan getter userId dari UserProvider

    // Panggil setUserId di NotificationProvider.
    // Ini akan memicu NotificationProvider untuk mulai/menghentikan mendengarkan notifikasi
    // sesuai dengan status autentikasi userId.
    notificationProvider.setUserId(userId);

    print(
      'DEBUG: didChangeDependencies called in MyApp. User ID for notif provider: $userId',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    print(
      'DEBUG: Main Build: UserProvider.isLoading: ${userProvider.isLoading}',
    );
    print(
      'DEBUG: Main Build: isAuthenticated: ${userProvider.isAuthenticated}',
    );

    // PERBAIKAN KRUSIAL: Bungkus seluruh logika pemilihan screen dengan MaterialApp.
    // MaterialApp menyediakan widget Directionality yang dibutuhkan oleh Scaffold.
    return MaterialApp(
      title: 'Perpustakaan Digital', // Judul aplikasi
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Builder(
        // Menggunakan Builder untuk mendapatkan BuildContext yang benar di dalam MaterialApp
        builder: (context) {
          if (userProvider.isLoading) {
            print('DEBUG: Main Build: Showing blue userProvider loading.');
            return const Scaffold(
              // Scaffold ini sekarang aman di dalam MaterialApp
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            );
          }

          if (userProvider.isAuthenticated) {
            print('DEBUG: Main Build: Showing HomeScreen.');
            return const HomeScreen(); // HomeScreen sekarang aman
          } else {
            print('DEBUG: Main Build: Showing WelcomeScreen.');
            return const WelcomeScreen(); // WelcomeScreen sekarang aman
          }
        },
      ),
    );
  }
}
