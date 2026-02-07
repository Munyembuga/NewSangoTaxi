import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart'; // Add this import
import 'tabs/completed_rides_tab.dart';
import 'tabs/pending_rides_tab.dart';
import 'tabs/cancelled_rides_tab.dart';
import 'tabs/on_trip_tab.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!; // Get localization

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(s.rideHistory),
        backgroundColor: const Color(0xFFF5141E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(
              text: s.pending,
            ),
            Tab(
              text: s.onTrip,
            ),
            Tab(
              text: s.completed,
            ),
            Tab(
              text: s.cancelled,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PendingRidesTab(),
          OnTripTab(),
          CompletedRidesTab(),
          CancelledRidesTab(),
        ],
      ),
    );
  }
}
