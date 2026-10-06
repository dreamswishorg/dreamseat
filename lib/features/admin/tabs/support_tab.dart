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
  Future<List<TicketReply>>? _repliesFuture;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(appStateProvider.select((s) => s.supportTickets));

    final activeTicket = _selectedTicket != null
        ? tickets.firstWhere((t) => t.id == _selectedTicket!.id, orElse: () => _selectedTicket!)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticket Queue
          Expanded(
            flex: 4,
            child: _buildQueue(tickets),
          ),
          const SizedBox(width: 32),
          // Chat / Detail
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

  Widget _buildQueue(List<SupportTicket> tickets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            child: const Row(
              children: [
                Icon(Icons.support_agent_rounded, size: 20, color: AppTheme.mutedGrey),
                SizedBox(width: 12),
                Text("Inbound Queue", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: tickets.isEmpty
                ? const NoDataState(msg: "All clear! No pending tickets.", icon: Icons.done_all_rounded)
                : ListView.separated(
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final t = tickets[i];
                      final isSel = _selectedTicket?.id == t.id;
                      return ListTile(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedTicket = t;
                            _repliesFuture = SupabaseService().fetchTicketReplies(t.id);
                          });
                        },
                        tileColor: isSel ? AppTheme.lightGreenBg.withValues(alpha: 0.5) : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        title: Text(t.subject, style: TextStyle(fontWeight: isSel ? FontWeight.w900 : FontWeight.w700, fontSize: 14)),
                        subtitle: Text("${t.userName} • ${DateFormat('MMM d').format(t.createdAt)}", style: const TextStyle(fontSize: 12)),
                        trailing: _StatusBadge(status: t.status),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetail() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), style: BorderStyle.solid),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text("Select a ticket to begin investigation", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDetail(SupportTicket t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Detail Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primaryGreen,
                  child: Text(t.userName.isNotEmpty ? t.userName[0].toUpperCase() : 'C'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal)),
                      const SizedBox(height: 4),
                      Text("Customer: ${t.userName} (ID: ${t.userId.substring(0, 8)})", style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: t.status),
                const SizedBox(width: 12),
                if (t.status != 'resolved')
                  ElevatedButton(
                    onPressed: () => ref.read(appStateProvider.notifier).resolveTicket(t.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Resolve", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
          ),
          // Chat Area (WhatsApp Style)
          Expanded(
            child: Container(
              color: const Color(0xFFE5DDD5), // Standard WhatsApp chat background
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
                      // 1. Initial Inquiry (from customer)
                      _buildChatBubble(
                        senderName: t.userName,
                        message: t.message,
                        timestamp: t.createdAt,
                        isStaff: false,
                        isInitialInquiry: true,
                      ),
                      // 2. Replies
                      ...replies.map((reply) => _buildChatBubble(
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
          // Reply Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0), // WhatsApp gray bottom bar
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Type an official response...",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A884), // WhatsApp send button green
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      if (_replyController.text.trim().isEmpty) return;
                      final text = _replyController.text.trim();
                      _replyController.clear();
                      await ref.read(appStateProvider.notifier).replyToTicket(t.id, text, isStaff: true);
                      setState(() {
                        _repliesFuture = SupabaseService().fetchTicketReplies(t.id);
                      });
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({
    required String senderName,
    required String message,
    required DateTime timestamp,
    required bool isStaff,
    bool isInitialInquiry = false,
  }) {
    // Staff messages are on the right (greenish bubble), Customer messages are on the left (white bubble)
    final isMe = isStaff;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe ? const Color(0xFFD9FDD3) : Colors.white;
    final textColor = const Color(0xFF111B21);
    final timeStr = DateFormat('hh:mm a').format(timestamp);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender name (different colors WhatsApp style)
            if (!isMe || isInitialInquiry) ...[
              Text(
                isMe ? "Support Agent (You)" : senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isMe ? AppTheme.primaryGreen : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 3),
            ],
            // Message text
            Text(
              message,
              style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 4),
            // Timestamp and checkmark (if staff)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 9.5),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    color: Color(0xFF53BDEB), // WhatsApp blue ticks
                    size: 14,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color c = status == 'open' ? AppTheme.warningOrange : (status == 'resolved' ? AppTheme.primaryGreen : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: c)),
    );
  }
}
