import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabApprovals extends ConsumerStatefulWidget {
  const TabApprovals({super.key});

  @override
  ConsumerState<TabApprovals> createState() => _TabApprovalsState();
}

class _TabApprovalsState extends ConsumerState<TabApprovals> {
  int _selectedFilter = 0; // 0 = Pending, 1 = Active
  int _currentPage = 0;
  static const int _itemsPerPage = 8;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final pending = state.businesses.where((b) => !b.isApproved).toList();
    final active = state.businesses.where((b) => b.isApproved).toList();
    final allList = _selectedFilter == 0 ? pending : active;

    final filteredByQuery = allList.where((b) {
      if (_searchQuery.isEmpty) return true;
      return b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Reset page if filter changes and current page is out of bounds
    final totalPages = (filteredByQuery.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    } else if (filteredByQuery.isEmpty) {
      _currentPage = 0;
    }

    final list = filteredByQuery.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 0;
                    }),
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.charcoal),
                    decoration: const InputDecoration(
                      hintText: "Search merchants by name, category...",
                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.mutedGrey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _filterTab("Pending Queue (${pending.length})", 0),
                    _filterTab("Verified Partners (${active.length})", 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: list.isEmpty
                ? NoDataState(
                    icon: _selectedFilter == 0 ? Icons.verified_user_rounded : Icons.storefront_rounded,
                    msg: _selectedFilter == 0 ? "Application queue is currently empty." : "No verified partners detected in the system.",
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final b = list[i];
                            return _MerchantApprovalCard(
                              business: b,
                              onApprove: () => ref.read(appStateProvider.notifier).setMerchantApproval(b.id, true),
                              onSuspend: () => ref.read(appStateProvider.notifier).setMerchantApproval(b.id, false),
                              onViewVault: () => _showVault(context, b),
                            );
                          },
                        ),
                      ),
                      if (totalPages > 1) _buildPagination(totalPages),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 16),
          Text(
            "Page ${_currentPage + 1} of $totalPages",
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 13),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, int index) {
    final sel = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFilter = index;
        _currentPage = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: sel
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
            color: sel ? AppTheme.primaryGreen : AppTheme.mutedGrey,
          ),
        ),
      ),
    );
  }

  void _showVault(BuildContext context, BusinessProfile b) {
    final state = ref.read(appStateProvider);
    final kycLogs = state.auditLogs.where((log) => 
      log.action == 'KYC_UPLOAD' && 
      log.entityId == b.id
    ).toList();

    String getDocSub(String title, String defaultSub) {
      final log = kycLogs.firstWhere(
        (l) => l.metadata['document_title']?.toString().toLowerCase().contains(title.toLowerCase()) ?? false,
        orElse: () => AuditLog(id: '', actorId: '', actorName: '', actorRole: '', action: '', entityType: '', entityId: '', description: '', metadata: {}, createdAt: DateTime.now())
      );
      if (log.id.isNotEmpty) {
        final refNum = log.metadata['reference_number'] ?? 'Uploaded';
        return "Ref: $refNum";
      }
      return defaultSub;
    }

    String? getDocUrl(String title) {
      final log = kycLogs.firstWhere(
        (l) => l.metadata['document_title']?.toString().toLowerCase().contains(title.toLowerCase()) ?? false,
        orElse: () => AuditLog(id: '', actorId: '', actorName: '', actorRole: '', action: '', entityType: '', entityId: '', description: '', metadata: {}, createdAt: DateTime.now())
      );
      return log.id.isNotEmpty ? log.metadata['file_url']?.toString() : null;
    }

    final bizUrl = getDocUrl("business");
    final healthUrl = getDocUrl("health");
    final taxUrl = getDocUrl("vat");

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          width: 850,
          constraints: const BoxConstraints(maxHeight: 720),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppTheme.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("KYC Compliance Vault", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                          Text("Verification documents for ${b.name} (${b.category})", style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Summary Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.mutedGrey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.location,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: b.isApproved ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        b.isApproved ? "✅ VERIFIED & APPROVED" : "⌛ PENDING APPROVAL",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: b.isApproved ? AppTheme.primaryGreen : const Color(0xFFB45309),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Document Cards Grid
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _KycDocVaultCard(
                          title: "Business Registration",
                          sub: getDocSub("business", "Verified GH-2024-882"),
                          fileUrl: bizUrl,
                          business: b,
                          icon: Icons.business_center_rounded,
                          onInspect: () => _viewDocument(context, "Business Registration", bizUrl, b),
                        ),
                        _KycDocVaultCard(
                          title: "Health & Safety Permit",
                          sub: getDocSub("health", "Valid: Oct 2025"),
                          fileUrl: healthUrl,
                          business: b,
                          icon: Icons.health_and_safety_rounded,
                          onInspect: () => _viewDocument(context, "Health & Safety Certificate", healthUrl, b),
                        ),
                        _KycDocVaultCard(
                          title: "VAT / Tax Certificate",
                          sub: getDocSub("vat", "GRA Compliant"),
                          fileUrl: taxUrl,
                          business: b,
                          icon: Icons.account_balance_wallet_rounded,
                          onInspect: () => _viewDocument(context, "VAT Registration", taxUrl, b),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.charcoal,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text("Close Vault", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewDocument(BuildContext context, String title, String? fileUrl, BusinessProfile business) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 650,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${business.name} • Pinch to zoom & inspect",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  height: 450,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: fileUrl != null && fileUrl.isNotEmpty
                        ? Image.network(
                            fileUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, color: AppTheme.errorRed, size: 48),
                                    SizedBox(height: 12),
                                    Text("Failed to load document image", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
                                  ],
                                ),
                              );
                            },
                          )
                        : _buildSimulatedCertificate(business, title),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black.withValues(alpha: 0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (fileUrl != null)
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primaryGreen, size: 16),
                        label: const Text("Open Original Url", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("File URL: $fileUrl"), backgroundColor: AppTheme.primaryGreen),
                          );
                        },
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Done"),
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

  Widget _buildSimulatedCertificate(BusinessProfile business, String title) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF7),
        border: Border.all(color: const Color(0xFFD4AF37), width: 6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4AF37), size: 48),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "REPUBLIC OF GHANA",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.mutedGrey,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                "This certifies that the business profile",
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 6),
              Text(
                business.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "located at ${business.location} is officially registered and compliant with standard operating procedures.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("REFERENCE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                  Text("GH-9982-2026", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                ],
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.verified_rounded, color: Color(0xFFD4AF37), size: 28),
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("STATUS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                  Text("VALID & VERIFIED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KycDocVaultCard extends StatelessWidget {
  final String title;
  final String sub;
  final String? fileUrl;
  final BusinessProfile business;
  final IconData icon;
  final VoidCallback onInspect;

  const _KycDocVaultCard({
    required this.title,
    required this.sub,
    required this.fileUrl,
    required this.business,
    required this.icon,
    required this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final hasUploadedImage = fileUrl != null && fileUrl!.isNotEmpty;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(fontSize: 10.5, color: context.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Uploaded Image Preview Area
          GestureDetector(
            onTap: onInspect,
            child: Container(
              height: 160,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasUploadedImage)
                    Image.network(
                      fileUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen));
                      },
                      errorBuilder: (context, error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_rounded, color: AppTheme.mutedGrey, size: 32),
                            const SizedBox(height: 6),
                            Text("Image preview unavailable", style: TextStyle(fontSize: 10, color: context.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    // Fallback Official Certificate Mockup Thumbnail
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFFFCFBF7),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4AF37), size: 28),
                          const SizedBox(height: 4),
                          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          const Text("REPUBLIC OF GHANA", style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 1)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text("VERIFIED SEAL", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                          ),
                        ],
                      ),
                    ),

                  // Overlay Hover/Tap Banner
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text("Tap to Zoom", style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),

                  // Badge top-left: Live Upload vs Verified Record
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasUploadedImage ? AppTheme.primaryGreen : Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasUploadedImage ? "LIVE UPLOAD" : "COMPLIANCE RECORD",
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: onInspect,
                icon: const Icon(Icons.fullscreen_rounded, size: 15),
                label: const Text("Inspect Document", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textPrimary,
                  side: BorderSide(color: context.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantApprovalCard extends StatelessWidget {
  final BusinessProfile business;
  final VoidCallback onApprove;
  final VoidCallback onSuspend;
  final VoidCallback onViewVault;

  const _MerchantApprovalCard({
    required this.business,
    required this.onApprove,
    required this.onSuspend,
    required this.onViewVault,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.borderColor),
            boxShadow: context.clientShadow,
          ),
          child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildLogo(48),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfo(context, 16, 12, 11)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildVaultBtn(context, 40, 12)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildActionBtn(40, 12)),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  _buildLogo(56),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInfo(context, 18, 13, 11)),
                  const SizedBox(width: 16),
                  _buildVaultBtn(context, 44, 12),
                  const SizedBox(width: 12),
                  _buildActionBtn(44, 12),
                ],
              ),
        );
      }
    );
  }

  Widget _buildLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.lightGreenBg,
        borderRadius: BorderRadius.circular(12),
        image: business.logoUrl.isNotEmpty
          ? DecorationImage(image: NetworkImage(business.logoUrl), fit: BoxFit.cover)
          : null,
      ),
      child: business.logoUrl.isEmpty
        ? Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen, size: size * 0.5)
        : null,
    );
  }

  Widget _buildInfo(BuildContext context, double titleSize, double subSize, double metaSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                business.name,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: titleSize, color: context.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(isApproved: business.isApproved),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "${business.category} • ${business.location}",
          style: TextStyle(fontSize: subSize, color: context.textSecondary, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 14, color: AppTheme.goldAccent),
            const SizedBox(width: 4),
            Text(
              business.rating.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: metaSize, color: context.textPrimary),
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time_rounded, size: 12, color: context.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text("Applied 2d ago", style: TextStyle(fontSize: metaSize - 1, color: context.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildVaultBtn(BuildContext context, double height, double fontSize) {
    return OutlinedButton.icon(
      onPressed: onViewVault,
      icon: const Icon(Icons.folder_shared_rounded, size: 14),
      label: Text("KYC Vault", style: TextStyle(fontSize: fontSize)),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(120, height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: context.borderColor, width: 1.5),
        foregroundColor: context.textPrimary,
      ),
    );
  }

  Widget _buildActionBtn(double height, double fontSize) {
    if (!business.isApproved) {
      return ElevatedButton.icon(
        onPressed: onApprove,
        icon: const Icon(Icons.check_circle_rounded, size: 14),
        label: Text("Approve", style: TextStyle(fontSize: fontSize)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: Size(120, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onSuspend,
        icon: const Icon(Icons.block_rounded, size: 14),
        label: Text("Suspend", style: TextStyle(fontSize: fontSize)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorRed,
          foregroundColor: Colors.white,
          minimumSize: Size(120, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isApproved;
  const _StatusBadge({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isApproved ? AppTheme.primaryGreen : AppTheme.warningOrange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isApproved ? "VERIFIED" : "PENDING",
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: isApproved ? AppTheme.primaryGreen : AppTheme.warningOrange,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
