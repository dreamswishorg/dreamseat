class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'customer', 'merchant', 'admin', 'super_admin'
  final String? phone;
  final String? avatarUrl;
  final bool isSuspended;
  final bool isApproved;
  final int dreamPoints;
  final double referralCredit;
  final String referralCode;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isSuspended = false,
    this.isApproved = true,
    this.dreamPoints = 0,
    this.referralCredit = 0.0,
    this.referralCode = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'isSuspended': isSuspended,
        'isApproved': isApproved,
        'dreamPoints': dreamPoints,
        'referralCredit': referralCredit,
        'referralCode': referralCode,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        role: json['role'],
        phone: json['phone'],
        avatarUrl: json['avatarUrl'] as String?,
        isSuspended: json['isSuspended'] ?? false,
        isApproved: json['isApproved'] ?? true,
        dreamPoints: json['dreamPoints'] ?? 0,
        referralCredit: (json['referralCredit'] as num?)?.toDouble() ?? 0.0,
        referralCode: json['referralCode'] ?? '',
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      );

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    bool? isSuspended,
    bool? isApproved,
    int? dreamPoints,
    double? referralCredit,
    String? referralCode,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      isSuspended: isSuspended ?? this.isSuspended,
      isApproved: isApproved ?? this.isApproved,
      dreamPoints: dreamPoints ?? this.dreamPoints,
      referralCredit: referralCredit ?? this.referralCredit,
      referralCode: referralCode ?? this.referralCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BusinessProfile {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String logoUrl;
  final String coverUrl;
  final String category;
  final String location;
  final double latitude;
  final double longitude;
  final double distance;
  final double rating;
  final bool isApproved;
  final String phone;

  BusinessProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.logoUrl,
    this.coverUrl = '',
    required this.category,
    required this.location,
    this.latitude = 5.6037, // Default Accra
    this.longitude = -0.1870,
    required this.distance,
    required this.rating,
    this.isApproved = false,
    this.phone = '+233 24 412 3456',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'description': description,
        'logoUrl': logoUrl,
        'coverUrl': coverUrl,
        'category': category,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
        'rating': rating,
        'isApproved': isApproved,
        'phone': phone,
      };

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        id: json['id'],
        ownerId: json['ownerId'] ?? json['owner_id'] ?? '',
        name: json['name'],
        description: json['description'],
        logoUrl: json['logoUrl'] ?? '',
        coverUrl: json['coverUrl'] ?? '',
        category: json['category'],
        location: json['location'],
        latitude: (json['latitude'] as num?)?.toDouble() ?? 5.6037,
        longitude: (json['longitude'] as num?)?.toDouble() ?? -0.1870,
        distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
        rating: ((json['rating'] as num?)?.toDouble() ?? 5.0) <= 0.0 ? 5.0 : ((json['rating'] as num?)?.toDouble() ?? 5.0),
        isApproved: json['isApproved'] ?? false,
        phone: json['phone'] ?? '+233 24 412 3456',
      );

  BusinessProfile copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? logoUrl,
    String? coverUrl,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
    double? distance,
    double? rating,
    bool? isApproved,
    String? phone,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      rating: rating ?? this.rating,
      isApproved: isApproved ?? this.isApproved,
      phone: phone ?? this.phone,
    );
  }
}


class FoodDeal {
  final String id;
  final String businessId;
  final String businessName;
  final String title;
  final String description;
  final String category;
  final double originalPrice;
  final double discountedPrice;
  final String pickupWindow;
  final int quantityRemaining;
  final int quantityTotal;
  final String imageUrl;
  final bool isActive;
  final List<String> dietaryTags;

  FoodDeal({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.description,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.pickupWindow,
    required this.quantityRemaining,
    required this.quantityTotal,
    required this.imageUrl,
    this.isActive = true,
    this.dietaryTags = const [],
  });

  int get percentageSaved {
    if (originalPrice <= 0) return 0;
    return (((originalPrice - discountedPrice) / originalPrice) * 100).round();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'businessName': businessName,
        'title': title,
        'description': description,
        'category': category,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'pickupWindow': pickupWindow,
        'quantityRemaining': quantityRemaining,
        'quantityTotal': quantityTotal,
        'imageUrl': imageUrl,
        'is_active': isActive,
        'dietaryTags': dietaryTags,
      };

