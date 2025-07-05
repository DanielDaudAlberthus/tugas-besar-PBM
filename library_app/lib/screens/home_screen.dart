// lib/screens/home_screen.dart
// IMPORTS ANDA SAMA PERSIS SEPERTI YANG ANDA BERIKAN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/screens/add_book_screen.dart';
import 'package:library_app/screens/book_detail_screen.dart';
import 'package:library_app/screens/account_screen.dart';
import 'package:library_app/screens/borrowed_books_screen.dart';
import 'package:library_app/providers/notification_provider.dart';
import 'package:library_app/screens/notification_screen.dart';
import 'package:library_app/providers/user_provider.dart';
import 'package:library_app/models/app_notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchBooks();
      // >>> HAPUS PEMANGGILAN _loadNotifications() DI SINI <<<
      // _loadNotifications(); // BARIS INI TIDAK PERLU LAGI
    });

    _searchController.addListener(() {
      setState(() {});
    });
  }

  // >>> HAPUS SELURUH FUNGSI _loadNotifications() INI <<<
  // void _loadNotifications() async {
  //   final userProvider = Provider.of<UserProvider>(context, listen: false);
  //   final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
  //   final String? currentUserId = userProvider.userId;
  //   if (currentUserId != null && notificationProvider.notifications.isEmpty && !notificationProvider.isLoading) {
  //     print('DEBUG: HomeScreen: Calling getNotifications from _loadNotifications for User ID: $currentUserId');
  //     // await notificationProvider.getNotifications(currentUserId); // Metode ini tidak ada
  //   } else {
  //       print('DEBUG: HomeScreen: Not calling getNotifications. userId: $currentUserId, isEmpty: ${notificationProvider.notifications.isEmpty}, isLoading: ${notificationProvider.isLoading}');
  //   }
  // }
  // >>> AKHIR HAPUS FUNGSI _loadNotifications() <<<

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Home (sudah di sini)
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BorrowedBooksScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountScreen()),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        // Ambil NotificationProvider dan UserProvider untuk digunakan di UI.
        // Listen: true untuk notifikasi agar badge dan UI notifikasi diperbarui.
        final notificationProvider = Provider.of<NotificationProvider>(context);
        final userProvider = Provider.of<UserProvider>(context);

        final currentUserId = userProvider
            .userId; // Getter userId sudah ditambahkan di UserProvider
        final currentUserRole = userProvider.currentUser?.role;
        final isAdmin = currentUserRole == 'admin';

        print('DEBUG: HomeScreen: User ID: $currentUserId');
        print('DEBUG: HomeScreen: User Role from Provider: $currentUserRole');
        print('DEBUG: HomeScreen: Is Admin (calculated): $isAdmin');
        print(
          'DEBUG: HomeScreen: NotificationProvider.isLoading: ${notificationProvider.isLoading}',
        );
        print(
          'DEBUG: HomeScreen: Notifications count: ${notificationProvider.notifications.length}',
        );
        print(
          'DEBUG: HomeScreen: Unread count: ${notificationProvider.unreadCount}',
        );

        final List<Book> displayedBooks = _searchController.text.isEmpty
            ? bookProvider.books
            : bookProvider.searchBooks(_searchController.text);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 130, // Tetap tinggi agar search bar muat
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Menu dibuka (simulasi)!'),
                              ),
                            );
                          },
                        ),
                        const Text(
                          'Library',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        // Ikon Notifikasi dengan Badge
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationScreen(),
                                  ),
                                );
                              },
                            ),
                            if (notificationProvider.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    '${notificationProvider.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari buku, penulis...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tambahkan CircularProgressIndicator jika notifikasi sedang dimuat
          body:
              notificationProvider
                  .isLoading // Periksa isLoading NotificationProvider
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ), // Indikator loading notifikasi
                  ),
                )
              : bookProvider.isLoading && displayedBooks.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : displayedBooks.isEmpty && _searchController.text.isNotEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada hasil ditemukan untuk pencarian Anda.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : displayedBooks.isEmpty && _searchController.text.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tidak ada buku di perpustakaan.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (isAdmin)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddBookScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Buku Pertama'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: displayedBooks.length,
                  itemBuilder: (context, index) {
                    final book = displayedBooks[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(book: book),
                          ),
                        );
                      },
                      child: Card(
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
                                        errorBuilder:
                                            (context, error, stackTrace) =>
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: book.isBorrowed
                                            ? Colors.red[100]
                                            : Colors.green[100],
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        book.isBorrowed
                                            ? 'Dipinjam'
                                            : 'Tersedia',
                                        style: TextStyle(
                                          color: book.isBorrowed
                                              ? Colors.red[700]
                                              : Colors.green[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      book.isBorrowed
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: book.isBorrowed
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: () async {
                                      await bookProvider.toggleBorrowStatus(
                                        book.id!,
                                        !book.isBorrowed,
                                      );
                                      String statusMessage = book.isBorrowed
                                          ? "dikembalikan"
                                          : "dipinjam";
                                      if (currentUserId != null) {
                                        final notification = AppNotification(
                                          id: '',
                                          title: 'Status Buku Berubah!',
                                          message:
                                              'Buku "${book.title}" sekarang telah $statusMessage.',
                                          timestamp: DateTime.now(),
                                          type: 'book_status_change',
                                          relatedItemId: book.id,
                                          userId: currentUserId,
                                        );
                                        await notificationProvider
                                            .addNotification(notification);
                                      }
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Buku "${book.title}" telah $statusMessage.',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (isAdmin) // HANYA UNTUK ADMIN
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        bool confirmDelete =
                                            await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Hapus Buku'),
                                                content: Text(
                                                  'Apakah Anda yakin ingin menghapus buku "${book.title}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(false),
                                                    child: const Text('Batal'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(true),
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                            ) ??
                                            false;

                                        if (confirmDelete) {
                                          await bookProvider.deleteBook(
                                            book.id!,
                                          );
                                          if (currentUserId != null) {
                                            final notification = AppNotification(
                                              id: '',
                                              title: 'Buku Dihapus!',
                                              message:
                                                  'Buku "${book.title}" telah dihapus dari perpustakaan.',
                                              timestamp: DateTime.now(),
                                              type: 'book_deleted',
                                              userId: currentUserId,
                                            );
                                            await notificationProvider
                                                .addNotification(notification);
                                          }
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Buku "${book.title}" dihapus.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          // BottomNavigationBar untuk navigasi antar halaman
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
              BottomNavigationBarItem(
                icon: Icon(Icons.collections_bookmark),
                label: 'Dipinjam',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue,
            onTap: _onItemTapped,
          ),
          // FloatingActionButton hanya terlihat oleh admin
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddBookScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }
}
