import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_store.dart';
import '../widgets/common_widgets.dart';
import 'group_buy_screen.dart';
import 'exchange_screen.dart';
import 'review_screen.dart';
import 'gather_screen.dart';
import 'chat_list_screen.dart';
import 'notification_screen.dart';
import 'signup_screen.dart';
import 'mypage_screen.dart';
import '../utils/in_app_notification_service.dart';
import 'dart:async';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, String> _lastMessageIds = {};

  final List<Widget> _screens = const [
    _HomeTab(),
    GroupBuyScreen(),
    ExchangeScreen(),
    ReviewScreen(),
    GatherScreen(),
    ChatListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToMessages();
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void _subscribeToMessages() {
    final store = UserStoreProvider.of(context);
    final uid = store.uid;
    if (uid.isEmpty) return;

    FirebaseFirestore.instance
        .collection('chatRooms')
        .where('members', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final roomId = doc.id;
        final roomData = doc.data();
        final roomTitle = roomData['title'] as String? ?? '';
        final roomType = roomData['type'] as String? ?? '';
        final roomEmoji = switch (roomType) {
          'groupBuy' => '🛒',
          'exchange' => '🔄',
          'gather' => '👥',
          _ => '💬',
        };

        final sub = FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(roomId)
            .collection('messages')
            .orderBy('time', descending: true)
            .limit(1)
            .snapshots()
            .listen((msgSnap) {
          if (msgSnap.docs.isEmpty) return;
          final msgDoc = msgSnap.docs.first;
          final msgId = msgDoc.id; // ← 추가

          // 이미 본 메시지면 무시
          if (_lastMessageIds[roomId] == msgId) return; // ← 추가
          _lastMessageIds[roomId] = msgId; // ← 추가

          final msg = msgDoc.data(); // ← msgSnap.docs.first.data() 에서 변경
          final senderUid = msg['senderUid'] as String? ?? '';
          final senderName = msg['senderName'] as String? ?? '';
          final text = msg['text'] as String? ?? '';
          final time = (msg['time'] as Timestamp?)?.toDate();

          if (senderUid == uid) return;
          if (senderName == 'system') return;
          if (store.currentChatRoomId == roomId) return;
          if (time == null) return;
          if (DateTime.now().difference(time).inSeconds > 3) return;

          if (!mounted) return;
          InAppNotificationService.show(
            context: context,
            title: roomTitle,
            message: '$senderName: $text',
            roomId: roomId,
            emoji: roomEmoji,
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    room: ChatRoom.fromMap(roomData, roomId),
                  ),
                ),
              );
            },
          );
        });
        _subscriptions.add(sub);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: '공동구매',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: '물물교환',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apartment_outlined),
              activeIcon: Icon(Icons.apartment),
              label: '원룸리뷰',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: '모임',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: '채팅',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 홈 탭 ───────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Future<void> _showResetDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗑️ 데이터 초기화'),
        content: const Text(
          '모든 게시글과 채팅방을 삭제합니다.\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('전부 삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // posts 전체 삭제
      final posts = await firestore.collection('posts').get();
      for (final doc in posts.docs) {
        await doc.reference.delete();
      }

      // chatRooms 전체 삭제 (messages 서브컬렉션 포함)
      final chatRooms = await firestore.collection('chatRooms').get();
      for (final room in chatRooms.docs) {
        final messages = await room.reference.collection('messages').get();
        for (final msg in messages.docs) {
          await msg.reference.delete();
        }
        await room.reference.delete();
      }

      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 모든 테스트 데이터가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationSheet(BuildContext context) {
    final store = UserStoreProvider.of(context);
    final parts = store.location.split(' ').where((p) => p.isNotEmpty).toList();
    int scope = store.locationScope == 0 ? parts.length : store.locationScope;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('내 동네 범위 설정',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('선택한 범위 내 이웃의 글을 볼 수 있어요',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),

                // 현재 주소 표시
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(store.location,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('범위 선택',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),

                // 범위 칩 (시도 / 구 / 동)
                if (parts.isEmpty)
                  const Text('주소 정보가 없어요',
                      style: TextStyle(color: AppColors.textHint))
                else
                  Row(
                    children: List.generate(parts.length, (i) {
                      final level = i + 1; // 1=시도, 2=구, 3=동
                      final isSelected = scope == level;
                      final label = parts[i];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => scope = level),
                          child: Container(
                            margin: EdgeInsets.only(
                                right: i < parts.length - 1 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    )),
                                const SizedBox(height: 2),
                                Text(
                                  i == 0
                                      ? '시/도 전체'
                                      : i == 1
                                          ? '구/군 전체'
                                          : '동네만',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      store.setLocationScope(scope);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('적용하기',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = UserStoreProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── 앱바 ──
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.surface,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 20,
                  right: 20,
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _showLocationSheet(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '📍 ${store.filterLocation}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down,
                                  size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '안녕하세요, ${store.name}님!',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(UserStoreProvider.of(context).uid)
                          .collection('items')
                          .where('isRead', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snap) {
                        final hasUnread = (snap.data?.docs.length ?? 0) > 0;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                );
                              },
                              color: AppColors.textPrimary,
                            ),
                            if (hasUnread)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: () => _showResetDialog(context),
                      color: Colors.red.shade300,
                      tooltip: '테스트 데이터 초기화 (개발용)',
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              builder: (_) => const MyPageScreen()),
                        );
                      },
                      color: AppColors.textSecondary,
                      tooltip: '마이페이지',
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true)
                            .pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        );
                      },
                      color: AppColors.textSecondary,
                      tooltip: '로그아웃',
                    ),
                  ],
                ),
              ),
            ),
            expandedHeight: 70,
            toolbarHeight: 70,
          ),

          // ── 배너 ──
          const SliverToBoxAdapter(child: _HomeBanner()),

          // ── 기능 바로가기 ──
          SliverToBoxAdapter(child: _FeatureGrid()),

          // ── 최근 공동구매 ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '🛒 마감 임박 공동구매',
              actionLabel: '더보기',
              onAction: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const GroupBuyScreen()),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _RecentGroupBuy()),

          // ── 오늘의 모임 ──
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '🎯 오늘의 모임',
              actionLabel: '더보기',
              onAction: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const GatherScreen()),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _TodayGather()),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── 홈 배너 ─────────────────────────────────────────────────────
