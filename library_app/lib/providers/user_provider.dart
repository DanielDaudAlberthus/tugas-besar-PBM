import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

// Kelas AppUser untuk data pengguna kita
class AppUser {
  String uid; // User ID dari Firebase
  String name;
  String email;
  String? profileImageUrl;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? profileImageUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

class UserProvider extends ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  UserProvider() {
    _firebaseAuth.authStateChanges().listen((auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _currentUser = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          email: firebaseUser.email!,
          profileImageUrl: firebaseUser.photoURL,
        );
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      _currentUser = AppUser(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        profileImageUrl: userCredential.user!.photoURL,
      );
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error during sign in: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? name, String? email}) async {
    _isLoading = true;
    notifyListeners();
    try {
      auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        if (name != null && name != firebaseUser.displayName) {
          await firebaseUser.updateDisplayName(name);
        }
        if (email != null && email != firebaseUser.email) {
          await firebaseUser.updateEmail(email);
          // Opsi: ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          //   const SnackBar(content: Text('Email telah diubah. Mohon verifikasi email baru Anda.')),
          // );
        }
        _currentUser = _currentUser?.copyWith(
          name: firebaseUser.displayName ?? _currentUser?.name,
          email: firebaseUser.email ?? _currentUser?.email,
          profileImageUrl:
              firebaseUser.photoURL ?? _currentUser?.profileImageUrl,
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updatePassword(newPassword);
        // Opsi: ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        //   const SnackBar(content: Text('Kata sandi berhasil diperbarui!')),
        // );
      }
    } catch (e) {
      print('Error changing password: $e');
      // Opsi: ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      //     SnackBar(content: Text('Gagal mengganti kata sandi: $e')),
      // );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// GlobalKey untuk Navigator state - HARUS DI LUAR KELAS UserProvider
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
