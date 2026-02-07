import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:sango/services/cancellation_service.dart';
import 'package:sango/models/cancellation_model.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CancelledRidesTab extends StatefulWidget {
  const CancelledRidesTab({Key? key}) : super(key: key);

  @override
  State<CancelledRidesTab> createState() => _CancelledRidesTabState();
}

class _CancelledRidesTabState extends State<CancelledRidesTab> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  CancellationHistoryResponse? _cancellationHistory;
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMoreData = false;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCancellationHistory();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreData();
      }
    }
  }

  Future<void> _fetchCancellationHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasError = false;
      });
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    final result = await CancellationService.getCancellationHistory(
      page: _currentPage,
      limit: _limit,
    );

    if (result['success']) {
      final data = result['data'] as CancellationHistoryResponse;
      setState(() {
        _cancellationHistory = data;
        _isLoading = false;
        _hasMoreData = data.pagination.currentPage < data.pagination.totalPages;
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = result['message'];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final result = await CancellationService.getCancellationHistory(
      page: _currentPage + 1,
      limit: _limit,
    );

    if (result['success']) {
      final newData = result['data'] as CancellationHistoryResponse;
      setState(() {
        _currentPage++;
        _cancellationHistory?.cancellations.addAll(newData.cancellations);
        _hasMoreData =
            newData.pagination.currentPage < newData.pagination.totalPages;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!; // Get localization

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_cancellationHistory?.cancellations.isEmpty ?? true) {
      return EmptyState(
        icon: Icons.cancel_outlined,
        title: s.noCancelledRides,
        subtitle: s.cancelledRidesWillAppearHere,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCancellationHistory(refresh: true),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Total Cancelled: ${_cancellationHistory?.totalCancelled ?? 0}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                if ((_cancellationHistory?.pagination.totalPages ?? 0) > 1)
                  Text(
                    'Page ${_cancellationHistory?.pagination.currentPage}/${_cancellationHistory?.pagination.totalPages}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: (_cancellationHistory?.cancellations.length ?? 0) +
                  (_hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >=
                    (_cancellationHistory?.cancellations.length ?? 0)) {
                  return _buildLoadMoreIndicator();
                }
                final cancellation = _cancellationHistory!.cancellations[index];
                return _buildCancellationCard(cancellation);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load cancellation history',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchCancellationHistory(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07723D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildCancellationCard(Cancellation cancellation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with booking code and category
            Row(
              children: [
                Expanded(
                  child: Text(
                    () {
                      String bookingCode =
                          cancellation.bookingCode?.toString() ?? 'N/A';
                      String truncatedCode = (bookingCode.length > 13)
                          ? '${bookingCode.substring(0, 8)}...${bookingCode.substring(bookingCode.length - 5)}'
                          : bookingCode;
                      return 'Booking #$truncatedCode';
                    }(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cancel,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cancelled',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),

            // Vehicle category with image
            Row(
              children: [
                // Category image
                if (cancellation.catgImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: cancellation.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.car_rental, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.car_rental, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),

                // Category details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cancellation.catgName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated price: \$${cancellation.estimatedPrice}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Locations
            _buildLocationInfo(
              icon: Icons.location_on,
              title: 'Pickup',
              location: cancellation.pickupLocation,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _buildLocationInfo(
              icon: Icons.flag,
              title: 'Dropoff',
              location: cancellation.dropoffLocation,
              color: Colors.red,
            ),
            const Divider(),

            // Cancellation details
            // Text(
            //   'Reason: ${cancellation.cancellationReason}',
            //   style: TextStyle(
            //     color: Colors.red[700],
            //     fontStyle: FontStyle.italic,
            //   ),
            // ),
            const SizedBox(height: 8),

            // Dates
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${cancellation.formattedCreatedAt}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Cancelled: ${cancellation.formattedCancelledAt}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required String title,
    required String location,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                location,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
