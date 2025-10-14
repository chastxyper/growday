// lib/screens/test_page.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  void initState() {
    super.initState();
    _showPermissionPromptOnce();
  }

  // show the custom dialog once per session
  Future<void> _showPermissionPromptOnce() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow Notifications'),
        content: const Text(
          'This app would like to send you reminders to complete your habits. '
          'Allow notifications so you don’t miss them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, thanks'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      await _requestNotificationPermission();
    }
  }

  // use permission_handler to request notification permission
  Future<void> _requestNotificationPermission() async {
    // For Android 13+ and iOS
    final status = await Permission.notification.status;
    if (status.isGranted) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications already allowed')),
        );
      return;
    }

    final result = await Permission.notification.request();

    if (result.isGranted) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission granted')),
        );
    } else if (result.isPermanentlyDenied) {
      // open app settings so user can enable it manually
      if (mounted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission required'),
            content: const Text(
              'Please enable notifications in app settings to receive reminders.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (open == true) {
          await openAppSettings();
        }
      }
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Test'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async =>
                  await NotificationService.showTestNotification(),
              child: const Text('Send Test Notification'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await NotificationService.scheduleDailyReminder();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Daily reminder set for 8:00 AM'),
                    ),
                  );
                }
              },
              child: const Text('Set Daily Reminder (8 AM)'),
            ),
          ],
        ),
      ),
    );
  }
}
