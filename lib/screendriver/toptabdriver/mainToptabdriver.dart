import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:sango/screendriver/toptabdriver/assgined.dart';
import 'package:sango/screendriver/toptabdriver/canceled.dart';
import 'package:sango/screendriver/toptabdriver/confirmed.dart';
import 'package:sango/screendriver/toptabdriver/completed.dart';
import 'package:sango/screendriver/toptabdriver/ontrip.dart';

class rideScreenDriver extends StatefulWidget {
  const rideScreenDriver({Key? key}) : super(key: key);

  @override
  State<rideScreenDriver> createState() => _rideScreenDriverState();
}

class _rideScreenDriverState extends State<rideScreenDriver>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final s = S.of(context)!;

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
            Tab(text: s.pending),
            Tab(text: s.confirmed),
            Tab(text: s.onTrip),
            Tab(text: s.completed),
            Tab(text: s.cancelled),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AssignedRidesTab(),
          ConfirmedRidesTab(),
          OnRidesTab(),
          CompletedRidesDriverTab(),
          CanceledRidesDriverTab()
        ],
      ),
    );
  }
}
