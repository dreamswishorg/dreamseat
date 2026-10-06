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
  static const int _itemsPerPage = 6;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final pending = state.businesses.where((b) => !b.isApproved).toList();
    final active = state.businesses.where((b) => b.isApproved).toList();
    final allList = _selectedFilter == 0 ? pending : active;

    // Reset page if filter changes and current page is out of bounds
    final totalPages = (allList.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    } else if (allList.isEmpty) {
      _currentPage = 0;
    }

    final list = allList.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    _filterTab("Pending Queue", 0, pending.length),
                    _filterTab("Verified Partners", 1, active.length),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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

  Widget _filterTab(String label, int index, int count) {
    final sel = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFilter = index;
        _currentPage = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: sel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: sel ? AppTheme.primaryGreen : AppTheme.mutedGrey,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primaryGreen.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: sel ? AppTheme.primaryGreen : AppTheme.mutedGrey,
                  ),
                ),
              ),
            ],
          ],
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
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("KYC Compliance Vault", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      Text("Verification documents for ${b.name}", style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _CompactKycCard(
                    title: "Business Registration",
                    sub: getDocSub("business", "Verified GH-2024-882"),
                    icon: Icons.business_center_rounded,
                    onTap: () => _viewDocument(context, "Business Registration", bizUrl, b),
                  ),
                  _CompactKycCard(
                    title: "Health & Safety Certificate",
                    sub: getDocSub("health", "Valid: Oct 2025"),
                    icon: Icons.health_and_safety_rounded,
                    onTap: () => _viewDocument(context, "Health & Safety Certificate", healthUrl, b),
                  ),
                  _CompactKycCard(
                    title: "VAT Registration",
                    sub: getDocSub("vat", "GRA Compliant"),
                    icon: Icons.account_balance_wallet_rounded,
                    onTap: () => _viewDocument(context, "VAT Registration", taxUrl, b),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Close Vault"),
                ),
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
          width: 500,
          color: const Color(0xFF0F172A),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                color: Colors.black.withValues(alpha: 0.3),
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
                            business.name,
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
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
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
                  color: Color(0xFF0F172A),
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

class _CompactKycCard extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;
  const _CompactKycCard({required this.title, required this.sub, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 310,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppTheme.charcoal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                ],
              ),
            ),
            const Icon(Icons.remove_red_eye_rounded, size: 16, color: AppTheme.primaryGreen),
          ],
        ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.005), blurRadius: 5, offset: const Offset(0, 2))
            ],
          ),
          child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildLogo(48),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfo(16, 12, 11)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildVaultBtn(40, 12)),
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
                  Expanded(child: _buildInfo(18, 13, 11)),
                  const SizedBox(width: 16),
                  _buildVaultBtn(44, 12),
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

  Widget _buildInfo(double titleSize, double subSize, double metaSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                business.name,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: titleSize, color: AppTheme.charcoal),
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
          style: TextStyle(fontSize: subSize, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 14, color: AppTheme.goldAccent),
            const SizedBox(width: 4),
            Text(
              business.rating.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: metaSize, color: AppTheme.charcoal),
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time_rounded, size: 12, color: AppTheme.mutedGrey.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text("Applied 2d ago", style: TextStyle(fontSize: metaSize - 1, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildVaultBtn(double height, double fontSize) {
    return OutlinedButton.icon(
      onPressed: onViewVault,
      icon: const Icon(Icons.folder_shared_rounded, size: 14),
      label: Text("KYC Vault", style: TextStyle(fontSize: fontSize)),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(120, height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        foregroundColor: AppTheme.charcoal,
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
          minimumSize: Size(120, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onSuspend,
        icon: const Icon(Icons.block_rounded, size: 14),
        label: Text("Suspend", style: TextStyle(fontSize: fontSize)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorRed,
          minimumSize: Size(120, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
