class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final bool isOffer;
  final String offerStatus; // pending, accepted, rejected
  final double? proposedPrice;
  final int? proposedQuantity;
  final DateTime? createdAt;
  final int type; // 0=Text, 1=Image, 2=File, 3=NegotiationOffer, etc.

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    this.isOffer = false,
    this.offerStatus = '',
    this.proposedPrice,
    this.proposedQuantity,
    this.createdAt,
    this.type = 0,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['Id'] ?? json['messageId'] ?? '';
    final roomIdRaw = json['roomId'] ?? json['RoomId'] ?? json['chatRoomId'] ?? json['ChatRoomId'] ?? '';
    final senderIdRaw = json['senderId'] ?? json['SenderId'] ?? '';

    // Accept both 'text', 'content', and 'Content' from REST + SignalR payloads
    final textRaw = json['text'] ?? json['Text'] ?? json['content'] ?? json['Content'] ?? '';

    final typeRaw = json['type'] ?? json['Type'] ?? json['messageType'] ?? json['MessageType'] ?? 0;
    final typeInt = typeRaw is int ? typeRaw : int.tryParse(typeRaw.toString()) ?? 0;

    // type == 3 means NegotiationOffer
    final isOfferRaw = json['isOffer'] ?? json['IsOffer'] ?? (typeInt == 3);
    final offerStatusRaw = json['offerStatus'] ?? json['OfferStatus'] ?? json['status'] ?? '';
    final proposedPriceRaw = json['proposedPrice'] ?? json['ProposedPrice'] ?? json['price'];
    final proposedQuantityRaw = json['proposedQuantity'] ?? json['ProposedQuantity'] ?? json['quantity'];

    DateTime? parsedDate;
    // Accept 'sentAt' (SignalR payload) and 'createdAt' / 'CreatedAt' (REST response)
    final dateStr = json['sentAt'] ?? json['SentAt'] ??
        json['createdAt'] ?? json['CreatedAt'] ??
        json['createdOn'] ?? json['CreatedOn'];
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
      isOffer: isOfferRaw is bool
          ? isOfferRaw
          : isOfferRaw.toString().toLowerCase() == 'true',
      offerStatus: offerStatusRaw.toString(),
      proposedPrice: proposedPriceRaw != null
          ? double.tryParse(proposedPriceRaw.toString())
          : null,
      proposedQuantity: proposedQuantityRaw != null
          ? int.tryParse(proposedQuantityRaw.toString())
          : null,
      createdAt: parsedDate,
      type: typeInt,
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
      'proposedPrice': proposedPrice,
      'proposedQuantity': proposedQuantity,
      'createdAt': createdAt?.toIso8601String(),
      'type': type,
    };
  }
}
