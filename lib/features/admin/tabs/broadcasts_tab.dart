import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final broadcasts = state.broadcasts;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Banner ─────────────────────────────────────────────
            _buildHeroHeader(state),
            const SizedBox(height: 24),

            // ── Responsive Layout ───────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1100;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Compose (60%)
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _buildComposeCard(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Right: History & Audit Log (40%)
                      Expanded(
                        flex: 4,
                        child: _buildHistoryCard(broadcasts, shrinkWrap: true),
                      ),
                    ],
                  );
                } else {
                  // Mobile/Tablet: Stacked view
                  return Column(
                    children: [
                      _buildComposeCard(),
                      const SizedBox(height: 32),
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

  Widget _buildHeroHeader(AppState state) {
    final activeCustomers = state.users.where((u) => u.role == 'customer').length;
    final totalReach = activeCustomers + state.businesses.length;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppTheme.primaryGreen, size: 28),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Enterprise Broadcast Engine",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Dispatch real-time push notifications and email alerts across your global ecosystem.",
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "ENGINE ONLINE",
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _headerStat("DISPATCH CHANNELS", "Push & Email Dispatch", Icons.cell_tower_rounded),
              _headerStat("ACTIVE AUDIENCE", "$totalReach Users ($activeCustomers Rescuers • ${state.businesses.length} Hubs)", Icons.groups_rounded),
              _headerStat("TOTAL CAMPAIGNS", "${state.broadcasts.length} Dispatched", Icons.send_time_extension_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComposeCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_notifications_rounded, color: AppTheme.charcoal, size: 22),
              const SizedBox(width: 10),
              Text(
                "Configure Campaign",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Select your target segment and compose your announcement message below.", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
          const SizedBox(height: 28),

          // Audience Selection Cards
          const Text("1. TARGET SEGMENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAudienceOption('all', "All Users", "Global Audience", Icons.public_rounded, AppTheme.primaryGreen),
              const SizedBox(width: 12),
              _buildAudienceOption('customers', "Customers", "Rescuers & Buyers", Icons.person_rounded, Colors.blue),
              const SizedBox(width: 12),
              _buildAudienceOption('merchants', "Merchants", "Stores & Kitchens", Icons.storefront_rounded, AppTheme.goldAccent),
            ],
          ),

          const SizedBox(height: 28),
          const Text("2. MESSAGE CONTENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            onChanged: (v) => setState(() {}),
            maxLength: 60,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            decoration: InputDecoration(
              labelText: "Notification Heading",
              hintText: "e.g. Flash Sale Live Now! 🔥",
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.mutedGrey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            onChanged: (v) => setState(() {}),
            maxLines: 4,
            maxLength: 250,
            style: const TextStyle(fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              labelText: "Message Body",
              hintText: "Enter the details of your announcement here...",
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.mutedGrey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 28),

          // Dispatch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSend,
              icon: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.rocket_launch_rounded, size: 20),
              label: Text(
                _isLoading ? "DISPATCHING CAMPAIGN..." : "LAUNCH BROADCAST NOW",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
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
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _audience = id);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? iconColor.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? iconColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? iconColor.withValues(alpha: 0.15) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? iconColor : AppTheme.mutedGrey,
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? iconColor : AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.mutedGrey,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHistoryCard(List<BroadcastMessage> broadcasts, {bool shrinkWrap = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 22, color: AppTheme.charcoal),
                const SizedBox(width: 12),
                Text(
                  "Campaign Audit Trail",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.charcoal,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.charcoal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    "${broadcasts.length} Dispatched",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
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
            shrinkWrap
                ? ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: broadcasts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _buildHistoryTile(broadcasts[i]),
                  )
                : Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: broadcasts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _buildHistoryTile(broadcasts[i]),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(BroadcastMessage msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        expandedAlignment: Alignment.topLeft,
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(
            msg.audience == 'merchants'
                ? Icons.storefront_rounded
                : (msg.audience == 'customers' ? Icons.person_rounded : Icons.public_rounded),
            size: 20,
            color: AppTheme.charcoal,
          ),
        ),
        title: Text(
          msg.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.charcoal),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _AudienceBadge(audience: msg.audience),
              Text(
                DateFormat('MMM d, h:mm a').format(msg.createdAt),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          const Text("MESSAGE BODY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(
            msg.message,
            style: const TextStyle(fontSize: 13, color: AppTheme.charcoal, height: 1.5),
          ),
          const SizedBox(height: 16),
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
                    const SnackBar(content: Text("Campaign copied to compose editor!"), backgroundColor: AppTheme.charcoal),
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
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both heading and message body."), backgroundColor: AppTheme.errorRed),
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
          const SnackBar(content: Text("✅ Broadcast campaign dispatched successfully to all target channels."), backgroundColor: AppTheme.primaryGreen),
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
        label = "CUSTOMERS ONLY";
        break;
      case 'merchants':
        color = AppTheme.goldAccent;
        label = "MERCHANTS ONLY";
        break;
      default:
        color = AppTheme.primaryGreen;
        label = "ALL USERS (GLOBAL)";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }
}
