import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _mockNotifications = const [
    {
      'title': 'Nouvelle offre reçue',
      'body': 'Hamza vous propose 2 objets pour votre appareil photo vintage.',
      'time': 'Il y a 5 min',
      'icon': Icons.swap_horiz_rounded,
      'route': '/messages',
    },
    {
      'title': 'Contre-offre reçue',
      'body': 'Youssef a ajusté sa proposition avec soulte possible.',
      'time': 'Il y a 25 min',
      'icon': Icons.edit_note_rounded,
      'route': '/messages',
    },
    {
      'title': 'Rappel de rendez-vous',
      'body': 'Rencontre prévue demain à 15h30 à Place El Hedim, Meknès.',
      'time': 'Il y a 2 h',
      'icon': Icons.event_available_rounded,
      'route': '/feed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) {
          final notif = _mockNotifications[idx];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(notif['icon'] as IconData, color: AppColors.primary, size: 22),
              ),
              title: Text(
                notif['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(notif['body'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(notif['time'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                ],
              ),
              onTap: () {
                Get.toNamed(notif['route'] as String);
              },
            ),
          );
        },
      ),
    );
  }
}
