import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';
import 'astro_match_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  // Draggable floating chatbot button initial offset
  Offset _botButtonOffset = const Offset(20, 100);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.profile != null) {
        ref.read(chatProvider.notifier).initSocket(auth.profile!['id']);
      }
      ref.read(chatProvider.notifier).fetchMatches();
    });
  }

  void _openChatbotConsole() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PremiumTheme.primaryBgBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const ChatbotConsoleSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgBlack,
      appBar: AppBar(
        title: Text(
          'MATCH CHATS',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, color: PremiumTheme.textWhite),
        ),
      ),
      body: Stack(
        children: [
          // Main chats lists
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Matches horizontal Checklist Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  'New Connections',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: PremiumTheme.goldAccent,
                  ),
                ),
              ),
              _buildMatchesRow(chatState.matches),

              const Divider(color: Colors.white10, height: 32),

              // 2. Active Chat Rooms List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Conversations',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: PremiumTheme.goldAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildConversationsList(chatState.matches),
              ),
            ],
          ),

          // Draggable floating circular AI Bot icon
          Positioned(
            left: _botButtonOffset.dx,
            bottom: _botButtonOffset.dy,
            child: Draggable(
              feedback: _buildBotFloatingIcon(opacity: 0.8),
              childWhenDragging: const SizedBox(),
              onDragEnd: (details) {
                final screenHeight = MediaQuery.of(context).size.height;
                final screenWidth = MediaQuery.of(context).size.width;
                // Keep inside screen constraints
                double newX = details.offset.dx;
                double newY = screenHeight - details.offset.dy - 60; // invert y for bottom positioning
                if (newX < 10) newX = 10;
                if (newX > screenWidth - 70) newX = screenWidth - 70;
                if (newY < 10) newY = 10;
                if (newY > screenHeight - 120) newY = screenHeight - 120;

                setState(() {
                  _botButtonOffset = Offset(newX, newY);
                });
              },
              child: GestureDetector(
                onTap: _openChatbotConsole,
                child: _buildBotFloatingIcon(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotFloatingIcon({double opacity = 1.0}) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PremiumTheme.goldGradient,
            boxShadow: [
              BoxShadow(
                color: PremiumTheme.goldAccent.withOpacity(0.35),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
            border: Border.all(color: PremiumTheme.primaryBgBlack, width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Text('🤖', style: TextStyle(fontSize: 26)),
        ),
      ),
    );
  }

  Widget _buildMatchesRow(List<dynamic> matches) {
    if (matches.isEmpty) {
      return Container(
        height: 90,
        alignment: Alignment.center,
        child: Text(
          'Connect with matches to start chatting!',
          style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final profile = matches[index];
          final photos = profile['photos'] as List<dynamic>? ?? [];
          final hasPhoto = photos.isNotEmpty;
          final photoUrl = hasPhoto 
              ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
              : '';

          return GestureDetector(
            onTap: () => _openChatRoom(profile),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: PremiumTheme.goldAccent, width: 1.5),
                        ),
                        child: ClipOval(
                          child: hasPhoto
                              ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                  errorWidget: (context, url, err) => Container(color: Colors.grey.shade900),
                                )
                              : Container(color: Colors.grey.shade900),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile['name'] ?? 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: PremiumTheme.textSilver, fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationsList(List<dynamic> matches) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No chats yet.',
          style: GoogleFonts.inter(color: PremiumTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final profile = matches[index];
        final photos = profile['photos'] as List<dynamic>? ?? [];
        final hasPhoto = photos.isNotEmpty;
        final photoUrl = hasPhoto 
            ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => _openChatRoom(profile),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: SizedBox(
                width: 50,
                height: 50,
                child: hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey.shade900),
              ),
            ),
            title: Row(
              children: [
                Text(
                  profile['name'] ?? 'User',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: PremiumTheme.textWhite),
                ),
                const SizedBox(width: 6),
                if (profile['face_verified'] == true)
                  const Icon(Icons.verified, color: PremiumTheme.goldAccent, size: 16),
              ],
            ),
            subtitle: Text(
              'Tap to chat & check Vedic compatibility score!',
              style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: PremiumTheme.goldAccent),
          ),
        );
      },
    );
  }

  void _openChatRoom(Map<String, dynamic> partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(partnerProfile: partner),
      ),
    );
  }
}

