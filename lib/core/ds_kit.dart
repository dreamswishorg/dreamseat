import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'theme.dart';

/// DreamEats shared customer kit.
///
/// Every piece reads its values from [AppTheme], [AppSpace], [AppRadius] and
/// [AppMotion] — no raw colours or one-off radii — so a change to the theme
/// reaches every page that uses the kit.

// ─────────────────────────────────────────────────────────────────────────────
// Tones
// ─────────────────────────────────────────────────────────────────────────────

enum DsTone { brand, deal, warn, danger, info, neutral, dark }

class _ToneColors {
  final Color fg;
  final Color bg;
  final Color solid;
  const _ToneColors(this.fg, this.bg, this.solid);
}

_ToneColors _tone(DsTone t) {
  switch (t) {
    case DsTone.brand:
      return const _ToneColors(AppTheme.primaryGreen, AppTheme.lightGreenBg, AppTheme.primaryGreen);
    case DsTone.deal:
      return const _ToneColors(AppTheme.dealOrange, AppTheme.dealOrangeBg, AppTheme.dealOrange);
    case DsTone.warn:
      return const _ToneColors(AppTheme.goldAccent, Color(0xFFFFF6E0), AppTheme.goldAccent);
    case DsTone.danger:
      return const _ToneColors(AppTheme.errorRed, Color(0xFFFEECEC), AppTheme.errorRed);
    case DsTone.info:
      return const _ToneColors(AppTheme.infoBlue, AppTheme.infoBlueBg, AppTheme.infoBlue);
    case DsTone.neutral:
      return const _ToneColors(AppTheme.charcoal, AppTheme.lightGrey, AppTheme.charcoal);
    case DsTone.dark:
      return const _ToneColors(AppTheme.pureWhite, AppTheme.deepGreen, AppTheme.deepGreen);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pressable — tactile scale feedback (callers keep the hit target at 48 dp+)
// ─────────────────────────────────────────────────────────────────────────────

class DsPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double pressedScale;

  const DsPressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.pressedScale = 0.97,
  });

  @override
  State<DsPressable> createState() => _DsPressableState();
}

class _DsPressableState extends State<DsPressable> {
  bool _down = false;
  bool _hover = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final enabled = widget.onTap != null;
    final scale = !enabled || reduce
        ? 1.0
        : _down
            ? widget.pressedScale
            : (_hover ? 1.01 : 1.0);

    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: reduce ? Duration.zero : AppMotion.fast,
            curve: AppMotion.enter,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card surface
// ─────────────────────────────────────────────────────────────────────────────

class DsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final bool elevated;
  final bool bordered;

  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.onTap,
    this.radius = AppRadius.lg,
    this.color,
    this.elevated = true,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: AppTheme.hairline) : null,
        boxShadow: elevated ? AppTheme.clientCardShadow : null,
      ),
      child: child,
    );
    return onTap == null ? card : DsPressable(onTap: onTap, child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class DsSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const DsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xxl, AppSpace.gutter, AppSpace.md),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppTheme.charcoal,
                      height: 1.2,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 13.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: AppSpace.xxs),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill (tag / status)
// ─────────────────────────────────────────────────────────────────────────────

class DsPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final DsTone tone;
  final bool solid;
  final bool compact;

  const DsPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = DsTone.brand,
    this.solid = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = _tone(tone);
    final fg = solid ? (tone == DsTone.neutral ? AppTheme.pureWhite : AppTheme.pureWhite) : c.fg;
    final bg = solid ? c.solid : c.bg;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? AppSpace.sm : AppSpace.md, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.rPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: fg),
            const SizedBox(width: AppSpace.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: compact ? 11 : 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip (replaces emoji-labelled quick filters)
// ─────────────────────────────────────────────────────────────────────────────

class DsFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const DsFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppTheme.pureWhite : AppTheme.charcoal;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: DsPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          decoration: BoxDecoration(
            color: selected ? AppTheme.deepGreen : AppTheme.pureWhite,
            borderRadius: AppRadius.rPill,
            border: Border.all(color: selected ? AppTheme.deepGreen : AppTheme.hairline),
            boxShadow: selected ? AppTheme.softShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: selected ? AppTheme.limeAccent : AppTheme.mutedGrey),
                const SizedBox(width: AppSpace.sm),
              ],
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────────────────────

enum DsButtonVariant { primary, dark, secondary, ghost, danger, outline }

class DsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// A custom leading widget (e.g. a brand logo). Wins over [icon].
  final Widget? leading;
  final bool loading;
  final bool expand;
  final DsButtonVariant variant;

  /// Overrides the default 24 pt horizontal padding (for half-width buttons).
  final EdgeInsetsGeometry? padding;

  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.loading = false,
    this.expand = true,
    this.variant = DsButtonVariant.primary,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    Border? border;
    switch (variant) {
      case DsButtonVariant.primary:
        bg = AppTheme.primaryGreen;
        fg = AppTheme.pureWhite;
      case DsButtonVariant.dark:
        bg = AppTheme.deepGreen;
        fg = AppTheme.pureWhite;
      case DsButtonVariant.secondary:
        bg = AppTheme.pureWhite;
        fg = AppTheme.primaryGreen;
        border = Border.all(color: AppTheme.primaryGreen, width: 1.5);
      case DsButtonVariant.ghost:
        bg = AppTheme.lightGreenBg;
        fg = AppTheme.deepGreen;
      case DsButtonVariant.danger:
        bg = const Color(0xFFFEECEC);
        fg = AppTheme.errorRed;
      case DsButtonVariant.outline:
        bg = AppTheme.pureWhite;
        fg = AppTheme.charcoal;
        border = Border.all(color: AppTheme.hairline, width: 1.5);
    }

    final enabled = onPressed != null && !loading;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg, backgroundColor: fg.withValues(alpha: 0.2)),
          )
        else ...[
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpace.sm),
          ] else if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: AppSpace.sm),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.1),
            ),
          ),
        ],
      ],
    );

    return Opacity(
      opacity: onPressed == null && !loading ? 0.45 : 1,
      child: DsPressable(
        onTap: enabled ? onPressed : null,
        semanticLabel: label,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpace.xxl, vertical: AppSpace.md),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.rMd, border: border),
          child: content,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon badge (tinted circle / squircle)
// ─────────────────────────────────────────────────────────────────────────────

class DsIconBadge extends StatelessWidget {
  final IconData icon;
  final DsTone tone;
  final double size;

  const DsIconBadge({super.key, required this.icon, this.tone = DsTone.brand, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final c = _tone(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(size * 0.34)),
      child: Icon(icon, size: size * 0.5, color: c.fg),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat tile
// ─────────────────────────────────────────────────────────────────────────────

class DsStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final DsTone tone;

  const DsStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = DsTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      radius: AppRadius.md,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsIconBadge(icon: icon, tone: tone, size: 36),
          const SizedBox(height: AppSpace.md),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AppTheme.charcoal),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Remote image with branded fallback
// ─────────────────────────────────────────────────────────────────────────────

/// 'GHS 15' / 'GHS 15.50' — the one way a price is written.
String dsPrice(num value) => 'GHS ${AppTheme.formatPrice(value)}';

IconData dsCategoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('bakery')) return Icons.bakery_dining_rounded;
  if (c.contains('grocery')) return Icons.local_grocery_store_rounded;
  if (c.contains('fruit') || c.contains('vegetable')) return Icons.eco_rounded;
  if (c.contains('hotel') || c.contains('buffet')) return Icons.room_service_rounded;
  if (c.contains('restaurant')) return Icons.restaurant_rounded;
  if (c.contains('snack') || c.contains('drink')) return Icons.local_cafe_rounded;
  return Icons.fastfood_rounded;
}

class DsMedia extends StatelessWidget {
  final String url;
  final String category;
  final double? height;
  final BorderRadius borderRadius;

