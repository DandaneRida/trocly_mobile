import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/api_constants.dart';

String get API_URL => ApiConstants.baseUrl;
String get WS_URL => ApiConstants.wsUrl;

// Conversation summary model (used by MessagesInboxScreen)
class ConversationModel {
  final String offerId;
  final String otherUserName;
  final String lastMessage;
  final String offerStatus;

  ConversationModel({
    required this.offerId,
    required this.otherUserName,
    required this.lastMessage,
    required this.offerStatus,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      offerId: json['offerId'] ?? json['id'] ?? '',
      otherUserName: json['otherUser']?['displayName'] ?? 'Utilisateur',
      lastMessage: json['lastMessage'] ?? '',
      offerStatus: json['status'] ?? 'pending',
    );
  }
}

// Models
class ChatMessage {
  String id;
  String senderId;
  String senderName;
  String content;
  DateTime timestamp;
  bool isOwn;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isOwn,
  });

  /// Alias used by chat_screen.dart
  bool get isMe => isOwn;

  /// Formatted time string used by chat_screen.dart
  String get timestampStr => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender']['id'],
      senderName: json['sender']['displayName'] ?? 'Unknown',
      content: json['content'],
      timestamp: DateTime.parse(json['createdAt']),
      isOwn: json['sender']['id'] == currentUserId,
    );
  }
}

class ChatController extends GetxController {
  var messages = <ChatMessage>[].obs;
  var conversations = <ConversationModel>[].obs;
  var isLoading = false.obs;
  var isConnected = false.obs;
  var typingUsers = <String>[].obs;
  var unreadCount = 0.obs;
  var errorMessage = ''.obs;

  WebSocketChannel? _channel;
  late WebSocketChannel channel;
  final client = http.Client();

