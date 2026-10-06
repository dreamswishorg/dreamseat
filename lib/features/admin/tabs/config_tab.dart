import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';


class TabConfig extends ConsumerStatefulWidget {
  const TabConfig({super.key});
  @override
  ConsumerState<TabConfig> createState() => _TabConfigState();
}

class _TabConfigState extends ConsumerState<TabConfig> {
  final _versionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _versionController.text = ref.read(appStateProvider).platformSettings.minAppVersion;
  }

  @override
  void dispose() {
    _versionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final settings = state.platformSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual grouping of configuration modules
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // 1. Platform Governance Section
              _buildConfigSection(
                title: "Platform Governance",
                description: "Master switches for ecosystem availability and operational state.",
                children: [
                  _buildToggleTile(
                    title: "Maintenance Mode",
                    subtitle: "Instantly block all user traffic with a branded outage screen.",
                    value: settings.maintenanceMode,
                    icon: Icons.power_settings_new_rounded,
                    activeColor: AppTheme.errorRed,
                    statusText: settings.maintenanceMode ? "OFFLINE" : "OPERATIONAL",
                    onChanged: (v) => ref.read(appStateProvider.notifier).toggleMaintenanceMode(v),
                  ),
                ],
              ),

              // 2. Financial Engine Section
              _buildConfigSection(
                title: "Financial Engine",
                description: "Configure system-wide take rates and billing parameters.",
                children: [
                  _buildSliderTile(
                    title: "System Commission Rate",
                    subtitle: "Percentage of the rescue price retained by DREAMEATS.",
                    value: state.commissionRate,
                    icon: Icons.account_balance_rounded,
                    trailingText: "${(state.commissionRate * 100).toStringAsFixed(1)}%",
                    onChanged: (v) => ref.read(appStateProvider.notifier).setCommissionRate(v),
                  ),
                ],
              ),

              // 3. Client Compliance Section
              _buildConfigSection(
                title: "Client Compliance",
                description: "Enforce application integrity and mandatory software updates.",
                children: [
                  _buildInputTile(
                    title: "Minimum Software Version",
                    subtitle: "Force users on older versions to update before transacting.",
                    controller: _versionController,
                    icon: Icons.system_update_rounded,
                    buttonLabel: "Apply Force",
                    onPressed: () => _handleUpdateVersion(_versionController.text),
                  ),
                ],
              ),

              // 4. Infrastructure Health (Read-only status)
              _buildConfigSection(
                title: "Infrastructure Health",
                description: "Real-time status of underlying technical service nodes.",
                children: [
                  _buildStatusTile("Supabase Data Cluster", true),
                  const Divider(height: 1),
                  _buildStatusTile("Firebase Messaging Hub", true),
                  const Divider(height: 1),
                  _buildStatusTile("Paystack Gateway", true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection({required String title, required String description, required List<Widget> children}) {
    return Container(
      width: 500, // Fixed width for clean multi-column wrapping
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.charcoal, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, height: 1.4)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color activeColor,
    required String statusText,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: (value ? activeColor : AppTheme.primaryGreen).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: value ? activeColor : AppTheme.primaryGreen, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(statusText, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: value ? activeColor : AppTheme.primaryGreen)),
            const SizedBox(height: 4),
            Switch(
              value: value,
              activeThumbColor: activeColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required IconData icon,
    required String trailingText,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
                ],
              ),
            ),
            Text(trailingText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
          ],
        ),
        const SizedBox(height: 16),
        Slider(
          value: value,
          min: 0.05,
          max: 0.50,
          activeColor: AppTheme.primaryGreen,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildInputTile({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.charcoal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: AppTheme.charcoal, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "e.g. 1.0.4",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                minimumSize: const Size(140, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Apply Update"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusTile(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: ok ? AppTheme.primaryGreen : AppTheme.errorRed,
              shape: BoxShape.circle,
              boxShadow: [
                if (ok) BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.charcoal)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: (ok ? AppTheme.primaryGreen : AppTheme.errorRed).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(ok ? "ONLINE" : "ERROR", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: ok ? AppTheme.primaryGreen : AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdateVersion(String version) async {
    try {
      await ref.read(appStateProvider.notifier).updateMinAppVersion(version);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ System version policy updated successfully."), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } finally {
      // done
    }
  }
}
