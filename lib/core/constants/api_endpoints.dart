// lib/core/constants/api_endpoints.dart
class ApiEndpoints {
  static const baseUrl = 'http://localhost:8000/api/v1';

  // Auth
  static const login = '$baseUrl/auth/login';
  static const me = '$baseUrl/auth/me';

  // Users
  static const users = '$baseUrl/users';

  // Suppliers
  static const suppliers = '$baseUrl/suppliers';

  // Consumers
  static const consumers = '$baseUrl/consumers';

  // Products
  static const products = '$baseUrl/products';

  // Links
  static const links = '$baseUrl/links';

  // Orders
  static const orders = '$baseUrl/orders';
}
