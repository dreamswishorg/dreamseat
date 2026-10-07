import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'merchant_storefront.dart';

class PartnersDirectoryScreen extends ConsumerStatefulWidget {
  const PartnersDirectoryScreen({super.key});

  @override
  ConsumerState<PartnersDirectoryScreen> createState() => _PartnersDirectoryScreenState();
}

class _PartnersDirectoryScreenState extends ConsumerState<PartnersDirectoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Restaurant',
    'Bakery',
    'Supermarket',
    'Hotel',
    'Grocery',
  ];

  bool _matchesCategory(String bizCat, String filterCat) {
    if (filterCat == 'All') return true;
    final b = bizCat.toLowerCase();
    final f = filterCat.toLowerCase();
    
    if (b.contains(f)) return true;
    
    if (f == 'grocery') {
      return b.contains('grocery') || b.contains('fruit') || b.contains('produce');
    }
    if (f == 'supermarket') {
      return b.contains('wholesale') || b.contains('grocery');
    }
    if (f == 'restaurant') {
      return b.contains('restaurant') || b.contains('buffet') || b.contains('snacks');
    }
    if (f == 'hotel') {
      return b.contains('hotel') || b.contains('buffet');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final allBusinesses = ref.watch(appStateProvider).businesses;

    // Filter businesses by search query & category
    final filtered = allBusinesses.where((b) {
      final matchesSearch = _searchQuery.isEmpty ||
          b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _matchesCategory(b.category, _selectedCategory);
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 1100,
          child: Column(
            children: [
              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Our Partners",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Discover restaurants, bakeries & supermarkets rescuing food across Ghana.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedGrey,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search partner name, category, location...",
                        hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.mutedGrey),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen, size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Category Filter Chips
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _categories.length,
                        itemBuilder: (context, idx) {
                          final cat = _categories[idx];
                          final isSelected = cat == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                              labelStyle: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.charcoal,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: AppTheme.primaryGreen,
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryGreen : AppTheme.charcoal.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Partners List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined, size: 64, color: AppTheme.mutedGrey.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            const Text(
                              "No partners found",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Try searching with a different keyword or category.",
                              style: TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 640;
                          if (isWide) {
                            final cols = constraints.maxWidth >= 960 ? 3 : 2;
                            return GridView.builder(
                              padding: const EdgeInsets.all(20),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 150,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return _PartnerCard(partner: filtered[index]);
                              },
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.all(20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final partner = filtered[index];
                              return _PartnerCard(partner: partner);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final BusinessProfile partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MerchantStorefrontScreen(business: partner),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
              ),
              child: ClipOval(
                child: partner.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: partner.logoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, _, _) => const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen, size: 28),
                      )
                    : const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen, size: 28),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreenBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          partner.category.toUpperCase(),
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, letterSpacing: 0.5),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        partner.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    partner.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.charcoal),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppTheme.mutedGrey, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          partner.location,
                          style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryGreen, size: 16),
          ],
        ),
      ),
    );
  }
}
