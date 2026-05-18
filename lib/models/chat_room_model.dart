import 'package:flutter/foundation.dart';

class ChatRoomModel {
  final String id;
  final String chatTitle;       // Dynamic: otherPartyName > organizationName
  final String organizationName;
  final String productName;
  final String lastMessage;
  final String lastMessageAt;
  final int unreadCount;
  final bool isClosed;

  ChatRoomModel({
    required this.id,
    this.chatTitle = '',
    this.organizationName = '',
    this.productName = '',
    this.lastMessage = '',
    this.lastMessageAt = '',
    this.unreadCount = 0,
    this.isClosed = false,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    debugPrint("Room JSON: $json");
    
    // Dynamic title: backend returns otherPartyName for buyer context, organizationName for seller context
    final chatTitle = (json['otherPartyName'] ?? json['organizationName'] ?? 'Chat').toString();

    return ChatRoomModel(
      id: (json['id'] ?? json['Id'] ?? json['chatRoomId'] ?? json['roomId'] ?? '').toString(),
      chatTitle: chatTitle,
      organizationName: (json['organizationName'] ?? json['otherPartyName'] ?? json['sellerName'] ?? json['participantName'] ?? 'Unknown').toString(),
      productName: (json['productName'] ?? '').toString(),
      lastMessage: (json['lastMessageSnippet'] ?? json['lastMessage'] ?? json['LastMessage'] ?? '').toString(),
      lastMessageAt: (json['lastMessageAt'] ?? json['LastMessageAt'] ?? json['updatedAt'] ?? json['createdAt'] ?? '').toString(),
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : int.tryParse(json['unreadCount'].toString()) ?? 0,
      isClosed: (json['isClosed'] ?? json['IsClosed'] ?? false) == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatTitle': chatTitle,
      'organizationName': organizationName,
      'productName': productName,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'unreadCount': unreadCount,
      'isClosed': isClosed,
    };
  }
}