// ---------------- ACTIVE CHAT ROOM SCREEN ----------------
class ChatRoomScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> partnerProfile;

  const ChatRoomScreen({super.key, required this.partnerProfile});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isRecordingMock = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    if (auth.profile != null) {
      ref.read(chatProvider.notifier).fetchChatHistory(widget.partnerProfile['id']);
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final auth = ref.read(authProvider);
    if (auth.profile != null) {
      ref.read(chatProvider.notifier).sendChatMessage(
            senderId: auth.profile!['id'],
            receiverId: widget.partnerProfile['id'],
            message: text,
          );
      _msgController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // Pick Image mock upload
  Future<void> _sendImageAttachment() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (image == null) return;
    
    // In real app we upload file and send url. For mock we send text descriptor
    final auth = ref.read(authProvider);
    if (auth.profile != null) {
      ref.read(chatProvider.notifier).sendChatMessage(
        senderId: auth.profile!['id'],
        receiverId: widget.partnerProfile['id'],
        message: '📷 Image Attachment [Local Photo]',
      );
      _scrollToBottom();
    }
  }

  // Hold to Record mockup
  void _startMockRecording() {
    setState(() {
      _isRecordingMock = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
      });
    });
  }

  void _stopAndSendRecording() {
    _recordTimer?.cancel();
    if (!_isRecordingMock) return;

    setState(() {
      _isRecordingMock = false;
    });

    final auth = ref.read(authProvider);
    if (auth.profile != null && _recordSeconds > 0) {
      ref.read(chatProvider.notifier).sendChatMessage(
        senderId: auth.profile!['id'],
        receiverId: widget.partnerProfile['id'],
        message: '🎤 Voice Note (${_recordSeconds}s)',
      );
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final partner = widget.partnerProfile;

    // Scroll to bottom when history is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final isTypingPartner = chatState.isTyping && chatState.typingUser == partner['id'];

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: PremiumTheme.surfaceCard,
              backgroundImage: partner['photoUrl'] != null 
                  ? NetworkImage('${ApiService.baseUrl}${partner['photoUrl']}') 
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partner['name'] ?? 'User', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    isTypingPartner ? 'typing...' : 'Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: isTypingPartner ? PremiumTheme.goldAccent : Colors.green,
                      fontStyle: isTypingPartner ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Launch AstroMatch directly from chat
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: PremiumTheme.goldAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AstroMatchScreen(targetUser: partner)),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Messages lists
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator(color: PremiumTheme.goldAccent))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.activeMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.activeMessages[index];
                      final isMe = msg.senderId == authState.profile?['id'];
                      return _buildMessageBubble(msg.message, isMe, msg.createdAt);
                    },
                  ),
          ),

          // Voice note record indicators overlay
          if (_isRecordingMock)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: PremiumTheme.surfaceCard,
              child: Row(
                children: [
                  const Icon(Icons.mic, color: PremiumTheme.crimsonRed, size: 24),
                  const SizedBox(width: 8),
                  Text('Recording voice note...', style: GoogleFonts.inter(color: Colors.white)),
                  const Spacer(),
                  Text('${_recordSeconds}s', style: GoogleFonts.inter(color: PremiumTheme.goldAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Message input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceCard,
              border: Border(top: BorderSide(color: Colors.grey.shade900)),
            ),
            child: Row(
              children: [
                // Add attachments
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: PremiumTheme.goldAccent),
                  onPressed: _sendImageAttachment,
                ),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) {
                      if (authState.profile != null) {
                        ref.read(chatProvider.notifier).sendTypingIndicator(
                          authState.profile!['id'],
                          partner['id'],
                          val.trim().isNotEmpty,
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: PremiumTheme.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),

                // Hold down Mic Voice notes or send standard text button
                _msgController.text.trim().isEmpty
                    ? GestureDetector(
                        onLongPressStart: (_) => _startMockRecording(),
                        onLongPressEnd: (_) => _stopAndSendRecording(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mic, color: PremiumTheme.goldAccent),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send_rounded, color: PremiumTheme.goldAccent),
                        onPressed: _sendMessage,
                      ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, DateTime time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? PremiumTheme.goldAccent : Colors.grey.shade900,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                color: isMe ? PremiumTheme.primaryBgBlack : PremiumTheme.textWhite,
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 9,
                    color: isMe ? Colors.black54 : PremiumTheme.textMuted,
                  ),
                ),
                if (isMe)
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(Icons.done_all, size: 10, color: Colors.black54),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- CHATBOT CONSOLE SHEET ----------------
class ChatbotConsoleSheet extends ConsumerStatefulWidget {
  const ChatbotConsoleSheet({super.key});

  @override
  ConsumerState<ChatbotConsoleSheet> createState() => _ChatbotConsoleSheetState();
}

class _ChatbotConsoleSheetState extends ConsumerState<ChatbotConsoleSheet> {
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendPrompt() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendChatbotPrompt(text);
    _inputController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            // Handle header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PremiumTheme.surfaceCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🤖', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        'MATCHMAKER AI',
                        style: GoogleFonts.cormorantGaramond(
                          fontWeight: FontWeight.bold,
                          color: PremiumTheme.goldAccent,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Conversational content log
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: chatState.chatbotLogs.length,
                itemBuilder: (context, index) {
                  final turn = chatState.chatbotLogs[index];
                  return Column(
                    crossAxisAlignment: turn.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Chat Text Bubble
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: turn.isUser ? PremiumTheme.goldAccent : PremiumTheme.surfaceCard,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(turn.isUser ? 16 : 2),
                            bottomRight: Radius.circular(turn.isUser ? 2 : 16),
                          ),
                          border: turn.isUser ? null : Border.all(color: Colors.white10),
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        child: Text(
                          turn.text,
                          style: GoogleFonts.inter(
                            color: turn.isUser ? PremiumTheme.primaryBgBlack : PremiumTheme.textWhite,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // If recommendations are returned, render swipeable horizontal profile cards
                      if (turn.recommendedProfiles.isNotEmpty)
                        Container(
                          height: 190,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: turn.recommendedProfiles.length,
                            itemBuilder: (context, idx) {
                              final profile = turn.recommendedProfiles[idx];
                              final photos = profile['photos'] as List<dynamic>? ?? [];
                              final hasPhoto = photos.isNotEmpty;
                              final photoUrl = hasPhoto 
                                  ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
                                  : '';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context); // Close bot console
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AstroMatchScreen(targetUser: profile)),
                                  );
                                },
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: PremiumTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.3)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        hasPhoto
                                            ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                                            : Container(color: Colors.grey.shade900),
                                        // bottom black overlay text
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            color: Colors.black54,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${profile['name']}, ${profile['age']}',
                                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  profile['city'] ?? '',
                                                  style: GoogleFonts.inter(color: PremiumTheme.goldLight, fontSize: 10),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Typing indicators progress
            if (chatState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                child: Row(
                  children: [
                    Text('Matchmaker AI is thinking...', style: GoogleFonts.inter(color: PremiumTheme.goldAccent, fontStyle: FontStyle.italic, fontSize: 12)),
                  ],
                ),
              ),

            // Input console bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PremiumTheme.surfaceCard,
                border: Border(top: BorderSide(color: Colors.grey.shade900)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _sendPrompt(),
                      decoration: InputDecoration(
                        hintText: 'Search city, star alignment (e.g. "Tirupati")...',
                        hintStyle: const TextStyle(color: PremiumTheme.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: PremiumTheme.goldAccent),
                    onPressed: _sendPrompt,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
