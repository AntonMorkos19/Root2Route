// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
// import 'package:root2route/features/auctions/cubit/auction_state.dart';
// import 'package:root2route/models/auction_model.dart';

// class AuctionDetailsScreen extends StatefulWidget {
//   static const String id = '/auctionDetailsScreen';

//   final String? auctionId;

//   const AuctionDetailsScreen({super.key, this.auctionId});

//   @override
//   State<AuctionDetailsScreen> createState() => _AuctionDetailsScreenState();
// }

// class _AuctionDetailsScreenState extends State<AuctionDetailsScreen> {
//   late String _auctionId;
//   bool _isInit = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_isInit) {
//       if (widget.auctionId != null && widget.auctionId!.isNotEmpty) {
//         _auctionId = widget.auctionId!;
//       } else {
//         final args = ModalRoute.of(context)?.settings.arguments;
//         if (args is String) {
//           _auctionId = args;
//         } else if (args is Map && args['id'] != null) {
//           _auctionId = args['id'];
//         } else if (args is AuctionModel) {
//           _auctionId = args.id;
//         } else {
//           _auctionId = '';
//         }
//       }

//       if (_auctionId.isNotEmpty) {
//         context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
//       }
//       _isInit = true;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6F9),
//       appBar: AppBar(
//         title: const Text('Auction Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black87),
//       ),
//       body: BlocBuilder<AuctionCubit, AuctionState>(
//         builder: (context, state) {
//           if (state is AuctionLoading || state is AuctionInitial) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
//               ),
//             );
//           } else if (state is AuctionError) {
//             return _buildErrorWidget(state.message);
//           } else if (state is AuctionSuccess<AuctionModel>) {
//             return _buildDetailsWidget(state.data);
//           }
//           return const Center(child: Text('No details available.'));
//         },
//       ),
//     );
//   }

