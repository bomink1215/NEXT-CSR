import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/mock_data.dart';
import '../models/user_store.dart';
import '../services/location_service.dart';
import '../widgets/common_widgets.dart';
import 'group_buy_screen.dart';
import 'exchange_screen.dart';
import 'review_screen.dart';
import 'gather_screen.dart';
import 'chat_list_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    GroupBuyScreen(),
    ExchangeScreen(),
    GatherScreen(),
    ChatListScreen(),
  ];

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
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  void _showLocationSheet(BuildContext context) {
    final store = UserStoreProvider.of(context);
    final controller = TextEditingController(text: store.location);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(
        controller: controller,
        onConfirm: (newLocation) {
          store.updateLocation(newLocation);
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
                    // ✅ 동네 탭 → 수정 바텀시트
                    GestureDetector(
                      onTap: () => _showLocationSheet(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '📍 ${store.location}',
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
                    Stack(
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

// ─── 동네 수정 바텀시트 (GPS 포함) ───────────────────────────────
class _LocationSheet extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onConfirm;

  const _LocationSheet({required this.controller, required this.onConfirm});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  bool _isLocating = false;

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      final district = await LocationService.getCurrentDistrict();
      setState(() => widget.controller.text = district);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
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
            const Text(
              '내 동네 변경',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              '변경하면 근처 이웃 매칭 기준이 바뀌어요',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // 입력 + GPS 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: '동네 이름 입력',
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ✅ GPS 버튼
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLocating ? null : _detectLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLocating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.my_location,
                                  color: Colors.white, size: 20),
                              SizedBox(height: 2),
                              Text(
                                'GPS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final newLocation = widget.controller.text.trim();
                  if (newLocation.isNotEmpty) {
                    widget.onConfirm(newLocation);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '변경하기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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
          colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
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
                _PointBadge(),
              ],
            ),
          ),
          const Text('🏘️', style: TextStyle(fontSize: 60)),
        ],
      ),
    );
  }
}

class _PointBadge extends StatelessWidget {
  const _PointBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            '보유 포인트: 120P',
            style: TextStyle(
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
      _Feature('공동구매', '🛒', AppColors.buyColor, const GroupBuyScreen()),
      _Feature('물물교환', '🔄', AppColors.exchangeColor, const ExchangeScreen()),
      _Feature('원룸리뷰', '🏠', AppColors.reviewColor, const ReviewScreen()),
      _Feature('모임 찾기', '👥', AppColors.gatherColor, const GatherScreen()),
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
                  color: f.color.withOpacity(0.08),
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
  final Widget screen;
  _Feature(this.name, this.emoji, this.color, this.screen);
}

// ─── 마감 임박 공동구매 ───────────────────────────────────────────
class _RecentGroupBuy extends StatelessWidget {
  const _RecentGroupBuy();

  @override
  Widget build(BuildContext context) {
    final posts = MockData.groupBuyPosts.where((p) => !p.isFull).take(3).toList();
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: posts.length,
        itemBuilder: (context, i) {
          final p = posts[i];
          return GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const GroupBuyScreen()),
            ),
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TagBadge(label: p.category, color: AppColors.buyColor),
                      const SizedBox(width: 6),
                      WalkBadge(minutes: p.walkMinutes),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.title,
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
                        '1인 ${_formatPrice(p.unitPrice)}원',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${p.currentParticipants}/${p.maxParticipants}명',
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
      ),
    );
  }

  String _formatPrice(int price) =>
      price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

// ─── 오늘의 모임 ──────────────────────────────────────────────────
class _TodayGather extends StatelessWidget {
  const _TodayGather();

  @override
  Widget build(BuildContext context) {
    final posts = MockData.gatherPosts.where((p) => !p.isFull).take(2).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: posts.map((p) {
          final remaining = p.meetTime.difference(DateTime.now());
          final label = remaining.inHours > 0
              ? '${remaining.inHours}시간 후'
              : '${remaining.inMinutes}분 후';
          return GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const GatherScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.gatherColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '📍 ${p.place}',
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
                        '${p.currentMembers}/${p.maxMembers}명',
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
      ),
    );
  }
}
