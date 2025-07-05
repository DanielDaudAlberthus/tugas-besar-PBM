import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/providers/notification_provider.dart';
import 'package:library_app/models/app_notification.dart';
import 'package:library_app/providers/user_provider.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        final currentBook = bookProvider.books.firstWhere(
          (b) => b.id == book.id,
        );

        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUserId = userProvider.currentUser?.uid;

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
                // Tampilkan Kategori
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    currentBook.category, // Tampilkan kategori
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                      'Status: ${currentBook.isBorrowed ? 'Dipinjam' : 'Tersedia'}',
                      style: TextStyle(
                        fontSize: 18,
                        color: currentBook.isBorrowed
                            ? Colors.red[700]
                            : Colors.green[700],
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
                            await bookProvider.toggleBorrowStatus(
                              currentBook.id!,
                              true,
                            );

                            if (currentUserId != null) {
                              final notification = AppNotification(
                                id: '',
                                title: 'Buku Dipinjam!',
                                message:
                                    'Anda berhasil meminjam buku "${currentBook.title}".',
                                timestamp: DateTime.now(),
                                type: 'book_borrowed',
                                relatedItemId: currentBook.id,
                                userId: currentUserId,
                              );
                              await notificationProvider.addNotification(
                                notification,
                              );
                            }

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Anda berhasil meminjam "${currentBook.title}"!',
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.bookmark_add),
                    label: Text(
                      currentBook.isBorrowed ? 'TIDAK TERSEDIA' : 'PINJAM BUKU',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: currentBook.isBorrowed
                          ? Colors.grey
                          : Colors.blue,
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
                  currentBook.description,
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
