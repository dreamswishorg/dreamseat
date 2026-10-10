import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../../../services/supabase_service.dart';
import '../widgets/admin_components.dart';

class TabSupport extends ConsumerStatefulWidget {
  const TabSupport({super.key});

  @override
  ConsumerState<TabSupport> createState() => _TabSupportState();
}

class _TabSupportState extends ConsumerState<TabSupport> {
  SupportTicket? _selectedTicket;
  final _replyController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _statusFilter = 0; // 0: All, 1: Open, 2: Resolved
  Future<List<TicketReply>>? _repliesFuture;

  @override
  void dispose() {
    _replyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(appStateProvider.select((s) => s.supportTickets));

    final filteredTickets = tickets.where((t) {
      final matchesStatus = _statusFilter == 0
          ? true
          : (_statusFilter == 1 ? t.status == 'open' : t.status == 'resolved');
      final matchesQuery = _searchQuery.isEmpty ||
          t.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.message.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesQuery;
    }).toList();

    final activeTicket = _selectedTicket != null
        ? tickets.firstWhere((t) => t.id == _selectedTicket!.id, orElse: () => _selectedTicket!)
        : null;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: isMobile
          ? (activeTicket == null
              ? _buildQueue(filteredTickets, tickets)
              : _buildTicketDetail(activeTicket, onBack: () => setState(() => _selectedTicket = null)))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inbound Ticket Queue (40%)
                Expanded(
                  flex: 4,
                  child: _buildQueue(filteredTickets, tickets),
                ),
                const SizedBox(width: 24),
                // Conversation Workspace (60%)
                Expanded(
                  flex: 6,
                  child: activeTicket == null
                      ? _buildEmptyDetail()
                      : _buildTicketDetail(activeTicket),
                ),
              ],
            ),
    );
  }

  Widget _buildQueue(List<SupportTicket> filteredList, List<SupportTicket> allTickets) {
    final openCount = allTickets.where((t) => t.status == 'open').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Queue Header & Search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Inbound Queue",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.charcoal),
                        ),
                        if (openCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$openCount open",
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.warningOrange),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _filterPill("All", 0),
                          _filterPill("Open", 1),
                          _filterPill("Resolved", 2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.charcoal),
                    decoration: const InputDecoration(
                      hintText: "Search tickets, customers...",
                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: AppTheme.mutedGrey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tickets List
          Expanded(
            child: filteredList.isEmpty
                ? const NoDataState(
                    msg: "No tickets match your filters.",
                    icon: Icons.done_all_rounded,
                  )
                : ListView.separated(
                    itemCount: filteredList.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, i) {
                      final t = filteredList[i];
                      final isSel = _selectedTicket?.id == t.id;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedTicket = t;
                            _repliesFuture = SupabaseService().fetchTicketReplies(t.id);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: isSel ? const Color(0xFFF0FDF4) : Colors.transparent,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: isSel ? AppTheme.primaryGreen : const Color(0xFFF1F5F9),
                                foregroundColor: isSel ? Colors.white : AppTheme.charcoal,
                                child: Text(
                                  t.userName.isNotEmpty ? t.userName[0].toUpperCase() : 'C',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t.userName,
                                            style: TextStyle(
                                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w700,
                                              fontSize: 12.5,
                                              color: AppTheme.charcoal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MMM d').format(t.createdAt),
                                          style: const TextStyle(fontSize: 10.5, color: AppTheme.mutedGrey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      t.subject,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        color: isSel ? AppTheme.charcoal : const Color(0xFF475569),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    _statusPill(t.status),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label, int index) {
    final isSel = _statusFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? AppTheme.primaryGreen : AppTheme.mutedGrey,
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final isOpen = status == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isOpen ? AppTheme.warningOrange : AppTheme.primaryGreen).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOpen ? "OPEN" : "RESOLVED",
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: isOpen ? AppTheme.warningOrange : AppTheme.primaryGreen,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyDetail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_mic_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              "Select a ticket from the queue",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
            ),
            SizedBox(height: 4),
            Text(
              "View customer inquiries and respond with official solutions",
              style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDetail(SupportTicket t, {VoidCallback? onBack}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                if (onBack != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 10),
                ],
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.lightGreenBg,
                  foregroundColor: AppTheme.primaryGreen,
                  child: Text(
                    t.userName.isNotEmpty ? t.userName[0].toUpperCase() : 'C',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.subject,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.charcoal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "From: ${t.userName} • Ticket #${t.id.substring(0, 8).toUpperCase()}",
                        style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _statusPill(t.status),
                if (t.status != 'resolved') ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(appStateProvider.notifier).resolveTicket(t.id),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text("Mark Resolved", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Messages Timeline Area
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: FutureBuilder<List<TicketReply>>(
                future: _repliesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                  }

                  final replies = snapshot.data ?? [];

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // 1. Customer initial inquiry
                      _buildMessageBubble(
                        senderName: t.userName,
                        message: t.message,
                        timestamp: t.createdAt,
                        isStaff: false,
                        isInitialInquiry: true,
                      ),
                      // 2. Subsequent replies
                      ...replies.map((reply) => _buildMessageBubble(
                            senderName: reply.senderName,
                            message: reply.message,
                            timestamp: reply.createdAt,
                            isStaff: reply.isStaffReply,
                            isInitialInquiry: false,
                          )),
                    ],
                  );
                },
              ),
            ),
          ),

          // Reply Input & Quick Responses
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick macro chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _macroChip("We're investigating this now", () {
                        _replyController.text = "Hello, our operations team is currently investigating this report and we will update you shortly.";
                      }),
                      const SizedBox(width: 8),
                      _macroChip("Refund processed", () {
                        _replyController.text = "We have processed a full refund to your DreamWallet. Please allow a moment for balances to reflect.";
                      }),
                      const SizedBox(width: 8),
                      _macroChip("Order collection confirmed", () {
                        _replyController.text = "Your pickup code has been verified and confirmed with the merchant.";
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _replyController,
                          minLines: 1,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 13, color: AppTheme.charcoal),
                          decoration: const InputDecoration(
                            hintText: "Type an official support response...",
                            hintStyle: TextStyle(color: AppTheme.mutedGrey, fontSize: 12.5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_replyController.text.trim().isEmpty) return;
                        final text = _replyController.text.trim();
                        _replyController.clear();
                        await ref.read(appStateProvider.notifier).replyToTicket(t.id, text, isStaff: true);
                        setState(() {
                          _repliesFuture = SupabaseService().fetchTicketReplies(t.id);
                        });
                      },
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text("Send", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          "+ $text",
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String senderName,
    required String message,
    required DateTime timestamp,
    required bool isStaff,
    bool isInitialInquiry = false,
  }) {
    final timeStr = DateFormat('MMM d, h:mm a').format(timestamp);

    return Align(
      alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.45),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isStaff ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isStaff ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isStaff ? "DreamEats Support" : senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isStaff ? Colors.white.withValues(alpha: 0.9) : AppTheme.charcoal,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isStaff ? Colors.white70 : AppTheme.mutedGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isStaff ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
