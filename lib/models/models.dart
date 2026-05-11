import 'package:cloud_firestore/cloud_firestore.dart';

// ─── 공동구매 모델 ───────────────────────────────────────────────
class GroupBuyPost {
  final String id;
  final String title;
  final String category; // 식료품 / 생활용품 / 배달음식
  final String imageUrl;
  final int totalPrice;
  final int unitPrice; // 1인 부담금
  final int maxParticipants;
  final int currentParticipants;
  final int walkMinutes; // 도보 거리(분)
  final String location;
  final String authorName;
  final DateTime createdAt;
  final bool isDelivery;

  GroupBuyPost({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.totalPrice,
    required this.unitPrice,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.walkMinutes,
    required this.location,
    required this.authorName,
    required this.createdAt,
    required this.isDelivery,
  });

  bool get isFull => currentParticipants >= maxParticipants;
  double get fillRate => currentParticipants / maxParticipants;
}

// ─── 물물교환 모델 ───────────────────────────────────────────────
class ExchangePost {
  final String id;
  final String title;
  final String description;
  final String offerItem;
  final String wantItem;
  final String imageUrl;
  final String authorName;
  final String location;
  final int walkMinutes;
  final DateTime createdAt;
  final ExchangeStatus status;

  ExchangePost({
    required this.id,
    required this.title,
    required this.description,
    required this.offerItem,
    required this.wantItem,
    required this.imageUrl,
    required this.authorName,
    required this.location,
    required this.walkMinutes,
    required this.createdAt,
    required this.status,
  });
}

enum ExchangeStatus { open, chatting, done }

// ─── 원룸 리뷰 모델 ──────────────────────────────────────────────
class RoomReview {
  final String id;
  final String buildingName;
  final String address;
  final double rating;
  final String summaryText;
  final List<ReviewTag> tags;
  final int reviewCount;
  final bool isUnlocked;
  final int unlockPoints;
  final String authorName;
  final DateTime createdAt;

  RoomReview({
    required this.id,
    required this.buildingName,
    required this.address,
    required this.rating,
    required this.summaryText,
    required this.tags,
    required this.reviewCount,
    required this.isUnlocked,
    required this.unlockPoints,
    required this.authorName,
    required this.createdAt,
  });
}

class ReviewTag {
  final String label;
  final bool isPositive;

  ReviewTag({required this.label, required this.isPositive});
}

// ─── 모임 모델 ───────────────────────────────────────────────────
class GatherPost {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String place;
  final DateTime meetTime;
  final int maxMembers;
  final int currentMembers;
  final String authorName;
  final GenderFilter genderFilter;
  final AgeFilter ageFilter;
  final DateTime createdAt;

  GatherPost({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.place,
    required this.meetTime,
    required this.maxMembers,
    required this.currentMembers,
    required this.authorName,
    required this.genderFilter,
    required this.ageFilter,
    required this.createdAt,
  });

  bool get isFull => currentMembers >= maxMembers;
}

enum GenderFilter { any, maleOnly, femaleOnly }

enum AgeFilter { any, twenties, thirties, mixed }

// ─── 채팅 모델 ───────────────────────────────────────────────────
class ChatRoom {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String avatarEmoji;
  final ChatRoomType type;
  final List<String> members;

  ChatRoom({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.avatarEmoji,
    required this.type,
    required this.members,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatRoom(
      id: documentId,
      title: data['title'] ?? '이름 없는 채팅방',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      avatarEmoji: data['avatarEmoji'] ?? '💬',
      type: ChatRoomType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChatRoomType.gather,
      ),
      members: List<String>.from(data['members'] ?? []),
    );
  }
}

enum ChatRoomType { groupBuy, exchange, gather }

// ─── 알림 모델 ───────────────────────────────────────────────────
enum NotificationType { groupBuy, exchange, gather, review, system }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
