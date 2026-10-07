import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextOrFinish() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const AuthScreen(),
          transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 800;

    if (isDesktopOrTablet) {
      return _buildDesktopTabletOverview(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                // Top Bar with Brand Logo & Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.restaurant, size: 18, color: AppTheme.primaryGreen),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'DREAMEATS',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF0D3B22),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPage < 2)
                        TextButton(
                          onPressed: () => _goToAuth(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.mutedGrey,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          child: const Text('SKIP'),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // PageView Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildSlide1(),
                      _buildSlide2(),
                      _buildSlide3(),
                    ],
                  ),
                ),

                // Bottom Navigation & Pagination Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sleek Animated Dots
                      Row(
                        children: List.generate(3, (index) {
                          final isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(right: 8),
                            width: isActive ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.primaryGreen : AppTheme.charcoal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      // Action Button
                      ElevatedButton(
                        onPressed: _nextOrFinish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == 2 ? 'GET STARTED' : 'CONTINUE',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == 2 ? Icons.arrow_forward_rounded : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToAuth(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AuthScreen(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP / TABLET SINGLE-PAGE OVERVIEW (3-IN-1 VIEW)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopTabletOverview(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Top Navigation Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/images/logo.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Icon(Icons.restaurant, size: 20, color: AppTheme.primaryGreen),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'DREAMEATS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: Color(0xFF0D3B22),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _goToAuth(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primaryGreen,
                                      elevation: 0,
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Sign In',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_rounded, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Hero Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.eco_outlined, color: AppTheme.primaryGreen, size: 15),
                                    SizedBox(width: 6),
                                    Text(
                                      'SURPLUS FOOD RESCUE PLATFORM',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryGreen,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'Rescue Great Food.\nSave Money. Protect the Planet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0D3B22),
                                  height: 1.15,
                                  letterSpacing: -0.8,
                                ),
                              ),

                              const SizedBox(height: 12),

                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 620),
                                child: const Text(
                                  'DreamEats bridges top local restaurants, bakeries, and grocers with eco-conscious foodies to enjoy premium meals at up to 70% off.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.mutedGrey,
                                    height: 1.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 36),

                              // 3 Merged Feature Cards Side-by-Side (or Stack on narrow tablet)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth >= 720;
                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildOverviewCard(
                                            icon: Icons.restaurant_menu_rounded,
                                            badgeText: 'TOP RESTAURANTS & HOTELS',
                                            badgeBg: const Color(0xFFF1F8F4),
                                            badgeTextColor: const Color(0xFF0D3B22),
                                            title: 'Rescue Gourmet Surplus',
                                            description:
                                                'Enjoy delicious, high-quality surplus meals from premier culinary spots across Ghana before they go to waste.',
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _buildOverviewCard(
                                            icon: Icons.savings_outlined,
                                            badgeText: 'SAVE UP TO 70% DAILY',
                                            badgeBg: AppTheme.primaryGreen,
                                            badgeTextColor: Colors.white,
                                            title: 'Unbeatable Everyday Prices',
                                            description:
                                                'Access premium surplus packages at up to 70% off standard menu prices. Great for your wallet and instant pickup.',
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _buildOverviewCard(
                                            icon: Icons.public_rounded,
                                            badgeText: "PROTECT GHANA'S FUTURE",
                                            badgeBg: const Color(0xFFF1F8F4),
                                            badgeTextColor: const Color(0xFF0D3B22),
                                            title: 'Empower Local Community',
                                            description:
                                                'Every meal rescued directly cuts greenhouse emissions and supports Ghanaian food artisans and chefs.',
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        _buildOverviewCard(
                                          icon: Icons.restaurant_menu_rounded,
                                          badgeText: 'TOP RESTAURANTS & HOTELS',
                                          badgeBg: const Color(0xFFF1F8F4),
                                          badgeTextColor: const Color(0xFF0D3B22),
                                          title: 'Rescue Gourmet Surplus',
                                          description:
                                              'Enjoy delicious, high-quality surplus meals from premier culinary spots across Ghana before they go to waste.',
                                        ),
                                        const SizedBox(height: 16),
                                        _buildOverviewCard(
                                          icon: Icons.savings_outlined,
                                          badgeText: 'SAVE UP TO 70% DAILY',
                                          badgeBg: AppTheme.primaryGreen,
                                          badgeTextColor: Colors.white,
                                          title: 'Unbeatable Everyday Prices',
                                          description:
                                              'Access premium surplus packages at up to 70% off standard menu prices. Great for your wallet and instant pickup.',
                                        ),
                                        const SizedBox(height: 16),
                                        _buildOverviewCard(
                                          icon: Icons.public_rounded,
                                          badgeText: "PROTECT GHANA'S FUTURE",
                                          badgeBg: const Color(0xFFF1F8F4),
                                          badgeTextColor: const Color(0xFF0D3B22),
                                          title: 'Empower Local Community',
                                          description:
                                              'Every meal rescued directly cuts greenhouse emissions and supports Ghanaian food artisans and chefs.',
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),

                              const SizedBox(height: 36),

                              // Action CTA
                              ElevatedButton(
                                onPressed: () => _goToAuth(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'GET STARTED NOW',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Bottom Trust & Verification Footer (bottom of page)
                          Padding(
                            padding: const EdgeInsets.only(top: 32, bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_outlined, size: 16, color: AppTheme.primaryGreen),
                                  SizedBox(width: 8),
                                  Text(
                                    '100% Safe & Verified Pickups • Instant QR Verification • Direct Merchant Support',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF0D3B22),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                color: badgeTextColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D3B22),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.mutedGrey.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide 1: Gourmet Food Rescue ──────────────────────────────────────────
  Widget _buildSlide1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 250),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF1F8F4), Color(0xFFE8F5EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 48,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Top Restaurants & Hotels",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Color(0xFF0D3B22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const Text(
                    "Rescue Gourmet\nSurplus Meals",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D3B22),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enjoy delicious, high-quality food from premier culinary spots across Ghana while saving perfectly good meals from going to waste.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedGrey.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Slide 2: Unbeatable Savings ──────────────────────────────────────────
  Widget _buildSlide2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 250),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF1F8F4), Color(0xFFE8F5EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      size: 48,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "SAVE UP TO 70% TODAY",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const Text(
                    "Unbeatable Prices\nEvery Single Day",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D3B22),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Access premium meals at up to 70% off normal menu prices. Great for your wallet and incredible for the environment.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedGrey.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Slide 3: Community Impact ──────────────────────────────────────────────
  Widget _buildSlide3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 250),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF1F8F4), Color(0xFFE8F5EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      size: 48,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, color: AppTheme.errorRed, size: 15),
                        SizedBox(width: 8),
                        Text(
                          "Protect Ghana's Future",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Color(0xFF0D3B22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const Text(
                    "Empower Local\nBusinesses & Planet",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D3B22),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Each order directly cuts harmful greenhouse emissions and supports hard-working Ghanaian food artisans and chefs.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedGrey.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
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
