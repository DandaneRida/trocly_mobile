import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/notifications_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsController _controller = Get.find<NotificationsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchNotifications();
    });
  }

  IconData _iconForType(String type) {
    if (type.startsWith('offer')) return Icons.swap_horiz_rounded;
    if (type == 'new_message') return Icons.chat_bubble_outline_rounded;
    if (type.startsWith('meeting')) return Icons.qr_code_2_rounded;
    if (type.startsWith('review')) return Icons.star_outline_rounded;
    return Icons.notifications_none_rounded;
  }

  void _openNotification(NotificationItem item) {
    if (!item.isRead) {
      _controller.markAsRead(item.id);
    }
    final route = item.data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
      return;
    }
    if (item.data['offerId'] != null) {
      Get.toNamed('/chat/${item.data['offerId']}');
    } else if (item.data['meetingId'] != null) {
      Get.toNamed('/my-qr/${item.data['meetingId']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Get.back(),
        ),
        title: Text('Notifications', style: AppTypography.serif(size: 22)),
        actions: [
          Obx(() {
            if (_controller.unreadCount.value == 0) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: _controller.markAllAsRead,
              child: Text(
                'Tout lire',
                style: AppTypography.sans(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            );
          }),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.notifications.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2),
          );
        }

        if (_controller.notifications.isEmpty) {
          return const StatePage(
            type: StatePageType.emptyResults,
            customTitle: 'Aucune notification',
            customMessage:
                'Vous serez averti ici dès qu\'une offre, un message ou un rendez-vous arrive.',
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchNotifications,
          color: AppColors.ink,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            itemCount: _controller.notifications.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, idx) {
              final item = _controller.notifications[idx];
              return InkWell(
                onTap: () => _openNotification(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.isRead ? AppColors.bubble : AppColors.accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForType(item.type),
                          size: 19,
                          color: item.isRead ? AppColors.textSecondary : AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: AppTypography.sans(
                                      size: 13.5,
                                      weight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!item.isRead)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.body,
                              style: AppTypography.sans(
                                size: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.relativeTime,
                              style: AppTypography.sans(size: 11, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
