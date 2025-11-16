// lib/features/consumer/data/consumer_repository.dart
import '../domain/entities/consumer_models.dart';

abstract class ConsumerRepository {
  Future<List<Product>> getCatalog();
  Future<List<ConsumerOrder>> getOrders();
  Future<List<LinkInfo>> getLinks();
  Future<List<Complaint>> getComplaints();

  Future<void> createOrder(Product product, {int quantity = 1, int supplierId = 0});
  Future<void> requestLink(String supplierCode);
  Future<void> createComplaint(int orderId, String text);
  
  Future<List<Supplier>> getSuppliersForProduct(int productId);
  Future<bool> isLinkedToSupplier(String supplierCode);
  
  // New methods for supplier-based catalog
  Future<List<LinkInfo>> getLinkedSuppliers();
  Future<List<String>> getCategoriesForSupplier(String supplierCode);
  Future<List<SupplierProduct>> getProductsBySupplier(String supplierCode, {String? category});
  Future<Supplier?> getSupplierDetailsForProduct(int productId, String supplierCode);
}
