import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';

class TabMap extends ConsumerStatefulWidget {
  const TabMap({super.key});

  @override
  ConsumerState<TabMap> createState() => _TabMapState();
}

class _TabMapState extends ConsumerState<TabMap> {
  final MapController _mapController = MapController();
  bool _showBusinesses = true;

  String? _selectedBusinessId;

  // Default center position (Accra, Ghana)
  static final LatLng _kAccra = LatLng(5.6037, -0.1870);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final markers = _buildMarkers(state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildMapControls(),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Row(
              children: [
                // Interactive OpenStreetMap (Free Forever)
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _kAccra,
                        initialZoom: 13.0,
                        maxZoom: 18,
                        minZoom: 10,
                      ),
                      children: [
                        // OpenStreetMap Tiles (CartoDB Positron - Clean/Silver style)
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                          userAgentPackageName: 'com.dreameats.app',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          retinaMode: RetinaMode.isHighDensity(context),
                          tileProvider: CancellableNetworkTileProvider(),
                        ),

                        // Markers Layer (Hubs)
                        MarkerLayer(
                          markers: markers,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),

                // Analytics Sidebar
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildTelemetryPanel(state),
                      const SizedBox(height: 24),
                      Expanded(child: _buildInspectorPanel(state)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlChip("🏪 Hubs", _showBusinesses, (v) => setState(() => _showBusinesses = v)),
        ],
      ),
    );
  }

  Widget _controlChip(String label, bool active, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.w600)),
      selected: active,
      onSelected: onChanged,
      selectedColor: Colors.white,
      backgroundColor: Colors.transparent,
      checkmarkColor: AppTheme.primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
    );
  }

  List<Marker> _buildMarkers(AppState state) {
    final List<Marker> markers = [];

    if (_showBusinesses) {
      for (final b in state.businesses) {
        markers.add(
          Marker(
            point: LatLng(b.latitude, b.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => setState(() => _selectedBusinessId = b.id),
              child: Icon(
                Icons.location_on_rounded,
                color: _selectedBusinessId == b.id ? AppTheme.primaryGreen : AppTheme.charcoal,
                size: 30,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildTelemetryPanel(AppState state) {
    final activeOrders = state.orders.where((o) => o.status == 'reserved').length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("OPERATIONAL PULSE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _telemetryRow("Active Rescues", "$activeOrders", Icons.shopping_bag_outlined),
          const Divider(height: 24),
          _telemetryRow("Hub Network", "${state.businesses.length} Active Hubs", Icons.storefront_outlined),
          const Divider(height: 24),
          _telemetryRow("Network Health", "Stable", Icons.check_circle_outline_rounded),
        ],
      ),
    );
  }

  Widget _telemetryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
      ],
    );
  }

  Widget _buildInspectorPanel(AppState state) {
    if (_selectedBusinessId == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_searching_rounded, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text("Hub Inspector", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Click a hub to view real-time intelligence.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
          ],
        ),
      );
    }

    final biz = state.businesses.firstWhere((b) => b.id == _selectedBusinessId);
    final bizOrders = state.orders.where((o) => o.businessId == biz.id).length;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(8)),
                child: const Text("ACTIVE HUB", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 9)),
              ),
              IconButton(onPressed: () => setState(() => _selectedBusinessId = null), icon: const Icon(Icons.close_rounded, size: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(biz.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
          Text(biz.location, style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          _inspectorStat("Active Volume", "$bizOrders rescues"),
          _inspectorStat("Hub Performance", "Excellent"),
          _inspectorStat("Hub Type", "Business Center"),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal, minimumSize: const Size(double.infinity, 52)),
            child: const Text("View Hub Details"),
          ),
        ],
      ),
    );
  }

  Widget _inspectorStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
        ],
      ),
    );
  }
}
