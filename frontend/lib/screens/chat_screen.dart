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
import 'call_history_screen.dart';
import 'astro_match_screen.dart';
import 'rose_boutique_screen.dart';
import '../widgets/aesthetic_background.dart';
import '../widgets/glassmorphic_container.dart';

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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const ChatbotConsoleSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AestheticBackground(
        verticalText: 'CHATS',
        child: Stack(
          children: [
            // Main chats list with Image 5 styling
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 72),

                // Segmented Pill: [ Matches (X) | Requests (X) ] (from Image 5)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A3728).withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: PremiumTheme.darkEspresso,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Matches (${chatState.matches.length})',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RequestsScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: Text(
                              'Requests (0)',
                              style: GoogleFonts.inter(
                                color: PremiumTheme.textSilver,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Matches list cards (Image 5)
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
            border: Border.all(color: PremiumTheme.surfaceCard, width: 1.5),
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
          final matchItem = matches[index] as Map<String, dynamic>;
          final profile = matchItem['profile'] ?? {};
          final isUnlocked = matchItem['is_unlocked'] == true || matchItem['is_unlocked'] == 1;
          final photos = profile['photos'] as List<dynamic>? ?? [];
          final hasPhoto = photos.isNotEmpty;
          final photoUrl = hasPhoto 
              ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
              : '';

          return GestureDetector(
            onTap: () => _openChatRoom(matchItem),
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
                                  errorWidget: (context, url, err) => Container(color: PremiumTheme.surfaceElevated, child: const Icon(Icons.person, color: PremiumTheme.goldLight)),
                                )
                              : Container(color: PremiumTheme.surfaceElevated, child: const Icon(Icons.person, color: PremiumTheme.goldLight)),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isUnlocked ? Colors.green : PremiumTheme.goldAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: PremiumTheme.surfaceCard, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isUnlocked ? Icons.circle : Icons.lock,
                            size: 10,
                            color: isUnlocked ? Colors.transparent : Colors.white,
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
        final matchItem = matches[index] as Map<String, dynamic>;
        final profile = matchItem['profile'] ?? {};
        final isUnlocked = matchItem['is_unlocked'] == true || matchItem['is_unlocked'] == 1;
        final photos = profile['photos'] as List<dynamic>? ?? [];
        final hasPhoto = photos.isNotEmpty;
        final photoUrl = hasPhoto 
            ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
            : '';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A3728).withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            onTap: () => _openChatRoom(matchItem),
            leading: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(color: const Color(0xFFF0EBE3), child: const Icon(Icons.person, color: Color(0xFF756557))),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              profile['name'] ?? 'User',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: PremiumTheme.textWhite),
            ),
            subtitle: Text(
              'Tap to start chatting!',
              style: GoogleFonts.inter(
                color: PremiumTheme.textMuted,
                fontSize: 12,
              ),
            ),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF756557),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openChatRoom(Map<String, dynamic> matchItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(matchItem: matchItem),
      ),
    );
  }
}

