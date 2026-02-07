import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart';
import 'rent/pendingRent.dart';
import 'rent/confirmedRent.dart';

class MainRentScreen extends StatefulWidget {
  const MainRentScreen({Key? key}) : super(key: key);

  @override
  State<MainRentScreen> createState() => _MainRentScreenState();
}

class _MainRentScreenState extends State<MainRentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(s.carRentals),
        backgroundColor: const Color(0xFFF5141E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: s.pending,
            ),
            Tab(
              text: s.confirmed,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PendingRent(),
          ConfirmedRent(),
        ],
      ),
    );
  }
}
