// lib/features/sales/domain/entities/sales_models.dart
class SalesConsumer {
  final int id;
  final String name;
  final String status;
  final String? city;
  final int linkId; // ID of the link for this consumer
  final int? assignedSalesRepId; // ID of assigned sales rep (null if not assigned)
  final String? requestMessage; // Message from consumer when requesting link

  SalesConsumer({
    required this.id,
    required this.name,
    required this.status,
    this.city,
    required this.linkId,
    this.assignedSalesRepId,
    this.requestMessage,
  });

  factory SalesConsumer.fromJson(Map<String, dynamic> json) {
    return SalesConsumer(
      id: json['id'] as int,
      name: json['business_name'] as String? ?? json['name'] as String? ?? 'Consumer',
      status: 'pending', // Default status, will be updated from link data
      city: json['city'] as String?,
      linkId: json['link_id'] as int? ?? 0, // Will be set from link data
      assignedSalesRepId: json['assigned_sales_rep_id'] as int?,
      requestMessage: json['request_message'] as String?,
    );
  }
}

class SalesOrder {
  final int id;
  final String consumerName;
  final String status;
  final double total;
  final String? orderNumber;
  final String currency;

  SalesOrder({
    required this.id,
    required this.consumerName,
    required this.status,
    required this.total,
    this.orderNumber,
    this.currency = 'KZT',
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json, {String? consumerName}) {
    return SalesOrder(
      id: json['id'] as int,
      consumerName: consumerName ?? 'Consumer #${json['consumer_id']}',
      status: json['status'] as String,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      orderNumber: json['order_number'] as String?,
      currency: json['currency'] as String? ?? 'KZT',
    );
  }
}

class SalesComplaint {
  final int id;
  final String consumerName;
  final String title;
  final String status;
  final String? description;
  final int? linkId; // Link ID for chat
  final bool isEscalated; // Whether complaint is escalated
  final String? escalatedToManagerName; // Name of manager it's escalated to

  SalesComplaint({
    required this.id,
    required this.consumerName,
    required this.title,
    required this.status,
    this.description,
    this.linkId,
    this.isEscalated = false,
    this.escalatedToManagerName,
  });

  factory SalesComplaint.fromJson(Map<String, dynamic> json, {String? consumerName}) {
    return SalesComplaint(
      id: json['id'] as int,
      consumerName: consumerName ?? 'Consumer #${json['consumer_id']}',
      title: json['title'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      linkId: json['link_id'] as int?,
      isEscalated: json['status'] == 'escalated' || json['escalated_to_manager_id'] != null,
      escalatedToManagerName: json['escalated_to_manager_name'] as String?,
    );
  }
}

class SalesMessage {
  final int id;
  final String from;
  final String text;
  final DateTime createdAt;
  final int linkId;
  final int? senderId; // ID of the sender to determine if it's from current user

  SalesMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.createdAt,
    required this.linkId,
    this.senderId,
  });

  factory SalesMessage.fromJson(Map<String, dynamic> json) {
    return SalesMessage(
      id: json['id'] as int,
      from: json['sender_id'] != null ? 'User #${json['sender_id']}' : 'Unknown',
      text: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      linkId: json['link_id'] as int,
      senderId: json['sender_id'] as int?,
    );
  }
}