  factory FoodDeal.fromJson(Map<String, dynamic> json) => FoodDeal(
        id: json['id'],
        businessId: json['businessId'],
        businessName: json['businessName'],
        title: json['title'],
        description: json['description'],
        category: json['category'],
        originalPrice: (json['originalPrice'] as num).toDouble(),
        discountedPrice: (json['discountedPrice'] as num).toDouble(),
        pickupWindow: json['pickupWindow'],
        quantityRemaining: json['quantityRemaining'],
        quantityTotal: json['quantityTotal'],
        imageUrl: json['imageUrl'],
        isActive: json['is_active'] ?? true,
        dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
      );

  FoodDeal copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? title,
    String? description,
    String? category,
    double? originalPrice,
    double? discountedPrice,
    String? pickupWindow,
    int? quantityRemaining,
    int? quantityTotal,
    String? imageUrl,
    bool? isActive,
    List<String>? dietaryTags,
  }) {
    return FoodDeal(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      pickupWindow: pickupWindow ?? this.pickupWindow,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      quantityTotal: quantityTotal ?? this.quantityTotal,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      dietaryTags: dietaryTags ?? this.dietaryTags,
    );
  }
}

class Order {
  final String id;
  final String dealId;
  final String dealTitle;
  final String businessId;
  final String businessName;
  final String customerId;
  final String customerName;
  final double price;
  final double originalPrice;
  final String category;
  final String status;
  final DateTime timestamp;
  final String paymentMethod;
  final String paymentReference;
  final String collectionCode;
  final bool isRated;
  final String payoutStatus;

  final String fulfillmentType; // 'pickup' | 'delivery'
  final String? courierName;
  final String? courierPhone;
  final String? trackingNotes;
  final String? deliveryAddress;

  Order({
    required this.id,
    required this.dealId,
    required this.dealTitle,
    required this.businessId,
    required this.businessName,
    required this.customerId,
    required this.customerName,
    required this.price,
    required this.originalPrice,
    required this.category,
    required this.status,
    required this.timestamp,
    required this.paymentMethod,
    required this.paymentReference,
    required this.collectionCode,
    this.isRated = false,
    this.payoutStatus = 'pending',
    this.fulfillmentType = 'pickup',
    this.courierName,
    this.courierPhone,
    this.trackingNotes,
    this.deliveryAddress,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dealId': dealId,
        'dealTitle': dealTitle,
        'businessId': businessId,
        'businessName': businessName,
        'customerId': customerId,
        'customerName': customerName,
        'price': price,
        'originalPrice': originalPrice,
        'category': category,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
        'collectionCode': collectionCode,
        'isRated': isRated,
        'payoutStatus': payoutStatus,
        'fulfillmentType': fulfillmentType,
        'courierName': courierName,
        'courierPhone': courierPhone,
        'trackingNotes': trackingNotes,
        'deliveryAddress': deliveryAddress,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        dealId: json['dealId'] ?? '',
        dealTitle: json['dealTitle'] ?? '',
        businessId: json['businessId'] ?? '',
        businessName: json['businessName'] ?? '',
        customerId: json['customerId'] ?? '',
        customerName: json['customerName'] ?? '',
        price: (json['price'] as num).toDouble(),
        originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? (json['price'] as num).toDouble(),
        category: json['category'] ?? 'Food Rescue',
        status: json['status'],
        timestamp: DateTime.parse(json['timestamp']),
        paymentMethod: json['paymentMethod'],
        paymentReference: json['paymentReference'] ?? '',
        collectionCode: json['collectionCode'],
        isRated: json['isRated'] ?? false,
        payoutStatus: json['payoutStatus'] ?? 'pending',
        fulfillmentType: json['fulfillmentType'] ?? json['fulfillment_type'] ?? 'pickup',
        courierName: json['courierName'] ?? json['courier_name'],
        courierPhone: json['courierPhone'] ?? json['courier_phone'],
        trackingNotes: json['trackingNotes'] ?? json['tracking_notes'],
        deliveryAddress: json['deliveryAddress'] ?? json['delivery_address'],
      );

  Order copyWith({
    String? id,
    String? dealId,
    String? dealTitle,
    String? businessId,
    String? businessName,
    String? customerId,
    String? customerName,
    double? price,
    double? originalPrice,
    String? category,
    String? status,
    DateTime? timestamp,
    String? paymentMethod,
    String? paymentReference,
    String? collectionCode,
    bool? isRated,
    String? payoutStatus,
    String? fulfillmentType,
    String? courierName,
    String? courierPhone,
    String? trackingNotes,
    String? deliveryAddress,
  }) {
    return Order(
      id: id ?? this.id,
      dealId: dealId ?? this.dealId,
      dealTitle: dealTitle ?? this.dealTitle,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      collectionCode: collectionCode ?? this.collectionCode,
      isRated: isRated ?? this.isRated,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      trackingNotes: trackingNotes ?? this.trackingNotes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }
}

class CategoryItem {
  final String id;
  final String name;
  final String imageUrl;
  final String? iconName;

  CategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.iconName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'iconName': iconName,
      };

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        iconName: json['iconName'],
      );
}


