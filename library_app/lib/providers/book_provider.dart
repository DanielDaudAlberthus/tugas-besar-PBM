import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BookProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Book> _books = [];
  bool _isLoading = false;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;

  // Metode yang sudah ada (fetchBooks, searchBooks, addBook, deleteBook)
  // Pastikan fetchBooks mengambil borrowedByUserId juga
  Future<void> fetchBooks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .orderBy('title')
          .get();
      _books = querySnapshot.docs
          .map((doc) => Book.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching books: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambahkan atau modifikasi metode ini untuk update buku
  Future<void> updateBook(Book book) async {
    try {
      if (book.id == null) {
        throw Exception("Book ID cannot be null for update.");
      }
      await _firestore.collection('books').doc(book.id).update(book.toMap());
      // Update di daftar lokal
      int index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _books[index] = book;
      }
      notifyListeners();
      print('Book "${book.title}" updated successfully.');
    } catch (e) {
      print('Error updating book: $e');
      rethrow;
    }
  }

  // Tambahkan metode untuk mendapatkan buku berdasarkan ID
  Future<Book?> getBookById(String bookId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('books')
          .doc(bookId)
          .get();
      if (doc.exists) {
        return Book.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting book by ID: $e');
      return null;
    }
  }

  // Metode lainnya seperti addBook, deleteBook, searchBooks tetap sama
  // ...
  Future<void> addBook(Book book) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('books')
          .add(book.toMap());
      book.id = docRef.id;
      _books.add(book);
      notifyListeners();
      print('Book "${book.title}" added successfully.');
    } catch (e) {
      print('Error adding book: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).delete();
      _books.removeWhere((book) => book.id == bookId);
      notifyListeners();
      print('Book with ID "$bookId" deleted successfully.');
    } catch (e) {
      print('Error deleting book: $e');
      rethrow;
    }
  }

  List<Book> searchBooks(String query) {
    if (query.isEmpty) {
      return _books;
    }
    return _books
        .where(
          (book) =>
              book.title.toLowerCase().contains(query.toLowerCase()) ||
              book.author.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
