class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final int unreadCount;
  final bool isClosed;

  ChatRoomModel({
    required this.id,
    this.participants = const [],
    this.lastMessage = '',
    this.unreadCount = 0,
    this.isClosed = false,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['Id'] ?? json['roomId'] ?? '';
    final lastMessageRaw = json['lastMessage'] ?? json['LastMessage'] ?? '';
    final unreadCountRaw = json['unreadCount'] ?? json['UnreadCount'] ?? 0;
    final isClosedRaw = json['isClosed'] ?? json['IsClosed'] ?? false;
    
    List<String> parsedParticipants = [];
    final partsRaw = json['participants'] ?? json['Participants'];
    if (partsRaw is List) {
      parsedParticipants = partsRaw.map((e) => e.toString()).toList();
    }

    return ChatRoomModel(
      id: idRaw.toString(),
      participants: parsedParticipants,
      lastMessage: lastMessageRaw.toString(),
      unreadCount: unreadCountRaw is int ? unreadCountRaw : int.tryParse(unreadCountRaw.toString()) ?? 0,
      isClosed: isClosedRaw is bool ? isClosedRaw : isClosedRaw.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'isClosed': isClosed,
    };
  }
}
