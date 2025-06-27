import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as auth; // Import Firebase Auth

// Kita masih bisa menggunakan kelas User kita sendiri untuk data tambahan
// Selain data yang langsung dari Firebase User.
class AppUser {
  // Ganti nama kelas User menjadi AppUser untuk menghindari konflik dengan firebase_auth.User
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
  final auth.FirebaseAuth _firebaseAuth =
      auth.FirebaseAuth.instance; // Instance Firebase Auth

  AppUser? _currentUser; // Menggunakan AppUser kita
  bool _isLoading = false; // Untuk indikator loading

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  UserProvider() {
    // Dengarkan perubahan status autentikasi Firebase
    _firebaseAuth.authStateChanges().listen((auth.User? firebaseUser) {
      if (firebaseUser != null) {
        // Pengguna login atau baru terdaftar
        _currentUser = AppUser(
          uid: firebaseUser.uid,
          name:
              firebaseUser.displayName ??
              firebaseUser.email!.split(
                '@',
              )[0], // Gunakan displayName atau ambil dari email
          email: firebaseUser.email!,
          profileImageUrl: firebaseUser.photoURL,
        );
      } else {
        // Pengguna logout
        _currentUser = null;
      }
      notifyListeners(); // Beri tahu UI bahwa status telah berubah
    });
  }

  // Metode untuk mendaftar pengguna baru
  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      // Update display name (nama pengguna) di Firebase User
      await userCredential.user?.updateDisplayName(name);
      // Di sini Anda juga bisa menyimpan data AppUser ke Firestore jika ada data tambahan yang perlu disimpan
      _currentUser = AppUser(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        profileImageUrl: userCredential.user!.photoURL,
      );
    } catch (e) {
      print('Error during sign up: $e');
      rethrow; // Lempar error kembali agar bisa ditangani di UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk login pengguna
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      auth.UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      // Data _currentUser akan otomatis diisi oleh stream authStateChanges
    } catch (e) {
      print('Error during sign in: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk logout
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseAuth.signOut();
      // _currentUser akan otomatis null oleh stream authStateChanges
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk memperbarui profil (nama dan email)
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
          // Firebase mengharuskan verifikasi email ulang jika diubah
          await firebaseUser.updateEmail(email);
          // Anda mungkin ingin menampilkan pesan kepada pengguna untuk memverifikasi email baru mereka
        }
        // Perbarui _currentUser lokal setelah perubahan sukses
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

  // Untuk ganti password
  Future<void> changePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updatePassword(newPassword);
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil diperbarui!')),
        );
      }
    } catch (e) {
      print('Error changing password: $e');
      ScaffoldMessenger.of(
        navigatorKey.currentContext!,
      ).showSnackBar(SnackBar(content: Text('Gagal mengganti kata sandi: $e')));
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// GlobalKey untuk Navigator state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
