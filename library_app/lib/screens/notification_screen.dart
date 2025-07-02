import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:library_app/providers/notification_provider.dart';
import 'package:library_app/models/app_notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).markAllNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Anda'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () async {
              await Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).markAllNotificationsAsRead();
              print(
                'DEBUG: NotificationScreen - Mark All as Read pressed.',
              ); // ADDED PRINT
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi ditandai sudah dibaca.'),
                ),
              );
            },
            tooltip: 'Tandai semua sudah dibaca',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          print(
            'DEBUG: NotificationScreen Consumer rebuilding.',
          ); // ADDED PRINT
          print(
            'DEBUG: NotificationScreen - IsLoading: ${notificationProvider.isLoading}, Notifications count: ${notificationProvider.notifications.length}',
          ); // ADDED PRINT

          if (notificationProvider.isLoading &&
              notificationProvider.notifications.isEmpty) {
            print(
              'DEBUG: NotificationScreen showing loading indicator.',
            ); // ADDED PRINT
            return const Center(child: CircularProgressIndicator());
          }
          if (notificationProvider.notifications.isEmpty) {
            print(
              'DEBUG: NotificationScreen showing "Tidak ada notifikasi" message.',
            ); // ADDED PRINT
            return const Center(
              child: Text(
                'Tidak ada notifikasi.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          print(
            'DEBUG: NotificationScreen showing ListView with ${notificationProvider.notifications.length} items.',
          ); // ADDED PRINT
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notificationProvider.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];
              return Card(
                elevation: notification.isRead ? 1 : 3,
                color: notification.isRead ? Colors.white : Colors.blue[50],
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    notification.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: notification.isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'dd MMM BCE, HH:mm',
                        ).format(notification.timestamp),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!notification.isRead) {
                      await notificationProvider.markNotificationAsRead(
                        notification.id,
                        true,
                      );
                    }
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
