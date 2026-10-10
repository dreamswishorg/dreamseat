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

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    final mapWidget = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 20 : 32),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kAccra,
              initialZoom: 13.0,
              maxZoom: 19,
              minZoom: 3,
            ),
            children: [
              // Google Maps Cartography Tiles
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.dreameats.dreameats',
                tileProvider: CancellableNetworkTileProvider(),
                maxZoom: 19,
              ),

              // Markers Layer (Hubs)
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),

          // Map Zoom & Recenter Controls
          Positioned(
            right: 14,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapFloatingBtn(
                  icon: Icons.add_rounded,
                  tooltip: "Zoom In",
                  onTap: () {
                    final nextZoom = (_mapController.camera.zoom + 1).clamp(3.0, 19.0);
                    _mapController.move(_mapController.camera.center, nextZoom);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapFloatingBtn(
                  icon: Icons.remove_rounded,
                  tooltip: "Zoom Out",
                  onTap: () {
                    final nextZoom = (_mapController.camera.zoom - 1).clamp(3.0, 19.0);
                    _mapController.move(_mapController.camera.center, nextZoom);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapFloatingBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: "Recenter on Accra",
                  onTap: () => _mapController.move(_kAccra, 13.0),
                ),
              ],
            ),
          ),

          // OpenStreetMap Attribution
          Positioned(
            left: 10,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
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
            child: isMobile
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 280, child: mapWidget),
                        const SizedBox(height: 16),
                        _buildTelemetryPanel(state),
                        if (_selectedBusinessId != null) ...[
                          const SizedBox(height: 16),
                          _buildInspectorPanel(state),
                        ],
                      ],
                    ),
                  )
                : Row(
                    children: [
                      // Interactive OpenStreetMap (Free & Open Source)
                      Expanded(
                        flex: 3,
                        child: mapWidget,
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

  Widget _buildMapFloatingBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 20, color: AppTheme.charcoal),
          ),
        ),
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
        if (b.latitude == 0 && b.longitude == 0) continue;
        final isSelected = _selectedBusinessId == b.id;
        markers.add(
          Marker(
            point: LatLng(b.latitude, b.longitude),
            width: isSelected ? 48 : 40,
            height: isSelected ? 48 : 40,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedBusinessId = b.id);
                _mapController.move(LatLng(b.latitude, b.longitude), 15.0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryGreen : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppTheme.primaryGreen.withValues(alpha: 0.45)
                          : const Color(0x1A000000),
                      blurRadius: isSelected ? 14 : 8,
                      offset: const Offset(0, 4),
                    ),
                    if (!isSelected)
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                  ],
                  border: Border.all(
                    color: isSelected ? Colors.white : AppTheme.primaryGreen,
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: isSelected ? Colors.white : AppTheme.primaryGreen,
                    size: isSelected ? 24 : 20,
                  ),
                ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("NETWORK TELEMETRY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          _telemetryRow("Active Rescues", "$activeOrders", Icons.shopping_bag_outlined),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _telemetryRow("Hub Network", "${state.businesses.length} Active Hubs", Icons.storefront_outlined),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _telemetryRow("Network Health", "100% Operational", Icons.check_circle_outline_rounded),
        ],
      ),
    );
  }

  Widget _telemetryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
      ],
    );
  }

  Widget _buildInspectorPanel(AppState state) {
    if (_selectedBusinessId == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_searching_rounded, size: 36, color: Color(0xFFCBD5E1)),
              SizedBox(height: 12),
              Text("Hub Intelligence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
              SizedBox(height: 4),
              Text("Click any map pin to inspect live telemetry.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedGrey, fontSize: 11.5)),
            ],
          ),
        ),
      );
    }

    final biz = state.businesses.firstWhere((b) => b.id == _selectedBusinessId);
    final bizOrders = state.orders.where((o) => o.businessId == biz.id).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(6)),
                child: const Text("VERIFIED HUB", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 9)),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedBusinessId = null),
                icon: const Icon(Icons.close_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(biz.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
          const SizedBox(height: 2),
          Text("${biz.category} • ${biz.location}", style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          _inspectorStat("Total Rescue Orders", "$bizOrders orders"),
          _inspectorStat("Average Rating", "${biz.rating.toStringAsFixed(1)} ★"),
          _inspectorStat("Operating Status", "Online & Open"),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("Inspect Full Ledger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
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
