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
import 'rose_boutique_screen.dart';

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
    final authState = ref.watch(authProvider);

    // Check if there is an incoming call
    if (chatState.isInCall && chatState.isIncomingCall && chatState.callPartnerId != null) {
      final callerId = chatState.callPartnerId;
      final match = chatState.matches.firstWhere(
        (m) => m['partnerId'] == callerId,
        orElse: () => null,
      );
      if (match != null) {
        final callerProfile = match['profile'];
        return ActiveCallOverlay(
          partner: callerProfile,
          isIncoming: true,
          status: chatState.callStatus ?? 'ringing',
          onAccept: () {
            ref.read(chatProvider.notifier).acceptCall(callerId!, authState.profile!['id']);
          },
          onDecline: () {
            ref.read(chatProvider.notifier).rejectCall(callerId!, authState.profile!['id']);
          },
          onEnd: () {
            ref.read(chatProvider.notifier).endCall(authState.profile!['id'], callerId!);
          },
        );
      }
    }

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
                                  errorWidget: (context, url, err) => Container(color: Colors.grey.shade900),
                                )
                              : Container(color: Colors.grey.shade900),
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
                            border: Border.all(color: PremiumTheme.primaryBgBlack, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isUnlocked ? Icons.circle : Icons.lock,
                            size: 10,
                            color: isUnlocked ? Colors.transparent : PremiumTheme.primaryBgBlack,
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => _openChatRoom(matchItem),
            leading: Stack(
              children: [
                ClipRRect(
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
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isUnlocked ? Colors.green : PremiumTheme.goldAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: PremiumTheme.primaryBgBlack, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isUnlocked ? Icons.circle : Icons.lock,
                      size: 9,
                      color: isUnlocked ? Colors.transparent : PremiumTheme.primaryBgBlack,
                    ),
                  ),
                ),
              ],
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
              isUnlocked ? 'Tap to chat & check Vedic compatibility score!' : 'Locked - Tap to unlock connection',
              style: GoogleFonts.inter(
                color: isUnlocked ? PremiumTheme.textMuted : PremiumTheme.goldAccent.withOpacity(0.8),
                fontSize: 12,
                fontWeight: isUnlocked ? FontWeight.normal : FontWeight.w500,
              ),
            ),
            trailing: Icon(
              isUnlocked ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
              size: 14,
              color: PremiumTheme.goldAccent,
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
                    isUnlocked 
                        ? (isTypingPartner ? 'typing...' : 'Online')
                        : 'Offline',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnlocked && isTypingPartner 
                          ? PremiumTheme.goldAccent 
                          : (isUnlocked ? Colors.green : PremiumTheme.textMuted),
                      fontStyle: isUnlocked && isTypingPartner ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 1. Audio Call Icon (visible only if connection is fully unlocked)
          if (isUnlocked)
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: PremiumTheme.goldAccent),
              onPressed: () {
                final myName = authState.profile?['name'] ?? 'User';
                final myPhoto = authState.profile?['photoUrl'] ?? '';
                ref.read(chatProvider.notifier).dialCall(
                  senderId: currentUserId,
                  receiverId: partnerId,
                  senderName: myName,
                  senderPhoto: myPhoto,
                );
              },
            ),

          // 2. Launch AstroMatch directly from chat
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
                      ),
                    ],
                  ),
          ),

          // In-App Calling Screen Overlay (dialing, ringing, active call states)
          if (chatState.isInCall && (chatState.callPartnerId == partnerId || chatState.isIncomingCall))
            Positioned.fill(
              child: ActiveCallOverlay(
                partner: partner,
                isIncoming: chatState.isIncomingCall,
                status: chatState.callStatus ?? 'dialing',
                onAccept: () {
                  ref.read(chatProvider.notifier).acceptCall(partnerId, currentUserId);
                },
                onDecline: () {
                  ref.read(chatProvider.notifier).rejectCall(partnerId, currentUserId);
                },
                onEnd: () {
                  ref.read(chatProvider.notifier).endCall(currentUserId, partnerId);
                },
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
      color: PremiumTheme.primaryBgBlack,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container with gradient/shadow
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
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
                border: Border.all(color: Colors.white10),
                color: Colors.white.withOpacity(0.02),
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
                  foregroundColor: PremiumTheme.primaryBgBlack,
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

// ---------------- ACTIVE CALL OVERLAY WIDGET ----------------
class ActiveCallOverlay extends StatefulWidget {
  final Map<String, dynamic> partner;
  final bool isIncoming;
  final String status; // 'dialing', 'ringing', 'connected'
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onEnd;

  const ActiveCallOverlay({
    super.key,
    required this.partner,
    required this.isIncoming,
    required this.status,
    required this.onAccept,
    required this.onDecline,
    required this.onEnd,
  });

  @override
  State<ActiveCallOverlay> createState() => _ActiveCallOverlayState();
}

class _ActiveCallOverlayState extends State<ActiveCallOverlay> {
  Timer? _timer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    if (widget.status == 'connected') {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(ActiveCallOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == 'connected' && oldWidget.status != 'connected') {
      _startTimer();
    } else if (widget.status != 'connected') {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.partner['photos'] as List<dynamic>? ?? [];
    final hasPhoto = photos.isNotEmpty;
    final photoUrl = hasPhoto 
        ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
        : '';

    return Material(
      color: Colors.black.withOpacity(0.95),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background image
          if (hasPhoto)
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, o, s) => const SizedBox(),
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Top header
                Column(
                  children: [
                    Text(
                      'IN-APP CALL',
                      style: GoogleFonts.inter(
                        color: PremiumTheme.goldAccent,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.partner['name'] ?? 'User',
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.status == 'connected'
                          ? _formatDuration(_seconds)
                          : widget.status == 'dialing'
                              ? 'DIALING...'
                              : 'RINGING...',
                      style: GoogleFonts.inter(
                        color: PremiumTheme.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Central pulsing Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing Ring Animation
                    _PulsingCallRing(),
                    
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: PremiumTheme.goldAccent, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: PremiumTheme.goldAccent.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: hasPhoto
                            ? CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade900,
                                child: const Icon(Icons.person, size: 70, color: Colors.white30),
                              ),
                      ),
                    ),
                  ],
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: widget.isIncoming && widget.status == 'ringing'
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Decline Button
                            _buildCallButton(
                              icon: Icons.call_end_rounded,
                              label: 'Decline',
                              color: PremiumTheme.crimsonRed,
                              onTap: widget.onDecline,
                            ),
                            // Accept Button
                            _buildCallButton(
                              icon: Icons.phone_rounded,
                              label: 'Accept',
                              color: Colors.green,
                              onTap: widget.onAccept,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Mute
                            _buildCallIconButton(
                              icon: _isMuted ? Icons.mic_off : Icons.mic,
                              onTap: () => setState(() => _isMuted = !_isMuted),
                              isActive: _isMuted,
                            ),
                            // End Call Button
                            _buildCallButton(
                              icon: Icons.call_end_rounded,
                              label: 'End Call',
                              color: PremiumTheme.crimsonRed,
                              onTap: widget.onEnd,
                            ),
                            // Speaker
                            _buildCallIconButton(
                              icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                              onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                              isActive: _isSpeaker,
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

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCallIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white : Colors.white10,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white70,
          size: 24,
        ),
      ),
    );
  }
}

// Glowing pulsing concentric rings
class _PulsingCallRing extends StatefulWidget {
  @override
  State<_PulsingCallRing> createState() => _PulsingCallRingState();
}

class _PulsingCallRingState extends State<_PulsingCallRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(2, (index) {
            final delay = index * 0.5;
            final progress = (_controller.value + delay) % 1.0;
            final size = 140.0 + (progress * 80.0);
            final opacity = (1.0 - progress) * 0.4;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PremiumTheme.goldAccent.withOpacity(opacity),
                  width: 2,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
