// lib/models/book.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  String? id;
  String title;
  String author;
  String categoryId; // Pastikan ini ada jika Anda punya kategori
  String description;
  String imageUrl;
  bool isBorrowed;
  String? borrowedByUserId; // <<< PROPERTI INI DITAMBAHKAN
  // Tambahkan properti lain yang Anda miliki di sini

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.categoryId,
    required this.description,
    required this.imageUrl,
    this.isBorrowed = false,
    this.borrowedByUserId, // <<< PROPERTI INI DITAMBAHKAN
    // Tambahkan parameter lain di sini
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      categoryId: data['categoryId'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isBorrowed: data['isBorrowed'] ?? false,
      borrowedByUserId: data['borrowedByUserId'], // <<< BACA INI DARI FIRESTORE
      // Baca properti lain dari Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'categoryId': categoryId,
      'description': description,
      'imageUrl': imageUrl,
      'isBorrowed': isBorrowed,
      'borrowedByUserId': borrowedByUserId, // <<< SIMPAN INI KE FIRESTORE
      // Simpan properti lain ke Firestore
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? categoryId,
    String? description,
    String? imageUrl,
    bool? isBorrowed,
    String? borrowedByUserId, // <<< PROPERTI INI DITAMBAHKAN
    // Tambahkan parameter lain ke copyWith
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isBorrowed: isBorrowed ?? this.isBorrowed,
      borrowedByUserId:
          borrowedByUserId ??
          this.borrowedByUserId, // <<< PROPERTI INI DITAMBAHKAN
      // Salin properti lain
    );
  }
}
