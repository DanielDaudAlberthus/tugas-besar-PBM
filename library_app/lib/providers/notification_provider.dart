// lib/providers/notification_provider.dart
import 'package:flutter/material.dart'; // Diperlukan untuk WidgetsBinding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_app/models/app_notification.dart';
import 'dart:async'; // Import untuk StreamSubscription

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  StreamSubscription<QuerySnapshot>?
  _notificationSubscription; // Untuk mengelola langganan

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    // Konstruktor tidak lagi memanggil _listenToNotifications() secara langsung.
    // Ini akan dikelola sepenuhnya oleh setUserId.
  }

  // Metode untuk mengatur ID pengguna saat ini dan mengelola listener
  void setUserId(String? userId) {
    // Jika User ID tidak berubah
    if (_currentUserId == userId) {
      // Jika user ID sama dan tidak null, tapi langganan tidak aktif, coba aktifkan kembali.
      if (userId != null && _notificationSubscription == null) {
        print(
          'DEBUG: setUserId: User ID sama, tapi langganan null. Mencoba memulai ulang listener.',
        );
        _listenToNotifications();
      }
      // PERBAIKAN: Bungkus notifyListeners() dengan addPostFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Tetap notify bahkan jika ID sama, untuk memastikan UI update jika ada perubahan status loading atau unreadCount (walau tak ada data baru)
      });
      return; // Tidak perlu melakukan apa-apa jika user ID sama dan langganan sudah aktif/diatur ulang
    }

    // User ID telah berubah (misalnya dari null ke ID, atau dari ID A ke ID B, atau ke null/logout)
    _currentUserId = userId; // Perbarui user ID internal

    // Batalkan langganan lama jika ada
    _notificationSubscription?.cancel();
    _notificationSubscription = null; // Set ke null secara eksplisit

    // --- PENTING: Bersihkan data dan set loading true *segera* setelah UID berubah ---
    _notifications = []; // Kosongkan notifikasi dari pengguna sebelumnya
    _isLoading =
        true; // Set loading true untuk menunjukkan fetching data user baru

    // PERBAIKAN: Bungkus notifyListeners() dengan addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Beri tahu UI bahwa data notifikasi sedang di-reset dan di-load ulang
    });
    print(
      'DEBUG: setUserId: User ID diperbarui menjadi $_currentUserId. Mengelola langganan. Data notifikasi direset.',
    );
    // --- AKHIR PERBAIKAN ---

    // Mulai langganan baru hanya jika ada User ID yang valid
    if (_currentUserId != null) {
      _listenToNotifications();
    } else {
      // Jika User ID null (logout), pastikan isLoading menjadi false karena tidak ada yang perlu di-load
      _isLoading = false;
      // PERBAIKAN: Bungkus notifyListeners() dengan addPostFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Notify listeners karena isLoading bisa berubah
      });
      print('DEBUG: setUserId: User logout, notifikasi dikosongkan.');
    }
  }

  // Metode untuk mendengarkan perubahan notifikasi dari Firestore
  void _listenToNotifications() {
    _isLoading =
        true; // (Ini akan di-set false di bawah saat snapshot pertama tiba)
    // PERBAIKAN: Bungkus notifyListeners() dengan addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    if (_currentUserId == null) {
      print(
        'DEBUG: _listenToNotifications: Tidak ada User ID saat mencoba mendengarkan. Kembali.',
      );
      _isLoading = false; // Pastikan loading false jika tidak ada user
      // PERBAIKAN: Bungkus notifyListeners() dengan addPostFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }

    print(
      'DEBUG: _listenToNotifications: Memulai listener baru untuk userId: $_currentUserId.',
    );

    // Buat langganan Firestore baru
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _currentUserId) // Filter berdasarkan userId
        .orderBy('timestamp', descending: true)
        .snapshots() // Ini yang memberikan update real-time
        .listen(
          (snapshot) {
            // Callback ini akan dipicu setiap kali ada perubahan di Firestore
            print(
              'DEBUG: Listener callback dipicu! Menerima ${snapshot.docs.length} dokumen dari Firestore.',
            );
            if (snapshot.docs.isEmpty) {
              print(
                'DEBUG: Tidak ada dokumen ditemukan untuk userId: $_currentUserId di snapshot ini.',
              );
            } else {
              for (var doc in snapshot.docs) {
                print(
                  'DEBUG: Menerima dokumen: ${doc.id}, title: ${doc.data()['title']}, isRead: ${doc.data()['isRead']}, docUserId: ${doc.data()['userId']}',
                );
              }
            }

            _notifications = snapshot.docs.map((doc) {
              return AppNotification.fromFirestore(doc);
            }).toList();

            _isLoading = false; // Setelah menerima data, loading selesai
            // PERBAIKAN: Bungkus notifyListeners() dengan addPostFrameCallback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners(); // Beri tahu UI untuk rebuild
            });
            print(
              'DEBUG: notifyListeners() dipanggil di _listenToNotifications. Jumlah notifikasi belum dibaca: $unreadCount',
            );
          },
          onError: (error) {
            print('ERROR: Listener Firestore untuk notifikasi gagal: $error');
            _isLoading = false; // Set loading false jika ada error
            // PERBAIKAN: Bungkus notifyListeners() dengan addPostFrameCallback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          },
          onDone: () {
            // Callback ini dipicu jika stream selesai (misalnya karena koneksi terputus dan tidak bisa di-recover)
            print(
              'DEBUG: Listener Firestore untuk notifikasi telah selesai (onDone).',
            );
            _notificationSubscription = null; // Hapus referensi langganan
          },
          cancelOnError:
              false, // Penting: Jangan batalkan stream jika ada error, biarkan onError yang menangani.
        );
  }

  @override
  void dispose() {
    print('DEBUG: NotificationProvider dibuang. Membatalkan langganan.');
    _notificationSubscription?.cancel(); // Batalkan langganan Firestore
    _notificationSubscription = null; // Hapus referensi
    super.dispose();
  }

  // Menambahkan notifikasi baru ke Firestore
  Future<void> addNotification(AppNotification notification) async {
    // Pastikan notifikasi memiliki userId yang benar
    if (notification.userId.isEmpty && _currentUserId != null) {
      // Create a new notification object with the currentUserId, as the original one might have an empty userId.
      notification = notification.copyWith(userId: _currentUserId);
    }
    // Debug print sebelum menambahkan ke Firestore
    print(
      'DEBUG: addNotification: Mencoba menambahkan notifikasi dengan userId: ${notification.userId}, title: ${notification.title}',
    );

    try {
      await _firestore.collection('notifications').add(notification.toMap());
      print(
        'DEBUG: addNotification: Notifikasi berhasil ditambahkan ke Firestore.',
      );
    } catch (e) {
      print(
        'ERROR: addNotification: Gagal menambahkan notifikasi ke Firestore: $e',
      );
      rethrow;
    }
  }

  // Menandai notifikasi sebagai sudah dibaca (di Firestore)
  Future<void> markNotificationAsRead(String notificationId) async {
    // Hapus argumen isRead, karena ini selalu untuk menandai isRead = true
    try {
      // Temukan notifikasi di daftar lokal
      final index = _notifications.indexWhere(
        (notif) => notif.id == notificationId,
      );
      if (index != -1 && !_notifications[index].isRead) {
        final userIdFromNotification =
            _notifications[index].userId; // Ambil userId dari notifikasi
        if (userIdFromNotification == null || userIdFromNotification.isEmpty) {
          debugPrint(
            'Error: Notification userId is null or empty in local list. Cannot mark as read.',
          );
          return;
        }

        await _firestore.collection('notifications').doc(notificationId).update(
          {
            'isRead': true, // Selalu set ke true
          },
        );
        print(
          'DEBUG: markNotificationAsRead: Notifikasi $notificationId ditandai sudah dibaca: true',
        );
      } else {
        print(
          'DEBUG: Notification $notificationId not found or already read locally.',
        );
      }
    } catch (e) {
      print(
        'ERROR: markNotificationAsRead: Gagal menandai notifikasi sudah dibaca: $e',
      );
      rethrow;
    }
  }

  // Menandai semua notifikasi sebagai sudah dibaca
  Future<void> markAllNotificationsAsRead() async {
    WriteBatch batch = _firestore.batch();
    for (var notification in _notifications.where((n) => !n.isRead)) {
      batch.update(
        _firestore.collection('notifications').doc(notification.id),
        {'isRead': true},
      );
    }
    try {
      await batch.commit();
      print(
        'DEBUG: markAllNotificationsAsRead: Semua notifikasi belum dibaca ditandai sudah dibaca.',
      );
    } catch (e) {
      print(
        'ERROR: markAllNotificationsAsRead: Gagal menandai semua notifikasi sudah dibaca: $e',
      );
      rethrow;
    }
  }
}
