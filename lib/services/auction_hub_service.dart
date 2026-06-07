import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:logging/logging.dart';

/// Data class representing a real-time bid update from SignalR.
class LiveBidUpdate {
  final double newAmount;
  final String bidderId;

  const LiveBidUpdate({required this.newAmount, required this.bidderId});

  @override
  String toString() => 'LiveBidUpdate(amount: $newAmount, bidder: $bidderId)';
}

/// Service handling the SignalR connection to the Auction Hub.
///
/// Mirrors the established pattern from [ChatHubService] but tailored
/// for auction-specific group management, real-time bid events, and
/// live state retrieval as specified in the backend integration guide.
class AuctionHubService {
  HubConnection? _hubConnection;

  // ─── Streams ─────────────────────────────────────────────────────────────
  /// Broadcasts [LiveBidUpdate] events received from the hub's "ReceiveNewBid".
  final _bidController = StreamController<LiveBidUpdate>.broadcast();
  Stream<LiveBidUpdate> get onNewBid => _bidController.stream;

  /// Broadcasts connection state changes for UI indicators.
  final _connectionStateController = StreamController<HubConnectionState>.broadcast();
  Stream<HubConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;

  /// Current connection state accessor.
  HubConnectionState? get connectionState => _hubConnection?.state;

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  // ─── Connection ──────────────────────────────────────────────────────────

  /// Initializes and starts the SignalR connection to the Auction Hub.
  ///
  /// [jwtToken] is the user's current access token for authorization.
  Future<void> connect(String jwtToken) async {
    // Avoid duplicate connections
    if (_hubConnection?.state == HubConnectionState.Connected) {
      debugPrint('[AuctionHub] Already connected.');
      return;
    }

    const serverUrl = 'https://root2route.runasp.net/hubs/auction';

    // Configure logging (matches ChatHubService pattern)
    Logger.root.level = Level.WARNING;
    Logger.root.onRecord.listen((LogRecord rec) {
      debugPrint('[AuctionHub] ${rec.level.name}: ${rec.message}');
    });

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          serverUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => jwtToken,
          ),
        )
        .withAutomaticReconnect()
        .build();

    // Register lifecycle callbacks
    _hubConnection!.onclose(({error}) {
      debugPrint('[AuctionHub] Connection closed. Error: $error');
      _connectionStateController.add(HubConnectionState.Disconnected);
    });

    _hubConnection!.onreconnecting(({error}) {
      debugPrint('[AuctionHub] Reconnecting... Error: $error');
      _connectionStateController.add(HubConnectionState.Reconnecting);
    });

    _hubConnection!.onreconnected(({connectionId}) {
      debugPrint('[AuctionHub] Reconnected! ConnectionId: $connectionId');
      _connectionStateController.add(HubConnectionState.Connected);
    });

    // Setup event listeners BEFORE starting
    _setupListeners();

    try {
      await _hubConnection!.start();
      debugPrint('[AuctionHub] ✅ Connected successfully.');
      _connectionStateController.add(HubConnectionState.Connected);
    } catch (e, stackTrace) {
      debugPrint('[AuctionHub] ❌ Connection failed: $e');
      debugPrint('[AuctionHub] Stack: $stackTrace');
      _connectionStateController.add(HubConnectionState.Disconnected);
      rethrow;
    }
  }

  // ─── Event Listeners ─────────────────────────────────────────────────────

  void _setupListeners() {
    if (_hubConnection == null) return;

    // Listen for real-time bid updates
    // Backend signature: ReceiveNewBid(decimal newAmount, Guid bidderId)
    _hubConnection!.on('ReceiveNewBid', (args) {
      if (args != null && args.length >= 2) {
        try {
          final newAmount = double.tryParse(args[0].toString()) ?? 0.0;
          final bidderId = args[1].toString();

          final update = LiveBidUpdate(
            newAmount: newAmount,
            bidderId: bidderId,
          );

          debugPrint('[AuctionHub] 📢 ReceiveNewBid: $update');
          _bidController.add(update);
        } catch (e) {
          debugPrint('[AuctionHub] Error parsing ReceiveNewBid: $e');
        }
      }
    });
  }

  // ─── Group Management ────────────────────────────────────────────────────

  /// Joins the SignalR group for a specific auction to receive its real-time updates.
  ///
  /// Call this when the user navigates to an auction details screen.
  Future<void> joinAuctionGroup(String auctionId) async {
    if (_hubConnection?.state != HubConnectionState.Connected) {
      debugPrint('[AuctionHub] ⚠️ Cannot join group — not connected.');
      return;
    }
    try {
      await _hubConnection!.invoke('JoinAuctionGroup', args: [auctionId]);
      debugPrint('[AuctionHub] 📌 Joined auction group: $auctionId');
    } catch (e) {
      debugPrint('[AuctionHub] ❌ Failed to join group $auctionId: $e');
    }
  }

  /// Leaves the SignalR group for a specific auction.
  ///
  /// Call this when the user navigates away from the auction details screen
  /// to avoid memory leaks and unnecessary network traffic.
  Future<void> leaveAuctionGroup(String auctionId) async {
    if (_hubConnection?.state != HubConnectionState.Connected) {
      debugPrint('[AuctionHub] ⚠️ Cannot leave group — not connected.');
      return;
    }
    try {
      await _hubConnection!.invoke('LeaveAuctionGroup', args: [auctionId]);
      debugPrint('[AuctionHub] 👋 Left auction group: $auctionId');
    } catch (e) {
      debugPrint('[AuctionHub] ❌ Failed to leave group $auctionId: $e');
    }
  }

  // ─── Live State Retrieval ────────────────────────────────────────────────

  /// Fetches the current live auction state directly from the hub.
  ///
  /// Useful on first load or after a reconnection to sync the latest state
  /// without needing an HTTP API call.
  ///
  /// Returns a map: `{"currentHighestBid": 150.50, "highestBidderId": "guid-..."}`,
  /// or `null` if the invocation fails.
  Future<Map<String, dynamic>?> getAuctionState(String auctionId) async {
    if (_hubConnection?.state != HubConnectionState.Connected) {
      debugPrint('[AuctionHub] ⚠️ Cannot get state — not connected.');
      return null;
    }
    try {
      final result = await _hubConnection!
          .invoke('GetAuctionState', args: [auctionId]);

      if (result is Map) {
        debugPrint('[AuctionHub] 📊 AuctionState for $auctionId: $result');
        return Map<String, dynamic>.from(result);
      }

      debugPrint('[AuctionHub] ⚠️ Unexpected state format: $result');
      return null;
    } catch (e) {
      debugPrint('[AuctionHub] ❌ Failed to get auction state: $e');
      return null;
    }
  }

  // ─── Disconnect & Cleanup ────────────────────────────────────────────────

  /// Stops the hub connection gracefully.
  Future<void> disconnect() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (e) {
        debugPrint('[AuctionHub] Error during disconnect: $e');
      }
      _hubConnection = null;
      debugPrint('[AuctionHub] 🛑 Disconnected.');
    }
  }

  /// Closes all stream controllers and disconnects.
  /// Call this from the Cubit's `close()` method.
  void dispose() {
    _bidController.close();
    _connectionStateController.close();
    disconnect();
  }
}
