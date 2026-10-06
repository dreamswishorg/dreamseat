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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                        width: 34,
                        height: 34,
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
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) => const AuthScreen(),
                            transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.mutedGrey,
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
                          _currentPage == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
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
    );
  }

  // ── Slide 1: Gourmet Food Rescue ──────────────────────────────────────────
  Widget _buildSlide1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 260,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded, size: 54, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 18),
                      SizedBox(width: 8),
                      Text("Top Restaurants & Hotels", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D3B22))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            "Rescue Gourmet\nSurplus Meals",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D3B22), height: 1.2, letterSpacing: -0.5),
          ),
          const SizedBox(height: 14),
          const Text(
            "Enjoy delicious, high-quality food from premier culinary spots across Ghana while saving perfectly good meals from going to waste.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: AppTheme.mutedGrey, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Slide 2: Unbeatable Savings ──────────────────────────────────────────
  Widget _buildSlide2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 260,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.savings_rounded, size: 54, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("SAVE UP TO 70% TODAY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            "Unbeatable Prices\nEvery Single Day",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D3B22), height: 1.2, letterSpacing: -0.5),
          ),
          const SizedBox(height: 14),
          const Text(
            "Access premium meals at up to 70% off normal menu prices. Great for your wallet and incredible for the environment.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: AppTheme.mutedGrey, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Slide 3: Community Impact ──────────────────────────────────────────────
  Widget _buildSlide3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 260,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.public_rounded, size: 54, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, color: AppTheme.errorRed, size: 16),
                      SizedBox(width: 8),
                      Text("Protect Ghana's Future", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D3B22))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            "Empower Local\nBusinesses & Planet",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D3B22), height: 1.2, letterSpacing: -0.5),
          ),
          const SizedBox(height: 14),
          const Text(
            "Each order directly cuts harmful greenhouse emissions and supports hard-working Ghanaian food artisans and chefs.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: AppTheme.mutedGrey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
