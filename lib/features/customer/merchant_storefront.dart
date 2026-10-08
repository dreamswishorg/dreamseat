import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'deal_detail_screen.dart';

class MerchantStorefrontScreen extends ConsumerStatefulWidget {
  final BusinessProfile business;

  const MerchantStorefrontScreen({super.key, required this.business});

  @override
  ConsumerState<MerchantStorefrontScreen> createState() => _MerchantStorefrontScreenState();
}

class _MerchantStorefrontScreenState extends ConsumerState<MerchantStorefrontScreen> {
  String _selectedMode = 'Delivery'; // Delivery | Pickup | In-Store
  String _selectedFilter = 'All';    // All | Popular items | Build for you | Special Offers
  String? _scheduledTime;
  String? _kitchenNote;

  final List<String> _groupMembers = ['You (Host)', 'Sarah', 'Kofi'];

  void _showScheduleModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  const Text('Schedule Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Select your preferred rescue pickup or delivery window:'),
              const SizedBox(height: 16),
              ...[
                'ASAP (Estimated 25-35 mins)',
                'Today • 12:30 PM - 1:30 PM (Lunch Rush)',
                'Today • 6:00 PM - 7:30 PM (Dinner Rescue)',
                'Tomorrow • 10:00 AM - 11:30 AM (Bakery Batch)',
              ].map((time) {
                final isCurrent = _scheduledTime == time || (_scheduledTime == null && time.startsWith('ASAP'));
                return ListTile(
                  title: Text(time, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                  trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen) : null,
                  onTap: () {
                    setState(() => _scheduledTime = time);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Scheduled for: $time'), backgroundColor: AppTheme.primaryGreen),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupOrderModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.group_rounded, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  const Text('Group Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Order together with coworkers or friends and split delivery or pickup fees!',
                style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SHAREABLE ROOM CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                          SizedBox(height: 2),
                          Text('EATS-7842', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Invite'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔗 Group order invite link copied!'), backgroundColor: AppTheme.primaryGreen),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Joined Participants (3)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _groupMembers.map((m) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      child: Text(m[0], style: const TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                    label: Text(m, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNoteModal() {
    final noteCtrl = TextEditingController(text: _kitchenNote);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.note_alt_outlined, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  const Text('Kitchen & Delivery Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Please pack cutlery, leave sauce on the side, or gate directions...',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    setState(() => _kitchenNote = noteCtrl.text.trim());
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Note saved for this order'), backgroundColor: AppTheme.primaryGreen),
                    );
                  },
                  child: const Text('Save Note'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final deals = ref.watch(appStateProvider.select((s) => s.deals.where((d) => d.businessId == business.id).toList()));
    final isFavorite = ref.watch(appStateProvider.select((s) => s.favoriteBusinessIds.contains(business.id)));

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            final cols = constraints.maxWidth >= 900 ? 3 : 2;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, business, isFavorite),
                SliverToBoxAdapter(child: _buildMerchantInfo(business)),

                // ── SPECIAL OFFERS CAROUSEL (Mockup 2 Right) ─────────────
                if (deals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Special offers',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.charcoal),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGreen, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 190,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildOfferCard(
                            badge: 'Top offer • Buy 1, Get 1 Free',
                            title: 'Surplus Chef Combo',
                            price: 'GHS 25.00',
                            imageUrl: deals.first.imageUrl,
                            deal: deals.first,
                          ),
                          const SizedBox(width: 12),
                          _buildOfferCard(
                            badge: 'Top offer • Spend GHS 40, Save GHS 10',
                            title: 'Artisan Bakery Surprise Bag',
                            price: 'GHS 30.00',
                            imageUrl: deals.length > 1 ? deals[1].imageUrl : deals.first.imageUrl,
                            deal: deals.length > 1 ? deals[1] : deals.first,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ── ACTIVE DEALS HEADER ──────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      'Active Rescue Deals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                  ),
                ),

                deals.isEmpty
                    ? _buildEmptyDeals()
                    : isWide
                        ? SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 280,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final deal = deals[index];
                                  return _buildDealCard(context, ref, deal, isFavorite);
                                },
                                childCount: deals.length,
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final deal = deals[index];
                                  return _buildDealCard(context, ref, deal, isFavorite);
                                },
                                childCount: deals.length,
                              ),
                            ),
                          ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, BusinessProfile business, bool isFavorite) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      leading: Container(
        margin: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // Search in dark translucent circle (Image 1 Right)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 19),
            onPressed: () {},
          ),
        ),
        // Favorite heart in dark translucent circle (Image 1 Right)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
              size: 19,
            ),
            onPressed: () => ref.read(appStateProvider.notifier).toggleFavorite(business.id),
          ),
        ),
        // More options in dark translucent circle (Image 1 Right)
        Container(
          margin: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 19),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Store options for ${business.name}'), backgroundColor: AppTheme.primaryGreen),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (business.coverUrl.isNotEmpty || business.logoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: business.coverUrl.isNotEmpty ? business.coverUrl : business.logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppTheme.lightGrey),
                errorWidget: (context, url, error) => Container(color: AppTheme.lightGreenBg),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black45],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantInfo(BusinessProfile business) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Open now badge (Mockup 2 Right)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.lightGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Open now',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  business.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Rating, Address, Distance row
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 4),
              Text(
                '${business.rating > 0 ? business.rating.toStringAsFixed(1) : "5.0"} (236)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: AppTheme.mutedGrey)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${business.location} • ${business.distance.toStringAsFixed(1)} km',
                  style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── ACTION PILLS ROW (Schedule, Group order, Add note) (Mockup 2 Right) ──
          Row(
            children: [
              _buildActionPill(
                icon: Icons.schedule_rounded,
                label: _scheduledTime != null ? 'Scheduled' : 'Schedule',
                isSelected: _scheduledTime != null,
                onTap: _showScheduleModal,
              ),
              const SizedBox(width: 8),
              _buildActionPill(
                icon: Icons.group_rounded,
                label: 'Group order',
                isSelected: false,
                onTap: _showGroupOrderModal,
              ),
              const SizedBox(width: 8),
              _buildActionPill(
                icon: Icons.note_alt_outlined,
                label: _kitchenNote != null ? 'Note added' : 'Add note',
                isSelected: _kitchenNote != null,
                onTap: _showAddNoteModal,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── ORDER TYPE TABS (Delivery | Pickup | In-Store) (Mockup 2 Right) ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: ['Delivery', 'Pickup', 'In-Store'].map((mode) {
                final isSelected = _selectedMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          mode,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? AppTheme.charcoal : AppTheme.mutedGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── FEES INFO LINK (Image 1 Right) ──
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delivery fee calculated by live distance • Free pickup available')),
                  );
                },
                child: const Text(
                  'Fees info',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedGrey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── SECTION FILTER CHIPS WITH TUNE ICON (Image 1 Right) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filter Settings Circle Button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.charcoal),
                ),
                ...['All', 'Popular items', 'Build for you', 'Desserts', 'Special Offers'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryGreen : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryGreen : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.charcoal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.lightGreenBg : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? AppTheme.primaryGreen : AppTheme.charcoal),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard({
    required String badge,
    required String title,
    required String price,
    required String imageUrl,
    required FoodDeal deal,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal))),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                            errorWidget: (context, url, error) => Container(color: AppTheme.lightGreenBg),
                          )
                        : Container(color: AppTheme.lightGreenBg),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, WidgetRef ref, FoodDeal deal, bool isFavorite) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(12)),
              child: deal.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: deal.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppTheme.lightGrey),
                        errorWidget: (context, url, error) => Icon(_getIconForCategory(deal.category), color: AppTheme.primaryGreen),
                      ),
                    )
                  : Icon(_getIconForCategory(deal.category), color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("GHS ${deal.discountedPrice.toStringAsFixed(0)}",
                          style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Text("GHS ${deal.originalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppTheme.mutedGrey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(8)),
                    child: Text(deal.pickupWindow, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? AppTheme.errorRed : AppTheme.mutedGrey),
              onPressed: () => ref.read(appStateProvider.notifier).toggleFavorite(deal.businessId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDeals() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.mutedGrey),
            SizedBox(height: 16),
            Text("No active deals right now", style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Bakery Pack':
        return Icons.bakery_dining_rounded;
      case 'Restaurant Meal':
        return Icons.restaurant_rounded;
      case 'Fruit & Vegetable Pack':
        return Icons.shopping_basket_rounded;
      case 'Hotel Buffet':
        return Icons.room_service_rounded;
      case 'Grocery Bundle':
        return Icons.local_grocery_store_rounded;
      case 'Snacks & Drinks':
        return Icons.local_cafe_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }
}
