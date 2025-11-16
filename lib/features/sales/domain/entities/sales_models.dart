// lib/features/sales/domain/entities/sales_models.dart
class SalesConsumer {
  final int id;
  final String name;
  final String status;

  SalesConsumer({required this.id, required this.name, required this.status});
}

class SalesOrder {
  final int id;
  final String consumerName;
  final String status;
  final double total;

  SalesOrder({
    required this.id,
    required this.consumerName,
    required this.status,
    required this.total,
  });
}

class SalesComplaint {
  final int id;
  final String consumerName;
  final String title;
  final String status;

  SalesComplaint({
    required this.id,
    required this.consumerName,
    required this.title,
    required this.status,
  });
}

class SalesMessage {
  final int id;
  final String from;
  final String text;
  final DateTime createdAt;

  SalesMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.createdAt,
  });
}
