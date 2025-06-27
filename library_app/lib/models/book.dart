import 'package:cloud_firestore/cloud_firestore.dart'; // Import ini jika belum ada

class Book {
  final String? id; // ID opsional untuk dokumen Firestore
  final String title;
  final String author;
  final String imageUrl;
  final String description;
  bool isBorrowed; // Tidak final karena bisa berubah

  Book({
    this.id, // ID sekarang opsional
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.description,
    this.isBorrowed = false,
  });

  // Factory constructor untuk membuat objek Book dari DocumentSnapshot Firestore
  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id, // Ambil ID dokumen dari Firestore
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      isBorrowed: data['isBorrowed'] ?? false,
    );
  }

  // Mengonversi objek Book menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'description': description,
      'isBorrowed': isBorrowed,
    };
  }
}
