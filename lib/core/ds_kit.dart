import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
// Pressable — tactile scale feedback, hit target never under 44 pt
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
                minimumSize: const Size(44, 44),
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
          constraints: const BoxConstraints(minHeight: 44),
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

enum DsButtonVariant { primary, dark, secondary, ghost, danger }

class DsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final DsButtonVariant variant;

  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.variant = DsButtonVariant.primary,
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
          if (icon != null) ...[
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl, vertical: AppSpace.md),
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
                                  Text(
                                    'GHS ${AppTheme.formatPrice(deal.discountedPrice)}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 21,
                                      letterSpacing: -0.6,
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
                        DsPill(label: deal.pickupWindow, icon: Icons.schedule_rounded, tone: DsTone.neutral),
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
      button: true,
      label: isFavorite ? 'Remove from favourites' : 'Save to favourites',
      child: DsPressable(
        onTap: onTap,
        pressedScale: 0.88,
        child: SizedBox(
          width: 44,
          height: 44,
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