class SustainabilityStats {
  final int mealsRescued;
  final double moneySaved;
  final double moneySpent;
  final double co2Saved;

  SustainabilityStats({
    required this.mealsRescued,
    required this.moneySaved,
    this.moneySpent = 0.0,
    required this.co2Saved,
  });

  Map<String, dynamic> toJson() => {
        'mealsRescued': mealsRescued,
        'moneySaved': moneySaved,
        'moneySpent': moneySpent,
        'co2Saved': co2Saved,
      };

  factory SustainabilityStats.fromJson(Map<String, dynamic> json) => SustainabilityStats(
        mealsRescued: json['mealsRescued'] ?? 0,
        moneySaved: (json['moneySaved'] as num?)?.toDouble() ?? 0.0,
        moneySpent: (json['moneySpent'] as num?)?.toDouble() ?? 0.0,
        co2Saved: (json['co2Saved'] as num?)?.toDouble() ?? 0.0,
      );

  factory SustainabilityStats.zero() => SustainabilityStats(
        mealsRescued: 0,
        moneySaved: 0.0,
        moneySpent: 0.0,
        co2Saved: 0.0,
      );

  SustainabilityStats addMeal(double priceSaved, [double priceSpent = 0.0]) {
    return SustainabilityStats(
      mealsRescued: mealsRescued + 1,
      moneySaved: moneySaved + priceSaved,
      moneySpent: moneySpent + priceSpent,
      co2Saved: co2Saved + 2.5,
    );
  }
}

class BasketItem {
  final FoodDeal deal;
  final int quantity;

  BasketItem({
    required this.deal,
    required this.quantity,
  });

  double get totalPrice => deal.discountedPrice * quantity;

  Map<String, dynamic> toJson() => {
        'deal': deal.toJson(),
        'quantity': quantity,
      };

  factory BasketItem.fromJson(Map<String, dynamic> json) => BasketItem(
        deal: FoodDeal.fromJson(json['deal']),
        quantity: json['quantity'],
      );

  BasketItem copyWith({
    FoodDeal? deal,
    int? quantity,
  }) {
    return BasketItem(
      deal: deal ?? this.deal,
      quantity: quantity ?? this.quantity,
    );
  }
}

class DisputeTicket {
  final String id;
  final String orderId;
  final String customerName;
  final String merchantName;
  final String issueDescription;
  final String status; // 'open', 'resolved'
  final List<String> chatLogs;

  DisputeTicket({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.merchantName,
    required this.issueDescription,
    required this.status,
    required this.chatLogs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'customerName': customerName,
        'merchantName': merchantName,
        'issueDescription': issueDescription,
        'status': status,
        'chatLogs': chatLogs,
      };

  factory DisputeTicket.fromJson(Map<String, dynamic> json) => DisputeTicket(
        id: json['id'],
        orderId: json['orderId'],
        customerName: json['customerName'],
        merchantName: json['merchantName'],
        issueDescription: json['issueDescription'],
        status: json['status'],
        chatLogs: List<String>.from(json['chatLogs'] ?? []),
      );

  DisputeTicket copyWith({
    String? id,
    String? orderId,
    String? customerName,
    String? merchantName,
    String? issueDescription,
    String? status,
    List<String>? chatLogs,
  }) {
    return DisputeTicket(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      merchantName: merchantName ?? this.merchantName,
      issueDescription: issueDescription ?? this.issueDescription,
      status: status ?? this.status,
      chatLogs: chatLogs ?? this.chatLogs,
    );
  }
}

class PlatformSettings {
  final double commissionRate;
  final String minAppVersion;
  final bool maintenanceMode;

  PlatformSettings({
    required this.commissionRate,
    required this.minAppVersion,
    required this.maintenanceMode,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) => PlatformSettings(
        commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.15,
        minAppVersion: (json['min_app_version'] as String?) ?? '1.0.0',
        maintenanceMode: (json['maintenance_mode'] as bool?) ?? false,
      );

  factory PlatformSettings.defaultSettings() => PlatformSettings(
        commissionRate: 0.15,
        minAppVersion: '1.0.0',
        maintenanceMode: false,
      );

  PlatformSettings copyWith({
    double? commissionRate,
    String? minAppVersion,
    bool? maintenanceMode,
  }) {
    return PlatformSettings(
      commissionRate: commissionRate ?? this.commissionRate,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
    );
  }
}

class Voucher {
  final String id;
  final String code;
  final double discountAmount;
  final String discountType; // 'fixed' or 'percentage'
  final DateTime? expiresAt;
  final int usageLimit;
  final int usageCount;
  final bool isActive;
  final String fundedBy; // 'platform' or 'merchant'

