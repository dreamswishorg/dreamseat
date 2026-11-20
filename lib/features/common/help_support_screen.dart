import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';
import 'legal_screens.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _ticketFormKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  static const _faqs = <(String, String)>[
    (
      'How do I rescue a meal?',
      "Browse available deals, add them to your basket, and complete checkout. You'll receive a digital collection code to show at the store during their pickup window.",
    ),
    (
      'What if the store is closed upon arrival?',
      "Always arrive within the merchant's specified window. If the store is unexpectedly closed, open a support ticket immediately for a verified refund.",
    ),
    (
      'How do mystery bags work?',
      'Mystery bags contain high-quality surplus meals selected by the chef each day. While exact contents vary, the retail value is guaranteed to exceed the discounted price!',
    ),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitTicket() async {
    if (!(_ticketFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(appStateProvider).currentUser;
      if (user == null) return;

      await ref
          .read(appStateProvider.notifier)
          .createSupportTicket(
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
          );

      if (mounted) {
        AppToast.success(context, 'Support ticket submitted successfully.');
        _subjectController.clear();
        _messageController.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showNewTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: AppSpace.xxl,
          right: AppSpace.xxl,
          top: AppSpace.md,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _ticketFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.hairline,
                      borderRadius: AppRadius.rPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                const Text(
                  'New Support Request',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                const Text(
                  'Describe your issue and our dedicated support team in Accra will get back to you.',
                  style: TextStyle(
                    color: AppTheme.mutedGrey,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                DsTextField(
                  controller: _subjectController,
                  label: 'Subject',
                  hint: 'e.g. Order #1042 Collection Issue',
                  icon: Icons.subject_rounded,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please add a subject'
                      : null,
                ),
                const SizedBox(height: AppSpace.lg),
                DsTextField(
                  controller: _messageController,
                  label: 'Detailed Message',
                  hint: 'Tell us what happened',
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please describe your issue'
                      : null,
                ),
                const SizedBox(height: AppSpace.xxl),
                DsButton(
                  label: 'Send to support team',
                  icon: Icons.send_rounded,
                  loading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitTicket,
                ),
                const SizedBox(height: AppSpace.x4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(appStateProvider.select((s) => s.supportTickets));
    const sectionPad = EdgeInsets.fromLTRB(
      AppSpace.xs,
      AppSpace.xxl,
      AppSpace.xs,
      AppSpace.md,
    );

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: dsScreenBar(context, title: 'Help & Support'),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.lg,
            AppSpace.gutter,
            AppSpace.x4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero ────────────────────────────────────────────────────
              DsHeroCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DsPill(
                            label: '24/7 customer care',
                            icon: Icons.schedule_rounded,
                            compact: true,
                          ),
                          SizedBox(height: AppSpace.md),
                          Text(
                            'How can we assist your food rescue?',
                            style: TextStyle(
                              color: AppTheme.pureWhite,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: AppSpace.sm),
                          Text(
                            'Need help with collection codes or surplus deals? Reach out directly.',
                            style: TextStyle(
                              color: AppTheme.mintGreen,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.lg),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppTheme.limeAccent,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Contact ─────────────────────────────────────────────────
              const DsSectionHeader(
                title: 'Contact Options',
                padding: sectionPad,
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.add_comment_rounded,
                        label: 'Open Ticket',
                        detail: 'Fastest response',
                        onTap: _showNewTicketSheet,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.email_outlined,
                        label: 'Email Support',
                        detail: 'Direct mail inquiry',
                        tone: DsTone.info,
                        onTap: () => _launchEmail(context),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tickets ─────────────────────────────────────────────────
              if (tickets.isNotEmpty) ...[
                const DsSectionHeader(
                  title: 'My Active Requests',
                  padding: sectionPad,
                ),
                for (final t in tickets) _buildTicketTile(t),
              ],

              // ── FAQ ─────────────────────────────────────────────────────
              const DsSectionHeader(
                title: 'Frequently Asked Questions',
                padding: sectionPad,
              ),
              for (final (q, a) in _faqs) _buildFaqTile(question: q, answer: a),

              // ── Legal ───────────────────────────────────────────────────
              const DsSectionHeader(
                title: 'Legal & Documentation',
                padding: sectionPad,
              ),
              DsMenuGroup(
                margin: EdgeInsets.zero,
                children: [
                  DsMenuTile(
                    icon: Icons.description_rounded,
                    label: 'Terms of Service',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    ),
                  ),
                  DsMenuTile(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Privacy Policy',
                    tone: DsTone.info,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  DsMenuTile(
                    icon: Icons.info_outline_rounded,
                    label: 'App Version ${AppConfig.appVersion}',
                    tone: DsTone.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketTile(SupportTicket t) {
    final open = t.status == 'open';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: DsCard(
        onTap: () => _showTicketChat(context, t),
        padding: const EdgeInsets.all(AppSpace.lg),
        radius: AppRadius.md,
        child: Row(
          children: [
            DsIconBadge(
              icon: Icons.forum_rounded,
              tone: open ? DsTone.brand : DsTone.neutral,
              size: 44,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: AppTheme.charcoal,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  DsPill(
                    label: t.status.toUpperCase(),
                    tone: open ? DsTone.warn : DsTone.brand,
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              DateFormat('MMM d').format(t.createdAt),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: DsCard(
        padding: EdgeInsets.zero,
        radius: AppRadius.md,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
            collapsedShape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.xs,
            ),
            title: Text(
              question,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppTheme.charcoal,
                letterSpacing: -0.2,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              0,
              AppSpace.lg,
              AppSpace.lg,
            ),
            expandedAlignment: Alignment.topLeft,
            children: [
              Text(
                answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedGrey,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': 'DreamEats Support Request',
      }),
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.info(context, 'Email: ${AppConfig.supportEmail}');
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  void _showTicketChat(BuildContext context, SupportTicket ticket) {
    final replyController = TextEditingController();
    Future<List<TicketReply>> repliesFuture = SupabaseService()
        .fetchTicketReplies(ticket.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.sizeOf(context).height * 0.85,
            decoration: const BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Scaffold(
              backgroundColor: AppTheme.cream,
              appBar: AppBar(
                backgroundColor: AppTheme.pureWhite,
                centerTitle: false,
                leading: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      'Status: ${ticket.status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ticket.status == 'open'
                            ? AppTheme.goldAccent
                            : AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.hairline,
                  ),
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: FutureBuilder<List<TicketReply>>(
                      future: repliesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            snapshot.data == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final replies = snapshot.data ?? [];

                        return ListView(
                          padding: const EdgeInsets.all(AppSpace.lg),
                          children: [
                            // 1. The customer's own opening message
                            _buildChatBubble(
                              senderName: ticket.userName,
                              message: ticket.message,
                              timestamp: ticket.createdAt,
                              isStaffReply: false,
                              isInitial: true,
                            ),
                            // 2. Replies
                            ...replies.map(
                              (reply) => _buildChatBubble(
                                senderName: reply.senderName,
                                message: reply.message,
                                timestamp: reply.createdAt,
                                isStaffReply: reply.isStaffReply,
                                isInitial: false,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Reply bar — only while the ticket is still open
                  if (ticket.status != 'resolved')
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        AppSpace.md,
                        AppSpace.lg,
                        AppSpace.md + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      decoration: const BoxDecoration(
                        color: AppTheme.pureWhite,
                        border: Border(
                          top: BorderSide(color: AppTheme.hairline),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: replyController,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Type a reply...',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.xl,
                                  vertical: AppSpace.md,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.rPill,
                                  borderSide: const BorderSide(
                                    color: AppTheme.hairline,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.rPill,
                                  borderSide: const BorderSide(
                                    color: AppTheme.hairline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.rPill,
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: 'Send reply',
                              onPressed: () async {
                                if (replyController.text.trim().isEmpty) return;
                                final text = replyController.text.trim();
                                replyController.clear();
                                await ref
                                    .read(appStateProvider.notifier)
                                    .replyToTicket(
                                      ticket.id,
                                      text,
                                      isStaff: false,
                                    );
                                setModalState(() {
                                  repliesFuture = SupabaseService()
                                      .fetchTicketReplies(ticket.id);
                                });
                              },
                              icon: const Icon(
                                Icons.send_rounded,
                                color: AppTheme.pureWhite,
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(AppSpace.md),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
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

  Widget _buildChatBubble({
    required String senderName,
    required String message,
    required DateTime timestamp,
    required bool isStaffReply,
    bool isInitial = false,
  }) {
    // Customer messages sit on the right in a green bubble; staff replies on the left in white.
    final isMe = !isStaffReply;
    final timeStr = DateFormat('hh:mm a').format(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md + 2,
          vertical: AppSpace.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.lightGreenBg : AppTheme.pureWhite,
          border: Border.all(
            color: isMe ? AppTheme.mintGreen : AppTheme.hairline,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.sm),
            topRight: const Radius.circular(AppRadius.sm),
            bottomLeft: Radius.circular(isMe ? AppRadius.sm : AppSpace.xs),
            bottomRight: Radius.circular(isMe ? AppSpace.xs : AppRadius.sm),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe || isInitial) ...[
              Text(
                isMe ? 'You' : 'Support Agent ($senderName)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isMe ? AppTheme.primaryGreen : AppTheme.infoBlue,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
            ],
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.charcoal,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                timeStr,
                style: const TextStyle(
                  color: AppTheme.mutedGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable contact option: icon, label, one line of detail.
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final DsTone tone;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.tone = DsTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      radius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsIconBadge(icon: icon, tone: tone, size: 44),
          const SizedBox(height: AppSpace.md),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: AppTheme.charcoal,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.mutedGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
