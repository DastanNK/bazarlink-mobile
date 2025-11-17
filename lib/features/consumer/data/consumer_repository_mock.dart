// lib/features/consumer/data/consumer_repository_mock.dart
import 'dart:async';
import '../domain/entities/consumer_models.dart';
import 'consumer_repository.dart';

class MockConsumerRepository implements ConsumerRepository {
  final List<Product> _products = [
    Product(id: 1, name: 'Chicken Breast', unit: 'kg', price: 1500, category: 'Meat', imageUrl: null),
    Product(id: 2, name: 'Tomatoes', unit: 'kg', price: 700, category: 'Vegetables', imageUrl: null),
    Product(id: 3, name: 'Cheese', unit: 'kg', price: 2500, category: 'Dairy', imageUrl: null),
    Product(id: 4, name: 'Apples', unit: 'kg', price: 500, category: 'Fruits', imageUrl: null),
    Product(id: 5, name: 'Beef', unit: 'kg', price: 2000, category: 'Meat', imageUrl: null),
    Product(id: 6, name: 'Carrots', unit: 'kg', price: 400, category: 'Vegetables', imageUrl: null),
    Product(id: 7, name: 'Bananas', unit: 'kg', price: 600, category: 'Fruits', imageUrl: null),
    Product(id: 8, name: 'Milk', unit: 'L', price: 800, category: 'Dairy', imageUrl: null),
  ];

  final List<ConsumerOrder> _orders = [
    ConsumerOrder(
      id: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'accepted',
      total: 45000,
      supplierId: 1,
      supplierCode: 'BMS001',
    ),
    ConsumerOrder(
      id: 2,
      createdAt: DateTime.now(),
      status: 'pending',
      total: 12000,
      supplierId: 2,
      supplierCode: 'VL001',
    ),
  ];

  final List<LinkInfo> _links = [
    LinkInfo(
      id: 1,
      supplierName: 'Best Meat Supplier',
      status: 'accepted',
      supplierCode: 'BMS001',
      city: 'Almaty',
      logoUrl: null,
    ),
    LinkInfo(
      id: 2,
      supplierName: 'VeggieLand',
      status: 'accepted',
      supplierCode: 'VL001',
      city: 'Astana',
      logoUrl: null,
    ),
  ];

