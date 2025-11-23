// lib/features/consumer/data/consumer_repository_api.dart
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/entities/cart_item.dart';
import '../domain/entities/consumer_models.dart';
import 'consumer_repository.dart';

class ApiConsumerRepository implements ConsumerRepository {
  final ApiClient _client;
  final AuthRepository _authRepository;

  ApiConsumerRepository(this._client, this._authRepository);

  @override
  Future<List<Product>> getCatalog() async {
    final resp = await _client.get('/products/');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load products: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => _productFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ConsumerOrder>> getOrders() async {
    // Get current user to filter orders by consumer_id
    final user = await _authRepository.getCurrentUser();
    final consumerId = user?.consumerId;
    
    // Build query string with consumer_id filter if available
    var path = '/orders/';
    if (consumerId != null) {
      path += '?consumer_id=$consumerId&skip=0&limit=100';
    }
    
    final resp = await _client.get(path);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load orders: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => _orderFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    // Get order details which includes items
    final resp = await _client.get('/orders/$orderId');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load order items: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => _orderItemFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> getProductName(int productId) async {
    // Get product details
    final resp = await _client.get('/products/$productId');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load product: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['name'] as String? ?? 'Unknown Product';
  }

  @override
  Future<List<LinkInfo>> getLinks() async {
    // Get current user to filter links by consumer_id
    final user = await _authRepository.getCurrentUser();
    final consumerId = user?.consumerId;
    
    // Build query string with consumer_id filter if available
    var path = '/links/';
    if (consumerId != null) {
      path += '?consumer_id=$consumerId';
    }
    
    final resp = await _client.get(path);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load links: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    final links = <LinkInfo>[];
    
    // Get supplier info for each link
    final suppliersResp = await _client.get('/suppliers/');
    final suppliersMap = <int, Map<String, dynamic>>{};
    if (suppliersResp.statusCode == 200) {
      final suppliers = jsonDecode(suppliersResp.body) as List<dynamic>;
      for (final s in suppliers) {
        final supplier = s as Map<String, dynamic>;
        suppliersMap[supplier['id'] as int] = supplier;
      }
    }
    
    for (final linkData in data) {
      final link = linkData as Map<String, dynamic>;
      final supplierId = link['supplier_id'] as int?;
      if (supplierId != null && suppliersMap.containsKey(supplierId)) {
        final supplier = suppliersMap[supplierId]!;
        links.add(_linkFromJson(link, supplier));
      } else {
        links.add(_linkFromJson(link, null));
      }
    }
    
    return links;
  }

  @override
  Future<List<Complaint>> getComplaints() async {
    final resp = await _client.get('/complaints/');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load complaints: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => _complaintFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> createOrder(
    List<CartItem> items,
    int supplierId,
    String deliveryMethod,
    DateTime deliveryDate,
    String deliveryAddress, {
    String? notes,
  }) async {
    // Get current user to get consumer_id
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.consumerId == null) {
      throw Exception('User is not authenticated or not a consumer');
    }

    final body = {
      'supplier_id': supplierId,
      'consumer_id': user.consumerId!,
      'delivery_method': deliveryMethod,
      'delivery_address': deliveryAddress,
      'delivery_date': deliveryDate.toIso8601String(),
      'items': items.map((item) => {
        'product_id': item.productId,
        'quantity': item.quantity,
      }).toList(),
    };
    
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final resp = await _client.post('/orders/', body: body);
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception('Failed to create order: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<void> requestLink(String supplierCode) async {
    await requestLinkWithMessage(supplierCode);
  }

  @override
  Future<void> createComplaint(
    int orderId,
    String title,
    String description, {
    String? imageUrl,
    int? supplierId,
    String? supplierCode,
  }) async {
    final body = {
      'order_id': orderId,
      'title': title,
      'description': description,
    };
    final resp = await _client.post('/complaints/', body: body);
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception('Failed to create complaint: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    final resp = await _client.get('/links/chats/consumer');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load chats: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    
    // Get supplier IDs from links
    final supplierIds = <int>{};
    for (final link in data) {
      final linkData = link as Map<String, dynamic>;
      final supplierId = linkData['supplier_id'] as int?;
      if (supplierId != null) {
        supplierIds.add(supplierId);
      }
    }
    
    // Fetch supplier names
    final supplierNames = <int, String>{};
    for (final supplierId in supplierIds) {
      try {
        final supplierResp = await _client.get('/suppliers/$supplierId');
        if (supplierResp.statusCode == 200) {
          final supplierJson = jsonDecode(supplierResp.body) as Map<String, dynamic>;
          final name = supplierJson['company_name'] as String?;
          if (name != null) {
            supplierNames[supplierId] = name;
          }
        }
      } catch (e) {
        // If fetching fails, use default name
      }
    }
    
    return data.map((e) => _chatFromJson(e as Map<String, dynamic>, supplierNames: supplierNames)).toList();
  }

  @override
  Future<List<ChatMessage>> getChatMessages(int chatId) async {
    final resp = await _client.get('/messages/?link_id=$chatId');
    if (resp.statusCode != 200) {
      throw Exception('Failed to load messages: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    // Get current user once for all messages
    final user = await _authRepository.getCurrentUser();
    final currentUserId = user?.id;
    final currentConsumerId = user?.consumerId;
    
    final messages = <ChatMessage>[];
    for (final item in data) {
      final json = item as Map<String, dynamic>;
      final senderId = json['sender_id'] as int?;
      final isFromConsumer = currentUserId != null && currentConsumerId != null && senderId == currentUserId;
      
      // Determine attachment type
      final messageType = json['message_type'] as String? ?? 'text';
      final attachmentUrl = json['attachment_url'] as String?;
      final attachmentType = json['attachment_type'] as String?;
      
      String? imageUrl;
      String? fileUrl;
      String? audioUrl;
      String? fileName;
      
      if (attachmentUrl != null) {
        if (attachmentType == 'image' || messageType == 'image') {
          imageUrl = attachmentUrl;
        } else if (attachmentType == 'audio' || messageType == 'audio') {
          audioUrl = attachmentUrl;
        } else if (attachmentType == 'file' || messageType == 'file') {
          fileUrl = attachmentUrl;
          // Try to extract filename from URL
          final urlParts = attachmentUrl.split('/');
          if (urlParts.isNotEmpty) {
            fileName = urlParts.last;
          }
        } else {
          // Default to image if type is unknown but URL exists
          imageUrl = attachmentUrl;
        }
      }
      
      // Get sender role from API (sales_rep_id indicates sales rep, manager role indicates manager)
      String? senderRole;
      if (!isFromConsumer) {
        if (json['sales_rep_id'] != null) {
          senderRole = 'sales';
        } else if (json['sender_role'] != null) {
          final role = json['sender_role'] as String;
          if (role.toLowerCase() == 'manager' || role.toLowerCase() == 'owner') {
            senderRole = 'manager';
          } else {
            senderRole = 'sales';
          }
        }
      }
      
      // Check if message is from escalated complaint
      final isEscalated = json['is_escalated'] as bool? ?? false;
      
      messages.add(ChatMessage(
        id: json['id'] as int,
        chatId: chatId,
        text: json['content'] as String? ?? '',
        isFromConsumer: isFromConsumer,
        createdAt: DateTime.parse(json['created_at'] as String),
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        audioUrl: audioUrl,
        fileName: fileName,
        receiptUrl: null,
        productId: json['product_id'] as int?,
        productName: null,
        isEscalated: isEscalated,
        senderRole: senderRole,
      ));
    }
    
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  @override
  Future<void> sendMessage(
    int chatId,
    String text, {
    String? imageUrl,
    String? receiptUrl,
    int? productId,
  }) async {
    final body = {
      'link_id': chatId,
      'content': text,
      'message_type': 'text',
      if (imageUrl != null) 'attachment_url': imageUrl,
      if (receiptUrl != null) 'attachment_url': receiptUrl,
      if (productId != null) 'product_id': productId,
    };
    final resp = await _client.post('/messages/', body: body);
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception('Failed to send message: ${resp.statusCode} ${resp.body}');
    }
  }

  @override
  Future<List<String>> getCannedReplies() async {
    // This is a client-side feature, return empty list
    return [];
  }

  @override
  Future<int> startChatWithSupplier(int supplierId, String supplierCode) async {
    // Get current user to get consumer_id
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.consumerId == null) {
      throw Exception('User is not authenticated or not a consumer');
    }
    
    // Check if link already exists (any status)
    final linksResp = await _client.get('/links/');
    if (linksResp.statusCode == 200) {
      final links = jsonDecode(linksResp.body) as List<dynamic>;
      final existingLink = links.firstWhere(
        (l) {
          final link = l as Map<String, dynamic>;
          return link['supplier_id'] == supplierId && 
                 link['consumer_id'] == user.consumerId;
        },
        orElse: () => null,
      );
      if (existingLink != null) {
        // Return existing link ID - chat already exists
        return (existingLink as Map<String, dynamic>)['id'] as int;
      }
    }
    
    // Create new link if doesn't exist
    final body = {
      'supplier_id': supplierId,
      'consumer_id': user.consumerId,
    };
    final resp = await _client.post('/links/', body: body);
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception('Failed to create link: ${resp.statusCode} ${resp.body}');
    }
    final linkData = jsonDecode(resp.body) as Map<String, dynamic>;
    return linkData['id'] as int;
  }

  @override
  Future<List<Supplier>> getSuppliersForProduct(int productId) async {
    // Get product details first
    final productResp = await _client.get('/products/$productId');
    if (productResp.statusCode != 200) {
      throw Exception('Failed to load product: ${productResp.statusCode} ${productResp.body}');
    }
    final productData = jsonDecode(productResp.body) as Map<String, dynamic>;
    final supplierId = productData['supplier_id'] as int?;
    if (supplierId == null) return [];

    // Get supplier details
    final supplierResp = await _client.get('/suppliers/$supplierId');
    if (supplierResp.statusCode != 200) return [];

    final supplierData = jsonDecode(supplierResp.body) as Map<String, dynamic>;
    return [
      _supplierFromJson(supplierData, productData),
    ];
  }

  @override
  Future<bool> isLinkedToSupplier(String supplierCode) async {
    final linksResp = await _client.get('/links/chats/consumer');
    if (linksResp.statusCode != 200) return false;
    final links = jsonDecode(linksResp.body) as List<dynamic>;
    return links.any((l) {
      final link = l as Map<String, dynamic>;
      return link['status'] == 'accepted';
    });
  }

  @override
  Future<List<LinkInfo>> getLinkedSuppliers() async {
    return getLinks();
  }

  @override
  Future<List<String>> getCategoriesForSupplier(String supplierCode) async {
    // Get supplier by code
    final suppliersResp = await _client.get('/suppliers/');
    if (suppliersResp.statusCode != 200) return [];
    final suppliers = jsonDecode(suppliersResp.body) as List<dynamic>;
    final supplier = suppliers.firstWhere(
      (s) => (s as Map<String, dynamic>)['id'].toString() == supplierCode,
      orElse: () => null,
    );
    if (supplier == null) return [];

    // Get products for this supplier
    final productsResp = await _client.get('/products/?supplier_id=${(supplier as Map<String, dynamic>)['id']}');
    if (productsResp.statusCode != 200) return [];
    final products = jsonDecode(productsResp.body) as List<dynamic>;
    final categories = <String>{};
    for (final p in products) {
      final product = p as Map<String, dynamic>;
      final categoryId = product['category_id'] as int?;
      if (categoryId != null) {
        final catResp = await _client.get('/categories/$categoryId');
        if (catResp.statusCode == 200) {
          final cat = jsonDecode(catResp.body) as Map<String, dynamic>;
          categories.add(cat['name'] as String);
        }
      }
    }
    return categories.toList();
  }

  @override
  Future<List<SupplierProduct>> getProductsBySupplier(String supplierCode, {String? category}) async {
    // Get supplier by code
    final suppliersResp = await _client.get('/suppliers/');
    if (suppliersResp.statusCode != 200) return [];
    final suppliers = jsonDecode(suppliersResp.body) as List<dynamic>;
    final supplier = suppliers.firstWhere(
      (s) => (s as Map<String, dynamic>)['id'].toString() == supplierCode,
      orElse: () => null,
    );
    if (supplier == null) return [];

    final supplierData = supplier as Map<String, dynamic>;
    final supplierId = supplierData['id'] as int;

    // Get products
    var productsResp = await _client.get('/products/?supplier_id=$supplierId');
    if (productsResp.statusCode != 200) return [];
    var products = jsonDecode(productsResp.body) as List<dynamic>;

    // Filter by category if needed
    if (category != null) {
      // Get category ID
      final catsResp = await _client.get('/categories/');
      if (catsResp.statusCode == 200) {
        final cats = jsonDecode(catsResp.body) as List<dynamic>;
        final cat = cats.firstWhere(
          (c) => (c as Map<String, dynamic>)['name'] == category,
          orElse: () => null,
        );
        if (cat != null) {
          final catId = (cat as Map<String, dynamic>)['id'] as int;
          products = products.where((p) => (p as Map<String, dynamic>)['category_id'] == catId).toList();
        }
      }
    }

    return products.map((p) => _supplierProductFromJson(p as Map<String, dynamic>, supplierData)).toList();
  }

  @override
  Future<Supplier?> getSupplierDetailsForProduct(int productId, String supplierCode) async {
    final suppliers = await getSuppliersForProduct(productId);
    return suppliers.isNotEmpty ? suppliers.first : null;
  }

  @override
  Future<List<SupplierInfo>> getAllSuppliers({String? searchQuery}) async {
    var path = '/suppliers/';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // URL encode the search query
      final encodedQuery = Uri.encodeComponent(searchQuery);
      path += '?search=$encodedQuery';
    }
    final resp = await _client.get(path);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load suppliers: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    final suppliers = data.map((e) => _supplierInfoFromJson(e as Map<String, dynamic>)).toList();
    
    // Get links to update status - filter by current consumer
    final user = await _authRepository.getCurrentUser();
    final consumerId = user?.consumerId;
    var linksPath = '/links/';
    if (consumerId != null) {
      linksPath += '?consumer_id=$consumerId';
    }
    final linksResp = await _client.get(linksPath);
    if (linksResp.statusCode == 200) {
      final links = jsonDecode(linksResp.body) as List<dynamic>;
      final linksMap = <int, String>{}; // supplier_id -> status
      // If multiple links exist for same supplier, use the most recent one (last in list)
      for (final link in links) {
        final linkData = link as Map<String, dynamic>;
        final supplierId = linkData['supplier_id'] as int?;
        final status = linkData['status'] as String?;
        if (supplierId != null && status != null) {
          // Always update to latest status (last link wins)
          linksMap[supplierId] = status;
        }
      }
      
      // Update supplier statuses
      for (int i = 0; i < suppliers.length; i++) {
        final supplier = suppliers[i];
        if (linksMap.containsKey(supplier.id)) {
          final newStatus = linksMap[supplier.id]!;
          suppliers[i] = SupplierInfo(
            id: supplier.id,
            name: supplier.name,
            code: supplier.code,
            city: supplier.city,
            logoUrl: supplier.logoUrl,
            status: newStatus,
            category: supplier.category,
            description: supplier.description,
            address: supplier.address,
            deliveryRegions: supplier.deliveryRegions,
            minOrderAmount: supplier.minOrderAmount,
            paymentTerms: supplier.paymentTerms,
            deliverySchedule: supplier.deliverySchedule,
            phone: supplier.phone,
            email: supplier.email,
            website: supplier.website,
            workingHours: supplier.workingHours,
            productCategories: supplier.productCategories,
          );
        }
      }
    }
    
    return suppliers;
  }

  @override
  Future<void> requestLinkWithMessage(String supplierCode, {String? message}) async {
    // Get current user to get consumer_id
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.consumerId == null) {
      throw Exception('User is not authenticated or not a consumer');
    }

    // supplierCode is the supplier ID as string
    final supplierId = int.tryParse(supplierCode);
    if (supplierId == null) {
      throw Exception('Invalid supplier code: $supplierCode');
    }

    // Build request body according to API spec
    // API expects: { "supplier_id": int, "consumer_id": int, "request_message": "string" (optional) }
    final body = <String, dynamic>{
      'supplier_id': supplierId,
      'consumer_id': user.consumerId!,
    };
    // Only include request_message if it's not null and not empty
    if (message != null && message.trim().isNotEmpty) {
      body['request_message'] = message.trim();
    }

    print('Creating link request:');
    print('  supplier_id: $supplierId');
    print('  consumer_id: ${user.consumerId}');
    print('  request_message: ${message?.trim() ?? "(none)"}');
    print('  Request body: ${jsonEncode(body)}');

    try {
      final resp = await _client.post('/links/', body: body);
      
      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.body}');
      
      if (resp.statusCode != 201 && resp.statusCode != 200) {
        final errorBody = resp.body;
        print('ERROR creating link:');
        print('  Status: ${resp.statusCode}');
        print('  Body: $errorBody');
        print('  Request body sent: ${jsonEncode(body)}');
        throw Exception('Failed to request link: ${resp.statusCode} $errorBody');
      }
      
      // Verify the link was created with pending status
      try {
        final linkData = jsonDecode(resp.body) as Map<String, dynamic>;
        final createdStatus = linkData['status'] as String?;
        print('Link created successfully with status: $createdStatus');
        if (createdStatus != 'pending') {
          // Log warning but don't fail - status might be set by backend
          print('Warning: Link created with status "$createdStatus" instead of "pending"');
        }
      } catch (e) {
        print('Warning: Could not parse response body: $e');
        print('Response body was: ${resp.body}');
      }
    } catch (e) {
      print('Exception in requestLinkWithMessage: $e');
      print('Request body: ${jsonEncode(body)}');
      rethrow;
    }
  }

  @override
  Future<void> cancelLinkRequest(String supplierCode) async {
    // Get current user to get consumer_id
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.consumerId == null) {
      throw Exception('User is not authenticated or not a consumer');
    }

    // Get links filtered by consumer_id
    final linksResp = await _client.get('/links/?consumer_id=${user.consumerId}');
    if (linksResp.statusCode != 200) {
      throw Exception('Failed to load links: ${linksResp.statusCode}');
    }
    
    final supplierId = int.tryParse(supplierCode);
    if (supplierId == null) {
      throw Exception('Invalid supplier code: $supplierCode');
    }

    final links = jsonDecode(linksResp.body) as List<dynamic>;
    final link = links.cast<Map<String, dynamic>>().firstWhere(
      (linkData) {
        return linkData['supplier_id'] == supplierId && 
               (linkData['status'] as String?) == 'pending';
      },
      orElse: () => <String, dynamic>{},
    );
    
    if (link.isNotEmpty) {
      final linkId = link['id'] as int;
      final deleteResp = await _client.delete('/links/$linkId');
      if (deleteResp.statusCode != 200 && deleteResp.statusCode != 204) {
        throw Exception('Failed to cancel link request: ${deleteResp.statusCode} ${deleteResp.body}');
      }
    } else {
      throw Exception('Link request not found for supplier $supplierCode');
    }
  }

