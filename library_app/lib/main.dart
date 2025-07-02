import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:library_app/firebase_options.dart';

import 'package:library_app/screens/welcome_screen.dart';
import 'package:library_app/screens/home_screen.dart';
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/providers/user_provider.dart';
import 'package:library_app/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BookProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth.FirebaseAuth firebaseAuth = auth.FirebaseAuth.instance;

    return MaterialApp(
      title: 'Library App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey,
      home: StreamBuilder<auth.User?>(
        stream: firebaseAuth.authStateChanges(),
        builder: (context, snapshot) {
          final notificationProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final String? userId = snapshot.hasData ? snapshot.data!.uid : null;

          // --- PERBAIKAN DI SINI: Tunda panggilan setUserId ---
          // Ini memastikan panggilan setUserId (yang memicu notifyListeners)
          // terjadi SETELAH StreamBuilder selesai membangun widget-nya,
          // sehingga tidak ada konflik selama build phase.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notificationProvider.setUserId(userId);
          });
          // --- AKHIR PERBAIKAN ---

          if (snapshot.hasData) {
            return const HomeScreen();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
