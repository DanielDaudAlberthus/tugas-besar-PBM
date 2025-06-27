import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/models/book.dart'; // Pastikan import ini ada

class BorrowedBooksScreen extends StatelessWidget {
  const BorrowedBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buku yang Dipinjam')),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, child) {
          final borrowedBooks = bookProvider.borrowedBooks;

          if (bookProvider.isLoading && borrowedBooks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (borrowedBooks.isEmpty) {
            return const Center(
              child: Text('Tidak ada buku yang sedang dipinjam.'),
            );
          }

          return ListView.builder(
            itemCount: borrowedBooks.length,
            itemBuilder: (context, index) {
              final book = borrowedBooks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: ListTile(
                  leading: book.imageUrl.isNotEmpty
                      ? Image.network(
                          book.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.book, size: 50),
                        )
                      : const Icon(Icons.book, size: 50),
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.undo,
                      color: Colors.blue,
                    ), // Ikon untuk mengembalikan
                    onPressed: () async {
                      await bookProvider.toggleBorrowStatus(
                        book.id!,
                        false,
                      ); // Set isBorrowed ke false
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Buku "${book.title}" berhasil dikembalikan.',
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // Opsional: navigasi ke detail buku jika diperlukan
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => BookDetailScreen(book: book),
                    //   ),
                    // );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
