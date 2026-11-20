import 'package:flutter/material.dart';
import '../../core/ds_kit.dart';
import '../../core/theme.dart';

/// One selling point shown in the wide-screen brand panel.
class AuthBenefit {
  final IconData icon;
  final String title;
  final String subtitle;
  const AuthBenefit(this.icon, this.title, this.subtitle);
}

/// The frame every signed-out screen shares (sign in / create account, forgot
/// password, reset password).
///
/// * Phones and small tablets: a deep-green brand band with the form card
///   resting on it.
/// * Wide screens (>= 768): brand showcase on the left, the form on the right.
///
/// The screen supplies only its form as [child]; the frame, brand and
/// responsive behaviour live here so the three screens cannot drift apart.
class AuthShell extends StatelessWidget {
  static const double wideBreakpoint = 768;

  final Widget child;

  /// Brand headline. Wide screens show `headline` + `subhead` as one block; the
  /// compact band shows them only when [showHeadlineOnCompact] is true.
  final String headline;
  final String? subhead;
  final String? description;
  final String? eyebrow;
  final IconData eyebrowIcon;
  final List<AuthBenefit> benefits;
  final bool showHeadlineOnCompact;

  /// When set, a back control is shown (arrow on the band, pill on wide).
  final VoidCallback? onBack;
  final String backLabel;

  /// Small print under the form.
  final Widget? footer;

  /// Optional fade-in for the compact layout.
  final Animation<double>? fade;

  const AuthShell({
    super.key,
    required this.child,
    required this.headline,
    this.subhead,
    this.description,
    this.eyebrow,
    this.eyebrowIcon = Icons.eco_outlined,
    this.benefits = const [],
    this.showHeadlineOnCompact = true,
    this.onBack,
    this.backLabel = 'Back',
    this.footer,
    this.fade,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    return wide ? _buildWide(context) : _buildCompact(context);
  }

  // ── Compact ────────────────────────────────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bandHeight = top + (showHeadlineOnCompact ? 260 : 176);
    final topPad = top + (onBack != null ? AppSpace.x5 + AppSpace.xs : AppSpace.xl);

    Widget content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.gutter, topPad, AppSpace.gutter, AppSpace.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _brandBlock(),
              const SizedBox(height: AppSpace.xxl),
              DsCard(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: child,
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpace.xl),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
    if (fade != null) content = FadeTransition(opacity: fade!, child: content);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: bandHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
                ),
              ),
            ),
            content,
            if (onBack != null)
              Positioned(
                top: top + AppSpace.xs,
                left: AppSpace.sm,
                child: IconButton(
                  tooltip: backLabel,
                  onPressed: onBack,
                  style: IconButton.styleFrom(foregroundColor: AppTheme.pureWhite),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _brandBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _brandMark(size: 44, textSize: 22),
        if (showHeadlineOnCompact) ...[
          const SizedBox(height: AppSpace.lg),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.pureWhite,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          if (subhead != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              subhead!,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTheme.mintGreen),
            ),
          ],
        ],
      ],
    );
  }

  Widget _brandMark({required double size, required double textSize}) {
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: AppRadius.rSm),
          child: ClipRRect(
            borderRadius: AppRadius.rSm,
            child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover, excludeFromSemantics: true),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Text(
          'DreamEats',
          style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w900, color: AppTheme.pureWhite, letterSpacing: -0.6),
        ),
      ],
    );
  }

  // ── Wide ───────────────────────────────────────────────────────────────────

  Widget _buildWide(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Row(
        children: [
          Expanded(flex: 5, child: _showcase()),
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x5, vertical: AppSpace.x3),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            child,
                            if (footer != null) ...[
                              const SizedBox(height: AppSpace.xl),
                              footer!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (onBack != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.lg, 0, 0),
                        child: TextButton.icon(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(backLabel),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.charcoal,
                            backgroundColor: AppTheme.lightGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _showcase() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.limeAccent.withValues(alpha: 0.08)),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4, vertical: AppSpace.x5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _brandMark(size: 44, textSize: 24),
                        const SizedBox(height: AppSpace.x5),
                        if (eyebrow != null) ...[
                          DsPill(label: eyebrow!, icon: eyebrowIcon),
                          const SizedBox(height: AppSpace.xl),
                        ],
                        Semantics(
                          header: true,
                          child: Text(
                            subhead == null ? headline : '$headline\n$subhead',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.pureWhite,
                              letterSpacing: -1.2,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: AppSpace.lg),
                          Text(
                            description!,
                            style: const TextStyle(fontSize: 15.5, color: AppTheme.mintGreen, height: 1.6),
                          ),
                        ],
                        if (benefits.isNotEmpty) const SizedBox(height: AppSpace.x3),
                        for (var i = 0; i < benefits.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpace.md),
                          _benefit(benefits[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(AuthBenefit b) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite.withValues(alpha: 0.08),
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppTheme.pureWhite.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppTheme.pureWhite.withValues(alpha: 0.10), borderRadius: AppRadius.rSm),
            child: Icon(b.icon, size: 20, color: AppTheme.limeAccent),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.pureWhite)),
                const SizedBox(height: AppSpace.xxs),
                Text(b.subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.mintGreen, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered icon + title + subtitle used at the top of single-purpose auth
/// cards (forgot password, reset password, their success states).
class AuthStatusHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthStatusHeader({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: DsIconBadge(icon: icon, size: 72)),
        const SizedBox(height: AppSpace.xl),
        Semantics(
          header: true,
          child: Text(title, textAlign: TextAlign.center, style: text.headlineLarge),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(subtitle, textAlign: TextAlign.center, style: text.bodyMedium),
      ],
    );
  }
}
