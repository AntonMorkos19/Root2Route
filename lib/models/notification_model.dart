class NotificationModel {
  final String id;
  final String message;
  final String title;
  bool isRead;
  final DateTime? createdAt;

  final String? type;
  final String? productId;
  final String? orderId;

  NotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    this.title = 'Notification',
    this.createdAt,
    this.type,
    this.productId,
    this.orderId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      isRead: json['isRead'] == true || json['isRead'] == 'true' || json['status'] == 'read',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      type: json['type']?.toString(),
      productId: json['productId']?.toString(),
      orderId: json['orderId']?.toString(),
    );
  }
}
