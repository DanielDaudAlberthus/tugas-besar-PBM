import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:library_app/models/book.dart'; // <--- PERBAIKI IMPORT INI
import 'package:library_app/providers/book_provider.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendengarkan perubahan status buku secara real-time
    // Ini memastikan UI di halaman detail buku juga diperbarui jika statusnya berubah
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        // Dapatkan buku terbaru dari provider menggunakan ID-nya
        // Ini penting karena objek 'book' yang dilewatkan ke konstruktor
        // mungkin bukan instance yang paling up-to-date di provider.
        final currentBook = bookProvider.books.firstWhere(
          (b) => b.id == book.id,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Buku'),
            backgroundColor: Colors.blue,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    currentBook.imageUrl,
                    height: 250,
                    width: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      width: 180,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  currentBook.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Oleh ${currentBook.author}',
                  style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${currentBook.isBorrowed ? 'Dipinjam' : 'Tersedia'}', // <--- SESUAIKAN LOGIKA STATUS
                      style: TextStyle(
                        fontSize: 18,
                        color: currentBook.isBorrowed
                            ? Colors.red[700]
                            : Colors.green[700], // <--- SESUAIKAN WARNA
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: currentBook.isBorrowed
                        ? null
                        : () async {
                            // <--- SESUAIKAN KONDISI ONPRESS
                            // Meminjam buku berarti set isBorrowed menjadi true
                            await bookProvider.toggleBorrowStatus(
                              currentBook.id!,
                              true,
                            ); // <--- PERBAIKI METHOD DAN ARGUMEN
                            // Pastikan widget masih mounted sebelum menggunakan context
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Anda berhasil meminjam "${currentBook.title}"!',
                                ),
                              ),
                            );
                            Navigator.pop(
                              context,
                            ); // Kembali ke halaman sebelumnya
                          },
                    icon: const Icon(Icons.bookmark_add),
                    label: Text(
                      currentBook.isBorrowed
                          ? 'TIDAK TERSEDIA'
                          : 'PINJAM BUKU', // <--- SESUAIKAN TEKS TOMBOL
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: currentBook.isBorrowed
                          ? Colors.grey
                          : Colors.blue, // <--- SESUAIKAN WARNA TOMBOL
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Deskripsi Singkat:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                Text(
                  currentBook
                      .description, // <--- Tampilkan deskripsi dari model
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
