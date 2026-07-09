import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/requests_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(requestsProvider.notifier).fetchRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _accept(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PremiumTheme.surfaceCard,
          title: Text(
            'Accept Connection Request',
            style: GoogleFonts.cormorantGaramond(
              fontWeight: FontWeight.bold,
              color: PremiumTheme.textWhite,
              fontSize: 22,
            ),
          ),
          content: Text(
            'Accepting this request will deduct 1 Rose to unlock your side of the chat. Do you want to proceed?',
            style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: PremiumTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.goldAccent,
                foregroundColor: PremiumTheme.primaryBgBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Spend 1 Rose', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ref.read(requestsProvider.notifier).accept(id);
      
      // Refresh matches list
      ref.read(chatProvider.notifier).fetchMatches();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accepted match request and unlocked your side! 🌹'), backgroundColor: PremiumTheme.goldAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: PremiumTheme.crimsonRed),
      );
    }
  }

  Future<void> _decline(String id) async {
    try {
      await ref.read(requestsProvider.notifier).decline(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Declined request.'), backgroundColor: Colors.white24),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: PremiumTheme.crimsonRed),
      );
    }
  }

  Future<void> _withdraw(String id) async {
    try {
      await ref.read(requestsProvider.notifier).withdraw(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrew interest request.'), backgroundColor: Colors.white24),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: PremiumTheme.crimsonRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsState = ref.watch(requestsProvider);

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgBlack,
      appBar: AppBar(
        title: Text(
          'REQUESTS HUB',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, color: PremiumTheme.textWhite),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.goldAccent,
          labelColor: PremiumTheme.goldAccent,
          unselectedLabelColor: PremiumTheme.textMuted,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Received Likes'),
            Tab(text: 'Sent Likes'),
          ],
        ),
      ),
      body: requestsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: PremiumTheme.goldAccent))
          : requestsState.errorMessage.isNotEmpty
              ? Center(child: Text(requestsState.errorMessage, style: GoogleFonts.inter(color: PremiumTheme.crimsonRed)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReceivedTab(requestsState.received),
                    _buildSentTab(requestsState.sent),
                  ],
                ),
    );
  }

  Widget _buildReceivedTab(List<dynamic> received) {
    if (received.isEmpty) {
      return _buildEmptyState('No Received Likes Yet', 'Profiles who swipe right on you will appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: received.length,
      itemBuilder: (context, index) {
        final item = received[index];
        final profile = item['profile'] ?? {};
        final photos = profile['photos'] as List<dynamic>? ?? [];
        final hasPhoto = photos.isNotEmpty;
        final photoUrl = hasPhoto 
            ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, err) => Container(color: Colors.grey.shade900),
                        )
                      : Container(color: Colors.grey.shade900),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${profile['name'] ?? "User"}, ${profile['age'] ?? ""}',
                          style: GoogleFonts.cormorantGaramond(
                            color: PremiumTheme.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item['interaction_type'] == 'rose')
                          const Padding(
                            padding: EdgeInsets.only(left: 6.0),
                            child: Text('🌹', style: TextStyle(fontSize: 14)),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile['city'] ?? '',
                      style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
                    ),
                    if (item['attached_message'] != null && item['attached_message'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          '"${item['attached_message']}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: PremiumTheme.goldAccent, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Accept / Decline button row
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () => _accept(item['interestId']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PremiumTheme.goldAccent,
                                foregroundColor: PremiumTheme.primaryBgBlack,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Accept', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () => _decline(item['interestId']),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: PremiumTheme.crimsonRed),
                                foregroundColor: PremiumTheme.crimsonRed,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Decline', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSentTab(List<dynamic> sent) {
    if (sent.isEmpty) {
      return _buildEmptyState('No Sent Likes Yet', 'Matches you express interest in will appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sent.length,
      itemBuilder: (context, index) {
        final item = sent[index];
        final profile = item['profile'] ?? {};
        final photos = profile['photos'] as List<dynamic>? ?? [];
        final hasPhoto = photos.isNotEmpty;
        final photoUrl = hasPhoto 
            ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
            : '';

        final isAccepted = item['status'] == 'accepted';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, err) => Container(color: Colors.grey.shade900),
                        )
                      : Container(color: Colors.grey.shade900),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile['name'] ?? "User"}, ${profile['age'] ?? ""}',
                      style: GoogleFonts.cormorantGaramond(
                        color: PremiumTheme.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile['city'] ?? '',
                      style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAccepted ? Colors.green.withOpacity(0.15) : PremiumTheme.goldAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isAccepted ? 'MUTUAL MATCH' : 'PENDING REPLY',
                        style: GoogleFonts.inter(
                          color: isAccepted ? Colors.green : PremiumTheme.goldAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Withdraw Button if not matched
                    if (!isAccepted)
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () => _withdraw(item['interestId']),
                          icon: const Icon(Icons.undo_rounded, size: 14),
                          label: Text('Withdraw Like', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            foregroundColor: PremiumTheme.textSilver,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String desc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border_rounded, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: PremiumTheme.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