// ---------------- ACTIVE CHAT ROOM SCREEN ----------------
class ChatRoomScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> matchItem;

  const ChatRoomScreen({super.key, required this.matchItem});

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

  Map<String, dynamic> get partner => widget.matchItem['profile'] ?? {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.profile != null) {
        // Guarantee socket initialization when entering the room
        ref.read(chatProvider.notifier).initSocket(auth.profile!['id']);
        
        final partnerId = partner['id'];
        final isUnlocked = widget.matchItem['is_unlocked'] == true || widget.matchItem['is_unlocked'] == 1;
        if (partnerId != null && isUnlocked) {
          ref.read(chatProvider.notifier).fetchChatHistory(partnerId);
        }
        ref.read(chatProvider.notifier).fetchMatches();
      }
    });
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
            receiverId: partner['id'],
            message: text,
          );
      _msgController.clear();
      setState(() {});
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
        receiverId: partner['id'],
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
        receiverId: partner['id'],
        message: '🎤 Voice Note (${_recordSeconds}s)',
      );
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final partner = this.partner;

    final currentUserId = authState.profile?['id'] ?? '';
    final partnerId = partner['id'] ?? '';

    // Find the latest match item from provider matches list to sync lock status dynamically
    final matchItem = chatState.matches.firstWhere(
      (m) => m['partnerId'] == partnerId,
      orElse: () => widget.matchItem,
    );

    final isUnlocked = matchItem['is_unlocked'] == true || matchItem['is_unlocked'] == 1;
    final myUnlocked = matchItem['my_unlocked'] == 1;
    final partnerUnlocked = matchItem['partner_unlocked'] == 1;
    final interestId = matchItem['interestId'] ?? '';
    final userRoses = authState.profile?['roses_balance'] ?? 0;

    // Scroll to bottom when history is loaded
    if (isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    final isTypingPartner = chatState.isTyping && chatState.typingUser == partner['id'];

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgLight,
      appBar: AppBar(
        backgroundColor: PremiumTheme.surfaceCard,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE5DDD1),
              backgroundImage: partner['photoUrl'] != null 
                  ? NetworkImage('${ApiService.baseUrl}${partner['photoUrl']}') 
                  : null,
              child: partner['photoUrl'] == null ? const Icon(Icons.person, size: 20, color: Color(0xFF756557)) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partner['name'] ?? 'User', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF241C15))),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF34C759), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(
                        isUnlocked 
                            ? (isTypingPartner ? 'typing...' : 'Online')
                            : 'Offline',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF34C759),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Sparkle AI button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AstroMatchScreen(targetUser: partner)),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F0),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8DFD3)),
              ),
              alignment: Alignment.center,
              child: const Text('✨', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),

          // Phone Call button (Image 6)
          if (isUnlocked)
            GestureDetector(
              onTap: () {
                final myName = authState.profile?['name'] ?? 'User';
                final myPhoto = authState.profile?['photoUrl'] ?? '';
                final partnerName = partner['name'] ?? 'User';
                final partnerPhoto = (partner['photos'] as List<dynamic>?)?.isNotEmpty == true
                    ? (partner['photos'] as List<dynamic>)[0] as String
                    : '';
                ref.read(chatProvider.notifier).dialCall(
                  senderId: currentUserId,
                  receiverId: partnerId,
                  senderName: myName,
                  senderPhoto: myPhoto,
                  partnerName: partnerName,
                  partnerPhoto: partnerPhoto,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6F0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF34C759).withOpacity(0.5)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.phone_rounded, color: Color(0xFF34C759), size: 18),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Standard Messages lists & input or Locked View
          Positioned.fill(
            child: !isUnlocked
                ? _buildLockedChatView(
                    myUnlocked: myUnlocked,
                    partnerUnlocked: partnerUnlocked,
                    partnerName: partner['name'] ?? 'User',
                    userRoses: userRoses,
                    interestId: interestId,
                  )
                : Column(
                    children: [
                      // Messages lists
                      Expanded(
                        child: chatState.isHistoryLoading
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: _msgController,
                                  style: const TextStyle(color: Colors.black),
                                  onChanged: (val) {
                                    setState(() {});
                                    if (authState.profile != null) {
                                      ref.read(chatProvider.notifier).sendTypingIndicator(
                                        authState.profile!['id'],
                                        partner['id'],
                                        val.trim().isNotEmpty,
                                      );
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Type your message...',
                                    hintStyle: TextStyle(color: Colors.black38),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Hold down Mic Voice notes or send standard text button
                            _msgController.text.trim().isEmpty
                                ? GestureDetector(
                                    onLongPressStart: (_) => _startMockRecording(),
                                    onLongPressEnd: (_) => _stopAndSendRecording(),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF2F2F7),
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
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedChatView({
    required bool myUnlocked,
    required bool partnerUnlocked,
    required String partnerName,
    required int userRoses,
    required String interestId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      color: PremiumTheme.primaryBgLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container with gradient/shadow
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PremiumTheme.surfaceElevated,
              border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(
              myUnlocked ? Icons.hourglass_empty_rounded : Icons.lock_outline_rounded,
              size: 64,
              color: PremiumTheme.goldAccent,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            myUnlocked ? 'Waiting for Partner' : 'Conversation Locked',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: PremiumTheme.textWhite,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            myUnlocked
                ? 'You have unlocked your side of this match! We are waiting for $partnerName to spend 1 Rose and unlock their side.'
                : 'Connect with $partnerName! Both of you must spend 1 Rose to unlock this chat and message in real-time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: PremiumTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),

          // Rose Balance & Action Button
          if (!myUnlocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PremiumTheme.goldBorder),
                color: PremiumTheme.surfaceElevated,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌹', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Your Balance: $userRoses Roses',
                    style: GoogleFonts.inter(
                      color: PremiumTheme.textSilver,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _unlockChatAction(interestId, userRoses),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.goldAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: Text(
                  'Unlock Chat (1 Rose)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            if (userRoses < 1) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoseBoutiqueScreen()),
                  );
                },
                child: Text(
                  'Visit Rose Boutique to buy Roses',
                  style: GoogleFonts.inter(
                    color: PremiumTheme.goldAccent,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ] else ...[
            // Spinning/pulsing animation
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: PremiumTheme.goldAccent,
                strokeWidth: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _unlockChatAction(String interestId, int userRoses) async {
    if (userRoses < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient roses. Please purchase more from the Boutique!'),
          backgroundColor: PremiumTheme.crimsonRed,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RoseBoutiqueScreen()),
      );
      return;
    }

    try {
      await ref.read(chatProvider.notifier).unlockMatch(interestId);
      final partnerId = partner['id'];
      if (partnerId != null) {
        ref.read(chatProvider.notifier).fetchChatHistory(partnerId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully unlocked chat room! 🌹'),
          backgroundColor: PremiumTheme.goldAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: PremiumTheme.crimsonRed,
        ),
      );
    }
  }

  Widget _buildMessageBubble(String text, bool isMe, DateTime time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF007AFF) : const Color(0xFFF0ECE6),
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isMe ? Colors.white : const Color(0xFF241C15),
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
          ),
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
      child: GlassmorphicContainer(
        borderRadius: 24,
        blur: 20,
        opacity: 0.85,
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
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: PremiumTheme.goldBorder, borderRadius: BorderRadius.circular(2))),
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
                          border: turn.isUser ? null : Border.all(color: PremiumTheme.goldBorder),
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        child: Text(
                          turn.text,
                          style: GoogleFonts.inter(
                            color: turn.isUser ? Colors.white : PremiumTheme.textWhite,
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
                                            : Container(color: PremiumTheme.surfaceElevated, child: const Icon(Icons.person, color: PremiumTheme.goldLight)),
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
            if (chatState.isChatbotLoading)
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.black),
                        onSubmitted: (_) => _sendPrompt(),
                        decoration: const InputDecoration(
                          hintText: 'Search city, star alignment (e.g. "Tirupati")...',
                          hintStyle: TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
      ),
    );
  }
}