  // All available suppliers
  final List<SupplierInfo> _allSuppliers = [
    SupplierInfo(
      id: 1,
      name: 'Best Meat Supplier',
      code: 'BMS001',
      city: 'Almaty',
      logoUrl: null,
      status: 'accepted',
      category: 'Meat & Poultry',
      description: 'Premium quality meat supplier specializing in fresh beef, chicken, and lamb. We source from local farms and ensure the highest standards.',
      address: '123 Meat Street, Almaty',
      deliveryRegions: ['Almaty', 'Astana', 'Shymkent'],
      minOrderAmount: 50000,
      paymentTerms: 'Net 30, Cash on delivery available',
      deliverySchedule: 'Monday, Wednesday, Friday',
      phone: '+7 777 123 4567',
      email: 'info@bestmeat.kz',
      website: 'www.bestmeat.kz',
      workingHours: 'Mon-Fri: 8:00-18:00',
      productCategories: ['Meat', 'Poultry', 'Sausages'],
    ),
    SupplierInfo(
      id: 2,
      name: 'VeggieLand',
      code: 'VL001',
      city: 'Astana',
      logoUrl: null,
      status: 'accepted',
      category: 'Produce',
      description: 'Fresh vegetables and fruits from local farms. Organic options available.',
      address: '456 Green Avenue, Astana',
      deliveryRegions: ['Astana', 'Almaty'],
      minOrderAmount: 30000,
      paymentTerms: 'Net 15',
      deliverySchedule: 'Tuesday, Thursday, Saturday',
      phone: '+7 777 234 5678',
      email: 'contact@veggieland.kz',
      website: 'www.veggieland.kz',
      workingHours: 'Mon-Sat: 7:00-19:00',
      productCategories: ['Vegetables', 'Fruits', 'Herbs'],
    ),
    SupplierInfo(
      id: 3,
      name: 'Fresh Dairy Co',
      code: 'FDC001',
      city: 'Almaty',
      logoUrl: null,
      status: 'pending',
      category: 'Dairy',
      description: 'Fresh dairy products including milk, cheese, yogurt, and butter.',
      address: '789 Dairy Road, Almaty',
      deliveryRegions: ['Almaty'],
      minOrderAmount: 25000,
      paymentTerms: 'Cash on delivery',
      deliverySchedule: 'Daily',
      phone: '+7 777 345 6789',
      email: 'sales@freshdairy.kz',
      website: null,
      workingHours: 'Mon-Sun: 6:00-20:00',
      productCategories: ['Milk', 'Cheese', 'Yogurt', 'Butter'],
    ),
    SupplierInfo(
      id: 4,
      name: 'Organic Fruits',
      code: 'OF001',
      city: 'Shymkent',
      logoUrl: null,
      status: null, // Not linked
      category: 'Produce',
      description: 'Certified organic fruits and vegetables.',
      address: '321 Organic Lane, Shymkent',
      deliveryRegions: ['Shymkent', 'Almaty'],
      minOrderAmount: 40000,
      paymentTerms: 'Net 30',
      deliverySchedule: 'Monday, Wednesday',
      phone: '+7 777 456 7890',
      email: 'info@organicfruits.kz',
      website: 'www.organicfruits.kz',
      workingHours: 'Mon-Fri: 9:00-17:00',
      productCategories: ['Organic Fruits', 'Organic Vegetables'],
    ),
    SupplierInfo(
      id: 5,
      name: 'Premium Seafood',
      code: 'PS001',
      city: 'Almaty',
      logoUrl: null,
      status: 'blocked',
      category: 'Seafood',
      description: 'Fresh seafood and fish products.',
      address: '654 Ocean Drive, Almaty',
      deliveryRegions: ['Almaty'],
      minOrderAmount: 60000,
      paymentTerms: 'Prepayment required',
      deliverySchedule: 'Tuesday, Friday',
      phone: '+7 777 567 8901',
      email: 'sales@premiumseafood.kz',
      website: null,
      workingHours: 'Mon-Fri: 7:00-16:00',
      productCategories: ['Fish', 'Seafood', 'Frozen Seafood'],
    ),
    SupplierInfo(
      id: 6,
      name: 'Bakery Supplies',
      code: 'BS001',
      city: 'Astana',
      logoUrl: null,
      status: null, // Not linked
      category: 'Bakery',
      description: 'Bakery ingredients and supplies for professional bakers.',
      address: '987 Bread Street, Astana',
      deliveryRegions: ['Astana'],
      minOrderAmount: 35000,
      paymentTerms: 'Net 20',
      deliverySchedule: 'Monday, Thursday',
      phone: '+7 777 678 9012',
      email: 'orders@bakerysupplies.kz',
      website: 'www.bakerysupplies.kz',
      workingHours: 'Mon-Fri: 8:00-17:00',
      productCategories: ['Flour', 'Yeast', 'Baking Supplies'],
    ),
  ];

  // Supplier products mapping: supplierCode -> List<SupplierProduct>
  final Map<String, List<SupplierProduct>> _supplierProducts = {
    'BMS001': [
      SupplierProduct(
        productId: 1,
        productName: 'Chicken Breast',
        category: 'Meat',
        imageUrl: null,
        supplierId: 1,
        supplierName: 'Best Meat Supplier',
        supplierCode: 'BMS001',
        price: 1500,
        discountPrice: 1350,
        currency: 'KZT',
        unit: 'kg',
      ),
      SupplierProduct(
        productId: 5,
        productName: 'Beef',
        category: 'Meat',
        imageUrl: null,
        supplierId: 1,
        supplierName: 'Best Meat Supplier',
        supplierCode: 'BMS001',
        price: 2000,
        discountPrice: 1800,
        currency: 'KZT',
        unit: 'kg',
      ),
    ],
    'VL001': [
      SupplierProduct(
        productId: 2,
        productName: 'Tomatoes',
        category: 'Vegetables',
        imageUrl: null,
        supplierId: 3,
        supplierName: 'VeggieLand',
        supplierCode: 'VL001',
        price: 700,
        discountPrice: 600,
        currency: 'KZT',
        unit: 'kg',
      ),
      SupplierProduct(
        productId: 6,
        productName: 'Carrots',
        category: 'Vegetables',
        imageUrl: null,
        supplierId: 3,
        supplierName: 'VeggieLand',
        supplierCode: 'VL001',
        price: 400,
        discountPrice: null,
        currency: 'KZT',
        unit: 'kg',
      ),
    ],
  };

