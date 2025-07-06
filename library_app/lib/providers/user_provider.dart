// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  String uid;
  String name;
  String email;
  String? profileImageUrl;
  String role;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.role = 'user',
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'role': role,
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? profileImageUrl,
    String? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
    );
  }
}

class UserProvider extends ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _isLoading =
      true; // <--- INISIALISASI TRUE UNTUK MENCAKUP STARTUP LOADING

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  // Perbaikan: Tambahkan getter userId di sini
  String? get userId => _currentUser?.uid;

  UserProvider() {
    _firebaseAuth.authStateChanges().listen((auth.User? firebaseUser) async {
      _isLoading = true; // Set isLoading true di awal listener
      notifyListeners(); // Beri tahu bahwa loading dimulai

      if (firebaseUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (userDoc.exists) {
          _currentUser = AppUser.fromFirestore(userDoc);
        } else {
          _currentUser = AppUser(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
            email: firebaseUser.email!,
            profileImageUrl: firebaseUser.photoURL,
            role: 'user',
          );
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(_currentUser!.toMap());
        }
      } else {
        _currentUser = null;
      }

      _isLoading = false; // Set isLoading false setelah fetch/check selesai
      notifyListeners(); // Beri tahu bahwa loading selesai dan status berubah
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      AppUser newUser = AppUser(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        profileImageUrl: userCredential.user!.photoURL,
        role: 'user',
      );
      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());

      _currentUser = newUser;
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

  Future<void> updateProfile({
    String? name,
    String? email,
    String? profileImageUrl,
  }) async {
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
        }
        // >>> PERBAIKAN: Update photoURL di Firebase Auth juga <<<
        if (profileImageUrl != null &&
            profileImageUrl != firebaseUser.photoURL) {
          await firebaseUser.updatePhotoURL(
            profileImageUrl,
          ); // AKTIFKAN/TAMBAHKAN BARIS INI
        }

        Map<String, dynamic> updateData = {};
        if (name != null) updateData['name'] = name;
        if (email != null) updateData['email'] = email;
        if (profileImageUrl != null)
          updateData['profileImageUrl'] = profileImageUrl;

        if (updateData.isNotEmpty) {
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .update(updateData);
        }

        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        _currentUser = AppUser.fromFirestore(userDoc);
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
      }
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
      if (_currentUser?.uid == uid) {
        _currentUser = _currentUser?.copyWith(role: newRole);
      }
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
