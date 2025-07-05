import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id; // ID dokumen Firestore
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? type; // Opsional: 'new_book', 'book_status_change', dll.
  final String? relatedItemId; // Opsional: ID buku yang terkait
  final String userId; // ID pengguna yang relevan dengan notifikasi ini

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type,
    this.relatedItemId,
    required this.userId,
  });

  // Factory constructor untuk membuat objek AppNotification dari DocumentSnapshot Firestore
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? 'Notifikasi Baru',
      message: data['message'] ?? 'Ada pembaruan.',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: data['type'],
      relatedItemId: data['relatedItemId'],
      userId: data['userId'] ?? '',
    );
  }

  // Mengonversi objek AppNotification menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type,
      'relatedItemId': relatedItemId,
      'userId': userId,
    };
  }

  // Metode untuk membuat salinan notifikasi dengan perubahan (misalnya, update userId)
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? relatedItemId,
    String? userId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      userId: userId ?? this.userId,
    );
  }
}
