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

  // Calling state
  final bool isInCall;
  final bool isIncomingCall;
  final String? callPartnerId;
  final String? callPartnerName;
  final String? callPartnerPhoto;
  final String? callStatus; // 'dialing', 'ringing', 'connected', 'disconnected'

  ChatState({
    required this.matches,
    required this.activeMessages,
    required this.chatbotLogs,
    required this.isLoading,
    required this.isTyping,
    required this.typingUser,
    this.isInCall = false,
    this.isIncomingCall = false,
    this.callPartnerId,
    this.callPartnerName,
    this.callPartnerPhoto,
    this.callStatus,
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
        isInCall: false,
        isIncomingCall: false,
      );

  ChatState copyWith({
    List<dynamic>? matches,
    List<ChatMessage>? activeMessages,
    List<ChatbotTurn>? chatbotLogs,
    bool? isLoading,
    bool? isTyping,
    String? typingUser,
    bool? isInCall,
    bool? isIncomingCall,
    String? callPartnerId,
    String? callPartnerName,
    String? callPartnerPhoto,
    String? callStatus,
  }) {
    return ChatState(
      matches: matches ?? this.matches,
      activeMessages: activeMessages ?? this.activeMessages,
      chatbotLogs: chatbotLogs ?? this.chatbotLogs,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      typingUser: typingUser ?? this.typingUser,
      isInCall: isInCall ?? this.isInCall,
      isIncomingCall: isIncomingCall ?? this.isIncomingCall,
      callPartnerId: callPartnerId ?? this.callPartnerId,
      callPartnerName: callPartnerName ?? this.callPartnerName,
      callPartnerPhoto: callPartnerPhoto ?? this.callPartnerPhoto,
      callStatus: callStatus ?? this.callStatus,
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
    if (_socket != null) {
      if (_socket!.connected) {
        _socket!.emit('join', userId);
      } else {
        _socket!.connect();
        _socket!.emit('join', userId);
      }
      return;
    }

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

      // Handle call signaling events
      _socket!.on('incoming-call', (data) {
        state = state.copyWith(
          isInCall: true,
          isIncomingCall: true,
          callPartnerId: data['senderId'],
          callPartnerName: data['senderName'],
          callPartnerPhoto: data['senderPhoto'],
          callStatus: 'ringing',
        );
      });

      _socket!.on('call-connected', (data) {
        state = state.copyWith(
          callStatus: 'connected',
        );
      });

      _socket!.on('call-rejected', (data) {
        state = state.copyWith(
          callStatus: 'disconnected',
          isInCall: false,
          isIncomingCall: false,
        );
      });

      _socket!.on('call-terminated', (data) {
        state = state.copyWith(
          callStatus: 'disconnected',
          isInCall: false,
          isIncomingCall: false,
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
      final matchesData = await apiService.getMatches();
      state = state.copyWith(matches: matchesData, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // Unlock a match chat by spending 1 rose
  Future<void> unlockMatch(String interestId) async {
    state = state.copyWith(isLoading: true);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.unlockChat(interestId);
      // Reload matches to reflect updated unlock status
      await fetchMatches();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Calling actions
  void dialCall({
    required String senderId,
    required String receiverId,
    required String senderName,
    required String senderPhoto,
  }) {
    if (_socket == null) return;
    state = state.copyWith(
      isInCall: true,
      isIncomingCall: false,
      callPartnerId: receiverId,
      callPartnerName: senderName,
      callPartnerPhoto: senderPhoto,
      callStatus: 'dialing',
    );
    _socket!.emit('call-dial', {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
    });
  }

  void acceptCall(String senderId, String receiverId) {
    if (_socket == null) return;
    state = state.copyWith(
      isIncomingCall: false,
      callStatus: 'connected',
    );
    _socket!.emit('call-accept', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  void rejectCall(String senderId, String receiverId) {
    if (_socket == null) return;
    state = state.copyWith(
      isInCall: false,
      isIncomingCall: false,
      callStatus: 'disconnected',
    );
    _socket!.emit('call-reject', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  void endCall(String senderId, String receiverId) {
    if (_socket == null) return;
    state = state.copyWith(
      isInCall: false,
      isIncomingCall: false,
      callStatus: 'disconnected',
    );
    _socket!.emit('call-end', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
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
