// lib/features/sales/data/sales_repository.dart
import '../domain/entities/sales_models.dart';

abstract class SalesRepository {
  Future<List<SalesConsumer>> getLinkedConsumers();
  Future<List<SalesOrder>> getOrders();
  Future<List<SalesComplaint>> getComplaints();
  Future<List<SalesMessage>> getChatMessages(int linkId);

  Future<void> acceptOrder(int orderId);
  Future<void> rejectOrder(int orderId);
  Future<void> sendMessage(int linkId, String text);
  Future<void> resolveComplaint(int complaintId, {required String resolution});
  Future<void> escalateComplaint(
    int complaintId, {
    required int managerUserId,
    String? note,
  });
  
  // Link management methods
  Future<void> acceptLink(int linkId);
  Future<void> rejectLink(int linkId);
  Future<void> assignLink(int linkId);
}
