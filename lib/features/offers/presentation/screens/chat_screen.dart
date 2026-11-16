import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/chat_controller.dart';
import '../../../../controllers/offers_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final OffersController _offersController = Get.find<OffersController>();
  final _textController = TextEditingController();

  String? _offerId;
  dynamic _conversation;

  @override
  void initState() {
    super.initState();
    _offerId = Get.parameters['offerId'];
    _conversation = Get.arguments;
    if (_offerId != null) {
      _chatController.loadMessages(_offerId!);
      _chatController.connectWebSocket(_offerId!);
    }
  }

  @override
  void dispose() {
    _chatController.disconnectWebSocket();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _offerId == null) return;
    _chatController.sendMessage(_offerId!, text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _conversation?.otherUserName ?? 'Discussion de troc',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Expire 22h après proposition',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_rounded),
            tooltip: 'Planifier RDV',
            onPressed: () {
              Get.toNamed('/plan-meeting/$_offerId');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar (Offre envoyée -> Contre-offre -> Acceptée)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stepBadge('Offre envoyée', true),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.textHint),
                  _stepBadge('Négociation', true),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.textHint),
                  _stepBadge('Acceptée', false),
                ],
              ),
            ),
            // Pinned Offer card dock
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'PROPOSITION DE TROC',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text(
                        'Soulte à convenir',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Appareil photo contre Poterie artisanale',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (_offerId != null) {
                              _offersController.rejectOffer(_offerId!);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_offerId != null) {
                              _offersController.acceptOffer(_offerId!);
                              Get.snackbar('Succès', 'Offre acceptée ! Vous pouvez maintenant planifier le RDV.');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Accepter', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.toNamed('/plan-meeting/$_offerId');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('RDV 📍', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Messages list
            Expanded(
              child: Obx(() {
                final messages = _chatController.messages;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Commencez la discussion...', style: TextStyle(color: AppColors.textHint)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = messages[idx];
                    final isMe = msg.isMe;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.accentLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isMe ? AppColors.accent.withOpacity(0.3) : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.timestampStr,
                              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            // Message input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBadge(String label, bool isDone) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
        color: isDone ? AppColors.primary : AppColors.textHint,
      ),
    );
  }
}
