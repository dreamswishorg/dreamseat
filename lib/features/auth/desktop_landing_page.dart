import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../common/legal_screens.dart';
import 'auth_screen.dart';

/// Landing page shown on tablet & desktop (width >= 800).
///
/// Layout: fixed top navigation (brand left, auth actions right), hero,
/// how-it-works, benefits, business call-to-action and a full footer.
class DesktopLandingPage extends StatefulWidget {
  const DesktopLandingPage({super.key});

  @override
  State<DesktopLandingPage> createState() => _DesktopLandingPageState();
}

class _DesktopLandingPageState extends State<DesktopLandingPage> {
  static const _ink = Color(0xFF0D3B22);
  static const _border = Color(0xFFE5E7EB);
  static const _surface = Color(0xFFF7F8F7);
  static const _maxWidth = 1180.0;

  final _howItWorksKey = GlobalKey();
  final _businessKey = GlobalKey();

  void _openAuth({int tab = 0}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => AuthScreen(initialTab: tab),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    }
  }

  void _contactSupport() {
    _showContactDialog(context);
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(28),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.headset_mic_rounded, color: AppTheme.primaryGreen, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact DreamEats Team',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0D3B22),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'We are available 7 days a week to help you.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Email card
              _buildContactOption(
                icon: Icons.mail_outline_rounded,
                title: 'Official Support Email',
                detail: AppConfig.supportEmail,
                buttonLabel: 'Email Team',
                onAction: () async {
                  final uri = Uri(scheme: 'mailto', path: AppConfig.supportEmail, query: 'subject=DreamEats%20Enquiry');
                  await launchUrl(uri);
                },
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: AppConfig.supportEmail));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support email copied to clipboard!'), backgroundColor: AppTheme.primaryGreen),
                  );
                },
              ),
              const SizedBox(height: 14),
              // Phone & WhatsApp card
              _buildContactOption(
                icon: Icons.phone_android_rounded,
                title: 'Customer Line & WhatsApp',
                detail: '+233 24 567 8901',
                buttonLabel: 'Call Now',
                onAction: () async {
                  final uri = Uri(scheme: 'tel', path: '+233245678901');
                  await launchUrl(uri);
                },
                onCopy: () {
                  Clipboard.setData(const ClipboardData(text: '+233 24 567 8901'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number copied to clipboard!'), backgroundColor: AppTheme.primaryGreen),
                  );
                },
              ),
              const SizedBox(height: 18),
              // Operating hours note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: AppTheme.primaryGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Monday – Sunday: 8:00 AM – 9:00 PM GMT\nPrompt response for customer orders and merchant partnerships.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF4B5563), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String detail,
    required String buttonLabel,
    required VoidCallback onAction,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0D3B22))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 17, color: AppTheme.mutedGrey),
            tooltip: 'Copy',
            onPressed: onCopy,
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildNavBar(isDesktop),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(isDesktop),
                  _section(key: _howItWorksKey, child: _buildHowItWorks()),
                  _section(background: _surface, child: _buildBenefits()),
                  _section(key: _businessKey, child: _buildBusinessBand(isDesktop)),
                  _buildFooter(isDesktop),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Layout helpers ─────────────────────────────────────────────────────────

  Widget _contained(Widget child, {EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 40)}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _section({Key? key, Color background = Colors.white, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,
      color: background,
      child: _contained(child, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 72)),
    );
  }

  Widget _sectionHeading(String eyebrow, String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.6, height: 1.2),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(subtitle, style: const TextStyle(fontSize: 15.5, color: AppTheme.mutedGrey, height: 1.55)),
          ),
        ],
      ],
    );
  }

  Widget _brand({Color textColor = _ink}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.restaurant, size: 22, color: AppTheme.primaryGreen),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'DreamEats',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.4),
        ),
      ],
    );
  }

  // ── Top navigation ─────────────────────────────────────────────────────────

  Widget _buildNavBar(bool isDesktop) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 68,
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
          child: _contained(
            Row(
              children: [
                _brand(),
                if (isDesktop) ...[
                  const SizedBox(width: 40),
                  _navLink('How it works', () => _scrollTo(_howItWorksKey)),
                  _navLink('For businesses', () => _scrollTo(_businessKey)),
                  _navLink('Contact', _contactSupport),
                ],
                const Spacer(),
                TextButton(
                  key: const Key('landing_sign_in'),
                  onPressed: () => _openAuth(tab: 0),
                  style: TextButton.styleFrom(
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Sign in'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const Key('landing_get_started_nav'),
                  onPressed: () => _openAuth(tab: 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Get started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF4B5563),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero(bool isDesktop) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SURPLUS FOOD, RESCUED',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 16),
        Text(
          'Great food from local favourites, for less.',
          style: TextStyle(
            fontSize: isDesktop ? 48 : 40,
            fontWeight: FontWeight.w800,
            color: _ink,
            height: 1.1,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: const Text(
            'Reserve unsold meals, pastries and groceries from restaurants and stores near you at up to 70% off, then pick them up at a time that suits you.',
            style: TextStyle(fontSize: 17, color: Color(0xFF4B5563), height: 1.55),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              key: const Key('landing_hero_find_deals'),
              onPressed: () => _openAuth(tab: 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
              ),
              child: const Text('Find deals near you'),
            ),
            OutlinedButton(
              key: const Key('landing_hero_list_business'),
              onPressed: () => _openAuth(tab: 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
              ),
              child: const Text('List your business'),
            ),
          ],
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 28,
          runSpacing: 12,
          children: const [
            _HeroFact(icon: Icons.sell_outlined, label: 'Up to 70% off'),
            _HeroFact(icon: Icons.qr_code_2_rounded, label: 'QR-verified pickup'),
            _HeroFact(icon: Icons.verified_user_outlined, label: 'Vetted partners'),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF1F8F4), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _contained(
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 6, child: copy),
                  const SizedBox(width: 56),
                  const Expanded(flex: 5, child: Center(child: _DealPreviewCard())),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: 48),
                  const Center(child: _DealPreviewCard()),
                ],
              ),
        padding: EdgeInsets.fromLTRB(40, isDesktop ? 80 : 56, 40, isDesktop ? 88 : 64),
      ),
    );
  }

  // ── How it works ───────────────────────────────────────────────────────────

  Widget _buildHowItWorks() {
    const steps = [
      (Icons.search_rounded, 'Browse', 'See surplus bags and meals available today from partners around you.'),
      (Icons.event_available_outlined, 'Reserve', 'Pay securely in the app to hold your order before it sells out.'),
      (Icons.shopping_bag_outlined, 'Pick up', 'Show your QR code at the store during the pickup window. Enjoy.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('How it works', 'Three steps from surplus to your table'),
        const SizedBox(height: 40),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                          child: Icon(steps[i].$1, size: 22, color: _ink),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '0${i + 1}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.mutedGrey, letterSpacing: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(steps[i].$2, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(height: 8),
                    Text(steps[i].$3, style: const TextStyle(fontSize: 15, color: AppTheme.mutedGrey, height: 1.55)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Benefits ───────────────────────────────────────────────────────────────

  Widget _buildBenefits() {
    const items = [
      (Icons.restaurant_outlined, 'Quality food, less waste', 'Meals and baked goods from respected local kitchens that would otherwise be thrown away.'),
      (Icons.savings_outlined, 'Real savings every day', 'Pay a fraction of the menu price. New deals are added by partners throughout the day.'),
      (Icons.eco_outlined, 'Measurable impact', 'Every order you rescue cuts food waste and emissions, and supports local businesses.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Why DreamEats',
          'Good for you, your neighbourhood and the planet',
        ),
        const SizedBox(height: 40),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(items[i].$1, size: 26, color: AppTheme.primaryGreen),
                        const SizedBox(height: 20),
                        Text(items[i].$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                        const SizedBox(height: 8),
                        Text(items[i].$3, style: const TextStyle(fontSize: 14.5, color: AppTheme.mutedGrey, height: 1.55)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Business band ──────────────────────────────────────────────────────────

  Widget _buildBusinessBand(bool isDesktop) {
    const bullets = ['Recover revenue from unsold stock', 'Reach new customers nearby', 'Simple QR check-out at pickup'];

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FOR BUSINESSES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Turn your surplus into revenue',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6, height: 1.2),
        ),
        const SizedBox(height: 20),
        for (final b in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.check_rounded, size: 18, color: Color(0xFFA7F3D0)),
                const SizedBox(width: 10),
                Text(b, style: TextStyle(fontSize: 15.5, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
      ],
    );

    final cta = ElevatedButton(
      key: const Key('landing_become_partner'),
      onPressed: () => _openAuth(tab: 1),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
      child: const Text('Become a partner'),
    );

    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: isDesktop
          ? Row(children: [Expanded(child: text), const SizedBox(width: 32), cta])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 20), cta]),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(bool isDesktop) {
    final muted = Colors.white.withValues(alpha: 0.65);

    Widget column(String title, List<(String, VoidCallback)> links) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          for (final l in links)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: l.$2,
                child: Text(l.$1, style: TextStyle(fontSize: 14, color: muted)),
              ),
            ),
        ],
      );
    }

    final brandBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _brand(textColor: Colors.white),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            'Connecting people with surplus food from local restaurants, bakeries and stores.',
            style: TextStyle(fontSize: 14, color: muted, height: 1.6),
          ),
        ),
      ],
    );

    final columns = [
      column('Product', [
        ('How it works', () => _scrollTo(_howItWorksKey)),
        ('Find deals', () => _openAuth(tab: 1)),
        ('Sign in', () => _openAuth(tab: 0)),
      ]),
      column('Business', [
        ('Become a partner', () => _openAuth(tab: 1)),
        ('Partner sign in', () => _openAuth(tab: 0)),
      ]),
      column('Support', [
        ('Contact Support', () => _showContactDialog(context)),
        ('Email: ${AppConfig.supportEmail}', () => _showContactDialog(context)),
        ('Phone: +233 24 567 8901', () => _showContactDialog(context)),
        ('Terms of Service', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()))),
        ('Privacy Policy', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
      ]),
    ];

    return Container(
      width: double.infinity,
      color: _ink,
      child: _contained(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: isDesktop ? 2 : 3, child: brandBlock),
                for (final c in columns) Expanded(child: c),
              ],
            ),
            const SizedBox(height: 40),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('© ${DateTime.now().year} DreamEats. All rights reserved.', style: TextStyle(fontSize: 13, color: muted)),
                const Spacer(),
                Icon(Icons.verified_outlined, size: 16, color: muted),
                const SizedBox(width: 6),
                Text('100% safe & verified pickups', style: TextStyle(fontSize: 13, color: muted)),
              ],
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(40, 64, 40, 32),
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroFact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      ],
    );
  }
}

/// Illustrative product preview, built from widgets so it stays crisp at any size.
class _DealPreviewCard extends StatelessWidget {
  const _DealPreviewCard();

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0D3B22);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(Icons.bakery_dining_outlined, size: 64, color: Colors.white.withValues(alpha: 0.9))),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: const Text('3 left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Neighbourhood Bakery', style: TextStyle(fontSize: 13, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text('Surprise pastry bag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 16, color: AppTheme.mutedGrey),
                      SizedBox(width: 6),
                      Text('Pick up today, 18:00 – 19:30', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('GHS 25', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(width: 8),
                      const Text(
                        'GHS 80',
                        style: TextStyle(fontSize: 14, color: AppTheme.mutedGrey, decoration: TextDecoration.lineThrough),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Reserve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
