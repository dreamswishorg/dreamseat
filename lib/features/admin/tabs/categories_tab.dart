import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';

class TabCategories extends ConsumerStatefulWidget {
  const TabCategories({super.key});

  @override
  ConsumerState<TabCategories> createState() => _TabCategoriesState();
}

class _TabCategoriesState extends ConsumerState<TabCategories> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Curated Preset Food Images for Quick Selection
  static const List<Map<String, String>> _presetImages = [
    {
      'label': 'Meals & Dinners',
      'url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop',
    },
    {
      'label': 'Bakery & Pastries',
      'url': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop',
    },
    {
      'label': 'Groceries & Pantry',
      'url': 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=600&auto=format&fit=crop',
    },
    {
      'label': 'Fruits & Veggies',
      'url': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600&auto=format&fit=crop',
    },
    {
      'label': 'Buffet & Banquet',
      'url': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&auto=format&fit=crop',
    },
    {
      'label': 'Drinks & Smoothies',
      'url': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop',
    },
    {
      'label': 'Local Jollof & Grill',
      'url': 'https://images.unsplash.com/photo-1574484284002-952d92456975?w=600&auto=format&fit=crop',
    },
    {
      'label': 'Burgers & Fast Food',
      'url': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop',
    },
    {
      'label': 'Desserts & Cakes',
      'url': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditCategoryDialog({CategoryItem? existingCategory}) {
    final isEditing = existingCategory != null;
    final nameCtrl = TextEditingController(text: existingCategory?.name ?? '');
    final urlCtrl = TextEditingController(text: existingCategory?.imageUrl ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final currentUrl = urlCtrl.text.trim();

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Category' : 'Add New Category',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                const Text(
                  "Curate meal collections and food discoverability for shoppers",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(ctx).width * 0.94).clamp(320.0, 520.0),
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'CATEGORY DETAILS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.mutedGrey,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: nameCtrl,
                        onChanged: (_) => setDlgState(() {}),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                        decoration: InputDecoration(
                          labelText: 'Category Title',
                          hintText: 'e.g., Traditional Jollof, Fresh Fruit Box',
                          prefixIcon: const Icon(Icons.label_outline_rounded, size: 19, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: urlCtrl,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.charcoal),
                        decoration: InputDecoration(
                          labelText: 'Image Resource URL',
                          hintText: 'https://images.unsplash.com/...',
                          prefixIcon: const Icon(Icons.link_rounded, size: 19, color: Color(0xFF64748B)),
                          suffixIcon: currentUrl.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.mutedGrey),
                                  onPressed: () {
                                    urlCtrl.clear();
                                    setDlgState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
                        ),
                        onChanged: (_) => setDlgState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide an image URL' : null,
                      ),
                      const SizedBox(height: 18),

                      // Quick Preset Images Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'POPULAR PRESET PHOTOS',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.mutedGrey, letterSpacing: 0.8),
                          ),
                          Text(
                            'Tap to apply',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _presetImages.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final preset = _presetImages[idx];
                            final isPicked = currentUrl == preset['url'];

                            return InkWell(
                              onTap: () {
                                setDlgState(() {
                                  urlCtrl.text = preset['url']!;
                                  if (nameCtrl.text.isEmpty && preset['name'] != null) {
                                    nameCtrl.text = preset['name']!;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 76,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPicked ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
                                    width: isPicked ? 2.5 : 1,
                                  ),
                                  boxShadow: isPicked
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        preset['url']!,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFF1F5F9)),
                                      ),
                                    ),
                                    if (isPicked)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Live Image Preview with Store Card Simulation
                      const Text(
                        'APP DISPLAY PREVIEW',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.mutedGrey, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (currentUrl.isNotEmpty)
                              Image.network(
                                currentUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image_rounded, color: AppTheme.mutedGrey, size: 28),
                                      SizedBox(height: 4),
                                      Text('Invalid image URL', style: TextStyle(color: AppTheme.mutedGrey, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                              )
                            else
                              const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image_outlined, color: AppTheme.mutedGrey, size: 30),
                                    SizedBox(height: 6),
                                    Text('Select a preset photo above or paste a URL', style: TextStyle(color: AppTheme.mutedGrey, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                            // Dark gradient overlay with Category Label Preview
                            if (currentUrl.isNotEmpty)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, Colors.black87],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Text(
                                    nameCtrl.text.isNotEmpty ? nameCtrl.text : "Category Title",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.mutedGrey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final name = nameCtrl.text.trim();
                    final url = urlCtrl.text.trim();

                    if (isEditing) {
                      await ref.read(appStateProvider.notifier).updateCategory(
                            id: existingCategory.id,
                            name: name,
                            imageUrl: url,
                          );
                    } else {
                      await ref.read(appStateProvider.notifier).addCategory(
                            name: name,
                            imageUrl: url,
                          );
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Category updated!' : 'Category added successfully!'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Create Category', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(CategoryItem cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await ref.read(appStateProvider.notifier).deleteCategory(cat.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "${cat.name}" removed.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final categories = state.categories;
    final deals = state.deals;

    final filtered = categories.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 650;

    return SingleChildScrollView(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Action Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Category Catalog & Imagery',
                  style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddEditCategoryDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isMobile ? 'Add' : 'Add Category', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 10 : 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Responsive Metrics KPI Row/Column
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final statCards = [
                _buildStatCard(
                  title: 'Total Categories',
                  value: '${categories.length}',
                  icon: Icons.category_rounded,
                  color: AppTheme.primaryGreen,
                  isCompact: isNarrow,
                ),
                _buildStatCard(
                  title: 'Live Rescue Deals',
                  value: '${deals.length}',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF2563EB),
                  isCompact: isNarrow,
                ),
                _buildStatCard(
                  title: 'Preset Food Photos',
                  value: '${_presetImages.length}',
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFFD97706),
                  isCompact: isNarrow,
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    for (int i = 0; i < statCards.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      statCards[i],
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < statCards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(child: statCards[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.mutedGrey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search categories...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.mutedGrey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Categories Grid
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.category_outlined, size: 48, color: AppTheme.mutedGrey),
                    SizedBox(height: 12),
                    Text('No categories found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final gridWidth = constraints.maxWidth;
                  final crossAxisCount = gridWidth > 1200 ? 4 : (gridWidth > 900 ? 3 : (gridWidth > 600 ? 2 : 1));
                  final cellWidth = (gridWidth - 16 * (crossAxisCount - 1)) / crossAxisCount;
                  final childAspectRatio = cellWidth / (cellWidth * 0.62 + 56);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final cat = filtered[idx];
                      final catDealCount = deals.where((d) => d.category.toLowerCase() == cat.name.toLowerCase()).length;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Picture with dark overlay gradient
                            Expanded(
                              flex: 3,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    cat.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.broken_image_rounded, color: AppTheme.mutedGrey),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 14,
                                    right: 14,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cat.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 17,
                                              letterSpacing: -0.3,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$catDealCount deals',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Footer actions
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showAddEditCategoryDialog(existingCategory: cat),
                                    icon: const Icon(Icons.edit_rounded, size: 16),
                                    label: const Text('Edit Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryGreen,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorRed),
                                    onPressed: () => _confirmDeleteCategory(cat),
                                    tooltip: 'Delete Category',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 18,
        vertical: isCompact ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 9 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isCompact ? 20 : 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.mutedGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isCompact ? 1 : 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.charcoal,
                      letterSpacing: -0.5,
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
}
