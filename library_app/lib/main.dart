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

// >>> INI ADALAH PERUBAHAN KRUSIAL: UBAH MyApp MENJADI StatefulWidget <<<
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Metode ini dipanggil setelah initState, dan setiap kali dependensi widget berubah.
  // Ini adalah tempat yang AMAN untuk memanggil metode provider yang mungkin memicu notifyListeners().
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dapatkan instance provider yang dibutuhkan.
    // UserProvider harus listen: true karena kita butuh currentUser di sini.
    final userProvider = Provider.of<UserProvider>(context);
    // NotificationProvider tidak perlu listen: true di sini karena kita hanya memanggil methodnya,
    // bukan membangun UI langsung dari state-nya di sini.
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    // Panggil setUserId di NotificationProvider ketika dependensi berubah (misal, status user berubah).
    final String? userId = userProvider.currentUser?.uid;
    notificationProvider.setUserId(userId);

    print(
      'DEBUG: didChangeDependencies called in MyApp. User ID for notif provider: $userId',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Di metode build, kita mendapatkan provider lagi untuk digunakan dalam logika UI
    // Kali ini, karena panggilan yang memicu notifyListeners() sudah ditangani di didChangeDependencies(),
    // ini tidak akan menyebabkan error.
    final userProvider = Provider.of<UserProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
    ); // Listen di sini agar UI MyApp me-rebuild

    print(
      'DEBUG: Main Build: UserProvider.isLoading: ${userProvider.isLoading}',
    );
    print(
      'DEBUG: Main Build: NotificationProvider.isLoading: ${notificationProvider.isLoading}',
    );
    print(
      'DEBUG: Main Build: Notifications count: ${notificationProvider.notifications.length}',
    );
    print(
      'DEBUG: Main Build: Notifications isEmpty: ${notificationProvider.notifications.isEmpty}',
    );
    print(
      'DEBUG: Main Build: Unread count: ${notificationProvider.unreadCount}',
    );
    print(
      'DEBUG: Main Build: isAuthenticated: ${userProvider.isAuthenticated}',
    );

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
      print(
        'DEBUG: Main Build: User is authenticated. Checking notification loading.',
      );
      if (notificationProvider.isLoading ||
          notificationProvider.notifications.isEmpty) {
        print(
          'DEBUG: Main Build: Showing green notificationProvider loading OR empty.',
        );
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        );
      }
      print('DEBUG: Main Build: Showing HomeScreen.');
      return const HomeScreen();
    } else {
      print('DEBUG: Main Build: Showing WelcomeScreen.');
      return const WelcomeScreen();
    }
  }
}
