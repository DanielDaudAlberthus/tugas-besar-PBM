// lib/screens/book_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:library_app/models/book.dart';
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/providers/loan_provider.dart'; // <<< Import LoanProvider
import 'package:library_app/providers/user_provider.dart'; // <<< Import UserProvider
import 'package:library_app/models/loan.dart'; // <<< Import model Loan
import 'package:library_app/providers/notification_provider.dart'; // Import NotificationProvider
import 'package:library_app/models/app_notification.dart'; // Import AppNotification model

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  DateTime? _selectedBorrowDate;
  DateTime? _selectedReturnDate;
  Loan? _activeLoan; // Untuk menyimpan data peminjaman aktif jika ada

  @override
  void initState() {
    super.initState();
    // Panggil logika untuk mendapatkan peminjaman aktif saat screen dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveLoan();
    });
  }

  Future<void> _fetchActiveLoan() async {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    if (!context.mounted) return; // Tambahkan ini juga, sebagai praktik terbaik
    _activeLoan = await loanProvider.getActiveLoanForBook(widget.book.id!);
    setState(() {
      // Perbarui UI jika ada peminjaman aktif yang ditemukan
    });
  }

  Future<void> _selectBorrowDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Tanggal pinjam tidak bisa di masa depan
    );
    if (picked != null && picked != _selectedBorrowDate) {
      setState(() {
        _selectedBorrowDate = picked;
      });
    }
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate:
          _selectedBorrowDate ??
          DateTime(2000), // Tidak bisa sebelum tanggal pinjam
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedReturnDate) {
      setState(() {
        _selectedReturnDate = picked;
      });
    }
  }

  Future<void> _borrowBook() async {
    if (_selectedBorrowDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih tanggal pinjam.')));
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    ); // Ambil notificationProvider

    final currentUserId = userProvider.userId;
    final currentUserName = userProvider.currentUser?.name;

    if (currentUserId == null || currentUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk meminjam buku.')),
      );
      return;
    }

    try {
      await loanProvider.borrowBook(
        book: widget.book,
        userId: currentUserId,
        userName: currentUserName,
        borrowDate: _selectedBorrowDate!,
        bookProvider: bookProvider,
      );
      // Perbarui status buku lokal di BookDetailScreen setelah peminjaman berhasil
      // agar tombol bisa berubah.
      await _fetchActiveLoan(); // Refresh status peminjaman aktif

      // Tambahkan notifikasi setelah berhasil meminjam
      final notification = AppNotification(
        id: '',
        title: 'Buku Berhasil Dipinjam!',
        message: 'Anda telah berhasil meminjam buku "${widget.book.title}".',
        timestamp: DateTime.now(),
        type: 'book_borrowed',
        relatedItemId: widget.book.id,
        userId: currentUserId, // <<< INI YANG PENTING
      );
      await notificationProvider.addNotification(notification);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buku "${widget.book.title}" berhasil dipinjam!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal meminjam buku: ${e.toString()}')),
      );
    }
  }

  Future<void> _returnBook() async {
    if (_selectedReturnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dikembalikan.')),
      );
      return;
    }
    if (_activeLoan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku ini tidak sedang Anda pinjam.')),
      );
      return;
    }
    if (_selectedReturnDate!.isBefore(_activeLoan!.borrowDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tanggal dikembalikan tidak bisa sebelum tanggal pinjam.',
          ),
        ),
      );
      return;
    }

    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    ); // Ambil notificationProvider
    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    ); // Perlu untuk currentUserId
    final currentUserId = userProvider.userId; // Ambil userId

    try {
      await loanProvider.returnBook(
        loan: _activeLoan!,
        returnDate: _selectedReturnDate!,
        bookProvider: bookProvider,
      );
      // Perbarui status buku lokal setelah pengembalian berhasil
      // agar tombol bisa berubah.
      setState(() {
        _activeLoan = null; // Hapus peminjaman aktif
        _selectedBorrowDate = null;
        _selectedReturnDate = null;
      });

      // Tambahkan notifikasi setelah berhasil mengembalikan
      if (currentUserId != null) {
        final notification = AppNotification(
          id: '',
          title: 'Buku Berhasil Dikembalikan!',
          message:
              'Anda telah berhasil mengembalikan buku "${widget.book.title}".',
          timestamp: DateTime.now(),
          type: 'book_returned',
          relatedItemId: widget.book.id,
          userId: currentUserId, // <<< INI YANG PENTING
        );
        await notificationProvider.addNotification(notification);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buku "${widget.book.title}" berhasil dikembalikan!'),
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
    // Listen ke BookProvider untuk memastikan data buku terbaru (terutama isBorrowed dan borrowedByUserId)
    final bookProvider = Provider.of<BookProvider>(context);
    final currentBook = bookProvider.books.firstWhere(
      (b) => b.id == widget.book.id,
      orElse: () =>
          widget.book, // Fallback jika tidak ditemukan (jarang terjadi)
    );

    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.userId; // User yang sedang login
    final isAdmin = userProvider.currentUser?.role == 'admin';

    // Tentukan apakah buku sedang dipinjam dan oleh siapa
    final bool isBorrowed = currentBook.isBorrowed;
    final bool isBorrowedByCurrentUser =
        isBorrowed && currentBook.borrowedByUserId == currentUserId;
    final bool isBorrowedByOtherUser =
        isBorrowed && currentBook.borrowedByUserId != currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentBook.title),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: currentBook.imageUrl.isNotEmpty
                  ? Image.network(
                      currentBook.imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.book,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              currentBook.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Oleh: ${currentBook.author}',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategori: ${currentBook.categoryId}', // Anda mungkin perlu mengambil nama kategori dari CategoryProvider
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deskripsi:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(currentBook.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            // Tampilkan status peminjaman
            if (isBorrowed)
              Card(
                color: Colors.red[100],
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Peminjaman:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isBorrowedByCurrentUser)
                        Text(
                          'Buku ini sedang Anda pinjam.',
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      if (isBorrowedByOtherUser)
                        Text(
                          'Buku ini sedang dipinjam oleh pengguna lain.',
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      if (_activeLoan != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tanggal Pinjam: ${DateFormat('dd MMM yyyy, HH:mm').format(_activeLoan!.borrowDate)}',
                          style: TextStyle(color: Colors.red[800]),
                        ),
                        if (_activeLoan!.returnDate != null)
                          Text(
                            'Tanggal Dikembalikan: ${DateFormat('dd MMM yyyy, HH:mm').format(_activeLoan!.returnDate!)}',
                            style: TextStyle(color: Colors.red[800]),
                          ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Card(
                color: Colors.green[100],
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Peminjaman:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buku ini tersedia untuk dipinjam.',
                        style: TextStyle(color: Colors.green[800]),
                      ),
                    ],
                  ),
                ),
              ),

            // Kontrol Peminjaman/Pengembalian
            if (!isAdmin) // Admin tidak bisa meminjam/mengembalikan buku
              Column(
                children: [
                  if (!isBorrowed) // Jika buku tersedia, tampilkan tombol pinjam
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Pinjam:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ListTile(
                          title: Text(
                            _selectedBorrowDate == null
                                ? 'Pilih Tanggal'
                                : DateFormat(
                                    'dd MMM yyyy, HH:mm',
                                  ).format(_selectedBorrowDate!),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectBorrowDate(context),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _borrowBook,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Pinjam Buku',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (isBorrowedByCurrentUser) // Jika buku dipinjam oleh pengguna saat ini
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Dikembalikan:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ListTile(
                          title: Text(
                            _selectedReturnDate == null
                                ? 'Pilih Tanggal'
                                : DateFormat(
                                    'dd MMM yyyy, HH:mm',
                                  ).format(_selectedReturnDate!),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectReturnDate(context),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _returnBook,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Kembalikan Buku',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (isBorrowedByOtherUser) // Jika buku dipinjam oleh pengguna lain
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        'Buku ini sedang dipinjam oleh pengguna lain dan tidak dapat dipinjam.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[800], fontSize: 16),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