  final Map<int, List<Supplier>> _productSuppliers = {
    1: [
      Supplier(
        id: 1,
        name: 'Best Meat Supplier',
        code: 'BMS001',
        description: 'Premium quality chicken breast, fresh daily',
        price: 1500,
        discountPrice: 1350,
        currency: 'KZT',
        stockQuantity: 50,
        unit: 'kg',
        minOrderQuantity: 5,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 1,
      ),
      Supplier(
        id: 2,
        name: 'Meat Masters',
        code: 'MM002',
        description: 'Organic free-range chicken breast',
        price: 1800,
        discountPrice: null,
        currency: 'KZT',
        stockQuantity: 30,
        unit: 'kg',
        minOrderQuantity: 3,
        deliveryAvailability: true,
        pickupAvailability: false,
        leadTimeDays: 2,
      ),
    ],
    2: [
      Supplier(
        id: 3,
        name: 'VeggieLand',
        code: 'VL001',
        description: 'Fresh local tomatoes, vine-ripened',
        price: 700,
        discountPrice: 600,
        currency: 'KZT',
        stockQuantity: 100,
        unit: 'kg',
        minOrderQuantity: 2,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 0,
      ),
    ],
    3: [
      Supplier(
        id: 4,
        name: 'Dairy Fresh',
        code: 'DF001',
        description: 'Premium quality cheese, aged to perfection',
        price: 2500,
        discountPrice: 2200,
        currency: 'KZT',
        stockQuantity: 40,
        unit: 'kg',
        minOrderQuantity: 1,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 1,
      ),
    ],
    4: [
      Supplier(
        id: 5,
        name: 'Fruit Paradise',
        code: 'FP001',
        description: 'Sweet and crisp apples, locally sourced',
        price: 500,
        discountPrice: null,
        currency: 'KZT',
        stockQuantity: 80,
        unit: 'kg',
        minOrderQuantity: 3,
        deliveryAvailability: true,
        pickupAvailability: false,
        leadTimeDays: 1,
      ),
    ],
    5: [
      Supplier(
        id: 1,
        name: 'Best Meat Supplier',
        code: 'BMS001',
        description: 'Premium quality beef, fresh and tender',
        price: 2000,
        discountPrice: 1800,
        currency: 'KZT',
        stockQuantity: 40,
        unit: 'kg',
        minOrderQuantity: 3,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 1,
      ),
    ],
    6: [
      Supplier(
        id: 3,
        name: 'VeggieLand',
        code: 'VL001',
        description: 'Fresh local carrots, crisp and sweet',
        price: 400,
        discountPrice: null,
        currency: 'KZT',
        stockQuantity: 150,
        unit: 'kg',
        minOrderQuantity: 2,
        deliveryAvailability: true,
        pickupAvailability: true,
        leadTimeDays: 0,
      ),
    ],
  };

  final List<Complaint> _complaints = [
    Complaint(
      id: 1,
      title: 'Late delivery',
      status: 'open',
      orderId: 1,
      supplierId: 1,
      supplierCode: 'BMS001',
    ),
  ];

  // Chats and messages
  final List<Chat> _chats = [];
  final Map<int, List<ChatMessage>> _chatMessages = {}; // chatId -> messages

