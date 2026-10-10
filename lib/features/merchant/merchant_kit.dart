import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/web_utils.dart';
import '../../models/models.dart';

export '../../core/responsive.dart';

/// Destination tabs inside the merchant portal shell.
enum MTab { home, orders, listings, verify, financials, impact, shop, reviews, support }

/// Tabs surfaced in the merchant shell navigation, in display order.
const List<MTab> kMerchantNavTabs = [MTab.home, MTab.orders, MTab.listings, MTab.verify, MTab.shop];

/// Design tokens and building blocks for the DreamEats merchant portal.
class MK {
  MK._();

  static const Color canvas = Color(0xFFF6F8F5);
  static const Color ink = AppTheme.charcoal;
  static const Color inkSoft = AppTheme.mutedGrey;
  static const Color line = Color(0xFFE7ECE6);
  static const Color brand = AppTheme.primaryGreen;
  static const Color brandDeep = Color(0xFF0F5132);
  static const Color brandGlow = Color(0xFF34D399);
  static const Color amber = Color(0xFFFFB300);
  static const Color coral = Color(0xFFFF6B4A);
  static const Color sky = Color(0xFF2563EB);
  static const Color grape = Color(0xFF7C3AED);
  static const Color danger = AppTheme.errorRed;

  static const double rLg = 26;
  static const double rMd = 20;
  static const double rSm = 14;

  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: brand.withValues(alpha: 0.04),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get shadowLift => [
        BoxShadow(
          color: ink.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: brand.withValues(alpha: 0.10),
          blurRadius: 34,
          offset: const Offset(0, 16),
        ),
      ];

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B3D24), Color(0xFF1E7A46), Color(0xFF2E9C5B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static String money(num value) => 'GHS ${AppTheme.formatPrice(value)}';

  static String shortDate(DateTime d) => DateFormat('d MMM').format(d);

  static String clock(DateTime d) => DateFormat('h:mm a').format(d);

  static String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(d);
  }
}

/// Everything the portal knows about an order status.
class OrderStatusMeta {
  final String key;
  final String label;
  final String shortLabel;
  final String emoji;
  final Color color;
  final IconData icon;
  final String? next;
  final String nextLabel;

  const OrderStatusMeta({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.emoji,
    required this.color,
    required this.icon,
    this.next,
    this.nextLabel = '',
  });

  bool get isClosed => key == 'collected' || key == 'cancelled' || key == 'expired';
}

class OrderStatuses {
  OrderStatuses._();

  static const Map<String, OrderStatusMeta> _all = {
    'reserved': OrderStatusMeta(
      key: 'reserved',
      label: 'Order received',
      shortLabel: 'New',
      emoji: '🧾',
      color: Color(0xFFF97316),
      icon: Icons.inbox_rounded,
      next: 'preparing',
      nextLabel: 'Start preparing',
    ),
    'preparing': OrderStatusMeta(
      key: 'preparing',
      label: 'In the kitchen',
      shortLabel: 'Preparing',
      emoji: '🍳',
      color: Color(0xFFD97706),
      icon: Icons.soup_kitchen_rounded,
      next: 'ready',
      nextLabel: 'Mark ready',
    ),
    'ready': OrderStatusMeta(
      key: 'ready',
      label: 'Ready for pickup',
      shortLabel: 'Ready',
      emoji: '📦',
      color: MK.brand,
      icon: Icons.shopping_bag_rounded,
      next: 'collected',
      nextLabel: 'Hand over',
    ),
    'out_for_delivery': OrderStatusMeta(
      key: 'out_for_delivery',
      label: 'Out for delivery',
      shortLabel: 'On the way',
      emoji: '🛵',
      color: MK.sky,
      icon: Icons.two_wheeler_rounded,
      next: 'collected',
      nextLabel: 'Complete',
    ),
    'collected': OrderStatusMeta(
      key: 'collected',
      label: 'Completed',
      shortLabel: 'Done',
      emoji: '✅',
      color: Color(0xFF0F766E),
      icon: Icons.check_circle_rounded,
    ),
    'cancelled': OrderStatusMeta(
      key: 'cancelled',
      label: 'Cancelled',
      shortLabel: 'Cancelled',
      emoji: '❌',
      color: MK.danger,
      icon: Icons.cancel_rounded,
    ),
    'expired': OrderStatusMeta(
      key: 'expired',
      label: 'Expired',
      shortLabel: 'Expired',
      emoji: '⌛',
      color: MK.inkSoft,
      icon: Icons.hourglass_bottom_rounded,
    ),
  };

