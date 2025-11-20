// lib/features/consumer/data/consumer_repository.dart
import '../domain/entities/cart_item.dart';
import '../domain/entities/consumer_models.dart';

abstract class ConsumerRepository {
  Future<List<Product>> getCatalog();
  Future<List<ConsumerOrder>> getOrders();
  Future<List<LinkInfo>> getLinks();
  Future<List<Complaint>> getComplaints();

  Future<void> createOrder(
    List<CartItem> items,
    int supplierId,
    String deliveryMethod,
    DateTime deliveryDate,
    String deliveryAddress, {
    String? notes,
  });
  Future<void> requestLink(String supplierCode);
  Future<void> createComplaint(int orderId, String title, String description, {String? imageUrl, int? supplierId, String? supplierCode});
  
  // Chat methods
  Future<List<Chat>> getChats();
  Future<List<ChatMessage>> getChatMessages(int chatId);
  Future<void> sendMessage(int chatId, String text, {String? imageUrl, String? receiptUrl, int? productId});
  Future<List<String>> getCannedReplies();
  Future<int> startChatWithSupplier(int supplierId, String supplierCode); // Returns chatId
  
  Future<List<Supplier>> getSuppliersForProduct(int productId);
  Future<bool> isLinkedToSupplier(String supplierCode);
  
  // New methods for supplier-based catalog
  Future<List<LinkInfo>> getLinkedSuppliers();
  Future<List<String>> getCategoriesForSupplier(String supplierCode);
  Future<List<SupplierProduct>> getProductsBySupplier(String supplierCode, {String? category});
  Future<Supplier?> getSupplierDetailsForProduct(int productId, String supplierCode);
  
  // Methods for links page
  Future<List<SupplierInfo>> getAllSuppliers({String? searchQuery});
  Future<void> requestLinkWithMessage(String supplierCode, {String? message});
  Future<void> cancelLinkRequest(String supplierCode);
}
