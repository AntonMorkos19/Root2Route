import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/models/auction_model.dart';

class AuctionDetailsScreen extends StatefulWidget {
  static const String id = '/auctionDetailsScreen';
  
  final String? auctionId;

  const AuctionDetailsScreen({super.key, this.auctionId});

  @override
  State<AuctionDetailsScreen> createState() => _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends State<AuctionDetailsScreen> {
  late String _auctionId;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      if (widget.auctionId != null && widget.auctionId!.isNotEmpty) {
        _auctionId = widget.auctionId!;
      } else {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          _auctionId = args;
        } else if (args is Map && args['id'] != null) {
          _auctionId = args['id'];
        } else if (args is AuctionModel) {
          _auctionId = args.id;
        } else {
          _auctionId = '';
        }
      }
      
      if (_auctionId.isNotEmpty) {
        context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
      }
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Auction Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: BlocBuilder<AuctionCubit, AuctionState>(
        builder: (context, state) {
          if (state is AuctionLoading || state is AuctionInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
              ),
            );
          } else if (state is AuctionError) {
            return _buildErrorWidget(state.message);
          } else if (state is AuctionSuccess<AuctionModel>) {
            return _buildDetailsWidget(state.data);
          }
          return const Center(child: Text('No details available.'));
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_auctionId.isNotEmpty) {
                  context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsWidget(AuctionModel auction) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(auction),
          const SizedBox(height: 16),
          _buildInfoCard(auction),
          const SizedBox(height: 16),
          _buildCountdownCard(auction),
          const SizedBox(height: 24),
          if (auction.isActive)
            ElevatedButton(
              onPressed: null, // Disabled placeholder
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Place Bid',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(AuctionModel auction) {
    Color statusColor;
    if (auction.isUpcoming) {
      statusColor = Colors.orange;
    } else if (auction.isActive) {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  auction.title ?? auction.productName ?? 'Auction',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  auction.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AuctionModel auction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Start Price', '${auction.startingPrice.toStringAsFixed(2)} EGP', Icons.monetization_on_outlined),
          const Divider(height: 24),
          _buildInfoRow('Current Highest Bid', auction.currentHighestBid != null ? '${auction.currentHighestBid!.toStringAsFixed(2)} EGP' : 'No bids yet', Icons.trending_up),
          const Divider(height: 24),
          _buildInfoRow('Minimum Increment', '${auction.minimumBidIncrement.toStringAsFixed(2)} EGP', Icons.add_circle_outline),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildCountdownCard(AuctionModel auction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                auction.isUpcoming ? 'Starts In' : 'Time Remaining',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AuctionTimer(auction: auction),
        ],
      ),
    );
  }
}

class _AuctionTimer extends StatefulWidget {
  final AuctionModel auction;

  const _AuctionTimer({required this.auction});

  @override
  State<_AuctionTimer> createState() => _AuctionTimerState();
}

class _AuctionTimerState extends State<_AuctionTimer> {
  late Timer _timer;
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    setState(() {
      _timeRemaining = widget.auction.timeRemaining;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auction.isEnded) {
      return _buildMessageContainer('Auction Ended', Colors.red);
    }

    if (_timeRemaining.inSeconds <= 0) {
      if (widget.auction.isUpcoming) {
        return _buildMessageContainer('Starting Soon...', Colors.green);
      }
      return _buildMessageContainer('Auction Ended', Colors.red);
    }

    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours.remainder(24);
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (days > 0) _buildTimeBox(days.toString().padLeft(2, '0'), 'Days'),
        _buildTimeBox(hours.toString().padLeft(2, '0'), 'Hours'),
        _buildTimeBox(minutes.toString().padLeft(2, '0'), 'Mins'),
        _buildTimeBox(seconds.toString().padLeft(2, '0'), 'Secs'),
      ],
    );
  }

  Widget _buildMessageContainer(String message, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(
          message,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2ECC71)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
