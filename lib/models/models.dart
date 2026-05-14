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
  final String authorUid;
  final DateTime createdAt;
  final bool isDelivery;
  final DateTime? deadline;
  final String meetingPlace;

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
    this.authorUid = '',
    required this.createdAt,
    required this.isDelivery,
    this.meetingPlace = '',
    this.deadline,
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
  final String authorUid;
  final String location;
  final int walkMinutes;
  final DateTime createdAt;
  final ExchangeStatus status;
  final String meetingPlace;

  ExchangePost({
    required this.id,
    required this.title,
    required this.description,
    required this.offerItem,
    required this.wantItem,
    required this.imageUrl,
    required this.authorName,
    this.authorUid = '',
    required this.location,
    required this.walkMinutes,
    required this.createdAt,
    required this.status,
    this.meetingPlace = '',
  });
  factory ExchangePost.fromMap(Map<String, dynamic> data, String documentId) {
    return ExchangePost(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      offerItem: data['offerItem'] ?? '',
      wantItem: data['wantItem'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      authorName: data['authorName'] ?? '익명',
      authorUid: data['authorUid'] ?? '',
      location: data['location'] ?? '',
      walkMinutes: data['walkMinutes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ExchangeStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'open'),
        orElse: () => ExchangeStatus.open,
      ),
      meetingPlace: data['meetingPlace'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'offerItem': offerItem,
      'wantItem': wantItem,
      'imageUrl': imageUrl,
      'authorName': authorName,
      'location': location,
      'walkMinutes': walkMinutes,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status.name,
      'meetingPlace': meetingPlace,
    };
  }
}

enum ExchangeStatus { open, chatting, done }

// ─── 원룸 리뷰 모델 ──────────────────────────────────────────────
class RoomReview {
  final String id;
  final String buildingName;
  final String address;
  final String location; // 시/구/동 필터링용 (예: 서울특별시 성북구 안암동)
  final double rating;
  final String summaryText;
  final List<ReviewTag> tags;
  final int reviewCount;
  final bool isUnlocked;
  final int unlockPoints;
  final String authorName;
  final String authorUid;
  final DateTime createdAt;

  RoomReview({
    required this.id,
    required this.buildingName,
    required this.address,
    this.location = '',
    required this.rating,
    required this.summaryText,
    required this.tags,
    required this.reviewCount,
    required this.isUnlocked,
    required this.unlockPoints,
    required this.authorName,
    this.authorUid = '',
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
  final String authorUid;
  final GenderFilter genderFilter;
  final AgeFilter ageFilter;
  final String category;
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
    this.authorUid = '',
    required this.genderFilter,
    required this.ageFilter,
    this.category = '기타',
    required this.createdAt,
  });

  bool get isFull => currentMembers >= maxMembers;

  factory GatherPost.fromMap(String id, Map<String, dynamic> data) {
    return GatherPost(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '👥',
      place: data['place'] ?? '',
      // 1. Timestamp null 체크: 데이터가 아직 서버에 기록 중일 때 null일 수 있음
      meetTime: data['meetTime'] != null
          ? (data['meetTime'] as Timestamp).toDate()
          : DateTime.now(),
      maxMembers: data['maxMembers'] ?? 0,
      currentMembers: data['currentMembers'] ?? 0,
      authorName: data['authorName'] ?? '',
      authorUid: data['authorUid'] ?? '',
      // 2. Enum 매핑 시 예외 처리: 데이터베이스에 엉뚱한 문자열이 있을 경우 대비
      genderFilter: GenderFilter.values.firstWhere(
        (e) => e.name == data['genderFilter'],
        orElse: () => GenderFilter.any,
      ),
      ageFilter: AgeFilter.values.firstWhere(
        (e) => e.name == data['ageFilter'],
        orElse: () => AgeFilter.any,
      ),
      category: data['category'] ?? '기타',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

enum GenderFilter { any, maleOnly, femaleOnly }

enum AgeFilter { any, teens, twenties, thirties }

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
  final String authorUid;
  final Map<String, DateTime> lastRead;
  final Map<String, DateTime> joinedAt;
  final Map<String, int> unreadCounts; // uid → 미읽은 메시지 수

  ChatRoom({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.avatarEmoji,
    required this.type,
    required this.members,
    this.authorUid = '',
    this.lastRead = const {},
    this.joinedAt = const {},
    this.unreadCounts = const {},
  });

  factory ChatRoom.fromMap(Map<String, dynamic> data, String documentId) {
    final rawLastRead = data['lastRead'] as Map<String, dynamic>? ?? {};
    final lastReadMap = rawLastRead.map(
      (k, v) => MapEntry(k, (v as Timestamp).toDate()),
    );

    final rawJoinedAt = data['joinedAt'] as Map<String, dynamic>? ?? {};
    final joinedAtMap = rawJoinedAt.map(
      (k, v) => MapEntry(k, (v as Timestamp).toDate()),
    );

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
      authorUid: data['authorUid'] ?? '',
      lastRead: lastReadMap,
      joinedAt: joinedAtMap,
      unreadCounts: Map<String, int>.from(
        (data['unreadCounts'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      ),
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
