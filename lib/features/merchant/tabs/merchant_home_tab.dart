import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';

class MerchantHomeTab extends ConsumerWidget {
  final BusinessProfile business;
  final void Function({MTab? tab, String? filter, bool compose}) navigate;

  const MerchantHomeTab({super.key, required this.business, required this.navigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final orders = state.orders.where((o) => o.businessId == business.id).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final deals = state.merchantDeals;
    final notifier = ref.read(appStateProvider.notifier);

    final now = DateTime.now();
    final today = orders.where((o) => DateUtils.isSameDay(o.timestamp, now)).toList();
    final newOrders = orders.where((o) => o.status == 'reserved').toList();
    final preparing = orders.where((o) => o.status == 'preparing').toList();
    final ready = orders.where((o) => o.status == 'ready').toList();
    final onTheWay = orders.where((o) => o.status == 'out_for_delivery').toList();
    final collected = orders.where((o) => o.status == 'collected').toList();
    final open = newOrders.length + preparing.length + ready.length + onTheWay.length;

    final revenue7d = collected
        .where((o) => now.difference(o.timestamp).inDays < 7)
        .fold<double>(0, (sum, o) => sum + o.price);
    final pendingPayout = collected
        .where((o) => o.payoutStatus != 'paid')
        .fold<double>(0, (sum, o) => sum + o.price * (1 - notifier.commissionRate));
    final savedValue = collected.fold<double>(0, (sum, o) => sum + (o.originalPrice - o.price));

    final live = deals.where((d) => d.isActive && d.quantityRemaining > 0).length;
    final lowStock = deals.where((d) => d.quantityRemaining > 0 && d.quantityRemaining <= 2).length;
    final soldOut = deals.where((d) => d.quantityRemaining == 0).length;
    final paused = deals.where((d) => !d.isActive).length;

    final profileScore = _setupChecklist(business, deals, notifier);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktopOrTablet = screenWidth >= 920;
    final wide = useSideNav(context);

    final queueCard = MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MSectionHeader(
            title: 'Fulfilment queue',
            subtitle: 'Real-time kitchen pipeline · tap a stage to filter',
            icon: Icons.timeline_rounded,
          ),
          const SizedBox(height: 16),
          _QueueStrip(
            stages: [
              _Stage('New', newOrders.length, OrderStatuses.of('reserved').color, 'reserved'),
              _Stage('Preparing', preparing.length, OrderStatuses.of('preparing').color, 'preparing'),
              _Stage('Ready', ready.length, OrderStatuses.of('ready').color, 'ready'),
              _Stage('On the way', onTheWay.length, OrderStatuses.of('out_for_delivery').color, 'out_for_delivery'),
              _Stage('Completed', collected.length, OrderStatuses.of('collected').color, 'collected'),
            ],
            onTap: (filter) => navigate(tab: MTab.orders, filter: filter),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: MK.lineSoft,
              borderRadius: BorderRadius.all(Radius.circular(MK.rSm)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 17, color: MK.brand),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    deals.isEmpty
                        ? 'No listings yet — publish your first surplus pack to start receiving orders.'
                        : '$live live · $paused paused · $lowStock low on stock · $soldOut sold out',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: MK.ink),
                  ),
                ),
                if (lowStock > 0 || soldOut > 0 || deals.isEmpty)
                  TextButton(
                    onPressed: () => navigate(tab: MTab.listings),
                    child: const Text('Restock', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final activityCard = MCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MSectionHeader(
            title: 'Latest activity',
            subtitle: orders.isEmpty ? 'Orders appear here as customers reserve' : '${orders.length} lifetime orders',
            icon: Icons.bolt_rounded,
            iconColor: MK.amber,
            trailing: TextButton(
              onPressed: () => navigate(tab: MTab.orders),
              child: const Text('All orders', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 6),
          if (orders.isEmpty)
            const MFeedbackBlock(
              icon: Icons.receipt_long_rounded,
              title: 'No orders yet',
              message: 'Once a customer reserves one of your packs, the order lands here instantly.',
            )
          else
            ...orders.take(isDesktopOrTablet ? 7 : 5).map((o) => _ActivityRow(
                  order: o,
                  onTap: () => navigate(tab: MTab.orders, filter: o.status),
                )),
        ],
      ),
    );

    final revenueCard = _RevenueCard(collected: collected);

    final impactCard = _ImpactCard(
      savedValue: savedValue,
      meals: collected.length,
      totalOrders: orders.length,
      pendingPayout: pendingPayout,
      commissionPct: (notifier.commissionRate * 100),
    );

    final productSales = <String, ({int count, double revenue})>{};
    for (final o in collected) {
      final current = productSales[o.dealTitle];
      if (current == null) {
        productSales[o.dealTitle] = (count: 1, revenue: o.price);
      } else {
        productSales[o.dealTitle] = (count: current.count + 1, revenue: current.revenue + o.price);
      }
    }
    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    final topProductsCard = _TopProductsCard(topProducts: topProducts);

    return ResponsiveCenter(
      maxWidth: 1320,
      child: ListView(
        cacheExtent: 2000,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 20 : 14, wide ? 24 : 16, wide ? 32 : 110),
        children: [
          MReveal(
            child: _HeroCard(
              business: business,
              shopName: business.name,
              openOrders: open,
              todayRevenue: today.where((o) => o.status == 'collected').fold<double>(0, (s, o) => s + o.price),
              todayOrders: today.length,
              onVerify: () => navigate(tab: MTab.verify),
              onNewListing: () => navigate(tab: MTab.listings, compose: true),
            ),
          ),
          const SizedBox(height: 16),

          if (state.merchantDealsError != null)
            MReveal(
              child: _ErrorBanner(
                message: state.merchantDealsError!,
                onRetry: () => notifier.loadMerchantDeals(),
              ),
            ),

          if (profileScore.isNotEmpty) ...[
            MReveal(
              delay: 60,
              child: _SetupCard(
                items: profileScore,
                business: business,
                onFix: (target) => navigate(tab: target),
              ),
            ),
            const SizedBox(height: 16),
          ],

          MReveal(
            delay: 80,
            child: _StatGrid(
              tiles: [
                _Tile('New orders', newOrders.length.toDouble(), MK.gold, Icons.inbox_rounded, 'needs action',
                    () => navigate(tab: MTab.orders, filter: 'reserved')),
                _Tile('In kitchen', preparing.length.toDouble(), MK.amber, Icons.soup_kitchen_rounded, 'being packed',
                    () => navigate(tab: MTab.orders, filter: 'preparing')),
                _Tile('Ready for pickup', ready.length.toDouble(), MK.brand, Icons.shopping_bag_rounded, 'at the counter',
                    () => navigate(tab: MTab.orders, filter: 'ready')),
                _Tile('Revenue · 7 days', revenue7d, MK.brandDeep, Icons.trending_up_rounded, 'collected orders',
                    () => navigate(tab: MTab.orders, filter: 'collected'), money: true),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (isDesktopOrTablet) ...[
            MReveal(
              delay: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Operations Column
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        queueCard,
                        const SizedBox(height: 18),
                        activityCard,
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  // Right: Analytics & Tools Column
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        revenueCard,
                        const SizedBox(height: 18),
                        impactCard,
                        const SizedBox(height: 18),
                        topProductsCard,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            MReveal(delay: 120, child: queueCard),
            const SizedBox(height: 16),
            MReveal(delay: 160, child: revenueCard),
            const SizedBox(height: 16),
            MReveal(delay: 190, child: impactCard),
            const SizedBox(height: 16),
            MReveal(delay: 210, child: topProductsCard),
            const SizedBox(height: 16),
            MReveal(delay: 260, child: activityCard),
          ],
        ],
      ),
    );
  }

  /// Only returns items the merchant genuinely still has to do.
  List<_SetupItem> _setupChecklist(BusinessProfile b, List<FoodDeal> deals, AppStateManager notifier) {
    final items = <_SetupItem>[];
    if (!b.isApproved) {
      items.add(_SetupItem(
        'Platform review pending',
        'Our team verifies your documents before packs go live.',
        Icons.verified_user_outlined,
        MTab.shop,
      ));
    }
    if (b.phone.isEmpty) {
      items.add(_SetupItem(
        'Add a shop phone number',
        'Customers need a real number to reach you about pickups.',
        Icons.phone_outlined,
        MTab.shop,
      ));
    }
    if (b.logoUrl.isEmpty && b.coverUrl.isEmpty) {
      items.add(_SetupItem(
        'Upload shop photos',
        'Listings with a storefront photo get reserved far more often.',
        Icons.add_a_photo_outlined,
        MTab.shop,
      ));
    }
    if (deals.isEmpty) {
      items.add(_SetupItem(
        'Publish your first pack',
        'You have no listings, so customers have nothing to reserve yet.',
        Icons.storefront_outlined,
        MTab.listings,
      ));
    }
    return items;
  }
}

class _Tile {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String caption;
  final VoidCallback onTap;
  final bool money;

  _Tile(this.label, this.value, this.color, this.icon, this.caption, this.onTap, {this.money = false});
}

class _Stage {
  final String label;
  final int count;
  final Color color;
  final String filter;
  _Stage(this.label, this.count, this.color, this.filter);
}

class _SetupItem {
  final String title;
  final String detail;
  final IconData icon;
  final MTab target;
  _SetupItem(this.title, this.detail, this.icon, this.target);
}

// ─────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final BusinessProfile business;
  final String shopName;
  final int openOrders;
  final double todayRevenue;
  final int todayOrders;
  final VoidCallback onVerify;
  final VoidCallback onNewListing;

  const _HeroCard({
    required this.business,
    required this.shopName,
    required this.openOrders,
    required this.todayRevenue,
    required this.todayOrders,
    required this.onVerify,
    required this.onNewListing,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Container(
      decoration: BoxDecoration(
        gradient: MK.heroGradient,
        borderRadius: BorderRadius.circular(MK.rHero),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
        boxShadow: MK.brandShadow(),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -40, child: _Bubble(120)),
          Positioned(right: isWide ? 220 : 34, bottom: -26, child: _Bubble(70)),
          Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 26 : 20, isWide ? 22 : 20, isWide ? 26 : 20, isWide ? 22 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _greeting,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MPulseDot(color: business.isApproved ? Colors.white : MK.amber, size: 6.5),
                                    const SizedBox(width: 6),
                                    Text(
                                      business.isApproved ? 'VERIFIED STORE' : 'IN REVIEW',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWide ? 24 : 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWide) ...[
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HeroButton(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Verify pickup',
                            onTap: onVerify,
                          ),
                          const SizedBox(width: 10),
                          _HeroButton(
                            icon: Icons.add_rounded,
                            label: 'New surplus pack',
                            onTap: onNewListing,
                            soft: true,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                SizedBox(height: isWide ? 18 : 16),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                SizedBox(height: isWide ? 16 : 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(label: 'Orders today', value: todayOrders.toDouble()),
                    ),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.18)),
                    Expanded(
                      child: _HeroMetric(label: 'Collected today', value: todayRevenue, money: true),
                    ),
                    if (isWide) ...[
                      Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.18)),
                      Expanded(
                        child: _HeroMetric(label: 'Active in queue', value: openOrders.toDouble()),
                      ),
                    ],
                  ],
                ),
                if (!isWide) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroButton(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Verify pickup',
                          onTap: onVerify,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroButton(
                          icon: Icons.add_rounded,
                          label: 'New pack',
                          onTap: onNewListing,
                          soft: true,
                        ),
                      ),
                    ],
                  ),
                ],
                if (openOrders > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, size: 14, color: MK.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$openOrders order${openOrders == 1 ? '' : 's'} waiting on your kitchen or counter right now.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  const _Bubble(this.size);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
      );
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final double value;
  final bool money;

  const _HeroMetric({required this.label, required this.value, this.money = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MCountUp(
              value,
              decimals: money ? 2 : 0,
              prefix: money ? 'GHS ' : '',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.8),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.66),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool soft;

  const _HeroButton({required this.icon, required this.label, required this.onTap, this.soft = false});

  @override
  Widget build(BuildContext context) => MPressable(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: soft ? Colors.white.withValues(alpha: 0.16) : Colors.white,
            borderRadius: BorderRadius.circular(MK.rSm),
            border: Border.all(color: Colors.white.withValues(alpha: soft ? 0.3 : 1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: soft ? Colors.white : MK.brandDeep),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: soft ? Colors.white : MK.brandDeep,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _StatGrid extends StatelessWidget {
  final List<_Tile> tiles;

  const _StatGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final int columns = w >= 1050 ? 4 : 2;
    final double ratio = w >= 1050 ? 1.55 : (w >= 600 ? 1.85 : 1.15);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) {
        final t = tiles[i];
        return MPressable(
          onTap: t.onTap,
          child: MCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            t.color.withValues(alpha: 0.22),
                            t.color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.color.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Icon(t.icon, size: 18, color: t.color),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: t.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.color.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            t.caption.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: t.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                MCountUp(
                  t.value,
                  decimals: t.money ? 2 : 0,
                  prefix: t.money ? 'GHS ' : '',
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: -0.7),
                ),
                const SizedBox(height: 2),
                Text(
                  t.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: MK.inkSoft),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QueueStrip extends StatelessWidget {
  final List<_Stage> stages;
  final ValueChanged<String> onTap;

  const _QueueStrip({required this.stages, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 650;
    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 11, color: MK.inkSoft.withValues(alpha: 0.35)),
              ),
            Expanded(
              child: MPressable(
                onTap: () => onTap(stages[i].filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: stages[i].count > 0 ? stages[i].color.withValues(alpha: 0.08) : MK.surfaceAlt,
                    borderRadius: BorderRadius.circular(MK.rSm),
                    border: Border.all(
                      color: stages[i].count > 0 ? stages[i].color.withValues(alpha: 0.38) : MK.line,
                      width: stages[i].count > 0 ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${stages[i].count}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: stages[i].color, letterSpacing: -1),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stages[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: stages[i].count > 0 ? FontWeight.w900 : FontWeight.w700,
                          color: stages[i].count > 0 ? MK.ink : MK.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            if (i > 0)
              Icon(Icons.chevron_right_rounded, size: 18, color: MK.inkSoft.withValues(alpha: 0.4)),
            MPressable(
              onTap: () => onTap(stages[i].filter),
              child: Container(
                width: 104,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: stages[i].count > 0 ? stages[i].color.withValues(alpha: 0.09) : const Color(0xFFF5F7F6),
                  borderRadius: BorderRadius.circular(MK.rSm),
                  border: Border.all(
                    color: stages[i].count > 0 ? stages[i].color.withValues(alpha: 0.32) : MK.line,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${stages[i].count}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: stages[i].color, letterSpacing: -1),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stages[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: MK.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final List<Order> collected;
  const _RevenueCard({required this.collected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final totals = List.filled(7, 0.0);
    for (final o in collected) {
      for (var i = 0; i < 7; i++) {
        if (DateUtils.isSameDay(o.timestamp, days[i])) totals[i] += o.price;
      }
    }
    final maxValue = totals.fold<double>(0, (m, v) => v > m ? v : m);
    final weekTotal = totals.fold<double>(0, (s, v) => s + v);

    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MSectionHeader(
            title: 'Last 7 days',
            subtitle: maxValue == 0 ? 'No completed orders collected yet' : MK.money(weekTotal),
            icon: Icons.bar_chart_rounded,
            iconColor: MK.brandDeep,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: maxValue == 0
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F6),
                      borderRadius: BorderRadius.circular(MK.rSm),
                    ),
                    child: const Center(
                      child: Text(
                        'Nothing collected in this window',
                        style: TextStyle(fontSize: 12, color: MK.inkSoft, fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue * 1.25,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => MK.ink,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                            MK.money(rod.toY),
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              final i = val.toInt();
                              if (i < 0 || i >= days.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('E').format(days[i]),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: MK.inkSoft),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: List.generate(7, (i) {
                        final isToday = i == 6;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: totals[i],
                              width: 15,
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isToday
                                    ? [MK.brand, MK.brandGlow]
                                    : [MK.brand.withValues(alpha: 0.45), MK.brand.withValues(alpha: 0.8)],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final double savedValue;
  final int meals;
  final int totalOrders;
  final double pendingPayout;
  final double commissionPct;

  const _ImpactCard({
    required this.savedValue,
    required this.meals,
    required this.totalOrders,
    required this.pendingPayout,
    required this.commissionPct,
  });

  @override
  Widget build(BuildContext context) {
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MSectionHeader(
            title: 'Payouts & rescue value',
            subtitle: 'Calculated from your completed orders only',
            icon: Icons.savings_rounded,
            iconColor: MK.brandDeep,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MGauge(
                value: totalOrders == 0 ? 0 : meals / totalOrders,
                size: 92,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      meals.toString(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: -1),
                    ),
                    const Text('done', style: TextStyle(fontSize: 9.5, color: MK.inkSoft, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _MoneyLine('Rescue value passed on', MK.money(savedValue), MK.brand),
                    const SizedBox(height: 10),
                    _MoneyLine('Awaiting payout', MK.money(pendingPayout), MK.amber),
                    const SizedBox(height: 10),
                    _MoneyLine(
                      'Completed orders',
                      '$meals',
                      MK.ink,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              color: MK.lineSoft,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Text(
              'Payout figures are your order totals less the ${commissionPct.toStringAsFixed(0)}% platform commission. '
              'Settlement timing is handled by the DreamEats finance team.',
              style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MoneyLine(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: MK.inkSoft, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13.5, color: color, fontWeight: FontWeight.w900),
          ),
        ],
      );
}


class _TopProductsCard extends StatelessWidget {
  final List<MapEntry<String, ({int count, double revenue})>> topProducts;

  const _TopProductsCard({required this.topProducts});

  @override
  Widget build(BuildContext context) {
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MSectionHeader(
            title: 'Top-selling rescue packs',
            subtitle: 'Ranked by customer orders and revenue generated',
            icon: Icons.emoji_events_rounded,
            iconColor: MK.amber,
          ),
          const SizedBox(height: 16),
          if (topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              decoration: BoxDecoration(
                color: MK.surfaceAlt,
                borderRadius: BorderRadius.circular(MK.rSm),
                border: Border.all(color: MK.line),
              ),
              child: const Center(
                child: Text(
                  'Your top-selling dishes will rank here automatically as customers rescue meals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: MK.inkSoft, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else ...[
            ...topProducts.take(4).map((entry) {
              final maxRev = topProducts.first.value.revenue;
              final ratio = maxRev > 0 ? (entry.value.revenue / maxRev).clamp(0.05, 1.0) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: MK.ink),
                          ),
                        ),
                        Text(
                          '${entry.value.count} sold · ${MK.money(entry.value.revenue)}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: MK.brand),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(height: 6, color: const Color(0xFFF5F7F6)),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [MK.brand, MK.brandGlow]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}



class _ActivityRow extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _ActivityRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = OrderStatuses.of(order.status);
    return MPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: MK.line, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meta.icon, size: 18, color: meta.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderTitle(order),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MK.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.customerName} · ${MK.ago(order.timestamp)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: MK.inkSoft, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MK.money(order.price),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: MK.ink),
                ),
                const SizedBox(height: 3),
                MPill(meta.shortLabel, color: meta.color, fontSize: 8.5),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: MK.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(MK.rMd),
          border: Border.all(color: MK.amber.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 20, color: MK.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Could not load your listings',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: MK.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, height: 1.4),
                  ),
                ],
              ),
            ),
            MIconButton(icon: Icons.refresh_rounded, onPressed: onRetry, color: MK.amber, tooltip: 'Retry'),
          ],
        ),
      );
}

class _SetupCard extends StatelessWidget {
  final List<_SetupItem> items;
  final BusinessProfile business;
  final ValueChanged<MTab> onFix;

  const _SetupCard({required this.items, required this.business, required this.onFix});

  @override
  Widget build(BuildContext context) {
    final done = 5 - items.length;
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MSectionHeader(
            title: 'Get shop ready',
            subtitle: '$done of 5 steps done',
            icon: Icons.checklist_rounded,
            iconColor: MK.gold,
            trailing: SizedBox(
              width: 74,
              child: MGauge(
                value: done / 5,
                size: 52,
                stroke: 6,
                center: Text(
                  '${(done / 5 * 100).round()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: MK.ink),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: MK.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 16, color: MK.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: MK.ink),
                        ),
                        Text(
                          item.detail,
                          style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MButton(
                    'Fix',
                    kind: MKind.soft,
                    height: 34,
                    onPressed: () => onFix(item.target),
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
