import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_controller.dart';
import '../core/constants/api_constants.dart';

class ConversationModel {
  final String offerId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final String offerStatus;
  final double soulte;
  final bool isResponder;
  final String itemSummary;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.offerId,
    this.otherUserId = '',
    required this.otherUserName,
    required this.lastMessage,
    required this.offerStatus,
    this.soulte = 0,
    this.isResponder = false,
    this.itemSummary = '',
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      offerId: json['offerId']?.toString() ?? json['id']?.toString() ?? '',
      otherUserId: json['otherUser']?['id']?.toString() ?? '',
      otherUserName: json['otherUser']?['displayName'] ?? 'Membre Trocly',
      lastMessage: json['lastMessage'] ?? '',
      offerStatus: json['status'] ?? 'pending',
      soulte: json['soulte'] != null
          ? double.tryParse(json['soulte'].toString()) ?? 0
          : 0,
      isResponder: json['isResponder'] == true,
      itemSummary: json['itemSummary'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isOwn;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isOwn,
    this.readAt,
  });

  bool get isMe => isOwn;

  String get timestampStr =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderId =
        json['senderId']?.toString() ?? json['sender']?['id']?.toString() ?? '';
    final senderName =
        json['senderName'] ?? json['sender']?['displayName'] ?? 'Membre';
    final rawTime = json['createdAt'] ?? json['timestamp'];
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      content: json['content'] ?? '',
      timestamp: rawTime != null
          ? (DateTime.tryParse(rawTime.toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      isOwn: senderId.isNotEmpty && senderId == currentUserId,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
    );
  }
}

class ChatController extends GetxController {
  final messages = <ChatMessage>[].obs;
  final conversations = <ConversationModel>[].obs;
  final typingUsers = <String>[].obs;
  final isLoading = false.obs;
  final isConnected = false.obs;
  final unreadCount = 0.obs;

  io.Socket? _socket;
  String? _activeOfferId;
  Timer? _typingTimer;

  String get _apiUrl => ApiConstants.baseUrl;

  AuthController get _auth => Get.find<AuthController>();

  Map<String, String> _getAuthHeaders() {
    final token = _auth.authToken.value;
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String get _currentUserId => _auth.userId.value;

  Future<void> fetchConversations() async {
    if (_auth.authToken.value.isEmpty) return;
    isLoading.value = true;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/messages/conversations'),
        headers: _getAuthHeaders(),
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        conversations.value =
            data.map((e) => ConversationModel.fromJson(e)).toList();
      }
      await fetchUnreadCount();
    } catch (e) {
      debugPrint('Error fetchConversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnreadCount() async {
    if (_auth.authToken.value.isEmpty) return;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/messages/unread/count'),
        headers: _getAuthHeaders(),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        unreadCount.value = data['unreadCount'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetchUnreadCount: $e');
    }
  }

  Future<void> loadMessages(String offerId) async {
    if (_auth.authToken.value.isEmpty) return;
    isLoading.value = true;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/messages/offer/$offerId?page=1&limit=50'),
        headers: _getAuthHeaders(),
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        messages.value = data
            .map((e) => ChatMessage.fromJson(e, _currentUserId))
            .toList();
      }
      await markOfferRead(offerId);
    } catch (e) {
      debugPrint('Error loadMessages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markOfferRead(String offerId) async {
    if (_auth.authToken.value.isEmpty) return;
    try {
      await http.patch(
        Uri.parse('$_apiUrl/messages/offer/$offerId/read'),
        headers: _getAuthHeaders(),
      );
      await fetchUnreadCount();
    } catch (_) {}
  }

  void connectWebSocket(String offerId) {
    final token = _auth.authToken.value;
    if (token.isEmpty) return;

    disconnectWebSocket();
    _activeOfferId = offerId;

    try {
      final socket = io.io(
        _apiUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .disableAutoConnect()
            .build(),
      );

      socket.onConnect((_) {
        isConnected.value = true;
        socket.emit('join-offer', {'offerId': offerId});
        socket.emit('mark-read', {'offerId': offerId});
      });

      socket.onDisconnect((_) {
        isConnected.value = false;
      });

      socket.on('chat-history', (data) {
        if (data is List) {
          messages.value = data
              .map((e) => ChatMessage.fromJson(
                  Map<String, dynamic>.from(e), _currentUserId))
              .toList();
        }
      });

      socket.on('message', (data) {
        if (data is Map) {
          final msg = ChatMessage.fromJson(
              Map<String, dynamic>.from(data), _currentUserId);
          if (!messages.any((m) => m.id == msg.id && msg.id.isNotEmpty)) {
            messages.add(msg);
          }
          if (!msg.isOwn) {
            socket.emit('mark-read', {'offerId': offerId});
          }
        }
      });

      socket.on('users-typing', (data) {
        if (data is Map && data['typingUsers'] is List) {
          typingUsers.value = List<String>.from(data['typingUsers'])
              .where((u) => u != _currentUserId)
              .toList();
        }
      });

      socket.connect();
      _socket = socket;
    } catch (e) {
      debugPrint('Socket connect error: $e');
    }
  }

  void setTyping(String offerId, bool isTyping) {
    if (_socket != null && isConnected.value) {
      _socket!.emit('typing', {'offerId': offerId, 'isTyping': isTyping});
      _typingTimer?.cancel();
      if (isTyping) {
        _typingTimer = Timer(const Duration(seconds: 3), () {
          _socket?.emit('typing', {'offerId': offerId, 'isTyping': false});
        });
      }
    }
  }

  Future<void> sendMessage(String offerId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    if (_socket != null && isConnected.value) {
      _socket!.emit('send-message', {'offerId': offerId, 'content': trimmed});
      return;
    }

    // REST fallback when socket isn't connected
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/messages/offer/$offerId'),
        headers: _getAuthHeaders(),
        body: jsonEncode({'content': trimmed}),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        final msg = ChatMessage.fromJson(data, _currentUserId);
        if (!messages.any((m) => m.id == msg.id)) {
          messages.add(msg);
        }
      }
    } catch (e) {
      debugPrint('Error sendMessage REST fallback: $e');
    }
  }

  void disconnectWebSocket() {
    _typingTimer?.cancel();
    if (_socket != null) {
      if (_activeOfferId != null) {
        _socket!.emit('leave-offer', {'offerId': _activeOfferId});
      }
      _socket!.dispose();
      _socket = null;
    }
    _activeOfferId = null;
    isConnected.value = false;
    typingUsers.clear();
  }

  @override
  void onClose() {
    disconnectWebSocket();
    super.onClose();
  }
}
