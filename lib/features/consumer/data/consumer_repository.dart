// lib/features/consumer/data/consumer_repository.dart
import '../domain/entities/consumer_models.dart';

abstract class ConsumerRepository {
  Future<List<Product>> getCatalog();
  Future<List<ConsumerOrder>> getOrders();
  Future<List<LinkInfo>> getLinks();
  Future<List<Complaint>> getComplaints();

  Future<void> createOrder(Product product);
  Future<void> requestLink(String supplierCode);
  Future<void> createComplaint(int orderId, String text);
}
