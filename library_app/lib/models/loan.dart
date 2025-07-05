// lib/models/loan.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Loan {
  final String id;
  final String bookId;
  final String bookTitle; // Tambahkan ini untuk kemudahan tampilan
  final String userId;
  final String userName; // Tambahkan ini untuk kemudahan tampilan
  final DateTime borrowDate;
  final DateTime? returnDate; // Bisa null jika belum dikembalikan
  final bool isReturned; // Status apakah sudah dikembalikan

  Loan({
    required this.id,
    required this.bookId,
    required this.bookTitle, // Pastikan ini required
    required this.userId,
    required this.userName, // Pastikan ini required
    required this.borrowDate,
    this.returnDate,
    this.isReturned = false, // Default belum dikembalikan
  });

  factory Loan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Loan(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      bookTitle: data['bookTitle'] ?? 'Judul Tidak Diketahui', // Baca ini
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Pengguna Tidak Diketahui', // Baca ini
      borrowDate: (data['borrowDate'] as Timestamp).toDate(),
      returnDate: (data['returnDate'] as Timestamp?)?.toDate(),
      isReturned: data['isReturned'] ?? false, // Baca ini
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle, // Simpan ini
      'userId': userId,
      'userName': userName, // Simpan ini
      'borrowDate': Timestamp.fromDate(borrowDate),
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'isReturned': isReturned, // Simpan ini
    };
  }

  Loan copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? userId,
    String? userName,
    DateTime? borrowDate,
    DateTime? returnDate,
    bool? isReturned,
  }) {
    return Loan(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      borrowDate: borrowDate ?? this.borrowDate,
      returnDate: returnDate ?? this.returnDate,
      isReturned: isReturned ?? this.isReturned,
    );
  }
}
