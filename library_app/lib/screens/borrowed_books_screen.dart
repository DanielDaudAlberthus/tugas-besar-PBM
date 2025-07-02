import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/models/book.dart';

class BorrowedBooksScreen extends StatelessWidget {
  const BorrowedBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku yang Dipinjam'),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, child) {
          final borrowedBooks = bookProvider.borrowedBooks;

          if (bookProvider.isLoading && borrowedBooks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (borrowedBooks.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada buku yang sedang dipinjam.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: borrowedBooks.length,
            itemBuilder: (context, index) {
              final book = borrowedBooks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: book.imageUrl.isNotEmpty
                            ? Image.network(
                                book.imageUrl,
                                width: 80,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 80,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    ),
                              )
                            : Container(
                                width: 80,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.book,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              book.author,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Status: ${book.isBorrowed ? 'Dipinjam' : 'Tersedia'}', // Perbaiki ini juga
                              style: TextStyle(
                                color: book.isBorrowed
                                    ? Colors.red[700]
                                    : Colors.green[700],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Tanggal peminjaman dan pengembalian bisa ditambahkan di sini
                            // Perhatikan bahwa model Book saat ini tidak punya field ini,
                            // Anda perlu menambahkannya jika ingin menampilkan data ini dari Firestore
                            // if (book.borrowedDate != null)
                            //   Text(
                            //     'Dipinjam: ${DateFormat('dd MMM yyyy').format(book.borrowedDate!)}',
                            //     style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            //   ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await bookProvider.toggleBorrowStatus(
                            book.id!,
                            false,
                          ); // Set isBorrowed ke false
                          // --- PERBAIKAN DI SINI ---
                          if (!context.mounted) return; // <--- TAMBAHKAN INI
                          // -----------------------
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Buku "${book.title}" berhasil dikembalikan.',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Kembalikan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
