// lib/features/sales/data/sales_repository.dart
import '../domain/entities/sales_models.dart';

abstract class SalesRepository {
  Future<List<SalesConsumer>> getLinkedConsumers();
  Future<List<SalesOrder>> getOrders();
  Future<List<SalesComplaint>> getComplaints();
  Future<List<SalesMessage>> getChatMessages(int consumerId);

  Future<void> acceptOrder(int orderId);
  Future<void> rejectOrder(int orderId);
  Future<void> sendMessage(int consumerId, String text);
}
