import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/chat_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/offers_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ChatController _chatController = Get.find<ChatController>();
  final OffersController _offersController = Get.find<OffersController>();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String? _offerId;
  ConversationModel? _conversation;
  String _offerStatus = 'pending';
  bool _isResponder = false;
  String _otherUserName = 'Conversation';
  String _otherUserId = '';
  String _itemSummary = '';
  double _soulte = 0;

  @override
  void initState() {
    super.initState();
    _offerId = Get.parameters['offerId'];
    if (Get.arguments is ConversationModel) {
      _conversation = Get.arguments as ConversationModel;
      _offerStatus = _conversation!.offerStatus;
      _isResponder = _conversation!.isResponder;
      _otherUserName = _conversation!.otherUserName;
      _otherUserId = _conversation!.otherUserId;
      _itemSummary = _conversation!.itemSummary;
      _soulte = _conversation!.soulte;
    }
    if (_offerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _offerId == null) return;
        _chatController.messages.clear();
        _chatController.loadMessages(_offerId!);
        _chatController.connectWebSocket(_offerId!);
        _refreshOfferDetails();
      });
    }
  }

  Future<void> _refreshOfferDetails() async {
    if (_offerId == null) return;
    final offer = await _offersController.fetchOfferById(_offerId!);
    if (offer != null && mounted) {
      final uid = _authController.userId.value;
      final responder = offer.responderId.isNotEmpty && offer.responderId == uid;
      setState(() {
        _offerStatus = offer.status;
        _isResponder = responder;
        _soulte = offer.soulte ?? _soulte;
        if (responder) {
          if (offer.initiatorName.isNotEmpty) _otherUserName = offer.initiatorName;
          if (offer.initiatorId.isNotEmpty) _otherUserId = offer.initiatorId;
        } else {
          if (offer.responderName.isNotEmpty) _otherUserName = offer.responderName;
          if (offer.responderId.isNotEmpty) _otherUserId = offer.responderId;
        }
        if (_itemSummary.isEmpty && offer.items.isNotEmpty) {
          _itemSummary = offer.items.map((e) => e.title).join(' contre ');
        }
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

  /// Phase 1.2 — Contre-proposition directe depuis le chat (Écran 14)
  Future<void> _showCounterOfferSheet() async {
    if (_offerId == null) return;
    final listingsCtrl = Get.isRegistered<ListingsController>()
        ? Get.find<ListingsController>()
        : Get.put(ListingsController());
    await listingsCtrl.fetchMyListings(status: 'active');
    if (!mounted) return;

    final selectedIds = <String>{
      ...listingsCtrl.myListings.take(1).map((e) => e.id),
    };
    bool soultePossible = _soulte > 0;
    final msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final myItems = listingsCtrl.myListings;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Contre-proposer',
                        style: AppTypography.serif(size: 21)),
                    const SizedBox(height: 4),
                    Text(
                      'Ajustez les objets inclus ou l\'option soulte (sans prix fixe).',
                      style: AppTypography.sans(
                          size: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    if (myItems.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 170),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: myItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final it = myItems[i];
                            final checked = selectedIds.contains(it.id);
                            return CheckboxListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              tileColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              activeColor: AppColors.accent,
                              value: checked,
                              title: Text(it.title,
                                  style: AppTypography.sans(
                                      size: 13.5, weight: FontWeight.w600)),
                              subtitle: Text(it.city,
                                  style: AppTypography.sans(
                                      size: 11.5,
                                      color: AppColors.textSecondary)),
                              onChanged: (v) {
                                setModalState(() {
                                  if (v == true) {
                                    selectedIds.add(it.id);
                                  } else {
                                    selectedIds.remove(it.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Soulte possible (à discuter)',
                              style: AppTypography.sans(
                                  size: 13, weight: FontWeight.w600)),
                          Switch(
                            value: soultePossible,
                            activeTrackColor: AppColors.accent,
                            onChanged: (v) =>
                                setModalState(() => soultePossible = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: msgCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Message d\'accompagnement (facultatif)…',
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Envoyer la contre-proposition',
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final counter =
                            await _offersController.createCounterOffer(
                          originalOfferId: _offerId!,
                          counterListingIds: selectedIds.toList(),
                          soultePossible: soultePossible,
                          message: msgCtrl.text.trim(),
                        );
                        if (counter != null && mounted) {
                          Get.offNamed('/chat/${counter.id}');
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherName = _otherUserName;
    final initials = otherName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final status = _offerStatus;
    final soulte = _soulte;
    final canPlanMeeting = status == 'accepted';

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
          if (canPlanMeeting)
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.accent),
              tooltip: 'Proposer un rendez-vous',
              onPressed: () {
                if (_offerId != null) {
                  Get.toNamed('/plan-meeting/$_offerId', arguments: {
                    'offerId': _offerId,
                    'responderId': _otherUserId,
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
                          : status == 'rejected'
                              ? 'OFFRE REFUSÉE'
                              : status == 'cancelled'
                                  ? 'OFFRE ANNULÉE'
                                  : status == 'countered'
                                      ? 'CONTRE-PROPOSITION'
                                      : _isResponder
                                          ? 'PROPOSITION REÇUE'
                                          : 'PROPOSITION ENVOYÉE',
                      style: AppTypography.eyebrow(
                        color: status == 'accepted'
                            ? AppColors.success
                            : (status == 'rejected' || status == 'cancelled')
                                ? AppColors.error
                                : AppColors.accent,
                      ),
                    ),
                    if (soulte > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Soulte possible',
                          style: AppTypography.sans(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _itemSummary.isNotEmpty
                      ? _itemSummary
                      : status == 'cancelled'
                          ? 'Annonce supprimée · Échange annulé'
                          : status == 'rejected'
                              ? 'Proposition déclinée'
                              : 'Échange en cours de négociation',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 11),
                if (status == 'accepted')
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed('/plan-meeting/$_offerId', arguments: {
                          'offerId': _offerId,
                          'responderId': _otherUserId,
                          'otherUserName': otherName,
                        });
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 15),
                      label: const Text('Planifier le rendez-vous QR'),
                    ),
                  )
                else if (status == 'rejected' || status == 'cancelled')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_busy_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            status == 'rejected'
                                ? 'Cette proposition d\'échange a été refusée.'
                                : 'Une annonce de cet échange a été supprimée — impossible de planifier un rendez-vous.',
                            style: AppTypography.sans(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_isResponder)
                  Row(
                    children: [
                      Expanded(
                        child: _compactBtn(
                          label: 'Refuser',
                          borderColor: AppColors.line,
                          fg: AppColors.textSecondary,
                          onTap: () async {
                            if (_offerId != null) {
                              final ok = await _offersController.rejectOffer(_offerId!);
                              if (ok && mounted) {
                                setState(() => _offerStatus = 'rejected');
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _compactBtn(
                          label: 'Contre-offre',
                          borderColor: AppColors.accent,
                          fg: AppColors.accent,
                          onTap: _showCounterOfferSheet,
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
                              final ok = await _offersController.acceptOffer(_offerId!);
                              if (ok && mounted) {
                                setState(() => _offerStatus = 'accepted');
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            size: 15, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'En attente de réponse de $otherName (seul le destinataire peut accepter)',
                            style: AppTypography.sans(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg.timestampStr,
                                style: AppTypography.sans(
                                  size: 10,
                                  color: isMe ? Colors.white70 : AppColors.textHint,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  msg.readAt != null
                                      ? Icons.done_all_rounded
                                      : Icons.check_rounded,
                                  size: 13,
                                  color: msg.readAt != null
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ],
                            ],
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
                  if (canPlanMeeting)
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.accent),
                      onPressed: () {
                        if (_offerId != null) {
                          Get.toNamed('/plan-meeting/$_offerId', arguments: {
                            'offerId': _offerId,
                            'responderId': _otherUserId,
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
