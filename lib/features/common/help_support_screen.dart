import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/config.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import 'legal_screens.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitTicket() async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(appStateProvider).currentUser;
      if (user == null) return;

      await ref.read(appStateProvider.notifier).createSupportTicket(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Support ticket submitted successfully."), backgroundColor: AppTheme.primaryGreen),
        );
        _subjectController.clear();
        _messageController.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showNewTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text("New Support Request", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.charcoal)),
            const SizedBox(height: 6),
            const Text("Describe your issue and our dedicated support team in Accra will get back to you.", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13, height: 1.4)),
            const SizedBox(height: 24),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: "Subject (e.g. Order #1042 Collection Issue)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppTheme.lightGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Detailed Message",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppTheme.lightGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("SEND TO SUPPORT TEAM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(appStateProvider.select((s) => s.supportTickets));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help & Support', style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Help Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F5B3C), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: const Text("24/7 CUSTOMER CARE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        ),
                        const SizedBox(height: 12),
                        const Text("How can we assist your food rescue?", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
                        const SizedBox(height: 6),
                        Text("Need help with collection codes or surplus deals? Reach out directly.", style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text("Contact Options", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.charcoal, letterSpacing: -0.3)),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildContactCard(
                  icon: Icons.add_comment_rounded,
                  label: "Open Ticket",
                  sublabel: "Fastest response",
                  color: AppTheme.primaryGreen,
                  onTap: _showNewTicketSheet,
                ),
                const SizedBox(width: 14),
                _buildContactCard(
                  icon: Icons.email_outlined,
                  label: "Email Support",
                  sublabel: "Direct mail inquiry",
                  color: const Color(0xFF0284C7),
                  onTap: () => _launchEmail(context),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Active Tickets
            if (tickets.isNotEmpty) ...[
              const Text("My Active Requests", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.charcoal, letterSpacing: -0.3)),
              const SizedBox(height: 14),
              ...tickets.map((t) => InkWell(
                    onTap: () => _showTicketChat(context, t),
                    borderRadius: BorderRadius.circular(18),
                    child: _buildTicketTile(t),
                  )),
              const SizedBox(height: 28),
            ],

            const Text("Frequently Asked Questions", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.charcoal, letterSpacing: -0.3)),
            const SizedBox(height: 14),
            _buildFAQTile(question: "How do I rescue a meal?", answer: "Browse available deals, add them to your basket, and complete checkout. You'll receive a digital collection code to show at the store during their pickup window."),
            _buildFAQTile(question: "What if the store is closed upon arrival?", answer: "Always arrive within the merchant's specified window. If the store is unexpectedly closed, open a support ticket immediately for a verified refund."),
            _buildFAQTile(question: "How do mystery bags work?", answer: "Mystery bags contain high-quality surplus meals selected by the chef each day. While exact contents vary, the retail value is guaranteed to exceed the discounted price!"),
            const SizedBox(height: 32),

            const Text("Legal & Documentation", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.charcoal, letterSpacing: -0.3)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05))),
              child: Column(
                children: [
                  _buildLegalRow(
                    icon: Icons.description_rounded,
                    label: "Terms of Service",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                  ),
                  Divider(height: 1, color: AppTheme.charcoal.withValues(alpha: 0.05)),
                  _buildLegalRow(
                    icon: Icons.privacy_tip_rounded,
                    label: "Privacy Policy",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  ),
                  Divider(height: 1, color: AppTheme.charcoal.withValues(alpha: 0.05)),
                  _buildLegalRow(
                    icon: Icons.info_outline_rounded,
                    label: "App Version ${AppConfig.appVersion}",
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTile(SupportTicket t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
            child: Icon(Icons.forum_rounded, size: 20, color: t.status == 'resolved' ? AppTheme.mutedGrey : AppTheme.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.charcoal)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.status == 'open' ? AppTheme.warningOrange.withValues(alpha: 0.15) : AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text("Status: ${t.status.toUpperCase()}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: t.status == 'open' ? AppTheme.warningOrange : AppTheme.primaryGreen)),
                ),
              ],
            ),
          ),
          Text(DateFormat('MMM d').format(t.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
        ],
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String label, required String sublabel, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 14),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.charcoal)),
                const SizedBox(height: 2),
                Text(sublabel, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05))),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.charcoal)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [Text(answer, style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey, height: 1.5))],
      ),
    );
  }

  Widget _buildLegalRow({required IconData icon, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppTheme.primaryGreen),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.charcoal))),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedGrey, size: 22),
          ],
        ),
      ),
    );
  }

  void _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: _encodeQueryParameters(<String, String>{'subject': 'DreamEats Support Request'}),
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email: ${AppConfig.supportEmail}")));
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries.map((MapEntry<String, String> e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
  }

  void _showTicketChat(BuildContext context, SupportTicket ticket) {
    final replyController = TextEditingController();
    Future<List<TicketReply>> repliesFuture = SupabaseService().fetchTicketReplies(ticket.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Scaffold(
              backgroundColor: const Color(0xFFE5DDD5), // Standard WhatsApp chat background
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 1,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.charcoal),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Status: ${ticket.status.toUpperCase()}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ticket.status == 'open' ? AppTheme.warningOrange : AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: FutureBuilder<List<TicketReply>>(
                      future: repliesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                        }

                        final replies = snapshot.data ?? [];

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // 1. Customer's own initial message
                            _buildModalChatBubble(
                              senderName: ticket.userName,
                              message: ticket.message,
                              timestamp: ticket.createdAt,
                              isStaffReply: false,
                              isInitial: true,
                            ),
                            // 2. Replies
                            ...replies.map((reply) => _buildModalChatBubble(
                                  senderName: reply.senderName,
                                  message: reply.message,
                                  timestamp: reply.createdAt,
                                  isStaffReply: reply.isStaffReply,
                                  isInitial: false,
                                )),
                          ],
                        );
                      },
                    ),
                  ),
                  // Bottom send bar (Only if ticket is not resolved!)
                  if (ticket.status != 'resolved')
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0),
                        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: replyController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: "Type a reply...",
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
                              color: Color(0xFF00A884),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () async {
                                if (replyController.text.trim().isEmpty) return;
                                final text = replyController.text.trim();
                                replyController.clear();
                                await ref.read(appStateProvider.notifier).replyToTicket(
                                      ticket.id,
                                      text,
                                      isStaff: false,
                                    );
                                setModalState(() {
                                  repliesFuture = SupabaseService().fetchTicketReplies(ticket.id);
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalChatBubble({
    required String senderName,
    required String message,
    required DateTime timestamp,
    required bool isStaffReply,
    bool isInitial = false,
  }) {
    // For the customer screen: Customer messages (isStaffReply = false) are on the right (greenish bubble)
    // Staff replies (isStaffReply = true) are on the left (white bubble)
    final isMe = !isStaffReply;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe ? const Color(0xFFD9FDD3) : Colors.white;
    final textColor = const Color(0xFF111B21);
    final timeStr = DateFormat('hh:mm a').format(timestamp);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
            // Sender identifier header
            if (!isMe || isInitial) ...[
              Text(
                isMe ? "You" : "Support Agent ($senderName)",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isMe ? AppTheme.primaryGreen : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              message,
              style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 4),
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
                    color: Color(0xFF53BDEB),
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
