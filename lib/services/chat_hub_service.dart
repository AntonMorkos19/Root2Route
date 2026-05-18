import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:root2route/models/chat_message_model.dart';
import 'package:logging/logging.dart';

class ChatHubService {
  HubConnection? _hubConnection;
  
  // Stream to broadcast received messages
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  Stream<ChatMessageModel> get onMessageReceived => _messageController.stream;

  Future<void> connect(String jwtToken) async {
    final serverUrl = "https://root2route.runasp.net/hubs/chat";
    
    // Configure logging for signalr
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
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

    _setupListeners();

    try {
      await _hubConnection!.start();
      print(" Connected to ChatHub!");
    } catch (e, stackTrace) {
      print(" EXACT ERROR: $e");
      print(" STACK TRACE: $stackTrace");
    }
  }

  void _setupListeners() {
    if (_hubConnection == null) return;

    _hubConnection!.on("ReceiveMessage", (args) {
      if (args != null && args.isNotEmpty) {
        final messageData = args[0] as Map<String, dynamic>;
        try {
          final message = ChatMessageModel.fromJson(messageData);
          _messageController.add(message);
        } catch (e) {
          print("Error parsing ReceiveMessage data: $e");
        }
      }
    });

    // You can add more listeners here for ReceiveTypingIndicator, ReceiveOfferAccepted, etc.
  }

  Future<void> joinRoom(String roomId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke("JoinRoom", args: [roomId]);
      print("📌 Joined chat room: $roomId");
    }
  }

  Future<void> leaveRoom(String roomId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke("LeaveRoom", args: [roomId]);
      print("👋 Left chat room: $roomId");
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
      print("🛑 Disconnected from ChatHub");
    }
  }
  
  void dispose() {
    _messageController.close();
    disconnect();
  }
}
