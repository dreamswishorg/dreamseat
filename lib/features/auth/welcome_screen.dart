import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import 'auth_screen.dart';
import 'desktop_landing_page.dart';

class _Slide {
  final IconData icon;
  final IconData chipIcon;
  final String chip;
  final String title;
  final String body;
  const _Slide({
    required this.icon,
    required this.chipIcon,
    required this.chip,
    required this.title,
    required this.body,
  });
}

const List<_Slide> _slides = [
  _Slide(
    icon: Icons.restaurant_menu_rounded,
    chipIcon: Icons.verified_rounded,
    chip: 'Top Restaurants & Hotels',
    title: 'Rescue Gourmet\nSurplus Meals',
    body:
        'Enjoy delicious, high-quality food from premier culinary spots across Ghana while saving perfectly good meals from going to waste.',
  ),
  _Slide(
    icon: Icons.savings_rounded,
    chipIcon: Icons.sell_rounded,
    chip: 'SAVE UP TO 70% TODAY',
    title: 'Unbeatable Prices\nEvery Single Day',
    body:
        'Access premium meals at up to 70% off normal menu prices. Great for your wallet and incredible for the environment.',
  ),
  _Slide(
    icon: Icons.public_rounded,
    chipIcon: Icons.favorite_rounded,
    chip: "Protect Ghana's Future",
    title: 'Empower Local\nBusinesses & Planet',
    body:
        'Each order directly cuts harmful greenhouse emissions and supports hard-working Ghanaian food artisans and chefs.',
  ),
];

class WelcomeScreen extends StatefulWidget {
  final String? errorMessage;
  const WelcomeScreen({super.key, this.errorMessage});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLast => _currentPage == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.errorMessage!),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextOrFinish() {
    if (!_isLast) {
      _pageController.nextPage(duration: AppMotion.slow, curve: Curves.easeInOutCubic);
    } else {
      _goToAuth(context);
    }
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

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 800;
    if (isDesktopOrTablet) {
      return const DesktopLandingPage();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  // Brand + skip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: AppSpace.sm),
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
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.restaurant, size: 18, color: AppTheme.primaryGreen),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            const Text(
                              'DREAMEATS',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.deepGreen,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        AnimatedOpacity(
                          duration: AppMotion.base,
                          opacity: _isLast ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: _isLast,
                            child: TextButton(
                              onPressed: () => _goToAuth(context),
                              style: TextButton.styleFrom(foregroundColor: AppTheme.mutedGrey),
                              child: const Text('SKIP'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _slides.length,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                    ),
                  ),

                  // Pagination + CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.xxl),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (index) {
                            final isActive = _currentPage == index;
                            return AnimatedContainer(
                              duration: AppMotion.base,
                              curve: AppMotion.enter,
                              margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                              width: isActive ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primaryGreen : AppTheme.hairline,
                                borderRadius: AppRadius.rPill,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        DsButton(
                          label: _isLast ? 'GET STARTED' : 'CONTINUE',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _nextOrFinish,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: AppSpace.sm),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpace.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Illustration(slide: slide, height: compact ? 190 : 280),
                SizedBox(height: compact ? AppSpace.xl : AppSpace.x3),
                Semantics(
                  header: true,
                  child: Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.deepGreen,
                      height: 1.15,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15.5, color: AppTheme.mutedGrey, height: 1.55),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Illustration extends StatelessWidget {
  final _Slide slide;
  final double height;
  const _Illustration({required this.slide, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: AppRadius.rXl,
        boxShadow: AppTheme.clientElevatedShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative concentric rings
          for (final d in const [1.0, 0.72, 0.46])
            Positioned.fill(
              child: Center(
                child: FractionallySizedBox(
                  heightFactor: d * 1.5,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.07 + (1 - d) * 0.05)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Hero icon
          Container(
            width: height * 0.4,
            height: height * 0.4,
            decoration: BoxDecoration(
              color: AppTheme.limeAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.limeAccent.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(slide.icon, size: height * 0.2, color: AppTheme.deepGreen),
          ),
          // Floating chip
          Positioned(
            bottom: AppSpace.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm + 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.rPill,
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(slide.chipIcon, size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    slide.chip,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.deepGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