  static const List<String> flowKeys = [
    'reserved',
    'preparing',
    'ready',
    'out_for_delivery',
    'collected',
  ];

  static OrderStatusMeta of(String status) =>
      _all[status] ??
      OrderStatusMeta(
        key: status,
        label: status,
        shortLabel: status,
        emoji: '•',
        color: MK.inkSoft,
        icon: Icons.help_outline_rounded,
      );

  static List<OrderStatusMeta> get all => _all.values.toList();
}

// ─────────────────────────────────────────────────────────────
// Motion
// ─────────────────────────────────────────────────────────────

/// Fades and slides its child in once, [delay] ms after it is built.
class MReveal extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;
  final Offset offset;

  const MReveal({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 380),
    this.offset = const Offset(0, 14),
  });

  @override
  State<MReveal> createState() => _MRevealState();
}

class _MRevealState extends State<MReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.delay == 0) {
      _c.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
}

/// Counts from 0 to [value] with an easing curve.
class MCountUp extends StatefulWidget {
  final double value;
  final int decimals;
  final String prefix;
  final String suffix;
  final Duration duration;
  final TextStyle? style;

  const MCountUp(
    this.value, {
    super.key,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
    this.style,
  });

  @override
  State<MCountUp> createState() => _MCountUpState();
}

class _MCountUpState extends State<MCountUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late Animation<double> _tween;

  @override
  void initState() {
    super.initState();
    _tween = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    _c.forward();
  }

  @override
  void didUpdateWidget(MCountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _tween = Tween<double>(begin: old.value, end: widget.value).animate(
        CurvedAnimation(parent: _c..reset(), curve: Curves.easeOutCubic),
      );
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Text(
        '${widget.prefix}${NumberFormat.decimalPatternDigits(decimalDigits: widget.decimals).format(_tween.value)}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}

/// Soft breathing dot used for live signals.
class MPulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const MPulseDot({super.key, required this.color, this.size = 8});

  @override
  State<MPulseDot> createState() => _MPulseDotState();
}

class _MPulseDotState extends State<MPulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45 * _c.value),
                blurRadius: 10 * _c.value + 2,
                spreadRadius: 3 * _c.value,
              ),
            ],
          ),
        ),
      );
}

/// Tactile press: shrinks slightly and taps haptically.
class MPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  const MPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.975,
  });

  @override
  State<MPressable> createState() => _MPressableState();
}

class _MPressableState extends State<MPressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null ? null : (_) => _set(true),
          onTapCancel: widget.onTap == null ? null : () => _set(false),
          onTapUp: widget.onTap == null ? null : (_) => _set(false),
          onTap: widget.onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: _down ? widget.pressedScale : 1,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Surfaces
// ─────────────────────────────────────────────────────────────

class MCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool glow;

  const MCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(MK.rMd),
        border: Border.all(color: MK.line),
        boxShadow: glow ? MK.shadowLift : MK.shadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return MPressable(onTap: onTap, child: card);
  }
}

class MSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  const MSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? MK.brand;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: 11),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: MK.ink,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 11.5, color: MK.inkSoft, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class MPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool solid;
  final bool pulse;
  final double fontSize;

  const MPill(
    this.label, {
    super.key,
    required this.color,
    this.icon,
    this.solid = false,
    this.pulse = false,
    this.fontSize = 10.5,
  });

  @override
  Widget build(BuildContext context) {
    final fg = solid ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: solid ? 1 : 0.28), width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            MPulseDot(color: fg, size: 6),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrollable, animated single-select chip row.
class MChipRow extends StatelessWidget {
  final List<String> items;
  final List<String> values;
  final int Function(String value) countOf;
  final String value;
  final ValueChanged<String> onChanged;