class _HomeBanner extends StatelessWidget {
  const _HomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC1D591), Color(0xFFD4E8A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '같이삽시다 🏠',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '더 가볍게 사고(Buy)\n더 즐겁게 사는(Live) 법',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                const _PointBadge(),
                const SizedBox(height: 8), // ← 추가
                const _AdBanner(),
              ],
            ),
          ),
          const Text('🏘️', style: TextStyle(fontSize: 60)),
        ],
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  const _AdBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('🎁 광고 포인트',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text('광고 서비스 준비 중이에요!\n곧 광고를 보고 포인트를 얻을 수 있어요 😊'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.play_circle_outline, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              '광고 보고 포인트 받기',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '+10P',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.reviewColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointBadge extends StatelessWidget {
  const _PointBadge();

  @override
  Widget build(BuildContext context) {
    final store = UserStoreProvider.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '보유 포인트: ${store.points}P',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 기능 바로가기 그리드 ─────────────────────────────────────────
class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      _Feature('공동구매', '🛒', AppColors.buyColor, AppColors.buyColorLight, const GroupBuyScreen()),
      _Feature('물물교환', '🔄', AppColors.exchangeColor, AppColors.exchangeColorLight, const ExchangeScreen()),
      _Feature('원룸리뷰', '🏠', AppColors.reviewColor, AppColors.reviewColorLight, const ReviewScreen()),
      _Feature('모임 찾기', '👥', AppColors.gatherColor, AppColors.gatherColorLight, const GatherScreen()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: features.map((f) {
          return Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => f.screen),
              ),
              child: Container(
                margin: EdgeInsets.only(
                  right: features.indexOf(f) < 3 ? 10 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: f.lightColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(f.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(
                      f.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: f.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Feature {
  final String name;
  final String emoji;
  final Color color;
  final Color lightColor;
  final Widget screen;
  _Feature(this.name, this.emoji, this.color, this.lightColor, this.screen);
}

// ─── 마감 임박 공동구매 ───────────────────────────────────────────
class _RecentGroupBuy extends StatelessWidget {
  const _RecentGroupBuy();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filterLoc = UserStoreProvider.of(context).filterLocation;

    return SizedBox(
      height: 160,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('type', isEqualTo: 'groupBuy')
            .where('isFull', isEqualTo: false)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          // 위치 범위 필터
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final loc = (data['location'] as String? ?? '');
            return loc.startsWith(filterLoc);
          }).toList();

          // 마감기한 지난 글 제거
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final deadline = (data['deadline'] as Timestamp?)?.toDate();
            if (deadline == null) return true;
            return deadline.isAfter(now);
          }).toList();

          // 정렬: 1순위 1자리 남은 것, 2순위 오래된 순
          docs.sort((a, b) {
            final aD = a.data() as Map<String, dynamic>;
            final bD = b.data() as Map<String, dynamic>;
            final aCurrent = aD['currentParticipants'] ?? 0;
            final aMax = aD['maxParticipants'] ?? 1;
            final bCurrent = bD['currentParticipants'] ?? 0;
            final bMax = bD['maxParticipants'] ?? 1;
            final aOnLeft = aMax - aCurrent == 1;
            final bOnLeft = bMax - bCurrent == 1;
            if (aOnLeft && !bOnLeft) return -1;
            if (!aOnLeft && bOnLeft) return 1;
            final aTime =
                (aD['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime =
                (bD['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return aTime.compareTo(bTime);
          });

          final topDocs = docs.take(5).toList();

          if (topDocs.isEmpty) {
            return const Center(
              child: Text('마감 임박 공동구매가 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: topDocs.length,
            itemBuilder: (context, i) {
              final data = topDocs[i].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const GroupBuyScreen()),
                ),
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TagBadge(
                              label: data['category'] ?? '기타',
                              color: AppColors.buyColor),
                          const SizedBox(width: 6),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1인 ${_formatPrice(data['unitPrice'] ?? 0)}원',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${data['currentParticipants']}/${data['maxParticipants']}명',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

// ─── 오늘의 모임 ──────────────────────────────────────────────────
class _TodayGather extends StatelessWidget {
  const _TodayGather();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final filterLoc = UserStoreProvider.of(context).filterLocation;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('type', isEqualTo: 'gathering')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // 마감된 모임 제외 + 위치 필터 + 정렬
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final meetTime = (data['meetTime'] as Timestamp).toDate();
            final current = data['currentMembers'] ?? 0;
            final max = data['maxMembers'] ?? 1;
            final loc = (data['location'] as String? ?? '');
            return meetTime.isAfter(now) &&
                meetTime.isBefore(endOfDay) &&
                current < max &&
                loc.startsWith(filterLoc);
          }).toList()
            ..sort((a, b) {
              final aTime =
                  ((a.data() as Map)['meetTime'] as Timestamp).toDate();
              final bTime =
                  ((b.data() as Map)['meetTime'] as Timestamp).toDate();
              return aTime.compareTo(bTime);
            });

          if (docs.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.gatherColor.withOpacity(0.3)),
              ),
              child: const Center(
                child: Text('오늘 예정된 모임이 없어요',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }

          return Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final meetTime = (data['meetTime'] as Timestamp).toDate();
              final remaining = meetTime.difference(DateTime.now());
              final label = remaining.inHours > 0
                  ? '${remaining.inHours}시간 후'
                  : remaining.inMinutes > 0
                      ? '${remaining.inMinutes}분 후'
                      : '진행 중';

              return GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const GatherScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.gatherColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(data['emoji'] ?? '👥',
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '📍 ${data['place'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gatherColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gatherColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['currentMembers']}/${data['maxMembers']}명',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
