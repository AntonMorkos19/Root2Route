/// Represents the lifecycle status of a withdrawal request.
enum WithdrawalStatus { pending, approved, rejected, processed }

/// Parses a raw status value (String or int) from the API into a typed enum.
WithdrawalStatus _parseStatus(dynamic raw) {
  if (raw == null) return WithdrawalStatus.pending;
  switch (raw.toString().toLowerCase()) {
    case 'approved':
    case '1':
      return WithdrawalStatus.approved;
    case 'rejected':
    case '2':
      return WithdrawalStatus.rejected;
    case 'processed':
    case '3':
      return WithdrawalStatus.processed;
    case 'pending':
    case '0':
    default:
      return WithdrawalStatus.pending;
  }
}

class WithdrawalModel {
  final String id;
  final String organizationId;
  final double amount;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String swiftCode;
  final WithdrawalStatus status;
  final String? adminNote;
  final DateTime? createdAt;

  const WithdrawalModel({
    required this.id,
    required this.organizationId,
    required this.amount,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.swiftCode,
    required this.status,
    this.adminNote,
    this.createdAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase and PascalCase keys from the backend.
    final amountRaw =
        json['amount'] ?? json['Amount'] ?? 0;
    final double parsedAmount =
        amountRaw is num ? amountRaw.toDouble() : double.tryParse(amountRaw.toString()) ?? 0.0;

    // Parse createdAt safely.
    DateTime? parsedDate;
    final dateStr =
        json['createdAt'] ?? json['CreatedAt'] ?? json['createdOn'] ?? json['CreatedOn'];
    if (dateStr != null && dateStr is String && dateStr.isNotEmpty) {
      try {
        String normalized = dateStr;
        if (!normalized.endsWith('Z') && !normalized.contains('+')) {
          normalized += 'Z';
        }
        parsedDate = DateTime.parse(normalized).toLocal();
      } catch (_) {}
    }

    return WithdrawalModel(
      id: (json['id'] ?? json['Id'] ?? json['withdrawalId'] ?? json['WithdrawalId'] ?? '').toString(),
      organizationId: (json['organizationId'] ?? json['OrganizationId'] ?? '').toString(),
      amount: parsedAmount,
      bankName: (json['bankName'] ?? json['BankName'] ?? '').toString(),
      accountName: (json['accountName'] ?? json['AccountName'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? json['AccountNumber'] ?? '').toString(),
      swiftCode: (json['swiftCode'] ?? json['SwiftCode'] ?? '').toString(),
      status: _parseStatus(json['status'] ?? json['Status']),
      adminNote: (json['adminNote'] ?? json['AdminNote'])?.toString(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'organizationId': organizationId,
        'amount': amount,
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'swiftCode': swiftCode,
      };

  /// Human-readable Arabic label for the status.
  String get statusLabel {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'قيد الانتظار';
      case WithdrawalStatus.approved:
        return 'موافق عليه';
      case WithdrawalStatus.rejected:
        return 'مرفوض';
      case WithdrawalStatus.processed:
        return 'تمت المعالجة';
    }
  }
}
