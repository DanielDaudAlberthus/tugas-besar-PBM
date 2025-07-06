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
import 'package:library_app/providers/loan_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BookProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => LoanProvider()),
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
    final userProvider = Provider.of<UserProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    final String? userId = userProvider.userId;
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

    return MaterialApp(
      title: 'Perpustakaan Digital',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Builder(
        builder: (context) {
          if (userProvider.isLoading) {
            print('DEBUG: Main Build: Showing blue userProvider loading.');
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            );
          }

          if (userProvider.isAuthenticated) {
            print('DEBUG: Main Build: Showing HomeScreen.');
            return const HomeScreen();
          } else {
            print('DEBUG: Main Build: Showing WelcomeScreen.');
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
