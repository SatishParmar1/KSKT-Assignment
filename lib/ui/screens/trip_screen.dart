import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/recovery_banner.dart';
import '../widgets/simulation_sheet.dart';
import 'trip_history_screen.dart';

class TripScreen extends StatelessWidget {
  const TripScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final isTripActive = provider.status == TripStatus.active;
    final isCompleted = provider.status == TripStatus.completed;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'RIDER TRACKING',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StatusBadge(
              label: provider.isOnline ? 'ONLINE' : 'OFFLINE',
              isDark: provider.isOnline,
              icon: provider.isOnline ? Icons.wifi : Icons.wifi_off,
            ),
          ),
          if (provider.pendingSyncCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusBadge(
                label: '${provider.pendingSyncCount} QUEUED',
                isDark: false,
                icon: Icons.sync,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF111827)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TripHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (provider.isRecoveredTrip)
                RecoveryBanner(
                  onDismiss: () => provider.dismissRecoveryBanner(),
                ),
              if (provider.errorMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 18, color: Color(0xFF111827)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF111827)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => provider.clearError(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TRIP STATUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTripActive
                                  ? 'TRACKING ACTIVE'
                                  : (isCompleted ? 'COMPLETED' : 'READY TO START'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: isTripActive
                              ? 'LIVE'
                              : (isCompleted ? 'FINISHED' : 'IDLE'),
                          isDark: isTripActive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    const SizedBox(height: 16),
                    const Text(
                      'ELAPSED TIME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(provider.tripDuration),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: 1.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (provider.currentTrip != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        provider.currentTrip!.tripId,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CURRENT SPEED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          isTripActive
                              ? provider.currentSpeed.toStringAsFixed(1)
                              : '0.0',
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'km/h',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Distance',
                      value: provider.totalDistanceKm >= 1.0
                          ? provider.totalDistanceKm.toStringAsFixed(2)
                          : provider.totalDistanceMeters.toStringAsFixed(0),
                      unit: provider.totalDistanceKm >= 1.0 ? 'km' : 'm',
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'Max Speed',
                      value: provider.maxSpeed.toStringAsFixed(1),
                      unit: 'km/h',
                      icon: Icons.speed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'GPS Accuracy',
                      value: provider.lastValidLocation != null
                          ? '±${provider.lastValidLocation!.accuracy.toStringAsFixed(1)}'
                          : '--',
                      unit: provider.lastValidLocation != null ? 'm' : null,
                      icon: Icons.my_location,
                      subtext: provider.lastValidLocation != null
                          ? (provider.lastValidLocation!.accuracy <= 15
                              ? 'Strong signal'
                              : 'Fair signal')
                          : 'Awaiting fix',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'GPS Fixes',
                      value: '${provider.acceptedPointsCount}',
                      unit: 'accepted',
                      icon: Icons.filter_alt_outlined,
                      subtext:
                          '${provider.rejectedPointsCount} jumps rejected',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LOCATION TELEMETRY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LATITUDE: ${provider.lastValidLocation?.latitude.toStringAsFixed(5) ?? '--'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          'LONGITUDE: ${provider.lastValidLocation?.longitude.toStringAsFixed(5) ?? '--'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    if (provider.lastRejectionReason != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: Color(0xFF111827)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Last rejected: ${provider.lastRejectionReason}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isTripActive && !isCompleted)
                ElevatedButton(
                  onPressed: provider.isProcessing
                      ? null
                      : () => provider.startTrip(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'START TRIP',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              if (isTripActive)
                ElevatedButton(
                  onPressed:
                      provider.isProcessing ? null : () => provider.endTrip(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'END TRIP',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              if (isCompleted)
                ElevatedButton(
                  onPressed: () => provider.resetToIdle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'START NEW TRIP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => SimulationSheet.show(context),
                icon: const Icon(Icons.tune, size: 16, color: Color(0xFF374151)),
                label: const Text(
                  'Simulation & Test Tools',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