  /// Fetch all conversations (used by MessagesInboxScreen)
  Future<void> fetchConversations() async {
    isLoading.value = true;
    try {
      final response = await client.get(
        Uri.parse('$API_URL/offers/conversations'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        conversations.value = data.map((c) => ConversationModel.fromJson(c)).toList();
      }
    } catch (e) {
      // silently fail — empty list shown
    } finally {
      isLoading.value = false;
    }
  }

  /// Load messages for one offer (REST)
  Future<void> loadMessages(String offerId) async {
    await fetchChatHistory(offerId);
  }

  /// Connect WebSocket for one offer (simple alias)
  Future<void> connectWebSocket(String offerId) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$WS_URL/socket.io/?transport=websocket'));
      channel = _channel!;
      isConnected.value = true;

      channel.sink.add(jsonEncode({
        'event': 'join-offer',
        'data': {'offerId': offerId},
      }));

      channel.stream.listen((dynamic msg) {
        final data = jsonDecode(msg);
        _handleWebSocketMessage(data, '');
      }, onDone: () {
        isConnected.value = false;
      }, onError: (_) {
        isConnected.value = false;
      });
    } catch (e) {
      isConnected.value = false;
    }
  }

  /// Disconnect WebSocket
  void disconnectWebSocket() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    isConnected.value = false;
  }

  /**
   * Connect to WebSocket and join offer chat room
   */
  Future<void> connectToChat(String offerId, String userId, String userName) async {
    try {
      // Connect to WebSocket
      channel = WebSocketChannel.connect(Uri.parse('$WS_URL/socket.io/?transport=websocket'));
      isConnected.value = true;

      // Join offer room
      channel.sink.add(jsonEncode({
        'event': 'join-offer',
        'data': {
          'userId': userId,
          'offerId': offerId,
          'userName': userName,
        },
      }));

      // Listen for messages
      channel.stream.listen((dynamic msg) {
        final data = jsonDecode(msg);
        _handleWebSocketMessage(data, userId);
      }, onDone: () {
        isConnected.value = false;
      }, onError: (error) {
        errorMessage.value = 'Connection error: $error';
        isConnected.value = false;
      });

      // Fetch chat history
      await fetchChatHistory(offerId);
    } catch (e) {
      errorMessage.value = 'Failed to connect: $e';
      Get.snackbar('Error', errorMessage.value);
    }
  }

  /**
   * Send a message via WebSocket (2-arg variant used by chat_screen.dart)
   */
  Future<void> sendMessage(String offerId, String content, [String? userId]) async {
    if (!isConnected.value) {
      Get.snackbar('Erreur', 'Non connecté au chat');
      return;
    }

    try {
      channel.sink.add(jsonEncode({
        'event': 'send-message',
        'data': {
          'userId': userId ?? '',
          'offerId': offerId,
          'content': content,
        },
      }));
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'envoyer le message');
    }
  }

  /**
   * Handle incoming WebSocket messages
   */
  void _handleWebSocketMessage(Map<String, dynamic> data, String currentUserId) {
    final event = data['event'];
    final messageData = data['data'];

    switch (event) {
      case 'chat-history':
        // Initial chat history
        final historyList = messageData as List;
        messages.value = historyList
            .map((m) => ChatMessage.fromJson(m, currentUserId))
            .toList();
        break;

      case 'message':
        // New message received
        final msg = ChatMessage(
          id: messageData['id'],
          senderId: messageData['senderId'],
          senderName: messageData['senderName'],
          content: messageData['content'],
          timestamp: DateTime.parse(messageData['timestamp']),
          isOwn: messageData['senderId'] == currentUserId,
        );
        messages.add(msg);
        break;

      case 'users-typing':
        // Update typing indicator
        final typing = List<String>.from(messageData['typingUsers'] ?? []);
        typingUsers.value = typing;
        break;

      case 'error':
        errorMessage.value = messageData['message'] ?? 'Error';
        break;
    }
  }

  /**
   * Fetch chat history (REST API fallback)
   */
  Future<void> fetchChatHistory(String offerId) async {
    try {
      final response = await client.get(
        Uri.parse('$API_URL/messages/offer/$offerId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        messages.value = data.map((m) => ChatMessage.fromJson(m, '')).toList();
      }
    } catch (e) {
      print('Error fetching chat history: $e');
    }
  }

  /**
   * Send typing indicator
   */
  void sendTypingIndicator(String offerId, String userId, bool isTyping) {
    if (!isConnected.value) return;

    try {
      channel.sink.add(jsonEncode({
        'event': 'typing',
        'data': {
          'userId': userId,
          'offerId': offerId,
          'isTyping': isTyping,
        },
      }));
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  /**
   * Fetch unread message count
   */
  Future<void> fetchUnreadCount(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$API_URL/messages/unread/count?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        unreadCount.value = data['unreadCount'];
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  /**
   * Leave chat room
   */
  Future<void> leaveChat(String offerId, String userId) async {
    try {
      channel.sink.add(jsonEncode({
        'event': 'leave-offer',
        'data': {
          'userId': userId,
          'offerId': offerId,
        },
      }));
      channel.sink.close();
      isConnected.value = false;
    } catch (e) {
      print('Error leaving chat: $e');
    }
  }

  @override
  void onClose() {
    // Close WebSocket on controller close
    try {
      channel.sink.close();
    } catch (e) {
      print('Error closing WebSocket: $e');
    }
    super.onClose();
  }
}

// Chat Screen
class ChatScreen extends StatefulWidget {
  final String offerId;
  final String otherUserName;
  final String userId;
  final String userName;

  const ChatScreen({
    required this.offerId,
    required this.otherUserName,
    required this.userId,
    required this.userName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController controller = Get.find();
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    controller.connectToChat(widget.offerId, widget.userId, widget.userName);
  }

  @override
  void dispose() {
    controller.leaveChat(widget.offerId, widget.userId);
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            Obx(
              () => Text(
                controller.isConnected.value ? 'Online' : 'Offline',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(
              () => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: controller.messages.length +
                          (controller.typingUsers.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Typing indicator at bottom
                        if (index == controller.messages.length) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${controller.typingUsers.join(", ")} is typing...',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        final msg = controller.messages[index];
                        return Align(
                          alignment: msg.isOwn
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: msg.isOwn
                                  ? Colors.purple[300]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: msg.isOwn
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.content,
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg.timestamp.toString().substring(10, 16),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onChanged: (value) {
                      final typing = value.isNotEmpty;
                      if (typing != isTyping) {
                        isTyping = typing;
                        controller.sendTypingIndicator(
                          widget.offerId,
                          widget.userId,
                          typing,
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                    if (messageController.text.isNotEmpty) {
                      controller.sendMessage(
                        widget.offerId,
                        widget.userId,
                        messageController.text,
                      );
                      messageController.clear();
                      isTyping = false;
                      _scrollToBottom();
                    }
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