  const MChipRow({
    super.key,
    required this.items,
    required this.values,
    required this.value,
    required this.onChanged,
    required this.countOf,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final v = values[i];
          final selected = v == value;
          final count = countOf(v);
          return MPressable(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? MK.brand : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? MK.brand : MK.line, width: selected ? 1.4 : 1),
                boxShadow: selected
                    ? [BoxShadow(color: MK.brand.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))]
                    : const [],
              ),
              child: Row(
                children: [
                  Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : MK.ink,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withValues(alpha: 0.24) : const Color(0xFFF1F5F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: selected ? Colors.white : MK.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact stat tile with icon, animated value and caption.
class MStatTile extends StatelessWidget {
  final String label;
  final double value;
  final String caption;
  final IconData icon;
  final Color color;
  final int decimals;
  final String prefix;
  final String suffix;

  const MStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption = '',
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return MCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Transform.rotate(
                angle: math.pi / 2,
                child: Icon(Icons.chevron_right_rounded, size: 16, color: color.withValues(alpha: 0.45)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MCountUp(
            value,
            decimals: decimals,
            prefix: prefix,
            suffix: suffix,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: MK.ink,
              letterSpacing: -0.6,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: MK.inkSoft),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular gauge with an animated sweep.
class MGauge extends StatefulWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? center;

  const MGauge({
    super.key,
    required this.value,
    this.size = 92,
    this.stroke = 9,
    this.color = MK.brand,
    this.center,
  });

  @override
  State<MGauge> createState() => _MGaugeState();
}

class _MGaugeState extends State<MGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();

  @override
  void didUpdateWidget(MGauge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _GaugePainter(
              progress: Curves.easeOutCubic.transform(_c.value) * widget.value.clamp(0.0, 1.0),
              color: widget.color,
              stroke: widget.stroke,
            ),
            child: Center(child: widget.center),
          ),
        ),
      );
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;

  _GaugePainter({required this.progress, required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.14),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color.withValues(alpha: 0.55), color],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Controls
// ─────────────────────────────────────────────────────────────

enum MKind { primary, soft, ghost, danger }

class MButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final MKind kind;
  final bool expanded;
  final bool loading;
  final double height;

  const MButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.kind = MKind.primary,
    this.expanded = false,
    this.loading = false,
    this.height = 46,
  });

  Color get _fg => switch (kind) {
        MKind.primary => Colors.white,
        MKind.soft => MK.brand,
        MKind.ghost => MK.ink,
        MKind.danger => MK.danger,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final bg = switch (kind) {
      MKind.primary => MK.brand,
      MKind.soft => MK.brand.withValues(alpha: 0.10),
      MKind.ghost => Colors.transparent,
      MKind.danger => MK.danger.withValues(alpha: 0.08),
    };
    final border = switch (kind) {
      MKind.soft => MK.brand.withValues(alpha: 0.28),
      MKind.danger => MK.danger.withValues(alpha: 0.3),
      MKind.ghost => MK.line,
      MKind.primary => Colors.transparent,
    };

    return MPressable(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: height,
        width: expanded ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? bg : bg.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(MK.rSm),
          border: Border.all(color: border, width: 1.1),
          boxShadow: kind == MKind.primary && enabled
              ? [BoxShadow(color: MK.brand.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
              : const [],
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: _fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: _fg),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _fg, fontSize: 13.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Small round icon button used in card action rails.
class MIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? tooltip;
  final double size;

  const MIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = MK.inkSoft,
    this.tooltip,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final btn = MPressable(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: size * 0.46, color: color),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

// ─────────────────────────────────────────────────────────────
// Overlays
// ─────────────────────────────────────────────────────────────

class MToast {
  static void ok(BuildContext context, String message) => _show(context, message, MK.brand, Icons.check_circle_rounded);

  static void err(BuildContext context, String message) =>
      _show(context, message, MK.danger, Icons.error_outline_rounded);

  static void info(BuildContext context, String message) =>
      _show(context, message, MK.ink, Icons.info_outline_rounded);

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 84),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Rounded, keyboard-aware, desktop-width-capped bottom sheet.
Future<T?> showMSheet<T>(BuildContext context, {required Widget child, String? title, double maxWidth = 560}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _MSheetScaffold(title: title, maxWidth: maxWidth, child: child),
  );
}

class _MSheetScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final double maxWidth;

  const _MSheetScaffold({required this.child, this.title, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width > 700 ? 16 : 0,
            right: MediaQuery.of(context).size.width > 700 ? 16 : 0,
            bottom: MediaQuery.of(context).size.width > 700 ? 16 : 0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(20, 12, 20, insets + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: MK.line, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: MK.ink,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        MIconButton(icon: Icons.close_rounded, onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Flexible(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated success/failure confirmation dialog.
Future<void> showMResult(
  BuildContext context, {
  required String title,
  required String message,
  bool ok = true,
  String actionLabel = 'Continue',
  Widget? extra,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ResultBadge(success: ok),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MK.ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: MK.inkSoft, height: 1.45),
            ),
            if (extra != null) ...[const SizedBox(height: 16), extra],
            const SizedBox(height: 20),
            MButton(
              actionLabel,
              expanded: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResultBadge extends StatefulWidget {
  final bool success;
  const _ResultBadge({required this.success});

  @override
  State<_ResultBadge> createState() => _ResultBadgeState();
}

class _ResultBadgeState extends State<_ResultBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? MK.brand : MK.danger;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(76, 76),
              painter: _RingPainter(
                progress: Curves.easeOutCubic.transform(_c.value),
                color: color,
              ),
            ),
            Icon(
              widget.success ? Icons.check_rounded : Icons.priority_high_rounded,
              size: 34,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(
      Rect.fromCircle(center: rect.center, radius: size.width / 2 - 4),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Vertical labelled row used inside detail sheets.
class MDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const MDetailRow({super.key, required this.label, required this.value, this.valueColor, this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: MK.inkSoft),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: MK.inkSoft, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? MK.ink,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Horizontal fulfilment timeline for an order.
class MStatusTimeline extends StatelessWidget {
  final String status;
  const MStatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final meta = OrderStatuses.of(status);
    if (meta.isClosed && status == 'cancelled') {
      return Row(
        children: [
          Icon(Icons.cancel_rounded, size: 15, color: MK.danger),
          const SizedBox(width: 8),
          const Text(
            'This order was cancelled.',
            style: TextStyle(fontSize: 11.5, color: MK.inkSoft, fontWeight: FontWeight.w700),
          ),
        ],
      );
    }

    final activeIndex = math.max(0, OrderStatuses.flowKeys.indexOf(status));
    return Row(
      children: List.generate(OrderStatuses.flowKeys.length * 2 - 1, (i) {
        if (i.isOdd) {
          final reached = (i - 1) / 2 < activeIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 3,
              color: reached ? MK.brand : MK.line,
            ),
          );
        }
        final step = i ~/ 2;
        final done = step <= activeIndex;
        final current = step == activeIndex;
        final stepMeta = OrderStatuses.of(OrderStatuses.flowKeys[step]);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: current ? 30 : 24,
          height: current ? 30 : 24,
          decoration: BoxDecoration(
            color: done ? MK.brand : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: done ? MK.brand : MK.line, width: 2),
            boxShadow: current
                ? [BoxShadow(color: MK.brand.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)]
                : const [],
          ),
          child: Icon(
            done ? Icons.check_rounded : stepMeta.icon,
            size: current ? 16 : 12,
            color: done ? Colors.white : MK.inkSoft,
          ),
        );
      }),
    );
  }
}

/// Deal thumbnail that degrades gracefully without an image.
class MThumb extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  final Widget? badge;

  const MThumb({super.key, required this.url, this.size = 56, this.radius = 14, this.badge});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F1),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: MK.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: url.isEmpty
                  ? Center(child: Icon(Icons.restaurant_rounded, size: size * 0.42, color: MK.brand.withValues(alpha: 0.55)))
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) =>
                          Center(child: Icon(Icons.restaurant_rounded, size: size * 0.42, color: MK.brand.withValues(alpha: 0.55))),
                      loadingBuilder: (_, child, prog) =>
                          prog == null ? child : const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                    ),
            ),
            if (badge != null) Positioned(right: 2, top: 2, child: badge!),
          ],
        ),
      );
}

