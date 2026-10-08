import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';

class OrderTrackScreen extends ConsumerStatefulWidget {
  final Order? order;
  final String? initialRiderName;

  const OrderTrackScreen({
    super.key,
    this.order,
    this.initialRiderName,
  });

  @override
  ConsumerState<OrderTrackScreen> createState() => _OrderTrackScreenState();
}

class _OrderTrackScreenState extends ConsumerState<OrderTrackScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Simulated GPS Coordinates for route (Accra central to Cantonments/Osu route)
  static final LatLng _restaurantLoc = LatLng(5.5600, -0.1780); // Kitchen
  static final LatLng _waypointLoc = LatLng(5.5720, -0.1810);   // En-route junction
  static final LatLng _customerLoc = LatLng(5.5860, -0.1795);   // Customer Delivery

  late List<LatLng> _routePoints;
  late LatLng _riderPosition;
  double _riderProgress = 0.45; // 45% along the route
  int _etaMinutes = 10;
  Timer? _motionTimer;

  late String _riderName;
  final String _riderRating = '4.5(102+)';
  final String _riderPhone = '+233 24 567 8901';

  final List<Map<String, dynamic>> _messages = [
    {
      'isRider': true,
      'text': 'Hello! I picked up your fresh surplus meal. On my way now! 🛵',
      'time': 'Just now',
    },
  ];

  @override
  void initState() {
    super.initState();
    _riderName = widget.initialRiderName ?? (widget.order?.courierName?.isNotEmpty == true ? widget.order!.courierName! : 'Assigned Courier');
    _routePoints = [
      _restaurantLoc,
      LatLng(5.5650, -0.1790),
      _waypointLoc,
      LatLng(5.5780, -0.1805),
      _customerLoc,
    ];
    _riderPosition = _interpolatePoint(_riderProgress);

    // Subtle simulation of rider movement along the path
    _motionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _riderProgress += 0.05;
        if (_riderProgress > 0.95) _riderProgress = 0.95;
        _riderPosition = _interpolatePoint(_riderProgress);
        _etaMinutes = ((1.0 - _riderProgress) * 18).ceil().clamp(2, 25);
      });
    });
  }

  @override
  void dispose() {
    _motionTimer?.cancel();
    super.dispose();
  }

  LatLng _interpolatePoint(double t) {
    if (_routePoints.length < 2) return _customerLoc;
    final totalSegments = _routePoints.length - 1;
    final segIndex = (t * totalSegments).floor().clamp(0, totalSegments - 1);
    final segT = (t * totalSegments) - segIndex;

    final p1 = _routePoints[segIndex];
    final p2 = _routePoints[segIndex + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * segT;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * segT;
    return LatLng(lat, lng);
  }

  double _getRouteBearing() {
    if (_routePoints.length < 2) return 0.0;
    final totalSegments = _routePoints.length - 1;
    final segIndex = (_riderProgress * totalSegments).floor().clamp(0, totalSegments - 1);
    final p1 = _routePoints[segIndex];
    final p2 = _routePoints[segIndex + 1];
    final dLng = (p2.longitude - p1.longitude) * (pi / 180.0);
    final lat1 = p1.latitude * (pi / 180.0);
    final lat2 = p2.latitude * (pi / 180.0);
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    // Road bearing in radians
    return atan2(y, x);
  }

  Widget _buildTopDownDeliveryScooter() {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ground shadow
          Container(
            width: 18,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Scooter structure
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Front tire
              Container(
                width: 6,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Handlebars & mirrors
              Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 1),
              // Front body shield (Delivery Red)
              Container(
                width: 15,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              // Courier Helmet (Black with tinted visor)
              Container(
                width: 14,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF97316), width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              // Rear insulated delivery box (Red)
              Container(
                width: 17,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFFB91C1C),
                  borderRadius: BorderRadius.circular(2.5),
                  border: Border.all(color: Colors.white, width: 0.8),
                ),
                child: const Center(
                  child: Icon(Icons.lunch_dining_rounded, color: Colors.white, size: 7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _recenter() {
    _mapController.move(_riderPosition, 14.5);
  }

  void _showChatModal() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.lightGreenBg,
                        child: Text(
                          _riderName[0],
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _riderName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.charcoal,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Online • On Delivery',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.mutedGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Quick chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'I am waiting outside',
                        'Please call upon arrival',
                        'Leave at security gate',
                        'Extra napkins please',
                      ].map((chip) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(chip, style: const TextStyle(fontSize: 11.5)),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onPressed: () {
                              setState(() {
                                _messages.add({
                                  'isRider': false,
                                  'text': chip,
                                  'time': 'Just now',
                                });
                              });
                              setSheetState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Chat Messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, idx) {
                      final m = _messages[idx];
                      final isRider = m['isRider'] as bool;
                      return Align(
                        alignment: isRider ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          decoration: BoxDecoration(
                            color: isRider
                                ? const Color(0xFFF1F5F9)
                                : AppTheme.primaryGreen,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isRider ? 4 : 16),
                              bottomRight: Radius.circular(isRider ? 16 : 4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isRider
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            children: [
                              Text(
                                m['text'] as String,
                                style: TextStyle(
                                  color: isRider ? AppTheme.charcoal : Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m['time'] as String,
                                style: TextStyle(
                                  color: isRider
                                      ? AppTheme.mutedGrey
                                      : Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Input field
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textCtrl,
                          decoration: InputDecoration(
                            hintText: 'Message rider...',
                            hintStyle: const TextStyle(fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          onPressed: () {
                            final text = textCtrl.text.trim();
                            if (text.isNotEmpty) {
                              setState(() {
                                _messages.add({
                                  'isRider': false,
                                  'text': text,
                                  'time': 'Just now',
                                });
                              });
                              textCtrl.clear();
                              setSheetState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.lightGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Call Courier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect directly with $_riderName for delivery directions and gate access.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_iphone_rounded, color: AppTheme.mutedGrey, size: 18),
                  const SizedBox(width: 8),
                  Text(_riderPhone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Dial Now'),
            onPressed: () async {
              Navigator.pop(ctx);
              final cleanPhone = _riderPhone.replaceAll(RegExp(r'[^0-9+]'), '');
              final uri = Uri.parse('tel:$cleanPhone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📞 Dialing $_riderName ($_riderPhone)...'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showStoreCallDialog(String storeName, String storePhone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.lightGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store_rounded, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Call $storeName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect directly with the store for collection directions, opening hours, or pack inquiries.',
              style: TextStyle(fontSize: 13, color: AppTheme.charcoal, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_rounded, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      storePhone,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: AppTheme.charcoal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.mutedGrey),
                    tooltip: 'Copy Number',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: storePhone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Store phone number copied!'),
                          backgroundColor: AppTheme.primaryGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final cleanPhone = storePhone.replaceAll(RegExp(r'[^0-9+]'), '');
              final uri = Uri.parse('tel:$cleanPhone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📞 Calling $storePhone...'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderList = ref.watch(appStateProvider).orders;
    final order = widget.order != null
        ? orderList.firstWhere((o) => o.id == widget.order!.id, orElse: () => widget.order!)
        : null;

    final businesses = ref.watch(appStateProvider).businesses;
    final business = (order != null && order.businessId.isNotEmpty)
        ? businesses.where((b) => b.id == order.businessId).firstOrNull
        : null;

    final bool isPickup = order == null || order.fulfillmentType == 'pickup';
    final dealTitle = order?.dealTitle ?? 'Surplus Meal Pack';
    final businessName = order?.businessName ?? (business?.name ?? 'Local Partner Kitchen');
    
    final displayName = isPickup
        ? businessName
        : (order.courierName?.isNotEmpty == true ? order.courierName! : (widget.initialRiderName ?? 'Assigned Courier'));
    final displayPhone = isPickup
        ? (business?.phone.isNotEmpty == true ? business!.phone : '+233 24 412 3456')
        : (order.courierPhone?.isNotEmpty == true ? order.courierPhone! : _riderPhone);

    final status = order?.status ?? 'reserved';
    final bool isPreparing = status == 'preparing' || status == 'ready' || status == 'collected';
    final bool isReady = status == 'ready' || status == 'collected';
    final bool isCollected = status == 'collected';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── MAP BACKGROUND ─────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _waypointLoc,
              initialZoom: 14.0,
              maxZoom: 18,
              minZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.dreameats.dreameats',
                tileProvider: CancellableNetworkTileProvider(),
              ),

              // Green Polyline Route matching the picture
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 6.0,
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),

              // Markers
              MarkerLayer(
                markers: [
                  // Kitchen Origin
                  Marker(
                    point: _restaurantLoc,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: AppTheme.primaryGreen,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // Destination Waypoint
                  Marker(
                    point: _customerLoc,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(isPickup ? Icons.storefront_rounded : Icons.home_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Courier / Scooter Rider Marker (Only if delivery)
                  if (!isPickup)
                    Marker(
                      point: _riderPosition,
                      width: 48,
                      height: 48,
                      child: Transform.rotate(
                        angle: _getRouteBearing(),
                        child: _buildTopDownDeliveryScooter(),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── FLOATING TOP BAR ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.charcoal),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          isPickup ? 'Store Pickup Tracker' : 'Delivery Tracker',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance leading icon
                  ],
                ),
              ),
            ),
          ),

          // ── RECENTER FLOATING BUTTON ────────────────────────────────────
          Positioned(
            right: 20,
            bottom: isPickup ? 280 : 230,
            child: FloatingActionButton.small(
              heroTag: 'track_recenter',
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.charcoal,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: _recenter,
              child: const Icon(Icons.my_location_rounded, size: 20),
            ),
          ),

          // ── FLOATING BOTTOM ORDER CARD ──────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Timeline Row for Pickup
                  if (isPickup) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PICKUP PROGRESS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedGrey, letterSpacing: 0.8),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCollected
                                ? const Color(0xFFDCFCE7)
                                : (isReady ? const Color(0xFFFEF3C7) : AppTheme.lightGreenBg),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: isCollected
                                  ? const Color(0xFF16A34A)
                                  : (isReady ? const Color(0xFFD97706) : AppTheme.primaryGreen),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 4 Step Visual Track
                    Row(
                      children: [
                        _buildStepIndicator(label: 'Placed', isDone: true),
                        _buildStepDivider(isDone: isPreparing),
                        _buildStepIndicator(label: 'Prep', isDone: isPreparing),
                        _buildStepDivider(isDone: isReady),
                        _buildStepIndicator(label: 'Ready', isDone: isReady),
                        _buildStepDivider(isDone: isCollected),
                        _buildStepIndicator(label: 'Rescued', isDone: isCollected),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Pickup Code Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGreen, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('COLLECTION CODE (SHOW CASHIER)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                Text(
                                  order?.collectionCode != null ? '#${order!.collectionCode}' : 'READY',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                          if (order?.trackingNotes != null && order!.trackingNotes!.isNotEmpty)
                            Tooltip(
                              message: order.trackingNotes ?? '',
                              child: const Icon(Icons.notes_rounded, color: AppTheme.primaryGreen, size: 20),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Delivery Section Header
                    const Text(
                      'Courier Status',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Courier Details Row
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFED7AA),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF97316),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text('🛵', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name, Rating & ETA
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 2),
                                  Text(
                                    _riderRating,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.charcoal,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'out_for_delivery' ? '$_etaMinutes mins' : status.replaceAll('_', ' '),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.charcoal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Chat Button
                        Material(
                          color: AppTheme.lightGreenBg,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _showChatModal,
                            borderRadius: BorderRadius.circular(16),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Call Button
                        Material(
                          color: AppTheme.primaryGreen,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            onTap: _showCallDialog,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.phone_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Order summary footnote
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreenBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppTheme.primaryGreen,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dealTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.charcoal,
                              ),
                            ),
                            Text(
                              businessName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.mutedGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPickup)
                        ElevatedButton.icon(
                          onPressed: () => _showStoreCallDialog(businessName, displayPhone),
                          icon: const Icon(Icons.call_rounded, size: 14),
                          label: Text(
                            'Call Store ($displayPhone)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 36),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({required String label, required bool isDone}) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isDone ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isDone ? Icons.check_rounded : Icons.circle,
              color: Colors.white,
              size: isDone ? 12 : 6,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
            color: isDone ? AppTheme.charcoal : AppTheme.mutedGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isDone ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
      ),
    );
  }
}