  Voucher({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.discountType,
    this.expiresAt,
    this.usageLimit = 100,
    this.usageCount = 0,
    this.isActive = true,
    required this.fundedBy,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        id: json['id'],
        code: json['code'],
        discountAmount: (json['discount_amount'] as num).toDouble(),
        discountType: json['discount_type'],
        expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
        usageLimit: json['usage_limit'] ?? 100,
        usageCount: json['usage_count'] ?? 0,
        isActive: json['is_active'] ?? true,
        fundedBy: json['funded_by'] ?? 'platform',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'discount_amount': discountAmount,
        'discount_type': discountType,
        'expires_at': expiresAt?.toIso8601String(),
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'is_active': isActive,
        'funded_by': fundedBy,
      };
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? screen; // e.g., 'deal_detail', 'orders'
  final String? dataId; // e.g., dealId or orderId
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.screen,
    this.dataId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'screen': screen,
        'data_id': dataId,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        body: json['body'],
        screen: json['screen'],
        dataId: json['data_id'],
        createdAt: DateTime.parse(json['created_at']),
        isRead: json['is_read'] ?? false,
      );

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? screen,
    String? dataId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      screen: screen ?? this.screen,
      dataId: dataId ?? this.dataId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class AuditLog {
  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String entityType; // 'merchant', 'admin', 'order', 'setting'
  final String entityId;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.description,
    required this.metadata,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id']?.toString() ?? '',
        actorId: json['actor_id']?.toString() ?? '',
        actorName: json['actor_name']?.toString() ?? 'System',
        actorRole: json['actor_role']?.toString() ?? 'unknown',
        action: json['action']?.toString() ?? 'ACTION',
        entityType: json['entity_type']?.toString() ?? 'platform',
        entityId: json['entity_id']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : {},
        createdAt: json['created_at'] != null
            ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
            : DateTime.now(),
      );
}

class BroadcastMessage {
  final String id;
  final String title;
  final String message;
  final String audience; // 'all', 'customers', 'merchants'
  final String? sentBy;
  final DateTime createdAt;

  BroadcastMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    this.sentBy,
    required this.createdAt,
  });

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) => BroadcastMessage(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        audience: json['audience'],
        sentBy: json['sent_by'],
        createdAt: DateTime.parse(json['created_at']),
      );
}

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String subject;
  final String message;
  final String status; // 'open', 'in_progress', 'resolved'
  final String priority; // 'low', 'normal', 'high', 'urgent'
  final String category;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.category,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'],
        userId: json['user_id'],
        userName: json['user_name'],
        subject: json['subject'],
        message: json['message'],
        status: json['status'],
        priority: json['priority'],
        category: json['category'],
        assignedTo: json['assigned_to'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
}

class TicketReply {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String message;
  final bool isStaffReply;
  final DateTime createdAt;

  TicketReply({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isStaffReply,
    required this.createdAt,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) => TicketReply(
        id: json['id'],
        ticketId: json['ticket_id'],
        senderId: json['sender_id'],
        senderName: json['sender_name'],
        message: json['message'],
        isStaffReply: json['is_staff_reply'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );
}

extension AppUserPrivileges on AppUser {
  List<String> get privileges {
    if (role == 'super_admin') {
      return [
        'analytics',
        'approvals',
        'directory',
        'ledger',
        'vouchers',
        'disputes',
        'support',
        'map',
        'broadcasts',
        'config',
        'audit',
        'pulse',
        'seed',
      ];
    }
    
    if (phone != null && phone!.contains('PRIVS:')) {
      final parts = phone!.split('PRIVS:');
      if (parts.length > 1) {
        return parts[1].split(',').map((s) => s.trim()).toList();
      }
    }
    
    if (role == 'admin') {
      // Default privileges for normal staff
      return [
        'analytics',
        'approvals',
        'directory',
        'ledger',
        'vouchers',
        'disputes',
        'support',
        'map',
        'broadcasts',
      ];
    }
    
    return [];
  }

  bool hasPrivilege(String privilege) {
    return privileges.contains(privilege);
  }
}

