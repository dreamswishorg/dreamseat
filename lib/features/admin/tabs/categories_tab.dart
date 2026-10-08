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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_photo_alternate_rounded,
                    color: AppTheme.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Category' : 'Add New Category',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Name
                      const Text(
                        'CATEGORY NAME',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Traditional Jollof, Fruit Box',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Image URL input
                      const Text(
                        'CATEGORY PICTURE URL',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: urlCtrl,
                        decoration: InputDecoration(
                          hintText: 'https://images.unsplash.com/...',
                          prefixIcon: const Icon(Icons.link_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => setDlgState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide an image URL' : null,
                      ),
                      const SizedBox(height: 12),

                      // Quick Preset Images Selector
                      const Text(
                        'OR SELECT A PRESET FOOD PHOTO:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 72,
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
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isPicked ? AppTheme.primaryGreen : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    preset['url']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFF1F5F9)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Live Image Preview
                      const Text(
                        'LIVE PICTURE PREVIEW',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: currentUrl.isNotEmpty
                            ? Image.network(
                                currentUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image_rounded, color: AppTheme.mutedGrey, size: 32),
                                      SizedBox(height: 4),
                                      Text('Invalid or broken image URL', style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image_outlined, color: AppTheme.mutedGrey, size: 32),
                                    SizedBox(height: 4),
                                    Text('No image specified yet', style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
                                  ],
                                ),
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
                child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category Catalog & Imagery',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage deal categories, set custom category cover photos, and organize taxonomy.',
                      style: TextStyle(fontSize: 13, color: AppTheme.mutedGrey.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditCategoryDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Row
            Row(
              children: [
                _buildStatCard(
                  title: 'Total Categories',
                  value: '${categories.length}',
                  icon: Icons.category_rounded,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Live Rescue Deals',
                  value: '${deals.length}',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Preset Food Photos',
                  value: '${_presetImages.length}',
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFFD97706),
                ),
              ],
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
                  final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.25,
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
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
