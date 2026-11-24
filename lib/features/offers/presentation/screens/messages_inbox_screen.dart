import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/chat_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_page.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({Key? key}) : super(key: key);

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen>
    with SingleTickerProviderStateMixin {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController.fetchConversations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'countered':
        return 'Contre-offre';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 3),
      appBar: AppBar(
        title: const TroclyAppBarTitle(pageTitle: 'Messages'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2.5,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.sans(size: 13.5, weight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.sans(size: 13.5, weight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Tous'),
                Tab(text: 'En cours'),
                Tab(text: 'Terminés'),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (_authController.authToken.value.isEmpty) {
          return StatePage(
            type: StatePageType.emptyResults,
            customTitle: 'Connectez-vous pour discuter',
            customMessage: 'Vos négociations et échanges en cours apparaîtront ici.',
            actionLabel: 'Se connecter',
            onAction: () => Get.toNamed('/login'),
          );
        }

        if (_chatController.isLoading.value && _chatController.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildList(_chatController.conversations),
            _buildList(_chatController.conversations
                .where((c) =>
                    c.offerStatus == 'pending' ||
                    c.offerStatus == 'countered' ||
                    c.offerStatus == 'accepted')
                .toList()),
            _buildList(_chatController.conversations
                .where((c) =>
                    c.offerStatus == 'rejected' || c.offerStatus == 'cancelled')
                .toList()),
          ],
        );
      }),
    );
  }

  Widget _buildList(List<ConversationModel> list) {
    if (list.isEmpty) {
      return const StatePage(
        type: StatePageType.emptyResults,
        customTitle: 'Aucune conversation',
        customMessage: 'Proposez un échange sur une annonce pour ouvrir une discussion en temps réel.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _chatController.fetchConversations(),
      color: AppColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, idx) {
          final conv = list[idx];
          final initials = conv.otherUserName
              .split(' ')
              .where((p) => p.isNotEmpty)
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join();
          final isAccepted = conv.offerStatus == 'accepted';
          final isPending = conv.offerStatus == 'pending' || conv.offerStatus == 'countered';

          return GestureDetector(
            onTap: () async {
              await Get.toNamed('/chat/${conv.offerId}', arguments: conv);
              _chatController.fetchConversations();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: AppColors.bubble,
                        child: Text(
                          initials.isEmpty ? 'T' : initials,
                          style: AppTypography.sans(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.paper, width: 2),
                            ),
                          ),
                        ),
                    ],
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
                                conv.otherUserName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.sans(
                                  size: 14.5,
                                  weight: conv.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAccepted
                                    ? AppColors.successLight
                                    : isPending
                                        ? AppColors.accentLight
                                        : AppColors.bubble,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _statusLabel(conv.offerStatus),
                                style: AppTypography.sans(
                                  size: 10.5,
                                  weight: FontWeight.w600,
                                  color: isAccepted
                                      ? AppColors.success
                                      : isPending
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (conv.itemSummary.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            conv.itemSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sans(size: 11.5, color: AppColors.textHint),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            size: 13,
                            weight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                            color: conv.unreadCount > 0
                                ? AppColors.ink
                                : AppColors.textSecondary,
                          ),
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
  }
}
