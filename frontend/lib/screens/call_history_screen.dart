import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';
import '../widgets/aesthetic_background.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _callLogs = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final logs = await ApiService().getCallHistory();
      if (mounted) {
        setState(() {
          _callLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getRelativeTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (_) {
      return '';
    }
  }

  String _formatDuration(int secs) {
    if (secs == 0) return '';
    if (secs < 60) return '${secs}s';
    final mins = secs ~/ 60;
    final remainingSecs = secs % 60;
    return '${mins}m ${remainingSecs}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PremiumTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CALL HISTORY',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            color: PremiumTheme.textWhite,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: PremiumTheme.textWhite),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: AestheticBackground(
        verticalText: 'HISTORY',
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: PremiumTheme.goldAccent))
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.inter(color: PremiumTheme.crimsonRed),
                    ),
                  )
                : _callLogs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchHistory,
                        color: PremiumTheme.goldAccent,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _callLogs.length,
                          itemBuilder: (context, index) {
                            final log = _callLogs[index];
                            final partner = log['partner'] ?? {};
                            final photos = partner['photos'] as List<dynamic>? ?? [];
                            final hasPhoto = photos.isNotEmpty;
                            final photoUrl = hasPhoto 
                                ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
                                : '';
                            
                            final isOutgoing = log['isOutgoing'] == true;
                            final status = log['status'] ?? 'missed';
                            final durationSecs = log['duration'] ?? 0;
                            final formattedDuration = _formatDuration(durationSecs);

                            // Determine status icon and label
                            IconData statusIcon;
                            Color statusColor;
                            String statusLabel;

                            if (status == 'completed') {
                              statusIcon = isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded;
                              statusColor = const Color(0xFF43A047); // Green
                              statusLabel = isOutgoing ? 'Outgoing ($formattedDuration)' : 'Incoming ($formattedDuration)';
                            } else if (status == 'rejected') {
                              statusIcon = Icons.call_missed_outgoing_rounded;
                              statusColor = const Color(0xFFE53935); // Red
                              statusLabel = 'Declined';
                            } else {
                              // missed or dialing
                              statusIcon = isOutgoing ? Icons.call_made_rounded : Icons.call_missed_rounded;
                              statusColor = isOutgoing ? Colors.grey : const Color(0xFFE53935);
                              statusLabel = isOutgoing ? 'Cancelled' : 'Missed';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PremiumTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: PremiumTheme.goldBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6E522E).withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // User Avatar
                                  GestureDetector(
                                    onTap: () => _navigateToChat(partner),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: PremiumTheme.goldBorder, width: 1.2),
                                      ),
                                      child: ClipOval(
                                        child: hasPhoto
                                            ? CachedNetworkImage(
                                                imageUrl: photoUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (c, u) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                errorWidget: (c, u, e) => Container(color: PremiumTheme.surfaceElevated, child: const Icon(Icons.person, color: PremiumTheme.goldLight)),
                                              )
                                            : Container(
                                                color: PremiumTheme.surfaceElevated,
                                                child: const Icon(Icons.person, color: PremiumTheme.goldLight),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Details
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _navigateToChat(partner),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            partner['name'] ?? 'User',
                                            style: GoogleFonts.cormorantGaramond(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: PremiumTheme.textWhite,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(statusIcon, size: 14, color: statusColor),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '$statusLabel • ${_getRelativeTime(log['created_at'])}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: PremiumTheme.textSilver,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Quick Callback icon
                                  IconButton(
                                    icon: const Icon(Icons.call_rounded, color: PremiumTheme.goldAccent, size: 22),
                                    onPressed: () => _callbackUser(partner),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PremiumTheme.goldAccent.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.phone_callback_rounded,
              color: Color(0xFFB5935E),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Call Logs Yet',
            style: GoogleFonts.cormorantGaramond(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: PremiumTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your incoming, outgoing, and missed call logs will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: PremiumTheme.textSilver,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(matchItem: {'profile': partner}),
      ),
    );
  }

  void _callbackUser(Map<String, dynamic> partner) {
    final authState = ref.read(authProvider);
    final myProfile = authState.profile;
    if (myProfile != null) {
      ref.read(chatProvider.notifier).dialCall(
        senderId: myProfile['id'],
        receiverId: partner['id'],
        senderName: myProfile['name'] ?? 'User',
        senderPhoto: (myProfile['photos'] as List<dynamic>?)?.isNotEmpty == true
            ? myProfile['photos'][0]
            : '',
        partnerName: partner['name'] ?? 'User',
        partnerPhoto: (partner['photos'] as List<dynamic>?)?.isNotEmpty == true
            ? partner['photos'][0]
            : '',
      );
    }
  }
}
