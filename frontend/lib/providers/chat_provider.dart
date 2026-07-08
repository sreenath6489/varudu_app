import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class ChatbotTurn {
  final String text;
  final bool isUser;
  final List<dynamic> recommendedProfiles;

  ChatbotTurn({
    required this.text,
    required this.isUser,
    this.recommendedProfiles = const [],
  });
}

class ChatState {
  final List<dynamic> matches; // profiles with status == accepted
  final List<ChatMessage> activeMessages;
  final List<ChatbotTurn> chatbotLogs;
  final bool isLoading;
  final bool isTyping;
  final String typingUser;

  ChatState({
    required this.matches,
    required this.activeMessages,
    required this.chatbotLogs,
    required this.isLoading,
    required this.isTyping,
    required this.typingUser,
  });

  factory ChatState.initial() => ChatState(
        matches: [],
        activeMessages: [],
        chatbotLogs: [
          ChatbotTurn(
            text: "నమస్కారం! Hello! I am your personal Matchmaker AI. Ask me to find matches, e.g., 'Show me profiles from Tirupati' or 'Find someone matching my Rasi'!",
            isUser: false,
          )
        ],
        isLoading: false,
        isTyping: false,
        typingUser: '',
      );

  ChatState copyWith({
    List<dynamic>? matches,
    List<ChatMessage>? activeMessages,
    List<ChatbotTurn>? chatbotLogs,
    bool? isLoading,
    bool? isTyping,
    String? typingUser,
  }) {
    return ChatState(
      matches: matches ?? this.matches,
      activeMessages: activeMessages ?? this.activeMessages,
      chatbotLogs: chatbotLogs ?? this.chatbotLogs,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      typingUser: typingUser ?? this.typingUser,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  IO.Socket? _socket;

  ChatNotifier(this._ref) : super(ChatState.initial());

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  // Socket initialization
  void initSocket(String userId) {
    if (_socket != null) return;

    try {
      _socket = IO.io(ApiService.baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build());

      _socket!.onConnect((_) {
        print('Socket client connected successfully');
        _socket!.emit('join', userId);
      });

      // Handle message events
      _socket!.on('message', (data) {
        final message = ChatMessage.fromJson(data);
        state = state.copyWith(
          activeMessages: [...state.activeMessages, message]
        );
      });

      // Handle typing events
      _socket!.on('typing', (data) {
        final isTyping = data['isTyping'] ?? false;
        state = state.copyWith(
          isTyping: isTyping,
          typingUser: isTyping ? data['senderId'] : '',
        );
      });

      _socket!.onDisconnect((_) => print('Socket client disconnected'));
    } catch (e) {
      print('Socket connection error: $e');
    }
  }

  // Load matches
  Future<void> fetchMatches() async {
    state = state.copyWith(isLoading: true);
    try {
      final apiService = _ref.read(apiServiceProvider);
      
      // Matches are users with status accepted in requests
      final requests = await apiService.getRequests();
      final sentMatches = (requests['sent'] as List<dynamic>)
          .where((m) => m['status'] == 'accepted')
          .map((m) => m['profile'])
          .toList();

      final receivedMatches = (requests['received'] as List<dynamic>)
          .where((m) => m['status'] == 'accepted')
          .map((m) => m['profile'])
          .toList();

      // Deduplicate profiles
      final allMatches = [...sentMatches, ...receivedMatches];
      final uniqueIds = <String>{};
      final uniqueMatches = allMatches.where((profile) {
        if (profile == null) return false;
        final id = profile['id'];
        return uniqueIds.add(id);
      }).toList();

      state = state.copyWith(matches: uniqueMatches, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // Load Chat Logs
  Future<void> fetchChatHistory(String partnerId) async {
    state = state.copyWith(isLoading: true, activeMessages: []);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final history = await apiService.getChats(partnerId);
      final parsed = history.map((json) => ChatMessage.fromJson(json)).toList();
      
      state = state.copyWith(activeMessages: parsed, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // Send real-time chat message
  void sendChatMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) {
    if (_socket == null) return;
    _socket!.emit('sendMessage', {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
    });
    // Stop typing
    sendTypingIndicator(senderId, receiverId, false);
  }

  // Send typing indicator
  void sendTypingIndicator(String senderId, String receiverId, bool isTyping) {
    if (_socket == null) return;
    _socket!.emit('typing', {
      'senderId': senderId,
      'receiverId': receiverId,
      'isTyping': isTyping,
    });
  }

  // Chatbot conversation
  Future<void> sendChatbotPrompt(String messageText) async {
    final userTurn = ChatbotTurn(text: messageText, isUser: true);
    state = state.copyWith(
      chatbotLogs: [...state.chatbotLogs, userTurn],
      isLoading: true
    );

    try {
      final apiService = _ref.read(apiServiceProvider);
      final res = await apiService.sendChatbotMessage(messageText);
      
      final botTurn = ChatbotTurn(
        text: res['reply'] ?? 'Something went wrong',
        isUser: false,
        recommendedProfiles: res['profiles'] ?? [],
      );

      state = state.copyWith(
        chatbotLogs: [...state.chatbotLogs, botTurn],
        isLoading: false
      );
    } catch (e) {
      final errorTurn = ChatbotTurn(
        text: "Error conversing: ${e.toString().replaceAll('Exception: ', '')}",
        isUser: false,
      );
      state = state.copyWith(
        chatbotLogs: [...state.chatbotLogs, errorTurn],
        isLoading: false
      );
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