String categoryEmoji(String category) => switch (category) {
      'Restaurant Meal' => '🍛',
      'Bakery Pack' => '🥐',
      'Grocery Bundle' => '🧺',
      'Fruit & Vegetable Pack' => '🥬',
      'Hotel Buffet' => '🍽️',
      'Snacks & Drinks' => '🥤',
      'Farm Produce' => '🌾',
      'Wholesale Bundle' => '📦',
      _ => '🥗',
    };

/// Single source of truth for deal/shop categories across the portal.
const List<String> kDealCategories = [
  'Restaurant Meal',
  'Bakery Pack',
  'Grocery Bundle',
  'Fruit & Vegetable Pack',
  'Hotel Buffet',
  'Snacks & Drinks',
  'Farm Produce',
  'Wholesale Bundle',
];

String orderTitle(Order o) => o.dealTitle.isEmpty ? 'Surplus pack' : o.dealTitle;

// ─────────────────────────────────────────────────────────────
// Export
// ─────────────────────────────────────────────────────────────

String csvCell(String raw) => '"${raw.replaceAll('"', '""')}"';

/// Builds CSV text from a header and rows of already-stringified cells.
String buildCsv(List<String> headers, List<List<String>> rows) {
  final buffer = StringBuffer(headers.map(csvCell).join(','));
  for (final row in rows) {
    buffer.write('\n');
    buffer.write(row.map(csvCell).join(','));
  }
  return buffer.toString();
}

