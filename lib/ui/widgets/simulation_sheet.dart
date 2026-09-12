import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';

class SimulationSheet extends StatelessWidget {
  const SimulationSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const SimulationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final isTripActive = provider.status == TripStatus.active;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SIMULATION & TEST TOOLS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF111827),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 8),
            if (!isTripActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Start a trip first to test location simulations.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                ),
              ),
            _buildTestButton(
              context: context,
              title: 'Simulate Valid Movement (+50m, 38 km/h)',
              subtitle: 'Tests normal speed and distance accumulation',
              enabled: isTripActive,
              onTap: () {
                provider.simulateLocationStep(
                  deltaLat: 0.00045,
                  deltaLon: 0.00045,
                  speedKmh: 38.0,
                  accuracy: 5.5,
                );
                Navigator.pop(context);
              },
            ),
            _buildTestButton(
              context: context,
              title: 'Simulate GPS Jump Spike (+5km instant)',
              subtitle: 'Tests unrealistic jump rejection filter',
              enabled: isTripActive,
              onTap: () {
                provider.simulateGpsJump();
                Navigator.pop(context);
              },
            ),
            _buildTestButton(
              context: context,
              title: 'Simulate Poor Accuracy Reading (75m)',
              subtitle: 'Tests accuracy threshold filter rejection',
              enabled: isTripActive,
              onTap: () {
                provider.simulatePoorAccuracy();
                Navigator.pop(context);
              },
            ),
            _buildTestButton(
              context: context,
              title: 'Simulate Stationary Drift (Signal Stop)',
              subtitle: 'Tests jitter suppression when standing still',
              enabled: isTripActive,
              onTap: () {
                provider.simulateStationaryDrift();
                Navigator.pop(context);
              },
            ),
            _buildTestButton(
              context: context,
              title: 'Trigger Offline Queue Sync',
              subtitle: 'Uploads pending offline points to Firebase',
              enabled: provider.pendingSyncCount > 0 && provider.isOnline,
              onTap: () {
                provider.syncPendingData();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? const Color(0xFF111827) : const Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: enabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: enabled ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: enabled ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }
}
