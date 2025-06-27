import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_app/models/book.dart';

class BookProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Book> _books = [];
  List<Book> get books => _books;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BookProvider() {
    fetchBooks(); // Panggil fetchBooks saat provider diinisialisasi
  }

  void fetchBooks() {
    _isLoading = true;
    notifyListeners();

    _firestore
        .collection('books')
        .snapshots()
        .listen(
          (snapshot) {
            _books = snapshot.docs.map((doc) {
              return Book.fromFirestore(doc);
            }).toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            notifyListeners();
            print('Error fetching books: $error');
            // Anda bisa menambahkan logika penanganan error yang lebih baik di sini
          },
        );
  }

  Future<void> addBook(Book book) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('books').add(book.toMap());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error adding book: $e');
      rethrow;
    }
  }

  Future<void> toggleBorrowStatus(String bookId, bool isBorrowed) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('books').doc(bookId).update({
        'isBorrowed': isBorrowed,
      });
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error toggling borrow status: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('books').doc(bookId).delete();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error deleting book: $e');
      rethrow;
    }
  }

  List<Book> get borrowedBooks {
    return _books.where((book) => book.isBorrowed).toList();
  }

  // >>> METODE SEARCHBOOKS INI YANG HARUS ADA DI SINI <<<
  List<Book> searchBooks(String query) {
    if (query.isEmpty) {
      return _books; // Mengembalikan semua buku jika query kosong
    }
    return _books.where((book) {
      // Melakukan pencarian berdasarkan judul atau penulis
      return book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.author.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
