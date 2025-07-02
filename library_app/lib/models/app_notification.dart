import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? type;
  final String? relatedItemId;
  final String userId; // <--- TAMBAHKAN INI

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type,
    this.relatedItemId,
    required this.userId, // <--- TAMBAHKAN INI DI CONSTRUCTOR
  });

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
      userId: data['userId'] ?? '', // <--- PASTIKAN INI DIAMBIL DARI FIRESTORE
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type,
      'relatedItemId': relatedItemId,
      'userId': userId, // <--- PASTIKAN INI DISIMPAN KE FIRESTORE
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? relatedItemId,
    String? userId, // <--- TAMBAHKAN INI
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      userId: userId ?? this.userId, // <--- TAMBAHKAN INI
    );
  }
}