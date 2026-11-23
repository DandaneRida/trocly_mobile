import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';

/// Barre de navigation basse Trocly (5 onglets épurés à filet supérieur)
class TroclyBottomNav extends StatelessWidget {
  final int currentIndex;

  const TroclyBottomNav({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  void _onTap(int index) {
    if (index == currentIndex) return;
    final auth =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final isLoggedIn = auth != null && auth.authToken.value.isNotEmpty;

    switch (index) {
      case 0:
        Get.offAllNamed('/feed');
        break;
      case 1:
        Get.toNamed('/search');
        break;
      case 2:
        if (!isLoggedIn) {
          Get.toNamed('/login');
        } else {
          Get.toNamed('/publish');
        }
        break;
      case 3:
        Get.toNamed('/messages');
        break;
      case 4:
        Get.toNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatCtrl = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                label: 'Explorer',
                isActive: currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box_rounded,
                label: 'Publier',
                isActive: currentIndex == 2,
                onTap: () => _onTap(2),
              ),
              chatCtrl != null
                  ? Obx(() => _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: 'Messages',
                        isActive: currentIndex == 3,
                        badgeCount: chatCtrl.unreadCount.value,
                        onTap: () => _onTap(3),
                      ))
                  : _NavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Messages',
                      isActive: currentIndex == 3,
                      onTap: () => _onTap(3),
                    ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                isActive: currentIndex == 4,
                onTap: () => _onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.ink : AppColors.textHint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, size: 22, color: color),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.sans(
                size: 10.5,
                weight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
