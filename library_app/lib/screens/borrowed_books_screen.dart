// lib/screens/borrowed_books_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:library_app/providers/loan_provider.dart';
import 'package:library_app/models/loan.dart';
import 'package:library_app/providers/user_provider.dart'; // Diperlukan untuk mengakses userId
import 'package:library_app/providers/book_provider.dart'; // <<< TAMBAHKAN BARIS INI

class BorrowedBooksScreen extends StatefulWidget {
  const BorrowedBooksScreen({super.key});

  @override
  State<BorrowedBooksScreen> createState() => _BorrowedBooksScreenState();
}

class _BorrowedBooksScreenState extends State<BorrowedBooksScreen> {
  @override
  void initState() {
    super.initState();
    // Memastikan listener di LoanProvider diaktifkan dengan userId yang benar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      // Panggil setUserId di LoanProvider agar mulai mendengarkan pinjaman user ini
      loanProvider.setUserId(userProvider.userId);
      print(
        'DEBUG: BorrowedBooksScreen initState: setUserId dipanggil untuk LoanProvider dengan userId: ${userProvider.userId}',
      );
    });
  }

  // Metode ini sekarang hanya untuk memicu pengembalian buku dari daftar
  Future<void> _returnBook(Loan loan) async {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(
      context,
      listen: false,
    ); // BookProvider sekarang akan dikenali

    try {
      await loanProvider.returnBook(
        loan: loan,
        returnDate: DateTime.now(),
        bookProvider: bookProvider,
      );
      // Data akan otomatis diperbarui karena LoanProvider menggunakan snapshots()
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buku "${loan.bookTitle}" berhasil dikembalikan!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengembalikan buku: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen ke LoanProvider untuk mendapatkan daftar buku yang sedang dipinjam
    final loanProvider = Provider.of<LoanProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Dipinjam'),
        backgroundColor: Colors.blue,
      ),
      body: loanProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : loanProvider.borrowedBooks.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada buku yang sedang Anda pinjam.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: loanProvider.borrowedBooks.length,
              itemBuilder: (context, index) {
                final loan = loanProvider.borrowedBooks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.bookTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          // PERBAIKAN: Ganti format string tanggal. Gunakan yyyy untuk tahun.
                          'Dipinjam pada: ${DateFormat('dd MMM yyyy, HH:mm').format(loan.borrowDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Tampilkan tombol kembalikan jika belum dikembalikan
                        if (!loan.isReturned)
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _returnBook(loan),
                              icon: const Icon(Icons.keyboard_return, size: 18),
                              label: const Text(
                                'Kembalikan',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
