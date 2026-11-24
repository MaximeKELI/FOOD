import 'package:dio/dio.dart';

import '../models/meal.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'catalog_api.dart';

class PlatformSettings {
  PlatformSettings({
    required this.paymentsEnabled,
    required this.cashEnabled,
    required this.digitalPaymentsEnabled,
    required this.newOrdersEnabled,
    required this.commissionPercent,
    required this.commissionFlat,
    required this.updatedAt,
  });

  final bool paymentsEnabled;
  final bool cashEnabled;
  final bool digitalPaymentsEnabled;
  final bool newOrdersEnabled;
  final int commissionPercent;
  final int commissionFlat;
  final String updatedAt;

  factory PlatformSettings.fromJson(Map<String, dynamic> json) => PlatformSettings(
        paymentsEnabled: json['payments_enabled'] as bool? ?? true,
        cashEnabled: json['cash_enabled'] as bool? ?? true,
        digitalPaymentsEnabled:
            json['digital_payments_enabled'] as bool? ?? true,
        newOrdersEnabled: json['new_orders_enabled'] as bool? ?? true,
        commissionPercent: json['commission_percent'] as int? ?? 0,
        commissionFlat: json['commission_flat'] as int? ?? 0,
        updatedAt: json['updated_at'] as String? ?? '',
      );
}

class OpenNowSeller {
  OpenNowSeller({
    required this.id,
    required this.name,
    required this.shopName,
    required this.opensAt,
    required this.closesAt,
    required this.cuisine,
    required this.isOpenNow,
  });

  final int id;
  final String name;
  final String shopName;
  final String opensAt;
  final String closesAt;
  final String cuisine;
  final bool isOpenNow;

  factory OpenNowSeller.fromJson(Map<String, dynamic> json) => OpenNowSeller(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        shopName: json['shop_name'] as String? ?? '',
        opensAt: json['opens_at'] as String? ?? '',
        closesAt: json['closes_at'] as String? ?? '',
        cuisine: json['cuisine'] as String? ?? '',
        isOpenNow: json['is_open_now'] as bool? ?? true,
      );
}

class WishListItem {
  WishListItem({
    required this.id,
    required this.mealId,
    this.meal,
    required this.createdAt,
  });

  final int id;
  final int mealId;
  final Meal? meal;
  final String createdAt;

