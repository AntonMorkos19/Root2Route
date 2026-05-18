class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final bool isOffer;
  final String offerStatus; // e.g., pending, accepted, rejected
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    this.isOffer = false,
    this.offerStatus = '',
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['Id'] ?? json['messageId'] ?? '';
    final roomIdRaw = json['roomId'] ?? json['RoomId'] ?? '';
    final senderIdRaw = json['senderId'] ?? json['SenderId'] ?? '';
    final textRaw = json['text'] ?? json['Text'] ?? json['content'] ?? '';
    final isOfferRaw = json['isOffer'] ?? json['IsOffer'] ?? false;
    final offerStatusRaw = json['offerStatus'] ?? json['OfferStatus'] ?? '';

    DateTime? parsedDate;
    final dateStr = json['createdAt'] ?? json['CreatedAt'] ?? json['createdOn'] ?? json['CreatedOn'];
    if (dateStr != null && dateStr is String && dateStr.isNotEmpty) {
      try {
        String normalized = dateStr;
        if (!normalized.endsWith('Z') && !normalized.contains('+')) {
          normalized += 'Z';
        }
        parsedDate = DateTime.parse(normalized).toLocal();
      } catch (_) {}
    }

    return ChatMessageModel(
      id: idRaw.toString(),
      roomId: roomIdRaw.toString(),
      senderId: senderIdRaw.toString(),
      text: textRaw.toString(),
      isOffer: isOfferRaw is bool ? isOfferRaw : isOfferRaw.toString().toLowerCase() == 'true',
      offerStatus: offerStatusRaw.toString(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'text': text,
      'isOffer': isOffer,
      'offerStatus': offerStatus,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
