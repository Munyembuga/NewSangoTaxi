import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sango/l10n/l10n.dart'; // Add this import

class ClientCompletedRideCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const ClientCompletedRideCard({
    Key? key,
    required this.trip,
  }) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanedNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      print('Could not launch $launchUri: $e');
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!; // Get localization

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        () {
                          String bookingCode =
                              trip['booking_code']?.toString() ?? 'N/A';
                          String truncatedCode = (bookingCode.length > 13)
                              ? '${bookingCode.substring(0, 8)}...${bookingCode.substring(bookingCode.length - 5)}'
                              : bookingCode;
                          return '${s.ride} $truncatedCode';
                        }(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${trip['trip_summary']?['final_amount']?.toString() ?? trip['estimated_price']?.toString() ?? '0'} FCFA',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Route information
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip['trip_pickup']?.toString() ??
                              trip['pickup_location']?.toString() ??
                              'Unknown pickup',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          trip['trip_dropoff']?.toString() ??
                              trip['dropoff_location']?.toString() ??
                              'Unknown destination',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Trip details
              if (trip['trip_summary']?['started_at'] != null ||
                  trip['trip_summary']?['completed_at'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (trip['trip_summary']?['started_at'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.startedAt(_formatTime(
                                          trip['trip_summary']['started_at']
                                              ?.toString())),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          if (trip['trip_summary']?['completed_at'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 12, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.completedAt(_formatTime(
                                          trip['trip_summary']['completed_at']
                                              ?.toString())),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (trip['actual_trip_duration'] != null ||
                          trip['trip_summary']?['distance_km'] != null)
                        const SizedBox(height: 8),
                      if (trip['actual_trip_duration'] != null ||
                          trip['trip_summary']?['distance_km'] != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (trip['actual_trip_duration'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.timer,
                                      size: 12, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    trip['actual_trip_duration']?.toString() ??
                                        'N/A',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.blue),
                                  ),
                                ],
                              ),
                            if (trip['trip_summary']?['distance_km'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.directions_car,
                                      size: 12, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${trip['trip_summary']['distance_km']?.toString() ?? '0'} km',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.orange),
                                  ),
                                ],
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // Driver info and rating section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip['driver']?['name']?.toString() ??
                                'Unknown Driver',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (trip['driver']?['phone'] != null)
                            GestureDetector(
                              onTap: () => _makePhoneCall(
                                  trip['driver']['phone'].toString()),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone,
                                      size: 12, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    trip['driver']['phone'].toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (trip['driver']?['vehicle'] != null)
                            Text(
                              '${trip['driver']['vehicle']['color']} ${trip['driver']['vehicle']['model']} (${trip['driver']['vehicle']['plaque']})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Rating button
                    if (trip['can_rate_driver'] == true)
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement rating functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Rating feature coming soon')),
                          );
                        },
                        icon: const Icon(Icons.star, size: 16),
                        label: const Text('Rate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Rated',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
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
}
