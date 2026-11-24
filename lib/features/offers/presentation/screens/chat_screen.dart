import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/chat_controller.dart';
import '../../../../controllers/offers_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final OffersController _offersController = Get.find<OffersController>();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String? _offerId;
  ConversationModel? _conversation;

  @override
  void initState() {
    super.initState();
    _offerId = Get.parameters['offerId'];
    if (Get.arguments is ConversationModel) {
      _conversation = Get.arguments as ConversationModel;
    }
    if (_offerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _offerId == null) return;
        _chatController.messages.clear();
        _chatController.loadMessages(_offerId!);
        _chatController.connectWebSocket(_offerId!);
      });
    }
  }

  @override
  void dispose() {
    _chatController.disconnectWebSocket(silent: true);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _offerId == null) return;
    _chatController.sendMessage(_offerId!, text);
    _chatController.setTyping(_offerId!, false);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final otherName = _conversation?.otherUserName ?? 'Conversation';
    final initials = otherName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final status = _conversation?.offerStatus ?? 'pending';
    final soulte = _conversation?.soulte ?? 0;

    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 3),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Get.offAllNamed('/feed'),
              child: AppTypography.wordmark(size: 17),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.bubble,
              child: Text(
                initials.isEmpty ? 'T' : initials,
                style: AppTypography.sans(size: 12, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherName, style: AppTypography.sans(size: 14.5, weight: FontWeight.w600)),
                  Obx(() => Text(
                        _chatController.isConnected.value ? 'En ligne · temps réel' : 'Connexion…',
                        style: AppTypography.sans(
                          size: 11,
                          color: _chatController.isConnected.value
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            tooltip: 'Proposer un rendez-vous',
            onPressed: () {
              if (_offerId != null) {
                Get.toNamed('/plan-meeting/$_offerId', arguments: {
                  'offerId': _offerId,
                  'responderId': _conversation?.otherUserId,
                  'otherUserName': otherName,
                });
              }
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          // Pinned offer summary card (modern white rounded card)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status == 'accepted'
                          ? 'OFFRE ACCEPTÉE'
                          : status == 'countered'
                              ? 'CONTRE-PROPOSITION'
                              : 'PROPOSITION EN COURS',
                      style: AppTypography.eyebrow(
                        color: status == 'accepted' ? AppColors.success : AppColors.accent,
                      ),
                    ),
                    if (soulte > 0)
                      Text(
                        '+ ${soulte.toStringAsFixed(0)} DH',
                        style: AppTypography.sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (_conversation?.itemSummary.isNotEmpty ?? false)
                      ? _conversation!.itemSummary
                      : 'Échange en cours de négociation',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(size: 13.5, weight: FontWeight.w500),
                ),
                const SizedBox(height: 11),
                if (status == 'accepted')
                  SizedBox(
                    height: 36,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed('/plan-meeting/$_offerId', arguments: {
                          'offerId': _offerId,
                          'responderId': _conversation?.otherUserId,
                          'otherUserName': otherName,
                        });
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 15),
                      label: const Text('Planifier le rendez-vous QR'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _compactBtn(
                          label: 'Refuser',
                          borderColor: AppColors.line,
                          fg: AppColors.textSecondary,
                          onTap: () async {
                            if (_offerId != null) {
                              await _offersController.rejectOffer(_offerId!);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _compactBtn(
                          label: 'RDV',
                          borderColor: AppColors.ink,
                          fg: AppColors.ink,
                          onTap: () {
                            if (_offerId != null) {
                              Get.toNamed('/plan-meeting/$_offerId', arguments: {
                                'offerId': _offerId,
                                'responderId': _conversation?.otherUserId,
                                'otherUserName': otherName,
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _compactBtn(
                          label: 'Accepter',
                          bg: AppColors.accent,
                          fg: Colors.white,
                          onTap: () async {
                            if (_offerId != null) {
                              await _offersController.acceptOffer(_offerId!);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Messages stream
          Expanded(
            child: Obx(() {
              final messages = _chatController.messages;
              final typing = _chatController.typingUsers;

              if (messages.isEmpty && _chatController.isMessagesLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 2.5),
                );
              }

              if (messages.isEmpty && !_chatController.isMessagesLoading.value) {
                return Center(
                  child: Text(
                    'Envoyez un premier message pour convenir des détails.',
                    style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                itemCount: messages.length + (typing.isNotEmpty ? 1 : 0),
                itemBuilder: (ctx, idx) {
                  if (idx == messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$otherName est en train d\'écrire…',
                        style: AppTypography.sans(size: 11.5, color: AppColors.textHint),
                      ),
                    );
                  }

                  final msg = messages[idx];
                  final isMe = msg.isMe;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.76,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 6),
                          bottomRight: Radius.circular(isMe ? 6 : 18),
                        ),
                        boxShadow: AppColors.pillShadow,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.content,
                            style: AppTypography.sans(
                              size: 13.5,
                              color: isMe ? Colors.white : AppColors.ink,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            msg.timestampStr,
                            style: AppTypography.sans(
                              size: 10,
                              color: isMe ? Colors.white60 : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Composer bar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      if (_offerId != null) {
                        Get.toNamed('/plan-meeting/$_offerId', arguments: {
                          'offerId': _offerId,
                          'responderId': _conversation?.otherUserId,
                          'otherUserName': otherName,
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: (v) {
                        if (_offerId != null) {
                          _chatController.setTyping(_offerId!, v.trim().isNotEmpty);
                        }
                      },
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        filled: true,
                        fillColor: AppColors.paper,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.coralShadow,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 19, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactBtn({
    required String label,
    Color? bg,
    Color? borderColor,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg ?? Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Text(
          label,
          style: AppTypography.sans(size: 12.5, weight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }
}
