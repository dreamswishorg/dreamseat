import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabBroadcasts extends ConsumerStatefulWidget {
  const TabBroadcasts({super.key});

  @override
  ConsumerState<TabBroadcasts> createState() => _TabBroadcastsState();
}

class _TabBroadcastsState extends ConsumerState<TabBroadcasts> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _audience = 'all'; // 'all', 'customers', 'merchants'
  String _priority = 'standard'; // 'standard', 'urgent', 'promo'
  bool _isLoading = false;

  final List<Map<String, String>> _templates = [
    {
      'title': 'Flash Surplus Drop Live! 🔥',
      'message': 'Surplus meals are ready for rescue across top neighborhood kitchens at up to 70% off. Claim yours before they sell out!',
      'audience': 'customers',
      'priority': 'promo',
      'label': '⚡ Flash Surplus Drop',
    },
    {
      'title': 'Holiday Operations & Hours 📢',
      'message': 'Please review holiday dispatch schedules and kitchen pickup cut-off times for this upcoming long weekend.',
      'audience': 'all',
      'priority': 'standard',
      'label': '📢 Holiday Schedule',
    },
    {
      'title': 'Scheduled Core Maintenance 🚨',
      'message': 'DreamEats systems will undergo scheduled maintenance tonight at 02:00 UTC. Expected downtime is under 15 minutes.',
      'audience': 'all',
      'priority': 'urgent',
      'label': '🚨 System Maintenance',
    },
    {
      'title': 'New Kitchen Hubs Onboarded! 🎉',
      'message': 'Explore 12 newly approved artisan bakeries and local eateries now live in your delivery zone.',
      'audience': 'customers',
      'priority': 'promo',
      'label': '🎉 New Hubs Live',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, String> t) {
    HapticFeedback.selectionClick();
    setState(() {
      _titleController.text = t['title'] ?? '';
      _messageController.text = t['message'] ?? '';
      _audience = t['audience'] ?? 'all';
      _priority = t['priority'] ?? 'standard';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Template '${t['label']}' loaded!"),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final broadcasts = state.broadcasts;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Header ─────────────────────────────────────────────
            _buildHeroHeader(state, isMobile),
            const SizedBox(height: 24),

            // ── Responsive Layout ───────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1100;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Compose & Quick Templates (60%)
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _buildQuickTemplates(),
                            const SizedBox(height: 24),
                            _buildComposeCard(state),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Right: Live Notification Mockup Preview & Audit Trail (40%)
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildLivePreviewCard(),
                            const SizedBox(height: 24),
                            _buildHistoryCard(broadcasts, shrinkWrap: true),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile/Tablet: Stacked view
                  return Column(
                    children: [
                      _buildQuickTemplates(),
                      const SizedBox(height: 20),
                      _buildComposeCard(state),
                      const SizedBox(height: 24),
                      _buildLivePreviewCard(),
                      const SizedBox(height: 24),
                      _buildHistoryCard(broadcasts, shrinkWrap: true),
                      const SizedBox(height: 40),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(AppState state, bool isMobile) {
    final activeCustomers = state.users.where((u) => u.role == 'customer').length;
    final totalReach = activeCustomers + state.businesses.length;

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppTheme.primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Global Broadcasts",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.charcoal,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Instant ecosystem announcements, push alerts & customer outreach",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_tethering_rounded, color: AppTheme.primaryGreen, size: 13),
                    SizedBox(width: 5),
                    Text(
                      "ENGINE ACTIVE",
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _headerStat("AUDIENCE REACH", "$totalReach Total", Icons.groups_rounded, const Color(0xFF2563EB)),
              _headerStat("CUSTOMERS", "$activeCustomers Savers", Icons.person_rounded, AppTheme.primaryGreen),
              _headerStat("MERCHANTS", "${state.businesses.length} Kitchens", Icons.storefront_rounded, const Color(0xFFD97706)),
              _headerStat("CAMPAIGNS", "${state.broadcasts.length} Sent", Icons.send_rounded, const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_rounded, size: 18, color: AppTheme.warningOrange),
            const SizedBox(width: 6),
            Text(
              "QUICK-START PRESET TEMPLATES",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: context.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _templates.map((t) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  onPressed: () => _applyTemplate(t),
                  backgroundColor: context.cardColor,
                  side: BorderSide(color: context.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: context.isDark ? 0 : 1,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  label: Text(
                    t['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildComposeCard(AppState state) {
    final activeCustomers = state.users.where((u) => u.role == 'customer').length;
    final totalMerchants = state.businesses.length;
    final totalReach = activeCustomers + totalMerchants;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.borderColor),
        boxShadow: context.isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_notifications_rounded, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Compose Campaign",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    "Target audience, message content & priority",
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Audience Selector
          Text(
            "1. TARGET AUDIENCE SEGMENT",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: context.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, c) {
              final isVeryCompact = c.maxWidth < 450;
              if (isVeryCompact) {
                return Column(
                  children: [
                    _buildAudienceOption('all', "All Users", "$totalReach reach", Icons.public_rounded, AppTheme.primaryGreen),
                    const SizedBox(height: 8),
                    _buildAudienceOption('customers', "Rescuers", "$activeCustomers savers", Icons.person_rounded, Colors.blue),
                    const SizedBox(height: 8),
                    _buildAudienceOption('merchants', "Partner Hubs", "$totalMerchants stores", Icons.storefront_rounded, AppTheme.goldAccent),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildAudienceOption('all', "All Users", "$totalReach reach", Icons.public_rounded, AppTheme.primaryGreen)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildAudienceOption('customers', "Rescuers", "$activeCustomers savers", Icons.person_rounded, Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildAudienceOption('merchants', "Partner Hubs", "$totalMerchants stores", Icons.storefront_rounded, AppTheme.goldAccent)),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // 2. Priority Selection
          Text(
            "2. CAMPAIGN PRIORITY",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: context.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPriorityPill('standard', "Standard Notice", Icons.info_outline_rounded, AppTheme.primaryGreen),
              const SizedBox(width: 10),
              _buildPriorityPill('urgent', "Urgent Alert", Icons.warning_amber_rounded, AppTheme.errorRed),
              const SizedBox(width: 10),
              _buildPriorityPill('promo', "Promotional", Icons.local_offer_rounded, Colors.purple),
            ],
          ),

          const SizedBox(height: 24),

          // 3. Message Content
          Text(
            "3. ANNOUNCEMENT CONTENT",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: context.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            onChanged: (v) => setState(() {}),
            maxLength: 60,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: context.textPrimary),
            decoration: InputDecoration(
              labelText: "Notification Heading",
              hintText: "e.g. Flash Surplus Drop Live! 🔥",
              labelStyle: TextStyle(fontWeight: FontWeight.w600, color: context.textSecondary),
              hintStyle: TextStyle(color: context.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
              filled: true,
              fillColor: context.cardAltColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            onChanged: (v) => setState(() {}),
            maxLines: 4,
            maxLength: 250,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: context.textPrimary),
            decoration: InputDecoration(
              labelText: "Message Body",
              hintText: "Enter the details of your announcement here...",
              labelStyle: TextStyle(fontWeight: FontWeight.w600, color: context.textSecondary),
              hintStyle: TextStyle(color: context.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
              filled: true,
              fillColor: context.cardAltColor,
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
          const SizedBox(height: 24),

          // Dispatch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSend,
              icon: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.rocket_launch_rounded, size: 20),
              label: Text(
                _isLoading ? "DISPATCHING..." : "DISPATCH GLOBAL BROADCAST",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceOption(String id, String title, String subtitle, IconData icon, Color iconColor) {
    final isSelected = _audience == id;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _audience = id);
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? iconColor.withValues(alpha: context.isDark ? 0.2 : 0.08)
              : context.cardAltColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? iconColor : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? iconColor.withValues(alpha: 0.2)
                        : context.borderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: isSelected ? iconColor : context.textSecondary),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: iconColor, size: 18)
                else
                  const SizedBox(width: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isSelected ? iconColor : context.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityPill(String id, String label, IconData icon, Color color) {
    final isSelected = _priority == id;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _priority = id);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: context.isDark ? 0.2 : 0.1) : context.cardAltColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : context.borderColor,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : context.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? color : context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasMessage = _messageController.text.trim().isNotEmpty;
    final displayTitle = hasTitle ? _titleController.text.trim() : "Flash Surplus Drop Live! 🔥";
    final displayMessage = hasMessage
        ? _messageController.text.trim()
        : "Surplus meals are ready for rescue across top neighborhood kitchens at up to 70% off.";

    Color priorityColor;
    String priorityText;
    switch (_priority) {
      case 'urgent':
        priorityColor = AppTheme.errorRed;
        priorityText = "URGENT ALERT";
        break;
      case 'promo':
        priorityColor = Colors.purple;
        priorityText = "PROMO DROP";
        break;
      default:
        priorityColor = AppTheme.primaryGreen;
        priorityText = "STANDARD";
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.borderColor),
        boxShadow: context.isDark
            ? []
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 6)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_iphone_rounded, size: 20, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    "Live Push Preview",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priorityText,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: priorityColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Real-time lock screen presentation on user devices",
            style: TextStyle(fontSize: 11.5, color: context.textSecondary),
          ),
          const SizedBox(height: 18),

          // Simulated iOS Lock Screen Notification Bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.8)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(Icons.eco_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "DreamEats",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text("•", style: TextStyle(fontSize: 10, color: context.textSecondary)),
                    const SizedBox(width: 6),
                    Text(
                      "now",
                      style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.more_horiz_rounded, size: 16, color: context.textSecondary),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayMessage,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: context.isDark ? Colors.white.withValues(alpha: 0.8) : AppTheme.charcoal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.mark_email_read_rounded, size: 14, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Text(
                "Multi-channel broadcast will deliver via Push & Email",
                style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(List<BroadcastMessage> broadcasts, {bool shrinkWrap = false}) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.borderColor),
        boxShadow: context.isDark
            ? []
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 6)),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: context.cardAltColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 22, color: context.textPrimary),
                const SizedBox(width: 12),
                Text(
                  "Campaign Audit Trail",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${broadcasts.length} Dispatched",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
          if (broadcasts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: NoDataState(msg: "No previous broadcasts found in the audit trail.", icon: Icons.history_rounded),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              shrinkWrap: shrinkWrap,
              physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              itemCount: broadcasts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, i) => _buildHistoryTile(broadcasts[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(BroadcastMessage msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: context.cardAltColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        expandedAlignment: Alignment.topLeft,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Icon(
            msg.audience == 'merchants'
                ? Icons.storefront_rounded
                : (msg.audience == 'customers' ? Icons.person_rounded : Icons.public_rounded),
            size: 18,
            color: context.textPrimary,
          ),
        ),
        title: Text(
          msg.title,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: context.textPrimary),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _AudienceBadge(audience: msg.audience),
              Text(
                DateFormat('MMM d, h:mm a').format(msg.createdAt),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
            ],
          ),
        ),
        children: [
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 12),
          Text(
            "DISPATCHED CONTENT",
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: context.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            msg.message,
            style: TextStyle(fontSize: 13, color: context.textPrimary, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _titleController.text = msg.title;
                    _messageController.text = msg.message;
                    _audience = msg.audience;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Campaign duplicated into composer!"),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryGreen),
                label: const Text(
                  "Duplicate Campaign",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both notification heading and message body."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(appStateProvider.notifier).broadcastAnnouncement(
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
            audience: _audience,
            sendPush: true,
            sendEmail: true,
          );

      _titleController.clear();
      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Broadcast campaign dispatched successfully to all target devices."),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _AudienceBadge extends StatelessWidget {
  final String audience;
  const _AudienceBadge({required this.audience});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (audience) {
      case 'customers':
        color = Colors.blue;
        label = "RESCUERS ONLY";
        break;
      case 'merchants':
        color = AppTheme.goldAccent;
        label = "PARTNER HUBS";
        break;
      default:
        color = AppTheme.primaryGreen;
        label = "ALL (GLOBAL)";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }
}
