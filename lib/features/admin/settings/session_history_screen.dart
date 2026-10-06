import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessions = [
      {
        'device': 'macOS / Chrome 124.0',
        'ip': '154.160.2.45',
        'location': 'Accra, Ghana',
        'time': 'Active Now',
        'status': 'Active',
      },
      {
        'device': 'iOS App / iPhone 15 Pro',
        'ip': '154.160.18.99',
        'location': 'Accra, Ghana',
        'time': '2 hours ago',
        'status': 'Expired',
      },
      {
        'device': 'Windows / Firefox 123.0',
        'ip': '102.176.44.12',
        'location': 'Kumasi, Ghana',
        'time': 'Yesterday at 14:32',
        'status': 'Terminated',
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Active & Past Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final session = sessions[index];
          final isActive = session['status'] == 'Active';

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    session['device']!.contains('iPhone') || session['device']!.contains('iOS')
                        ? Icons.phone_iphone_rounded
                        : Icons.computer_rounded,
                    color: isActive ? AppTheme.primaryGreen : (isDark ? Colors.white70 : AppTheme.mutedGrey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            session['device']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'IP: ${session['ip']} • ${session['location']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : AppTheme.mutedGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      session['status']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isActive
                            ? AppTheme.primaryGreen
                            : (session['status'] == 'Terminated' ? AppTheme.errorRed : AppTheme.mutedGrey),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session['time']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : AppTheme.mutedGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