  @override
  Future<List<Product>> getCatalog() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _products;
  }

  @override
  Future<List<ConsumerOrder>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _orders;
  }

  @override
  Future<List<LinkInfo>> getLinks() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _links;
  }

  @override
  Future<List<Complaint>> getComplaints() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _complaints;
  }

  @override
  Future<void> createOrder(Product product, {int quantity = 1, int supplierId = 0}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Get supplier code from supplierId (mock implementation)
    String? supplierCode;
    if (supplierId > 0) {
      final supplier = _allSuppliers.firstWhere(
        (s) => s.id == supplierId,
        orElse: () => SupplierInfo(id: 0, name: '', code: ''),
      );
      supplierCode = supplier.code.isEmpty ? null : supplier.code;
    }
    
    _orders.add(
      ConsumerOrder(
        id: _orders.length + 1,
        createdAt: DateTime.now(),
        status: 'pending',
        total: product.price * quantity,
        supplierId: supplierId > 0 ? supplierId : null,
        supplierCode: supplierCode,
      ),
    );
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
    await Future.delayed(const Duration(milliseconds: 300));
    
    final complaintId = _complaints.length + 1;
    _complaints.add(
      Complaint(
        id: complaintId,
        title: title,
        status: 'open',
        orderId: orderId,
        supplierId: supplierId,
        supplierCode: supplierCode,
      ),
    );

    // Create chat if supplier info is provided
    if (supplierId != null && supplierCode != null) {
      // Get supplier info
      final supplier = _allSuppliers.firstWhere(
        (s) => s.id == supplierId && s.code == supplierCode,
        orElse: () => SupplierInfo(
          id: supplierId,
          name: 'Supplier',
          code: supplierCode,
        ),
      );

      // Check if chat already exists for this supplier
      var existingChat = _chats.firstWhere(
        (chat) => chat.supplierId == supplierId && chat.complaintId == complaintId,
        orElse: () => Chat(
          id: 0,
          supplierId: 0,
          supplierName: '',
          lastMessageAt: DateTime.now(),
        ),
      );

      int chatId;
      if (existingChat.id == 0) {
        // Create new chat
        chatId = _chats.length + 1;
        _chats.add(
          Chat(
            id: chatId,
            supplierId: supplierId,
            supplierName: supplier.name,
            supplierCode: supplierCode,
            supplierLogoUrl: supplier.logoUrl,
            lastMessageAt: DateTime.now(),
            isComplaint: true,
            complaintId: complaintId,
          ),
        );
      } else {
        chatId = existingChat.id;
      }

      // Create first message with complaint
      final complaintMessage = 'Complaint: $title\n\n$description';
      if (!_chatMessages.containsKey(chatId)) {
        _chatMessages[chatId] = [];
      }
      _chatMessages[chatId]!.add(
        ChatMessage(
          id: _chatMessages[chatId]!.length + 1,
          chatId: chatId,
          text: complaintMessage,
          isFromConsumer: true,
          createdAt: DateTime.now(),
          imageUrl: imageUrl,
        ),
      );

      // Update chat last message time
      final chatIndex = _chats.indexWhere((c) => c.id == chatId);
      if (chatIndex >= 0) {
        _chats[chatIndex] = Chat(
          id: _chats[chatIndex].id,
          supplierId: _chats[chatIndex].supplierId,
          supplierName: _chats[chatIndex].supplierName,
          supplierCode: _chats[chatIndex].supplierCode,
          supplierLogoUrl: _chats[chatIndex].supplierLogoUrl,
          lastMessageAt: DateTime.now(),
          isComplaint: true,
          complaintId: complaintId,
        );
      }
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Chat>.from(_chats)..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  @override
  Future<List<ChatMessage>> getChatMessages(int chatId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List<ChatMessage>.from(_chatMessages[chatId] ?? [])
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> sendMessage(int chatId, String text, {String? imageUrl, String? receiptUrl, int? productId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!_chatMessages.containsKey(chatId)) {
      _chatMessages[chatId] = [];
    }
    
    String? productName;
    if (productId != null) {
      final product = _products.firstWhere((p) => p.id == productId, orElse: () => _products.first);
      productName = product.name;
    }
    
    _chatMessages[chatId]!.add(
      ChatMessage(
        id: _chatMessages[chatId]!.length + 1,
        chatId: chatId,
        text: text,
        isFromConsumer: true,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        receiptUrl: receiptUrl,
        productId: productId,
        productName: productName,
        senderRole: 'consumer',
      ),
    );

    // Update chat last message time
    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex >= 0) {
      _chats[chatIndex] = Chat(
        id: _chats[chatIndex].id,
        supplierId: _chats[chatIndex].supplierId,
        supplierName: _chats[chatIndex].supplierName,
        supplierCode: _chats[chatIndex].supplierCode,
        supplierLogoUrl: _chats[chatIndex].supplierLogoUrl,
        lastMessageAt: DateTime.now(),
        isComplaint: _chats[chatIndex].isComplaint,
        complaintId: _chats[chatIndex].complaintId,
      );
    }
  }

  @override
  Future<List<Supplier>> getSuppliersForProduct(int productId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _productSuppliers[productId] ?? [];
  }

  @override
  Future<bool> isLinkedToSupplier(String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Check if supplier code matches any accepted links
    // For demo: BMS001, VL001 are linked (accepted), others are not
    final linkedCodes = ['BMS001', 'VL001'];
    return linkedCodes.contains(supplierCode.toUpperCase());
  }

  @override
  Future<List<LinkInfo>> getLinkedSuppliers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _links.where((link) => link.status == 'accepted').toList();
  }

  @override
  Future<List<String>> getCategoriesForSupplier(String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final products = _supplierProducts[supplierCode.toUpperCase()] ?? [];
    final categories = products.map((p) => p.category).toSet().toList();
    return categories;
  }

  @override
  Future<List<SupplierProduct>> getProductsBySupplier(String supplierCode, {String? category}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var products = _supplierProducts[supplierCode.toUpperCase()] ?? [];
    if (category != null) {
      products = products.where((p) => p.category == category).toList();
    }
    return products;
  }

  @override
  Future<Supplier?> getSupplierDetailsForProduct(int productId, String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Find supplier from productSuppliers map
    final suppliers = _productSuppliers[productId] ?? [];
    try {
      return suppliers.firstWhere(
        (s) => s.code.toUpperCase() == supplierCode.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<SupplierInfo>> getAllSuppliers({String? searchQuery}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var suppliers = List<SupplierInfo>.from(_allSuppliers);
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      suppliers = suppliers.where((s) => 
        s.name.toLowerCase().contains(query) ||
        (s.city?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    return suppliers;
  }

  @override
  Future<void> requestLinkWithMessage(String supplierCode, {String? message}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Find supplier and add to links with pending status
    final supplier = _allSuppliers.firstWhere(
      (s) => s.code == supplierCode,
      orElse: () => SupplierInfo(
        id: 999,
        name: 'Unknown Supplier',
        code: supplierCode,
        status: null,
      ),
    );
    
    _links.add(
      LinkInfo(
        id: _links.length + 1,
        supplierName: supplier.name,
        status: 'pending',
        supplierCode: supplierCode,
        city: supplier.city,
        logoUrl: supplier.logoUrl,
      ),
    );
    
    // Update supplier status
    final index = _allSuppliers.indexWhere((s) => s.code == supplierCode);
    if (index >= 0) {
      final existing = _allSuppliers[index];
      _allSuppliers[index] = SupplierInfo(
        id: existing.id,
        name: existing.name,
        code: existing.code,
        city: existing.city,
        logoUrl: existing.logoUrl,
        status: 'pending',
        category: existing.category,
        description: existing.description,
        address: existing.address,
        deliveryRegions: existing.deliveryRegions,
        minOrderAmount: existing.minOrderAmount,
        paymentTerms: existing.paymentTerms,
        deliverySchedule: existing.deliverySchedule,
        phone: existing.phone,
        email: existing.email,
        website: existing.website,
        workingHours: existing.workingHours,
        productCategories: existing.productCategories,
      );
    }
  }

  @override
  Future<void> cancelLinkRequest(String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _links.removeWhere((link) => 
      link.supplierCode == supplierCode && link.status == 'pending'
    );
    
    // Update supplier status back to null
    final index = _allSuppliers.indexWhere((s) => s.code == supplierCode);
    if (index >= 0) {
      final existing = _allSuppliers[index];
      _allSuppliers[index] = SupplierInfo(
        id: existing.id,
        name: existing.name,
        code: existing.code,
        city: existing.city,
        logoUrl: existing.logoUrl,
        status: null,
        category: existing.category,
        description: existing.description,
        address: existing.address,
        deliveryRegions: existing.deliveryRegions,
        minOrderAmount: existing.minOrderAmount,
        paymentTerms: existing.paymentTerms,
        deliverySchedule: existing.deliverySchedule,
        phone: existing.phone,
        email: existing.email,
        website: existing.website,
        workingHours: existing.workingHours,
        productCategories: existing.productCategories,
      );
    }
  }

  @override
  Future<List<String>> getCannedReplies() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      'Thank you for your order!',
      'I have a question about my order.',
      'When will my order be delivered?',
      'I need to change my order.',
      'Can I cancel my order?',
      'The product quality was excellent!',
      'I received the wrong items.',
      'Thank you for your help!',
    ];
  }

  @override
  Future<int> startChatWithSupplier(int supplierId, String supplierCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Check if chat already exists
    final existingChat = _chats.firstWhere(
      (chat) => chat.supplierId == supplierId && chat.supplierCode == supplierCode,
      orElse: () => Chat(
        id: 0,
        supplierId: 0,
        supplierName: '',
        lastMessageAt: DateTime.now(),
      ),
    );

    if (existingChat.id != 0) {
      return existingChat.id;
    }

    // Create new chat
    final supplier = _allSuppliers.firstWhere(
      (s) => s.id == supplierId && s.code == supplierCode,
      orElse: () => SupplierInfo(
        id: supplierId,
        name: 'Supplier',
        code: supplierCode,
      ),
    );

    final chatId = _chats.length + 1;
    _chats.add(
      Chat(
        id: chatId,
        supplierId: supplierId,
        supplierName: supplier.name,
        supplierCode: supplierCode,
        supplierLogoUrl: supplier.logoUrl,
        lastMessageAt: DateTime.now(),
        isComplaint: false,
      ),
    );

    // Initialize empty messages list
    _chatMessages[chatId] = [];

    return chatId;
  }
}
