import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_config.dart';

class FaqEntry {
  FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
  });

  final int id;
  final String question;
  final String answer;
  final String category;
  final int order;

  factory FaqEntry.fromJson(Map<String, dynamic> json) => FaqEntry(
        id: json['id'] as int,
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        category: json['category'] as String? ?? '',
        order: json['order'] as int? ?? 0,
      );
}

class SavedAddress {
  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.phone,
    this.latitude,
    this.longitude,
    required this.isDefault,
    required this.createdAt,
  });

  final int id;
  final String label;
  final String address;
  final String phone;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final String createdAt;

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id'] as int,
        label: json['label'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isDefault: json['is_default'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class UserBlock {
  UserBlock({
    required this.id,
    required this.blockedId,
    required this.blockedName,
    required this.createdAt,
  });

  final int id;
  final int blockedId;
  final String blockedName;
  final String createdAt;

  factory UserBlock.fromJson(Map<String, dynamic> json) => UserBlock(
        id: json['id'] as int,
        blockedId: json['blocked'] as int? ?? 0,
        blockedName: json['blocked_name'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class StoryView {
  StoryView({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.mediaUrl,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
  });

  final int id;
  final int authorId;
  final String authorName;
  final String mediaUrl;
  final String caption;
  final String createdAt;
  final String expiresAt;

  factory StoryView.fromJson(Map<String, dynamic> json) => StoryView(
        id: json['id'] as int,
        authorId: json['author'] as int? ?? 0,
        authorName: json['author_name'] as String? ?? '',
        mediaUrl: ApiConfig.resolveMediaUrl(json['media'] as String? ?? ''),
        caption: json['caption'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        expiresAt: json['expires_at'] as String? ?? '',
      );
}

class ReferralInfo {
  ReferralInfo({
    required this.code,
    required this.rewardPoints,
    required this.createdAt,
  });

  final String code;
  final int rewardPoints;
  final String createdAt;

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => ReferralInfo(
        code: json['code'] as String? ?? '',
        rewardPoints: json['reward_points'] as int? ?? 0,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class DisputeView {
  DisputeView({
    required this.id,
    required this.orderId,
    required this.openedBy,
    required this.reason,
    required this.details,
    required this.status,
    required this.resolutionNote,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int orderId;
  final int openedBy;
  final String reason;
  final String details;
  final String status;
  final String resolutionNote;
  final String createdAt;
  final String updatedAt;

  factory DisputeView.fromJson(Map<String, dynamic> json) => DisputeView(
        id: json['id'] as int,
        orderId: json['order'] as int? ?? 0,
        openedBy: json['opened_by'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
        details: json['details'] as String? ?? '',
        status: json['status'] as String? ?? '',
        resolutionNote: json['resolution_note'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );
}

class GroupOrderItemView {
  GroupOrderItemView({
    required this.id,
    required this.userId,
    required this.userName,
    required this.mealId,
    required this.mealName,
    required this.quantity,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String userName;
  final int mealId;
  final String mealName;
  final int quantity;
  final String note;
  final String createdAt;

  factory GroupOrderItemView.fromJson(Map<String, dynamic> json) =>
      GroupOrderItemView(
        id: json['id'] as int,
        userId: json['user'] as int? ?? 0,
        userName: json['user_name'] as String? ?? '',
        mealId: json['meal'] as int? ?? 0,
        mealName: json['meal_name'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        note: json['note'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class GroupOrderView {
  GroupOrderView({
    required this.id,
    required this.code,
    required this.hostId,
    required this.hostName,
    required this.sellerId,
    required this.status,
    this.orderId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String code;
  final int hostId;
  final String hostName;
  final int sellerId;
  final String status;
  final int? orderId;
  final List<GroupOrderItemView> items;
  final String createdAt;
  final String updatedAt;

  factory GroupOrderView.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?) ?? const [];
    return GroupOrderView(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      hostId: json['host'] as int? ?? 0,
      hostName: json['host_name'] as String? ?? '',
      sellerId: json['seller'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      orderId: json['order'] as int?,
      items: items
          .map((e) => GroupOrderItemView.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class SupportApi {
  SupportApi._();
  static final SupportApi instance = SupportApi._();

  final _dio = ApiClient.instance.dio;

  Future<List<FaqEntry>> fetchFaq() async {
    final res = await _dio.get('/faq/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => FaqEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SavedAddress>> fetchAddresses() async {
    final res = await _dio.get('/addresses/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SavedAddress> createAddress({
    required String label,
    required String address,
    String phone = '',
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final res = await _dio.post('/addresses/', data: {
      'label': label,
      'address': address,
      'phone': phone,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_default': isDefault,
    });
    return SavedAddress.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SavedAddress> updateAddress(
    int id, {
    String? label,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    final res = await _dio.patch('/addresses/$id/', data: {
      if (label != null) 'label': label,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isDefault != null) 'is_default': isDefault,
    });
    return SavedAddress.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int id) async {
    await _dio.delete('/addresses/$id/');
  }

  Future<List<UserBlock>> fetchBlocks() async {
    final res = await _dio.get('/blocks/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => UserBlock.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> blockUser(int userId) async {
    await _dio.post('/blocks/', data: {'blocked': userId});
  }

  Future<void> unblockUser(int userId) async {
    await _dio.delete('/blocks/$userId/');
  }

  Future<void> reportContent({
    required String targetType,
    required int targetId,
    required String reason,
    String details = '',
  }) async {
    await _dio.post('/reports/', data: {
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'details': details,
    });
  }

  Future<List<StoryView>> fetchStoriesFeed() async {
    final res = await _dio.get('/stories/feed/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => StoryView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoryView> createStory({
    required String mediaPath,
    String caption = '',
  }) async {
    final form = FormData.fromMap({
      'caption': caption,
      'media': await MultipartFile.fromFile(mediaPath),
    });
    final res = await _dio.post('/stories/', data: form);
    return StoryView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteStory(int id) async {
    await _dio.delete('/stories/$id/');
  }

  Future<ReferralInfo> fetchReferral() async {
    final res = await _dio.get('/referral/');
    return ReferralInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> redeemReferral(String code) async {
    await _dio.post('/referral/redeem/', data: {'code': code.trim()});
  }

  Future<List<DisputeView>> fetchDisputes() async {
    final res = await _dio.get('/disputes/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => DisputeView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DisputeView> createDispute({
    required int orderId,
    required String reason,
    String details = '',
  }) async {
    final res = await _dio.post('/disputes/', data: {
      'order': orderId,
      'reason': reason,
      'details': details,
    });
    return DisputeView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GroupOrderView> createGroupOrder({required int sellerId}) async {
    final res = await _dio.post('/group-orders/', data: {'seller': sellerId});
    return GroupOrderView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GroupOrderView> fetchGroupOrder(String code) async {
    final res = await _dio.get('/group-orders/$code/');
    return GroupOrderView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GroupOrderView> joinGroupOrder(String code) async {
    final res = await _dio.post('/group-orders/$code/join/');
    return GroupOrderView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GroupOrderView> addGroupOrderItem(
    String code, {
    required int mealId,
    int quantity = 1,
    String note = '',
  }) async {
    final res = await _dio.post('/group-orders/$code/items/', data: {
      'meal': mealId,
      'quantity': quantity,
      'note': note,
    });
    return GroupOrderView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> removeGroupOrderItem(String code, int itemId) async {
    await _dio.delete('/group-orders/$code/items/$itemId/');
  }

  Future<Map<String, dynamic>> checkoutGroupOrder(
    String code, {
    required String fulfillment,
    required String paymentMethod,
    String address = '',
    String phone = '',
    String note = '',
  }) async {
    final res = await _dio.post('/group-orders/$code/checkout/', data: {
      'fulfillment': fulfillment,
      'payment_method': paymentMethod,
      'address': address,
      'phone': phone,
      'note': note,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }
}
