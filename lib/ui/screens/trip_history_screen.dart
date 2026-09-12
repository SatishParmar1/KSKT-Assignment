import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/trip_model.dart';
import '../widgets/status_badge.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final trips = provider.completedTrips;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'TRIP HISTORY',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No completed trips yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _buildTripCard(trip);
              },
            ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy • HH:mm');
    final String dateString = formatter.format(trip.startTime);
    final double distanceKm = trip.totalDistance / 1000.0;

    String durationText = '--';
    if (trip.endTime != null) {
      final diff = trip.endTime!.difference(trip.startTime);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      durationText = '${minutes}m ${seconds}s';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip.tripId,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              StatusBadge(
                label: trip.status.toUpperCase(),
                isDark: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateString,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTripStat(
                label: 'DISTANCE',
                value: '${distanceKm.toStringAsFixed(2)} km',
              ),
              _buildTripStat(
                label: 'DURATION',
                value: durationText,
              ),
              _buildTripStat(
                label: 'MAX SPEED',
                value: '${trip.maxSpeed.toStringAsFixed(1)} km/h',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTripStat(
                label: 'AVG SPEED',
                value: '${trip.averageSpeed.toStringAsFixed(1)} km/h',
              ),
              _buildTripStat(
                label: 'POINTS ACCEPTED',
                value: '${trip.totalLocations}',
              ),
              _buildTripStat(
                label: 'REJECTED JUMPS',
                value: '${trip.rejectedLocations}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