  const DsMedia({
    super.key,
    required this.url,
    required this.category,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppTheme.lightGreenBg,
      alignment: Alignment.center,
      child: Icon(dsCategoryIcon(category), color: AppTheme.primaryGreen, size: 40),
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: AppMotion.base,
                placeholder: (_, _) => Container(color: AppTheme.lightGrey),
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deal card — the one place a surplus-food deal is drawn
// ─────────────────────────────────────────────────────────────────────────────

class DsDealCard extends StatelessWidget {
  final FoodDeal deal;
  final double distance;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const DsDealCard({
    super.key,
    required this.deal,
    required this.distance,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  bool get _closingSoon {
    final w = deal.pickupWindow.toLowerCase();
    return w.contains('minutes') || (w.contains('pm') && DateTime.now().hour >= 17);
  }

  @override
  Widget build(BuildContext context) {
    final percent = deal.originalPrice > 0
        ? (((deal.originalPrice - deal.discountedPrice) / deal.originalPrice) * 100).round()
        : 0;
    final low = deal.quantityRemaining <= 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: DsPressable(
        onTap: onTap,
        pressedScale: 0.985,
        semanticLabel: '${deal.title} from ${deal.businessName}, '
            'GHS ${AppTheme.formatPrice(deal.discountedPrice)}',
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: AppRadius.rLg,
            border: Border.all(color: AppTheme.hairline),
            boxShadow: AppTheme.clientCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  DsMedia(
                    url: deal.imageUrl,
                    category: deal.category,
                    height: 168,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  ),
                  // Legibility scrim for the badges
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [Colors.black.withValues(alpha: 0.28), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpace.md,
                    left: AppSpace.md,
                    right: 64,
                    child: Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      children: [
                        if (percent > 0)
                          DsPill(label: '$percent% OFF', tone: DsTone.deal, solid: true, compact: true),
                        if (_closingSoon)
                          const DsPill(label: 'CLOSING SOON', icon: Icons.bolt_rounded, tone: DsTone.dark, solid: true, compact: true),
                      ],
                    ),
                  ),
                  Positioned(
                    top: AppSpace.sm,
                    right: AppSpace.sm,
                    child: _FavoriteButton(isFavorite: isFavorite, onTap: onFavorite),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deal.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        const Icon(Icons.near_me_rounded, size: 13, color: AppTheme.primaryGreen),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      deal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.4,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'GHS ${AppTheme.formatPrice(deal.discountedPrice)}',
                                        style: const TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 21,
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Flexible(
                                    child: Text(
                                      'GHS ${AppTheme.formatPrice(deal.originalPrice)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppTheme.mutedGrey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                low ? 'Only ${deal.quantityRemaining} left' : '${deal.quantityRemaining} available',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: low ? AppTheme.dealOrange : AppTheme.mutedGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(child: DsPill(label: deal.pickupWindow, icon: Icons.schedule_rounded, tone: DsTone.neutral)),
                      ],
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
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: DsPressable(
        onTap: onTap,
        pressedScale: 0.88,
        semanticLabel: isFavorite ? 'Remove from favourites' : 'Save to favourites',
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.base,
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(isFavorite),
                  size: 19,
                  color: isFavorite ? AppTheme.errorRed : AppTheme.mutedGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deal tile — compact card for horizontal carousels
// ─────────────────────────────────────────────────────────────────────────────

class DsDealTile extends StatelessWidget {
  final FoodDeal deal;
  final double distance;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final double width;

  const DsDealTile({
    super.key,
    required this.deal,
    required this.distance,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    this.width = 232,
  });

  @override
  Widget build(BuildContext context) {
    final percent = deal.originalPrice > 0
        ? (((deal.originalPrice - deal.discountedPrice) / deal.originalPrice) * 100).round()
        : 0;
    return SizedBox(
      width: width,
      child: DsPressable(
        onTap: onTap,
        pressedScale: 0.975,
        semanticLabel: '${deal.title}, GHS ${AppTheme.formatPrice(deal.discountedPrice)}',
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: AppRadius.rLg,
            border: Border.all(color: AppTheme.hairline),
            boxShadow: AppTheme.clientCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  DsMedia(
                    url: deal.imageUrl,
                    category: deal.category,
                    height: 132,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  ),
                  if (percent > 0)
                    Positioned(
                      top: AppSpace.sm,
                      left: AppSpace.sm,
                      child: DsPill(label: '$percent% OFF', tone: DsTone.deal, solid: true, compact: true),
                    ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _FavoriteButton(isFavorite: isFavorite, onTap: onFavorite),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      deal.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'GHS ${AppTheme.formatPrice(deal.discountedPrice)}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Text(
                            'GHS ${AppTheme.formatPrice(deal.originalPrice)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppTheme.mutedGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        const Icon(Icons.near_me_rounded, size: 13, color: AppTheme.mutedGrey),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: AppSpace.md),
                        const Icon(Icons.schedule_rounded, size: 13, color: AppTheme.mutedGrey),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text(
                            deal.pickupWindow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Text field — label above, hint inside, error under. Styling comes from the
// theme's inputDecorationTheme so a theme change reaches every form.
// ─────────────────────────────────────────────────────────────────────────────

class DsTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final String? prefixText;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const DsTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.prefixText,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.validator,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            textInputAction: textInputAction,
            obscureText: obscureText,
            enableSuggestions: !obscureText,
            autocorrect: !obscureText,
            autofillHints: autofillHints,
            maxLines: obscureText ? 1 : maxLines,
            enabled: enabled,
            readOnly: readOnly,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              helperMaxLines: 2,
              errorMaxLines: 2,
              prefixIcon: icon == null ? null : Icon(icon, size: 20),
              prefixText: prefixText,
              prefixStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}

/// Show/hide button for a password [DsTextField] — 44 pt target, labelled.
class DsObscureToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onToggle;
  const DsObscureToggle({super.key, required this.obscured, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      onPressed: onToggle,
      icon: Icon(obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown field — same label/field rhythm as DsTextField
// ─────────────────────────────────────────────────────────────────────────────

class DsDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  const DsDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Semantics(
          label: label,
          child: DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            borderRadius: AppRadius.rMd,
            dropdownColor: AppTheme.pureWhite,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.mutedGrey),
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
            decoration: InputDecoration(prefixIcon: icon == null ? null : Icon(icon, size: 20)),
            items: [
              for (final i in items) DropdownMenuItem<T>(value: i, child: Text(itemLabel(i))),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented switch — 2+ options, the selected one on the dark brand surface
// ─────────────────────────────────────────────────────────────────────────────

class DsSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const DsSegmented({super.key, required this.labels, required this.selected, required this.onChanged})
      : assert(labels.length >= 2);

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final n = labels.length;
    return Container(
      height: 56,
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: AppRadius.rPill),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: reduce ? Duration.zero : AppMotion.base,
            curve: AppMotion.enter,
            alignment: Alignment(-1 + 2 * selected / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.deepGreen,
                  borderRadius: AppRadius.rPill,
                  boxShadow: AppTheme.softShadow,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Semantics(
                    selected: i == selected,
                    inMutuallyExclusiveGroup: true,
                    child: DsPressable(
                      onTap: () => onChanged(i),
                      pressedScale: 0.98,
                      semanticLabel: labels[i],
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: reduce ? Duration.zero : AppMotion.base,
                          // Built on the theme's label style: this widget replaces,
                          // not merges, the ambient style, so the family must come along.
                          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                fontSize: 14.5,
                                fontWeight: i == selected ? FontWeight.w800 : FontWeight.w700,
                                color: i == selected ? AppTheme.pureWhite : AppTheme.charcoal,
                                letterSpacing: -0.1,
                              ),
                          child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Choice tile — one option of a mutually exclusive group (account type, …)
// ─────────────────────────────────────────────────────────────────────────────

class DsChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const DsChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final badge = compact ? 36.0 : 44.0;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: DsPressable(
        onTap: onTap,
        pressedScale: 0.985,
        semanticLabel: subtitle == null ? title : '$title. $subtitle',
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.base,
          curve: AppMotion.enter,
          padding: EdgeInsets.all(compact ? AppSpace.md : AppSpace.lg),
          decoration: BoxDecoration(
            color: selected ? AppTheme.lightGreenBg : AppTheme.pureWhite,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: selected ? AppTheme.primaryGreen : AppTheme.hairline, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: reduce ? Duration.zero : AppMotion.base,
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryGreen : AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(badge * 0.34),
                ),
                child: Icon(icon, size: badge * 0.5, color: selected ? AppTheme.pureWhite : AppTheme.charcoal),
              ),
              SizedBox(width: compact ? AppSpace.sm : AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 13.5 : 15.5,
                        fontWeight: FontWeight.w800,
                        color: selected ? AppTheme.deepGreen : AppTheme.charcoal,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.mutedGrey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: AppSpace.sm),
                AnimatedContainer(
                  duration: reduce ? Duration.zero : AppMotion.base,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppTheme.primaryGreen : Colors.transparent,
                    border: Border.all(color: selected ? AppTheme.primaryGreen : AppTheme.hairline, width: 2),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 15, color: AppTheme.pureWhite) : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step progress — "Step 1 of 2" with a bar per step
// ─────────────────────────────────────────────────────────────────────────────

class DsStepProgress extends StatelessWidget {
  /// Zero-based current step.
  final int step;
  final int total;
  final String label;

  const DsStepProgress({super.key, required this.step, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      label: 'Step ${step + 1} of $total, $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.2),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                'Step ${step + 1} of $total',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.mutedGrey),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: reduce ? Duration.zero : AppMotion.base,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= step ? AppTheme.primaryGreen : AppTheme.hairline,
                      borderRadius: AppRadius.rPill,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu group + tile — grouped list rows (profile, settings, privacy, help)
// ─────────────────────────────────────────────────────────────────────────────

class DsMenuGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const DsMenuGroup({
    super.key,
    required this.children,
    this.title,
    this.margin = const EdgeInsets.only(bottom: AppSpace.xl),
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const Divider(height: 1, indent: 68));
      rows.add(children[i]);
    }
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.sm),
              child: Semantics(
                header: true,
                child: Text(
                  title!,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.mutedGrey, letterSpacing: 0.2),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: AppTheme.hairline),
              boxShadow: AppTheme.clientCardShadow,
            ),
            child: Material(
              color: AppTheme.pureWhite,
              borderRadius: AppRadius.rLg,
              clipBehavior: Clip.antiAlias,
              child: Column(children: rows),
            ),
          ),
        ],
      ),
    );
  }
}

class DsMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final DsTone tone;
  final VoidCallback? onTap;

  /// Replaces the chevron (a switch, a value, a pill…).
  final Widget? trailing;

  const DsMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.tone = DsTone.brand,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final danger = tone == DsTone.danger;
    return Semantics(
      button: onTap != null,
      label: subtitle == null ? label : '$label. $subtitle',
      excludeSemantics: trailing == null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
            child: Row(
              children: [
                DsIconBadge(icon: icon, tone: tone, size: 40),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: danger ? AppTheme.errorRed : AppTheme.charcoal,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          subtitle!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.mutedGrey, height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  trailing!,
                ] else if (onTap != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  const Icon(Icons.chevron_right_rounded, size: 22, color: AppTheme.mutedGrey),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero card — the dark brand surface for the one number/idea a page leads with
// ─────────────────────────────────────────────────────────────────────────────

class DsHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const DsHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.xl),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: AppRadius.rLg,
        boxShadow: AppTheme.clientElevatedShadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.rLg,
        child: Stack(
          children: [
            Positioned(
              top: -48,
              right: -48,
              child: IgnorePointer(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.limeAccent.withValues(alpha: 0.10)),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
    return onTap == null ? card : DsPressable(onTap: onTap, pressedScale: 0.985, child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen bar — the header of a pushed (non-tab) screen
// ─────────────────────────────────────────────────────────────────────────────

PreferredSizeWidget dsScreenBar(
  BuildContext context, {
  required String title,
  VoidCallback? onBack,
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(title),
    leading: IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: onBack ?? () => Navigator.maybePop(context),
    ),
    actions: actions,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, thickness: 1, color: AppTheme.hairline),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar — photo (network or just-picked bytes) or initials, optional edit badge
// ─────────────────────────────────────────────────────────────────────────────

class DsAvatar extends StatelessWidget {
  final String name;
  final String? url;

  /// A just-picked photo, shown immediately while it uploads.
  final Uint8List? bytes;
  final double size;
  final bool busy;

  /// When set, the avatar is a button with a camera badge.
  final VoidCallback? onEdit;

  const DsAvatar({
    super.key,
    required this.name,
    this.url,
    this.bytes,
    this.size = 64,
    this.busy = false,
    this.onEdit,
  });

  Widget _initials() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      alignment: Alignment.center,
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w900, color: AppTheme.pureWhite),
      ),
    );
  }

  Widget _face() {
    final u = url?.trim() ?? '';
    if (bytes != null) return Image.memory(bytes!, fit: BoxFit.cover);
    if (u.isEmpty) return _initials();
    return CachedNetworkImage(
      imageUrl: u,
      fit: BoxFit.cover,
      fadeInDuration: AppMotion.base,
      placeholder: (_, _) => Container(color: AppTheme.lightGreenBg),
      errorWidget: (_, _, _) => _initials(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = size * 0.36 < 26 ? 26.0 : size * 0.36;
    final avatar = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.pureWhite, width: 3),
              boxShadow: AppTheme.softShadow,
            ),
            child: ClipOval(child: _face()),
          ),
          if (onEdit != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.pureWhite, width: 2),
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpace.xs + 1),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureWhite),
                      )
                    : Icon(Icons.camera_alt_rounded, color: AppTheme.pureWhite, size: badge * 0.52),
              ),
            ),
        ],
      ),
    );
    if (onEdit == null) return avatar;
    return DsPressable(onTap: onEdit, pressedScale: 0.95, semanticLabel: 'Change profile photo', child: avatar);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field — compact, label-less, with a clear button while there is text
// ─────────────────────────────────────────────────────────────────────────────

class DsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const DsSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: hint,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search_rounded, size: 22, color: AppTheme.primaryGreen),
            suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                      onClear?.call();
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
