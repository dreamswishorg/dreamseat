import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Comprehensive responsive utilities and wrappers for DreamEats.
/// Ensures optimal viewing experience across mobile devices, tablets,
/// desktop browsers, and device emulators.
class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Returns adaptive width based on percentage of screen width
  static double width(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.width * percentage;

  /// Returns adaptive height based on percentage of screen height
  static double height(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.height * percentage;

  /// Returns grid crossAxisCount adapted to device width
  static int gridCount(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    final w = MediaQuery.of(context).size.width;
    if (w >= tabletBreakpoint) return desktop;
    if (w >= mobileBreakpoint) return tablet;
    return mobile;
  }

  /// Clamps dimensions to avoid overflow on very small emulator screens
  static double scaleVal(BuildContext context, double baseVal, {double min = 10, double max = 500}) {
    final h = MediaQuery.of(context).size.height;
    final scale = (h / 800).clamp(0.75, 1.2);
    return (baseVal * scale).clamp(min, max);
  }
}

/// App-wide responsive builder wrapper for MaterialApp.
/// Ensures clean text scaling and frames mobile views nicely on wide emulators/tablets.
class ResponsiveAppWrapper extends StatelessWidget {
  final Widget? child;
  const ResponsiveAppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();

    final mediaQuery = MediaQuery.of(context);
    // Maintain clean, balanced text scaling without causing card or table overflow on mobile
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.90,
      maxScaleFactor: 1.15,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return child!;
        },
      ),
    );
  }
}

/// Width at which we switch from phone layout (bottom tabs) to
/// laptop layout (left sidebar).
const double kSideNavBreakpoint = 900;

bool useSideNav(BuildContext context) =>
    MediaQuery.of(context).size.width >= kSideNavBreakpoint;

/// Centers [child] and limits it to [maxWidth] on wide screens (laptops),
/// so pages don't stretch edge-to-edge.
///
/// Mouse-wheel / trackpad scrolling over the empty side margins is forwarded
/// to the centered content, so the page still scrolls wherever the pointer is.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1100,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        if (!available.isFinite || available <= maxWidth) return child;

        final side = (available - maxWidth) / 2;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerSignal: (event) {
            if (event is! PointerScrollEvent) return;
            final dx = event.localPosition.dx;
            if (dx >= side && dx <= side + maxWidth) return; // content handles it
            // Claim the event so it is handled exactly once, then re-dispatch
            // it at the horizontal centre so the page content scrolls.
            GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
              final shifted = resolved.copyWith(
                position: resolved.position + Offset(available / 2 - dx, 0),
              );
              Future.microtask(() => GestureBinding.instance.handlePointerEvent(shifted));
            });
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class SideNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const SideNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// Left sidebar navigation used on tablet/desktop widths.
/// Supports smooth animated collapsible rail mode (72px) and full mode (240px).
class DesktopSideNav extends StatelessWidget {
  final List<SideNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget? header;
  final Widget? footer;
  final Color accentColor;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const DesktopSideNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.accentColor,
    this.header,
    this.footer,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0x14000000);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final width = isCollapsed ? 74.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with toggle
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCollapsed ? 8 : 16,
                16,
                isCollapsed ? 8 : 12,
                12,
              ),
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!isCollapsed && header != null)
                    Expanded(child: header!),
                  if (onToggleCollapse != null)
                    IconButton(
                      icon: Icon(
                        isCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
                        color: mutedColor,
                        size: 22,
                      ),
                      tooltip: isCollapsed ? "Expand Sidebar" : "Collapse Sidebar",
                      onPressed: onToggleCollapse,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Navigation Items List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final selected = i == selectedIndex;

                  if (isCollapsed) {
                    return Tooltip(
                      message: item.label,
                      preferBelow: false,
                      child: Material(
                        color: selected
                            ? accentColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          hoverColor: accentColor.withValues(alpha: 0.08),
                          onTap: () => onSelect(i),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  selected ? item.activeIcon : item.icon,
                                  size: 24,
                                  color: selected ? accentColor : mutedColor,
                                ),
                                if (item.badgeCount > 0)
                                  Positioned(
                                    top: -4,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${item.badgeCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Material(
                    color: selected
                        ? accentColor.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: accentColor.withValues(alpha: 0.06),
                      onTap: () => onSelect(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 21,
                              color: selected ? accentColor : mutedColor,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: selected ? textColor : mutedColor,
                                ),
                              ),
                            ),
                            if (item.badgeCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${item.badgeCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (footer != null)
              Padding(
                padding: EdgeInsets.all(isCollapsed ? 8 : 16),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}
