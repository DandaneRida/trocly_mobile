import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';

/// Barre de navigation moderne avec pilule corail extensible sur l'onglet actif
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppColors.navShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PillNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _PillNavItem(
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                label: 'Explorer',
                isActive: currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _PillNavItem(
                icon: Icons.add_circle_outline_rounded,
                activeIcon: Icons.add_circle_rounded,
                label: 'Publier',
                isActive: currentIndex == 2,
                onTap: () => _onTap(2),
              ),
              chatCtrl != null
                  ? Obx(() => _PillNavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: 'Messages',
                        isActive: currentIndex == 3,
                        badgeCount: chatCtrl.unreadCount.value,
                        onTap: () => _onTap(3),
                      ))
                  : _PillNavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Messages',
                      isActive: currentIndex == 3,
                      onTap: () => _onTap(3),
                    ),
              _PillNavItem(
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

class _PillNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _PillNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive ? AppColors.coralShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 21,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
                if (badgeCount > 0 && !isActive)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.5, vertical: 1),
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
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.sans(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