  factory WishListItem.fromJson(Map<String, dynamic> json) => WishListItem(
        id: json['id'] as int,
        mealId: json['meal'] as int? ?? 0,
        meal: json['meal_detail'] != null
            ? CatalogApi.instance.mealFromApiJson(
                json['meal_detail'] as Map<String, dynamic>,
              )
            : null,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class WishList {
  WishList({
    required this.id,
    required this.name,
    required this.items,
    required this.itemsCount,
    required this.createdAt,
  });

  final int id;
  final String name;
  final List<WishListItem> items;
  final int itemsCount;
  final String createdAt;

  factory WishList.fromJson(Map<String, dynamic> json) => WishList(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        items: ((json['items'] as List?) ?? const [])
            .map((e) => WishListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        itemsCount: json['items_count'] as int? ?? 0,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class LoyaltyTier {
  LoyaltyTier({
    required this.id,
    required this.name,
    required this.minPoints,
    required this.perk,
    required this.order,
  });

  final int id;
  final String name;
  final int minPoints;
  final String perk;
  final int order;

  factory LoyaltyTier.fromJson(Map<String, dynamic> json) => LoyaltyTier(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        minPoints: json['min_points'] as int? ?? 0,
        perk: json['perk'] as String? ?? '',
        order: json['order'] as int? ?? 0,
      );
}

class LoyaltyLedgerEntry {
  LoyaltyLedgerEntry({
    required this.id,
    required this.kind,
    required this.points,
    required this.balanceAfter,
    required this.note,
    this.relatedOrder,
    required this.createdAt,
  });

  final int id;
  final String kind;
  final int points;
  final int balanceAfter;
  final String note;
  final int? relatedOrder;
  final String createdAt;

  factory LoyaltyLedgerEntry.fromJson(Map<String, dynamic> json) =>
      LoyaltyLedgerEntry(
        id: json['id'] as int,
        kind: json['kind'] as String? ?? '',
        points: json['points'] as int? ?? 0,
        balanceAfter: json['balance_after'] as int? ?? 0,
        note: json['note'] as String? ?? '',
        relatedOrder: json['related_order'] as int?,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class LoyaltyReward {
  LoyaltyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.active,
  });

  final int id;
  final String title;
  final String description;
  final int pointsCost;
  final bool active;

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) => LoyaltyReward(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        pointsCost: json['points_cost'] as int? ?? 0,
        active: json['active'] as bool? ?? true,
      );
}

class LoyaltySummary {
  LoyaltySummary({
    required this.points,
    this.currentTier,
    this.nextTier,
    required this.ledger,
    required this.rewards,
    this.progressToNext,
  });

  final int points;
  final LoyaltyTier? currentTier;
  final LoyaltyTier? nextTier;
  final List<LoyaltyLedgerEntry> ledger;
  final List<LoyaltyReward> rewards;
  final Map<String, int>? progressToNext;

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    final progress = json['progress_to_next'] as Map<String, dynamic>?;
    return LoyaltySummary(
      points: json['points'] as int? ?? 0,
      currentTier: json['current_tier'] != null
          ? LoyaltyTier.fromJson(
              json['current_tier'] as Map<String, dynamic>,
            )
          : null,
      nextTier: json['next_tier'] != null
          ? LoyaltyTier.fromJson(json['next_tier'] as Map<String, dynamic>)
          : null,
      ledger: ((json['ledger'] as List?) ?? const [])
          .map((e) => LoyaltyLedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewards: ((json['rewards'] as List?) ?? const [])
          .map((e) => LoyaltyReward.fromJson(e as Map<String, dynamic>))
          .toList(),
      progressToNext: progress != null
          ? {
              'have': progress['have'] as int? ?? 0,
              'need': progress['need'] as int? ?? 0,
              'remaining': progress['remaining'] as int? ?? 0,
            }
          : null,
    );
  }
}

class KycDocument {
  KycDocument({
    required this.id,
    required this.subject,
    required this.documentUrl,
    required this.idNumber,
    required this.status,
    required this.reviewNote,
    required this.createdAt,
    this.reviewedAt,
  });

  final int id;
  final String subject;
  final String documentUrl;
  final String idNumber;
  final String status;
  final String reviewNote;
  final String createdAt;
  final String? reviewedAt;

  factory KycDocument.fromJson(Map<String, dynamic> json) => KycDocument(
        id: json['id'] as int,
        subject: json['subject'] as String? ?? '',
        documentUrl: ApiConfig.resolveMediaUrl(json['document'] as String? ?? ''),
        idNumber: json['id_number'] as String? ?? '',
        status: json['status'] as String? ?? '',
        reviewNote: json['review_note'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        reviewedAt: json['reviewed_at'] as String?,
      );
}

class PickupSlot {
  PickupSlot({
    required this.id,
    required this.sellerId,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.booked,
    required this.remaining,
    required this.isActive,
  });

  final int id;
  final int sellerId;
  final String startsAt;
  final String endsAt;
  final int capacity;
  final int booked;
  final int remaining;
  final bool isActive;

  factory PickupSlot.fromJson(Map<String, dynamic> json) => PickupSlot(
        id: json['id'] as int,
        sellerId: json['seller'] as int? ?? 0,
        startsAt: json['starts_at'] as String? ?? '',
        endsAt: json['ends_at'] as String? ?? '',
        capacity: json['capacity'] as int? ?? 0,
        booked: json['booked'] as int? ?? 0,
        remaining: json['remaining'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class MealBoost {
  MealBoost({
    required this.id,
    required this.mealId,
    required this.mealName,
    required this.startsAt,
    required this.expiresAt,
    required this.score,
    required this.paidAmount,
    required this.createdAt,
  });

  final int mealId;
  final int id;
  final String mealName;
  final String startsAt;
  final String expiresAt;
  final int score;
  final int paidAmount;
  final String createdAt;

  factory MealBoost.fromJson(Map<String, dynamic> json) => MealBoost(
        id: json['id'] as int,
        mealId: json['meal'] as int? ?? 0,
        mealName: json['meal_name'] as String? ?? '',
        startsAt: json['starts_at'] as String? ?? '',
        expiresAt: json['expires_at'] as String? ?? '',
        score: json['score'] as int? ?? 0,
        paidAmount: json['paid_amount'] as int? ?? 0,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class SellerDashboardExtra {
  SellerDashboardExtra({
    required this.todayRevenue,
    required this.lowStockMeals,
    required this.pendingOrders,
    required this.unrepliedReviews,
    required this.monthGmv,
    required this.estimatedCommission,
    required this.commissionPercent,
  });

  final int todayRevenue;
  final int lowStockMeals;
  final int pendingOrders;
  final int unrepliedReviews;
  final int monthGmv;
  final int estimatedCommission;
  final int commissionPercent;

  factory SellerDashboardExtra.fromJson(Map<String, dynamic> json) =>
      SellerDashboardExtra(
        todayRevenue: json['today_revenue'] as int? ?? 0,
        lowStockMeals: json['low_stock_meals'] as int? ?? 0,
        pendingOrders: json['pending_orders'] as int? ?? 0,
        unrepliedReviews: json['unreplied_reviews'] as int? ?? 0,
        monthGmv: json['month_gmv'] as int? ?? 0,
        estimatedCommission: json['estimated_commission'] as int? ?? 0,
        commissionPercent: json['commission_percent'] as int? ?? 0,
      );
}

class OpsOverview {
  OpsOverview({
    required this.settings,
    required this.pendingDisputes,
    required this.pendingKyc,
    required this.activeDeliveries,
    required this.driversPending,
    required this.ordersToday,
  });

  final PlatformSettings settings;
  final int pendingDisputes;
  final int pendingKyc;
  final int activeDeliveries;
  final int driversPending;
  final int ordersToday;

  factory OpsOverview.fromJson(Map<String, dynamic> json) => OpsOverview(
        settings: PlatformSettings.fromJson(
          json['settings'] as Map<String, dynamic>? ?? const {},
        ),
        pendingDisputes: json['pending_disputes'] as int? ?? 0,
        pendingKyc: json['pending_kyc'] as int? ?? 0,
        activeDeliveries: json['active_deliveries'] as int? ?? 0,
        driversPending: json['drivers_pending'] as int? ?? 0,
        ordersToday: json['orders_today'] as int? ?? 0,
      );
}

class SellerInvoice {
  SellerInvoice({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.gmv,
    required this.commission,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String periodStart;
  final String periodEnd;
  final int gmv;
  final int commission;
  final String status;
  final String createdAt;

  factory SellerInvoice.fromJson(Map<String, dynamic> json) => SellerInvoice(
        id: json['id'] as int,
        periodStart: json['period_start'] as String? ?? '',
        periodEnd: json['period_end'] as String? ?? '',
        gmv: json['gmv'] as int? ?? 0,
        commission: json['commission'] as int? ?? 0,
        status: json['status'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class DisputeEvidence {
  DisputeEvidence({
    required this.id,
    required this.disputeId,
    required this.fileUrl,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int disputeId;
  final String fileUrl;
  final String note;
  final String createdAt;

  factory DisputeEvidence.fromJson(Map<String, dynamic> json) => DisputeEvidence(
        id: json['id'] as int,
        disputeId: json['dispute'] as int? ?? 0,
        fileUrl: ApiConfig.resolveMediaUrl(json['file'] as String? ?? ''),
        note: json['note'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class DeliveryReview {
  DeliveryReview({
    required this.id,
    required this.orderId,
    required this.sellerRating,
    this.driverRating,
    required this.comment,
    required this.createdAt,
  });

  final int id;
  final int orderId;
  final int sellerRating;
  final int? driverRating;
  final String comment;
  final String createdAt;

  factory DeliveryReview.fromJson(Map<String, dynamic> json) => DeliveryReview(
        id: json['id'] as int,
        orderId: json['order'] as int? ?? 0,
        sellerRating: json['seller_rating'] as int? ?? 0,
        driverRating: json['driver_rating'] as int?,
        comment: json['comment'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class PlatformApi {
  PlatformApi._();
  static final PlatformApi instance = PlatformApi._();

  final _dio = ApiClient.instance.dio;

  Future<PlatformSettings> fetchSettings() async {
    final res = await _dio.get('/platform/settings/');
    return PlatformSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<OpenNowSeller>> fetchOpenNowSellers() async {
    final res = await _dio.get('/platform/open-now/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => OpenNowSeller.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Meal>> fetchRecommendations() async {
    final res = await _dio.get('/platform/recommendations/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => CatalogApi.instance.mealFromApiJson(
              e as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<List<WishList>> fetchWishlists() async {
    final res = await _dio.get('/platform/wishlists/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => WishList.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WishList> createWishlist(String name) async {
    final res = await _dio.post('/platform/wishlists/', data: {'name': name});
    return WishList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WishList> fetchWishlist(int id) async {
    final res = await _dio.get('/platform/wishlists/$id/');
    return WishList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WishList> updateWishlist(int id, {required String name}) async {
    final res = await _dio.patch('/platform/wishlists/$id/', data: {'name': name});
    return WishList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteWishlist(int id) async {
    await _dio.delete('/platform/wishlists/$id/');
  }

  Future<WishListItem> addWishlistItem(int wishlistId, int mealId) async {
    final res = await _dio.post(
      '/platform/wishlists/$wishlistId/items/',
      data: {'meal': mealId},
    );
    return WishListItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> removeWishlistItem(int wishlistId, int mealId) async {
    await _dio.delete(
      '/platform/wishlists/$wishlistId/items/',
      data: {'meal': mealId},
    );
  }

  Future<LoyaltySummary> fetchLoyaltySummary() async {
    final res = await _dio.get('/platform/loyalty/');
    return LoyaltySummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> redeemLoyaltyReward(int rewardId) async {
    final res = await _dio.post(
      '/platform/loyalty/redeem/',
      data: {'reward': rewardId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<KycDocument>> fetchKycDocuments() async {
    final res = await _dio.get('/platform/kyc/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => KycDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KycDocument> uploadKyc({
    required String filePath,
    required String subject,
    String idNumber = '',
  }) async {
    final form = FormData.fromMap({
      'subject': subject,
      if (idNumber.isNotEmpty) 'id_number': idNumber,
      'document': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/platform/kyc/', data: form);
    return KycDocument.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<PickupSlot>> fetchPickupSlots({int? sellerId}) async {
    final res = await _dio.get(
      '/platform/slots/',
      queryParameters: {
        if (sellerId != null) 'seller': sellerId,
      },
    );
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => PickupSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PickupSlot> createPickupSlot({
    required String startsAt,
    required String endsAt,
    int capacity = 5,
    bool isActive = true,
  }) async {
    final res = await _dio.post('/platform/slots/', data: {
      'starts_at': startsAt,
      'ends_at': endsAt,
      'capacity': capacity,
      'is_active': isActive,
    });
    return PickupSlot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PickupSlot> bookPickupSlot(int slotId) async {
    final res = await _dio.post('/platform/slots/$slotId/book/');
    return PickupSlot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DisputeEvidence> uploadDisputeEvidence({
    required int disputeId,
    required String filePath,
    String note = '',
  }) async {
    final form = FormData.fromMap({
      'dispute': disputeId,
      if (note.isNotEmpty) 'note': note,
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/platform/disputes/evidence/', data: form);
    return DisputeEvidence.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DeliveryReview> submitDeliveryReview({
    required int orderId,
    required int sellerRating,
    int? driverRating,
    String comment = '',
  }) async {
    final res = await _dio.post('/platform/reviews/delivery/', data: {
      'order': orderId,
      'seller_rating': sellerRating,
      if (driverRating != null) 'driver_rating': driverRating,
      if (comment.isNotEmpty) 'comment': comment,
    });
    return DeliveryReview.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<MealBoost>> fetchBoosts() async {
    final res = await _dio.get('/platform/boosts/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => MealBoost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealBoost> createBoost({
    required int mealId,
    int hours = 24,
    int paidAmount = 0,
  }) async {
    final res = await _dio.post('/platform/boosts/', data: {
      'meal': mealId,
      'hours': hours,
      if (paidAmount > 0) 'paid_amount': paidAmount,
    });
    return MealBoost.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SellerDashboardExtra> fetchSellerDashboardExtra() async {
    final res = await _dio.get('/platform/seller/dashboard-extra/');
    return SellerDashboardExtra.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OpsOverview> fetchOps() async {
    final res = await _dio.get('/platform/ops/');
    return OpsOverview.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PlatformSettings> patchOpsFlags(Map<String, dynamic> flags) async {
    final res = await _dio.patch('/platform/ops/flags/', data: flags);
    return PlatformSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SellerInvoice>> fetchInvoices() async {
    final res = await _dio.get('/platform/invoices/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => SellerInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}