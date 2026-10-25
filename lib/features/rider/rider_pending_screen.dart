import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../auth/welcome_screen.dart';

class RiderPendingScreen extends ConsumerWidget {
  const RiderPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider.select((s) => s.currentUser));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(appStateProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.charcoal, size: 18),
            label: const Text('Log out', style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 3),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 44,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rider Verification in Review',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.charcoal,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome, ${user?.name ?? "Rider"}! Your courier application is being reviewed by our dispatch operations team in Accra. Once approved, you can toggle online and receive deliveries.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedGrey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.two_wheeler_rounded, 'Vehicle', user?.vehicleType ?? 'Motorbike'),
                    const Divider(height: 20),
                    _infoRow(Icons.badge_outlined, 'Driver License', user?.licenseNumber.isNotEmpty == true ? user!.licenseNumber : 'Submitted'),
                    const Divider(height: 20),
                    _infoRow(Icons.verified_outlined, 'Status', 'Pending Verification', isPending: true),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(appStateProvider.notifier).refreshOrders();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checking verification status...')),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Check Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isPending = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isPending ? const Color(0xFFD97706) : AppTheme.charcoal),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isPending ? const Color(0xFFD97706) : AppTheme.charcoal,
          ),
        ),
      ],
    );
  }
}
