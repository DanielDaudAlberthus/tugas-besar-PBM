// lib/providers/loan_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_app/models/loan.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/providers/book_provider.dart'; // Diperlukan untuk update status buku
import 'package:library_app/providers/user_provider.dart'; // Diperlukan untuk akses user ID
import 'dart:async'; // Untuk StreamSubscription

class LoanProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>?
  _loanSubscription; // Untuk mengelola langganan
  String? _currentUserId; // Untuk melacak userId saat ini

  List<Loan> _borrowedBooks = [];
  List<Loan> get borrowedBooks => _borrowedBooks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  LoanProvider() {
    // Konstruktor tidak memanggil _listenToLoans secara langsung.
    // Ini akan dikelola oleh setUserId dari main.dart.
  }

  // Metode untuk mengatur ID pengguna saat ini dan mengelola listener
  void setUserId(String? userId) {
    // Jika User ID tidak berubah dan sudah ada langganan, tidak perlu melakukan apa-apa.
    if (_currentUserId == userId) {
      if (userId != null && _loanSubscription == null) {
        print(
          'DEBUG: LoanProvider setUserId: User ID sama, tapi langganan null. Mencoba memulai ulang listener.',
        );
        _listenToLoans();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasListeners) return;
        notifyListeners();
      });
      return;
    }

    // User ID telah berubah (misalnya dari null ke ID, atau dari ID A ke ID B, atau ke null/logout)
    _currentUserId = userId; // Perbarui user ID internal

    // Batalkan langganan lama jika ada
    _loanSubscription?.cancel();
    _loanSubscription = null; // Set ke null secara eksplisit

    // Bersihkan data pinjaman dari pengguna sebelumnya dan set loading true
    _borrowedBooks = [];
    _isLoading = true;

    // Beri tahu listener setelah update internal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasListeners) return;
      notifyListeners();
    });
    print(
      'DEBUG: LoanProvider setUserId: User ID diperbarui menjadi $_currentUserId. Mengelola langganan. Data pinjaman direset.',
    );

    // Mulai langganan baru hanya jika ada User ID yang valid
    if (_currentUserId != null) {
      _listenToLoans();
    } else {
      // Jika User ID null (logout), pastikan isLoading menjadi false
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasListeners) return;
        notifyListeners();
      });
      print(
        'DEBUG: LoanProvider setUserId: User logout, pinjaman dikosongkan.',
      );
    }
  }

  // Metode untuk mendengarkan perubahan peminjaman dari Firestore
  void _listenToLoans() {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasListeners) return;
      notifyListeners();
    });

    if (_currentUserId == null) {
      print(
        'DEBUG: LoanProvider _listenToLoans: Tidak ada User ID saat mencoba mendengarkan. Kembali.',
      );
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasListeners) return;
        notifyListeners();
      });
      return;
    }

    print(
      'DEBUG: LoanProvider _listenToLoans: Memulai listener baru untuk userId: $_currentUserId.',
    );

    _loanSubscription = _firestore
        .collection('loans')
        .where('userId', isEqualTo: _currentUserId)
        .where(
          'isReturned',
          isEqualTo: false,
        ) // Hanya ambil yang belum dikembalikan
        .orderBy('borrowDate', descending: true)
        .snapshots() // Ini yang memberikan update real-time
        .listen(
          (snapshot) {
            print(
              'DEBUG: LoanProvider Listener callback dipicu! Menerima ${snapshot.docs.length} dokumen pinjaman dari Firestore.',
            );
            if (snapshot.docs.isEmpty) {
              print(
                'DEBUG: LoanProvider: Tidak ada dokumen pinjaman ditemukan untuk userId: $_currentUserId di snapshot ini.',
              );
            } else {
              for (var doc in snapshot.docs) {
                print(
                  'DEBUG: LoanProvider: Menerima dokumen pinjaman: ${doc.id}, bookTitle: ${doc.data()['bookTitle']}, isReturned: ${doc.data()['isReturned']}',
                );
              }
            }

            _borrowedBooks = snapshot.docs.map((doc) {
              return Loan.fromFirestore(doc);
            }).toList();

            _isLoading = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!hasListeners) return;
              notifyListeners();
            });
            print(
              'DEBUG: LoanProvider notifyListeners() dipanggil di _listenToLoans. Jumlah buku dipinjam: ${_borrowedBooks.length}',
            );
          },
          onError: (error) {
            print(
              'ERROR: LoanProvider Listener Firestore untuk pinjaman gagal: $error',
            );
            _isLoading = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!hasListeners) return;
              notifyListeners();
            });
          },
          onDone: () {
            print(
              'DEBUG: LoanProvider Listener Firestore untuk pinjaman telah selesai (onDone).',
            );
            _loanSubscription = null;
          },
          cancelOnError: false,
        );
  }

  @override
  void dispose() {
    print('DEBUG: LoanProvider dibuang. Membatalkan langganan.');
    _loanSubscription?.cancel();
    _loanSubscription = null;
    super.dispose();
  }

  Future<void> borrowBook({
    required Book book,
    required String userId,
    required String userName,
    required DateTime borrowDate,
    required BookProvider bookProvider, // Menerima BookProvider
  }) async {
    if (book.isBorrowed) {
      throw Exception('Buku ini sudah dipinjam.');
    }

    _isLoading = true;
    notifyListeners();
    try {
      // Buat objek Loan
      final newLoan = Loan(
        id: '', // ID akan diisi oleh Firestore
        bookId: book.id!,
        bookTitle: book.title, // Simpan judul buku
        userId: userId,
        userName: userName, // Simpan nama user
        borrowDate: borrowDate,
        isReturned: false, // Default belum dikembalikan
      );

      // Tambahkan loan ke koleksi 'loans'
      await _firestore.collection('loans').add(newLoan.toMap());

      // Update status buku di koleksi 'books'
      // PERBAIKAN: Panggil updateBook dengan HANYA SATU argumen (objek Book)
      await bookProvider.updateBook(
        book.copyWith(
          // Objek Book yang di-update
          isBorrowed: true,
          borrowedByUserId: userId, // Simpan ID pengguna yang meminjam
        ),
      );

      print(
        'DEBUG: LoanProvider: Buku "${book.title}" berhasil dipinjam oleh $userName.',
      );
    } catch (e) {
      print('ERROR: LoanProvider: Gagal meminjam buku: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> returnBook({
    required Loan loan,
    required DateTime returnDate,
    required BookProvider bookProvider, // Menerima BookProvider
  }) async {
    if (loan.isReturned) {
      throw Exception('Buku ini sudah dikembalikan.');
    }

    _isLoading = true;
    notifyListeners();
    try {
      // Update loan di koleksi 'loans'
      await _firestore.collection('loans').doc(loan.id).update({
        'isReturned': true,
        'returnDate': Timestamp.fromDate(returnDate),
      });

      // Update status buku di koleksi 'books'
      // Gunakan originalBook.copyWith agar tidak kehilangan data lain dari buku
      Book? originalBook = await bookProvider.getBookById(loan.bookId);
      if (originalBook != null) {
        // PERBAIKAN: Panggil updateBook dengan HANYA SATU argumen (objek Book)
        await bookProvider.updateBook(
          originalBook.copyWith(
            // Objek Book yang di-update
            isBorrowed: false,
            borrowedByUserId: null,
          ),
        );
      } else {
        print(
          'WARNING: LoanProvider: Buku dengan ID ${loan.bookId} tidak ditemukan saat mengembalikan.',
        );
      }

      print(
        'DEBUG: LoanProvider: Buku "${loan.bookTitle}" berhasil dikembalikan.',
      );
    } catch (e) {
      print('ERROR: LoanProvider: Gagal mengembalikan buku: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk mendapatkan peminjaman aktif untuk buku tertentu oleh user saat ini
  // Digunakan di BookDetailScreen untuk menentukan status tombol pinjam/kembalikan
  Future<Loan?> getActiveLoanForBook(String bookId) async {
    try {
      final querySnapshot = await _firestore
          .collection('loans')
          .where('bookId', isEqualTo: bookId)
          .where(
            'userId',
            isEqualTo: _currentUserId,
          ) // Hanya pinjaman oleh user ini
          .where('isReturned', isEqualTo: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Loan.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print(
        'ERROR: LoanProvider: Gagal mendapatkan peminjaman aktif untuk buku $bookId: $e',
      );
      return null;
    }
  }
}