  // Helper methods for JSON parsing
  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      unit: json['unit'] as String? ?? 'piece',
      price: double.tryParse(json['price'].toString()) ?? 0,
      category: 'Unknown', // Will need category lookup
      imageUrl: json['image_url'] as String?,
    );
  }

  OrderItem _orderItemFromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
    );
  }

  ConsumerOrder _orderFromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson.map((itemJson) {
      return _orderItemFromJson(itemJson as Map<String, dynamic>);
    }).toList();

    return ConsumerOrder(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      currency: json['currency'] as String? ?? 'KZT',
      orderNumber: json['order_number'] as String?,
      supplierId: json['supplier_id'] as int?,
      supplierCode: json['supplier_id']?.toString(), // Use supplier_id as code
      deliveryMethod: json['delivery_method'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      notes: json['notes'] as String?,
      items: items,
    );
  }

  LinkInfo _linkFromJson(Map<String, dynamic> json, Map<String, dynamic>? supplierJson) {
    String supplierName = 'Supplier #${json['supplier_id']}';
    String? supplierCode;
    String? city;
    
    if (supplierJson != null) {
      supplierName = supplierJson['company_name'] as String? ?? supplierName;
      supplierCode = supplierJson['id'].toString();
      city = supplierJson['city'] as String?;
    } else {
      supplierCode = json['supplier_id'].toString();
    }
    
    return LinkInfo(
      id: json['id'] as int,
      supplierName: supplierName,
      status: json['status'] as String,
      supplierCode: supplierCode,
      city: city,
      logoUrl: null,
    );
  }

  Complaint _complaintFromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      orderId: json['order_id'] as int,
      supplierId: json['supplier_id'] as int?,
      supplierCode: null,
    );
  }

  Chat _chatFromJson(Map<String, dynamic> json, {Map<int, String>? supplierNames}) {
    final supplierId = json['supplier_id'] as int;
    final supplierName = supplierNames?[supplierId] ?? 'Supplier #$supplierId';
    
    // Check if there's a complaint associated with this link
    final complaintId = json['complaint_id'] as int?;
    final isComplaint = complaintId != null;
    final isEscalated = json['complaint_escalated'] as bool? ?? false;
    final escalatedToManagerName = json['escalated_to_manager_name'] as String?;
    
    return Chat(
      id: json['id'] as int,
      supplierId: supplierId,
      supplierName: supplierName,
      supplierCode: supplierId.toString(),
      supplierLogoUrl: null,
      lastMessageAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isComplaint: isComplaint,
      complaintId: complaintId,
      isEscalated: isEscalated,
      escalatedToManagerName: escalatedToManagerName,
    );
  }


  Supplier _supplierFromJson(Map<String, dynamic> supplierJson, Map<String, dynamic> productJson) {
    return Supplier(
      id: supplierJson['id'] as int,
      name: supplierJson['company_name'] as String? ?? 'Supplier',
      code: supplierJson['id'].toString(),
      description: supplierJson['description'] as String?,
      price: double.tryParse(productJson['price'].toString()) ?? 0,
      discountPrice: productJson['discount_price'] != null
          ? double.tryParse(productJson['discount_price'].toString())
          : null,
      currency: productJson['currency'] as String? ?? 'KZT',
      stockQuantity: int.tryParse(productJson['stock_quantity'].toString()) ?? 0,
      unit: productJson['unit'] as String? ?? 'piece',
      minOrderQuantity: int.tryParse(productJson['min_order_quantity'].toString()) ?? 1,
      // Delivery options come from supplier, not product
      deliveryAvailability: supplierJson['delivery_available'] as bool? ?? false,
      pickupAvailability: supplierJson['pickup_available'] as bool? ?? false,
      // Lead time can come from product if specified, otherwise from supplier
      leadTimeDays: (productJson['lead_time_days'] as int?) ?? 
                    (supplierJson['lead_time_days'] as int?) ?? 0,
    );
  }

  SupplierProduct _supplierProductFromJson(Map<String, dynamic> productJson, Map<String, dynamic> supplierJson) {
    return SupplierProduct(
      productId: productJson['id'] as int,
      productName: productJson['name'] as String,
      category: 'Unknown',
      imageUrl: productJson['image_url'] as String?,
      supplierId: supplierJson['id'] as int,
      supplierName: supplierJson['company_name'] as String? ?? 'Supplier',
      supplierCode: supplierJson['id'].toString(),
      price: double.tryParse(productJson['price'].toString()) ?? 0,
      discountPrice: productJson['discount_price'] != null
          ? double.tryParse(productJson['discount_price'].toString())
          : null,
      currency: productJson['currency'] as String? ?? 'KZT',
      unit: productJson['unit'] as String? ?? 'piece',
    );
  }

  SupplierInfo _supplierInfoFromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      id: json['id'] as int,
      name: json['company_name'] as String? ?? 'Supplier',
      code: json['id'].toString(),
      city: json['city'] as String?,
      logoUrl: null,
      status: null,
      category: null,
      description: json['description'] as String?,
      address: json['address'] as String?,
      deliveryRegions: null,
      minOrderAmount: null,
      paymentTerms: null,
      deliverySchedule: null,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      workingHours: null,
      productCategories: null,
    );
  }
}


