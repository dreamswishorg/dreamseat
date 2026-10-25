import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';

class RiderDeliveryScreen extends ConsumerStatefulWidget {
  final Order order;
  const RiderDeliveryScreen({super.key, required this.order});

  @override
  ConsumerState<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends ConsumerState<RiderDeliveryScreen> {
  late MapController _mapController;
  final LatLng _restaurantLoc = const LatLng(5.6037, -0.1870); // Central Accra
  final LatLng _customerLoc = const LatLng(5.6200, -0.1700);
  late LatLng _riderLoc;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _riderLoc = const LatLng(5.6080, -0.1820);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String nextStatus) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(appStateProvider.notifier).riderUpdateDeliveryStatus(
        orderId: widget.order.id,
        status: nextStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery updated: ${nextStatus.toUpperCase()}'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showCompleteDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delivery Proof', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask the customer for their 4-digit Delivery PIN to confirm handoff:',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt_outlined, size: 16, color: AppTheme.primaryGreen),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Digital Proof of Delivery verified automatically', style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              Navigator.pop(ctx);
              setState(() => _isUpdating = true);
              try {
                await ref.read(appStateProvider.notifier).riderUpdateDeliveryStatus(
                  orderId: widget.order.id,
                  status: 'delivered',
                  pin: pin,
                  proofUrl: 'https://dreameats.gh/pod/${widget.order.id}.jpg',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 Delivery successfully completed! Trip payout credited.'), backgroundColor: AppTheme.primaryGreen),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isUpdating = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Confirm Delivered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportFailedDialog() {
    String selectedReason = 'Customer Unreachable';
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.report_problem_rounded, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Report Delivery Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Reporting a failed delivery will alert dispatch and initiate the cancellation & customer refund process.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey),
              ),
              const SizedBox(height: 16),
              ...['Customer Unreachable', 'Incorrect / Inaccessible Address', 'Restaurant Order Cancelled', 'Damaged Packaging'].map(
                (reason) {
                  final isSelected = selectedReason == reason;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setSheetState(() => selectedReason = reason),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? Colors.red : AppTheme.mutedGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppTheme.charcoal : AppTheme.mutedGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: 'Additional details for dispatch...',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _isUpdating = true);
                    try {
                      final reason = '$selectedReason: ${notesController.text.trim()}';
                      await ref.read(appStateProvider.notifier).riderUpdateDeliveryStatus(
                        orderId: widget.order.id,
                        status: 'failed',
                        reason: reason,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed delivery reported: $selectedReason. Customer refund triggered.'), backgroundColor: Colors.orange.shade800),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error reporting issue: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isUpdating = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Report & Cancel Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current live status
    final liveOrder = ref.watch(appStateProvider.select(
      (s) => s.orders.firstWhere((o) => o.id == widget.order.id, orElse: () => widget.order),
    ));
    final deliveryStatus = liveOrder.deliveryStatus;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Trip #${liveOrder.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            tooltip: 'Report Delivery Issue',
            onPressed: _showReportFailedDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Map View ──────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _riderLoc,
                    initialZoom: 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'org.dreamseat.dreameats',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_restaurantLoc, _riderLoc, _customerLoc],
                          strokeWidth: 4,
                          color: AppTheme.primaryGreen,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _restaurantLoc,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.storefront_rounded, color: Colors.blue, size: 30),
                        ),
                        Marker(
                          point: _customerLoc,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 32),
                        ),
                        Marker(
                          point: _riderLoc,
                          width: 44,
                          height: 44,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.navigation_rounded, color: AppTheme.primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                deliveryStatus == 'picked_up' || deliveryStatus == 'in_transit'
                                    ? 'Head to Customer Location'
                                    : 'Head to Restaurant for Pickup',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                deliveryStatus == 'picked_up' || deliveryStatus == 'in_transit'
                                    ? (liveOrder.deliveryAddress ?? 'Accra Central')
                                    : liveOrder.businessName,
                                style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            'GHS ${AppTheme.formatPrice(liveOrder.deliveryFee > 0 ? liveOrder.deliveryFee : 12.0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Sheet Controls ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CUSTOMER', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                          Text(liveOrder.customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(liveOrder.deliveryAddress ?? 'Accra, Ghana', style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey), maxLines: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('📞 Dialing ${liveOrder.customerName}...')),
                        );
                      },
                      icon: const Icon(Icons.phone, size: 14),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: AppTheme.charcoal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pickup Code reminder
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppTheme.primaryGreen),
                      const SizedBox(width: 10),
                      Text(
                        'Pickup Code: ${liveOrder.collectionCode}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      const Spacer(),
                      Text(
                        liveOrder.paymentMethod.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Step Buttons
                if (_isUpdating)
                  const Center(child: CircularProgressIndicator())
                else if (deliveryStatus == 'assigned')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('picked_up'),
                      icon: const Icon(Icons.check_box_outlined, size: 20),
                      label: const Text('Confirm Order Picked Up at Restaurant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  )
                else if (deliveryStatus == 'picked_up')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('in_transit'),
                      icon: const Icon(Icons.directions_bike_rounded, size: 20),
                      label: const Text('Start Heading to Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  )
                else if (deliveryStatus == 'in_transit')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showCompleteDialog,
                      icon: const Icon(Icons.verified_rounded, size: 20),
                      label: const Text('Arrived & Complete Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: Text('Trip status: ${deliveryStatus.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