//   Widget _buildErrorWidget(String message) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16, color: Colors.black87),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 if (_auctionId.isNotEmpty) {
//                   context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
//                 }
//               },
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF2ECC71),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailsWidget(AuctionModel auction) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _buildHeaderCard(auction),
//           const SizedBox(height: 16),
//           _buildInfoCard(auction),
//           const SizedBox(height: 16),
//           _buildCountdownCard(auction),
//           const SizedBox(height: 24),
//           if (auction.isActive)
//             ElevatedButton(
//               onPressed: null, // Disabled placeholder
//               style: ElevatedButton.styleFrom(
//                 disabledBackgroundColor: Colors.grey.shade400,
//                 disabledForegroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Text(
//                 'Place Bid',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderCard(AuctionModel auction) {
//     Color statusColor;
//     if (auction.isUpcoming) {
//       statusColor = Colors.orange;
//     } else if (auction.isActive) {
//       statusColor = Colors.green;
//     } else {
//       statusColor = Colors.grey;
//     }

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Text(
//                   auction.title ?? auction.productName ?? 'Auction',
//                   style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: statusColor.withOpacity(0.5)),
//                 ),
//                 child: Text(
//                   auction.status.toUpperCase(),
//                   style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoCard(AuctionModel auction) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           _buildInfoRow('Start Price', '${auction.startingPrice.toStringAsFixed(2)} EGP', Icons.monetization_on_outlined),
//           const Divider(height: 24),
//           _buildInfoRow('Current Highest Bid', auction.currentHighestBid != null ? '${auction.currentHighestBid!.toStringAsFixed(2)} EGP' : 'No bids yet', Icons.trending_up),
//           const Divider(height: 24),
//           _buildInfoRow('Minimum Increment', '${auction.minimumBidIncrement.toStringAsFixed(2)} EGP', Icons.add_circle_outline),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value, IconData icon) {
//     return Row(
//       children: [
//         Icon(icon, color: Colors.grey.shade600, size: 24),
//         const SizedBox(width: 12),
//         Text(
//           label,
//           style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
//         ),
//         const Spacer(),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
//         ),
//       ],
//     );
//   }

//   Widget _buildCountdownCard(AuctionModel auction) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.timer_outlined, color: Colors.grey.shade600),
//               const SizedBox(width: 8),
//               Text(
//                 auction.isUpcoming ? 'Starts In' : 'Time Remaining',
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           _AuctionTimer(auction: auction),
//         ],
//       ),
//     );
//   }
// }

// class _AuctionTimer extends StatefulWidget {
//   final AuctionModel auction;

//   const _AuctionTimer({required this.auction});

//   @override
//   State<_AuctionTimer> createState() => _AuctionTimerState();
// }

// class _AuctionTimerState extends State<_AuctionTimer> {
//   late Timer _timer;
//   late Duration _timeRemaining;

//   @override
//   void initState() {
//     super.initState();
//     _updateTime();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) _updateTime();
//     });
//   }

//   void _updateTime() {
//     setState(() {
//       _timeRemaining = widget.auction.timeRemaining;
//     });
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.auction.isEnded) {
//       return _buildMessageContainer('Auction Ended', Colors.red);
//     }

//     if (_timeRemaining.inSeconds <= 0) {
//       if (widget.auction.isUpcoming) {
//         return _buildMessageContainer('Starting Soon...', Colors.green);
//       }
//       return _buildMessageContainer('Auction Ended', Colors.red);
//     }

//     final days = _timeRemaining.inDays;
//     final hours = _timeRemaining.inHours.remainder(24);
//     final minutes = _timeRemaining.inMinutes.remainder(60);
//     final seconds = _timeRemaining.inSeconds.remainder(60);

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         if (days > 0) _buildTimeBox(days.toString().padLeft(2, '0'), 'Days'),
//         _buildTimeBox(hours.toString().padLeft(2, '0'), 'Hours'),
//         _buildTimeBox(minutes.toString().padLeft(2, '0'), 'Mins'),
//         _buildTimeBox(seconds.toString().padLeft(2, '0'), 'Secs'),
//       ],
//     );
//   }

//   Widget _buildMessageContainer(String message, Color color) {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color.withOpacity(0.2)),
//         ),
//         child: Text(
//           message,
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
//         ),
//       ),
//     );
//   }

//   Widget _buildTimeBox(String value, String label) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(
//             color: const Color(0xFFE8F8EE),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Text(
//             value,
//             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2ECC71)),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/models/auction_model.dart';
import 'package:root2route/services/api.dart'; // Ensure path is correct
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/services/chat_service.dart';
import 'package:root2route/screens/chat/chat_details_screen.dart';
import 'package:root2route/features/chat/cubit/chat_messages_cubit.dart';
import 'package:root2route/core/theme/app_colors.dart';

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

  // Adding bid variables
  final ApiService _api = ApiService();
  bool _isLoadingBids = true;
  List<dynamic> _bidsList = [];
  final TextEditingController _bidController = TextEditingController();

  /// Cached auction model — used to keep the UI visible during BidLoading/BidPlaced.
  AuctionModel? _lastAuction;

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
        // Fetching auction details with Cubit
        context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
        // Fetching bids list directly with API
        _fetchBids(_auctionId);
      }
      _isInit = true;
    }
  }

  Map<String, dynamic>? _productData;
  bool _isLoadingProduct = false;

  Future<void> _fetchProductData(String productId) async {
    if (_isLoadingProduct || _productData != null) return;
    if (mounted) setState(() => _isLoadingProduct = true);
    try {
      final res = await _api.getProductById(productId);
      if (mounted && res['success'] == true) {
        setState(() {
          _productData = res['data'];
          _isLoadingProduct = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingProduct = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  // =========================================
  // Bidding Logic Methods
  // =========================================

  Future<void> _fetchBids(String id) async {
    setState(() => _isLoadingBids = true);
    final result = await _api.getAuctionBids(id);

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _bidsList = result['data'] is List ? result['data'] : [];
        }
        _isLoadingBids = false;
      });
    }
  }

  /// Validates the entered amount and delegates to the Cubit.
  /// The Cubit emits [BidLoading] → [BidPlaced] or [AuctionError].
  void _submitBid(double currentHighestBid, String explicitAuctionId) {
    final double? enteredAmount = double.tryParse(_bidController.text.trim());

    if (enteredAmount == null || enteredAmount <= currentHighestBid) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Invalid Amount',
        text: 'Your bid must be higher than $currentHighestBid EGP',
      );
      return;
    }

    // Delegate to the Cubit — it handles Loading → Success/Error states.
    context.read<AuctionCubit>().placeBid(
      auctionId: explicitAuctionId,
      amount: enteredAmount,
    );
  }

  void _showBidBottomSheet(double currentHighestBid, String explicitAuctionId) {
    _bidController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Use a StatefulBuilder so the bottom sheet can rebuild on cubit changes.
      builder: (sheetContext) {
        return BlocConsumer<AuctionCubit, AuctionState>(
          listener: (ctx, state) {
            // When bid succeeds, close the sheet, refresh bids, show SnackBar.
            if (state is BidPlaced) {
              Navigator.of(sheetContext).pop(); // close bottom sheet
            } else if (state is AuctionError) {
              // Error SnackBar is shown in the outer BlocConsumer — nothing to do here.
            }
          },
          builder: (ctx, state) {
            final bool isBidLoading = state is BidLoading;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Bid Amount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Must be higher than $currentHighestBid EGP',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    enabled: !isBidLoading, // lock while loading
                    decoration: InputDecoration(
                      hintText: 'e.g. ${currentHighestBid + 100}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixText: 'EGP',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Disable the button while loading to prevent double-taps.
                      onPressed:
                          isBidLoading
                              ? null
                              : () => _submitBid(
                                currentHighestBid,
                                explicitAuctionId,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        disabledBackgroundColor: const Color(
                          0xFF2ECC71,
                        ).withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isBidLoading
                              ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Confirm Bid',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================
  // UI Builders
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Auction Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<AuctionCubit, AuctionState>(
        listener: (context, state) {
          // Fetch product info when auction details arrive.
          if (state is AuctionSuccess<AuctionModel>) {
            if (_productData == null && !_isLoadingProduct) {
              _fetchProductData(state.data.productId);
            }
          }

          // ── Bid events ──────────────────────────────────────
          if (state is BidPlaced) {
            _bidController.clear();
            _fetchBids(state.auctionId); // refresh bids list
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Bid placed successfully!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF2ECC71),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }

          if (state is AuctionError) {
            // Only show SnackBar for bid-related errors (not for general fetch errors
            // which are handled by the builder showing an error widget).
            // We show a SnackBar here so the auction details remain visible.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          // Cache the last successfully loaded auction.
          if (state is AuctionSuccess<AuctionModel>) {
            _lastAuction = state.data;
          }

          // Full-screen spinner only on initial load (no data yet).
          if ((state is AuctionLoading || state is AuctionInitial) &&
              _lastAuction == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
              ),
            );
          }

          // Errors before details were ever loaded → show full-screen error.
          if (state is AuctionError && _lastAuction == null) {
            return _buildErrorWidget(state.message);
          }

          // BidLoading / BidPlaced / AuctionError after details loaded →
          // keep showing the last known details (SnackBar handles feedback).
          if (_lastAuction != null) {
            return _buildDetailsWidget(_lastAuction!);
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
              style: TextStyle(
                fontSize: 16,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_auctionId.isNotEmpty) {
                  context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
                  _fetchBids(_auctionId);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsWidget(AuctionModel auction) {
    final currentHighest = auction.currentHighestBid ?? auction.startingPrice;
    final bool isGuest = StorageService().isGuest;
    final String? currentOrgId = StorageService().currentUserOrgId;

    final String? pOrgId =
        _productData != null
            ? (_productData!['organizationId'] ??
                    _productData!['OrganizationId'])
                ?.toString()
            : (auction.organizationId?.isNotEmpty == true
                ? auction.organizationId
                : null);

    final bool isOwner =
        !isGuest &&
        currentOrgId != null &&
        currentOrgId.isNotEmpty &&
        pOrgId != null &&
        currentOrgId == pOrgId;

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

          // Bid History
          Text(
            'Bid History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).textTheme.titleLarge?.color ?? Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildBidHistoryCard(),
          const SizedBox(height: 24),

          // Bid Button and Contact Seller Button
          if (isOwner) ...[
            if (auction.isActive)
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'You own this auction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (isGuest) {
                        Navigator.pushNamed(context, LoginScreen.id);
                        return;
                      }
                      final sellerId = pOrgId;
                      if (sellerId == null || sellerId.isEmpty) return;

                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.loading,
                        title: 'Starting Chat...',
                        text: 'Please wait',
                        barrierDismissible: false,
                      );

                      try {
                        final roomId = await ChatService().startChat(
                          organizationId: sellerId,
                          productId: auction.productId,
                        );
                        if (context.mounted) {
                          Navigator.pop(context); // close loading
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => BlocProvider(
                                    create:
                                        (_) => ChatMessagesCubit(ChatService()),
                                    child: ChatDetailsScreen(
                                      roomId: roomId,
                                      roomName:
                                          _productData?['sellerName'] ??
                                          _productData?['organizationName'] ??
                                          'Seller',
                                    ),
                                  ),
                            ),
                          );
                        }
                      } catch (e, stackTrace) {
                        debugPrint("🔥 EXACT ERROR: $e");
                        debugPrint("🔥 STACK TRACE: $stackTrace");
                        if (context.mounted) {
                          Navigator.pop(context);
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.error,
                            title: 'Error',
                            text: 'Connection failed. Please check the logs.',
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Contact Seller',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (auction.isActive) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (isGuest) {
                          Navigator.pushNamed(context, LoginScreen.id);
                          return;
                        }
                        _showBidBottomSheet(currentHighest, _auctionId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isGuest ? 'Login to Bid' : 'Place Bid',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBidHistoryCard() {
    if (_isLoadingBids) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
      );
    }

    if (_bidsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No bids yet. Be the first!',
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  Colors.white70,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true, // Crucial to avoid errors with SingleChildScrollView
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _bidsList.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final bid = _bidsList[index];
          final amount = bid['amount'] ?? 0;
          final bidderName = bid['bidderName'] ?? 'Bidder';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2ECC71).withOpacity(0.1),
              child: const Icon(Icons.person, color: Color(0xFF2ECC71)),
            ),
            title: Text(
              bidderName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '${amount.toString()} EGP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  // Your cards as they are, do not modify anything
  Widget _buildHeaderCard(AuctionModel auction) {
    Color statusColor;
    if (auction.isUpcoming) {
      statusColor = Colors.orange;
    } else if (auction.isActive) {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.grey;
    }

    String? imageUrl = auction.productImage;
    if (imageUrl == null || imageUrl.isEmpty) {
      if (_productData != null) {
        imageUrl =
            _productData!['imageUrl'] ??
            _productData!['ImageUrl'] ??
            _productData!['image'] ??
            _productData!['Image'];
        if (imageUrl == null) {
          final pImages = _productData!['images'] ?? _productData!['Images'];
          if (pImages is List && pImages.isNotEmpty) {
            imageUrl = pImages.first?.toString();
          }
        }
      }
    }
    final displayUrl =
        (imageUrl != null && imageUrl.startsWith('/'))
            ? 'https://root2route.runasp.net$imageUrl'
            : imageUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          if (displayUrl != null && displayUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(displayUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint('Error loading auction image: $exception');
                  },
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  auction.title ?? auction.productName ?? 'Auction',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.titleLarge?.color ??
                        Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  auction.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
        color: Theme.of(context).colorScheme.surface,
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
          _buildInfoRow(
            'Start Price',
            '${auction.startingPrice.toStringAsFixed(2)} EGP',
            Icons.monetization_on_outlined,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Current Highest Bid',
            auction.currentHighestBid != null
                ? '${auction.currentHighestBid!.toStringAsFixed(2)} EGP'
                : 'No bids yet',
            Icons.trending_up,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Minimum Increment',
            '${auction.minimumBidIncrement.toStringAsFixed(2)} EGP',
            Icons.add_circle_outline,
          ),
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
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownCard(AuctionModel auction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).textTheme.titleMedium?.color ??
                      Colors.white,
                ),
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

// Timer class exactly as it is
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2ECC71),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