/// Writes [csv] to the browser download stream on web, then confirms honestly
/// about what happened so the merchant is never told a file exists when it
/// was not produced.
void exportCsv(BuildContext context, {required String csv, required String fileName}) {
  if (kIsWeb) {
    try {
      downloadFile(content: csv, fileName: fileName, mimeType: 'text/csv');
      MToast.ok(context, 'Saved as $fileName');
      return;
    } catch (e) {
      MToast.err(context, 'Download failed: $e');
      return;
    }
  }
  showMCsvPreview(context, csv: csv, fileName: fileName);
}

/// Mobile has no browser download, so the CSV is shown for copy & paste.
Future<void> showMCsvPreview(BuildContext context, {required String csv, required String fileName}) async {
  await showMSheet<void>(
    context,
    title: 'Export ready',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Downloads are only available on the web app. Copy this sheet into your spreadsheet or email tool instead.',
          style: TextStyle(fontSize: 12.5, color: MK.inkSoft, height: 1.45),
        ),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F1),
            borderRadius: BorderRadius.circular(MK.rSm),
            border: Border.all(color: MK.line),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        MButton(
          'Copy $fileName',
          icon: Icons.copy_rounded,
          expanded: true,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv));
            if (context.mounted) {
              Navigator.pop(context);
              MToast.ok(context, 'Copied to clipboard');
            }
          },
        ),
      ],
    ),
  );
}

/// Rounded search field shared by the orders and listings tabs.
class MSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const MSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MK.rSm),
          border: Border.all(color: MK.line),
          boxShadow: MK.shadow,
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, size: 19, color: MK.inkSoft),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MK.ink),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: const TextStyle(fontSize: 13.5, color: MK.inkSoft, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 17, color: MK.inkSoft),
                tooltip: 'Clear',
              ),
            const SizedBox(width: 4),
          ],
        ),
      );
}

/// Empty state that distinguishes "nothing yet" from "we could not load this".
class MFeedbackBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool problem;

  const MFeedbackBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.problem = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = problem ? MK.amber : MK.brand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.07), shape: BoxShape.circle),
                ),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.13), shape: BoxShape.circle),
                ),
                Icon(icon, size: 30, color: color),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: MK.inkSoft, height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              SizedBox(width: 220, child: MButton(actionLabel!, icon: icon, onPressed: onAction)),
            ],
          ],
        ),
      ),
    );
  }
}

