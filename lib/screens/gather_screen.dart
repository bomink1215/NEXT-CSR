import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gatchi_sapsida/models/user_store.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';
import './chat_list_screen.dart';
import '../utils/notification_service.dart';
import '../utils/location_service.dart';

class GatherScreen extends StatefulWidget {
  final String? initialPostId;
  const GatherScreen({super.key, this.initialPostId});

  @override
  State<GatherScreen> createState() => _GatherScreenState();
}

// 카테고리 상수 (gather_screen 전체에서 공유)
const _kGatherCategories = [
  {'emoji': '🍜', 'label': '혼밥 메이트'},
  {'emoji': '🚶', 'label': '산책'},
  {'emoji': '☕', 'label': '카페'},
  {'emoji': '🎮', 'label': '게임'},
  {'emoji': '📚', 'label': '스터디'},
  {'emoji': '🏃', 'label': '운동'},
  {'emoji': '📌', 'label': '기타'},
];

class _GatherScreenState extends State<GatherScreen> {
  String? _selectedCategory; // null = 전체

  @override
  void initState() {
    super.initState();
    if (widget.initialPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final snap = await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.initialPostId)
            .get();
        if (!snap.exists || !mounted) return;
        final post =
            GatherPost.fromMap(snap.id, snap.data() as Map<String, dynamic>);
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _GatherDetail(post: post),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterLoc = UserStoreProvider.of(context).filterLocation;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('모임 찾기')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'gatherFab',
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.gatherColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('모임 만들기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('type', isEqualTo: 'gathering')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
                child: Text('데이터를 불러오지 못했습니다.')); // [cite: 1305, 2119]
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data!.docs;
          final userStore = UserStoreProvider.of(context);
          final userGender = userStore.gender;
          final userAgeCategory = userStore.ageCategory;

          // 사용자 성별/나이대/위치에 맞는 모임만 표시
          final profileDocs = allDocs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;

            final meetTime = (d['meetTime'] as Timestamp?)?.toDate();
            if (meetTime != null && meetTime.isBefore(DateTime.now()))
              return false;

            // 위치 필터 (이전 글 하위 호환 포함)
            final loc = (d['location'] as String? ?? '');
            if (loc.isEmpty || filterLoc.isEmpty) return true;  // location 없으면 표시
            if (!loc.startsWith(filterLoc)) {
              // 하위 호환: 이전 글은 "안암동", "성북구 안암동" 등 짧은 형식으로 저장됨
              final matches = loc.split(' ')
                  .where((p) => p.length >= 2)
                  .any((p) => filterLoc.contains(p));
              if (!matches) return false;
            }

            final gf = d['genderFilter'] ?? 'any';
            final af = d['ageFilter'] ?? 'any';
            if (gf == 'maleOnly' && userGender != '남성') return false;
            if (gf == 'femaleOnly' && userGender != '여성') return false;

            if (af == 'teens' && userAgeCategory != 'teens') return false;
            if (af == 'twenties' && userAgeCategory != 'twenties') return false;
            if (af == 'thirties' && userAgeCategory != 'thirties') return false;
            return true;
          }).toList();

          final uid = userStore.uid;
          final docs = (_selectedCategory == null
              ? profileDocs
              : profileDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['category'] ?? '기타') == _selectedCategory;
                }).toList())
            ..sort((a, b) {
              final aD = a.data() as Map;
              final bD = b.data() as Map;
              // 🔥 상단 노출 우선 ← 추가
              final now = DateTime.now();
              final aPinned = (aD['isPinned'] == true) &&
                  (aD['pinnedUntil'] as Timestamp?)?.toDate().isAfter(now) == true;
              final bPinned = (bD['isPinned'] == true) &&
                  (bD['pinnedUntil'] as Timestamp?)?.toDate().isAfter(now) == true;
              if (aPinned && !bPinned) return -1;
              if (!aPinned && bPinned) return 1;
              
              final aFull =
                  (aD['currentMembers'] ?? 0) >= (aD['maxMembers'] ?? 1);
              final bFull =
                  (bD['currentMembers'] ?? 0) >= (bD['maxMembers'] ?? 1);
              if (!aFull && bFull) return -1;
              if (aFull && !bFull) return 1;
              final aIsMe = aD['authorUid'] == uid;
              final bIsMe = bD['authorUid'] == uid;
              if (aIsMe && !bIsMe) return -1;
              if (!aIsMe && bIsMe) return 1;
              return 0;
            });

          if (allDocs.isEmpty) {
            return const Center(
                child: Text('주변에 열린 모임이 없어요.\n첫 모임을 만들어보세요! 👥',
                    textAlign: TextAlign.center));
          }
          return CustomScrollView(
            slivers: [
              // 1. 상단 고정 영역 (빠른 모임 찾기)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('빠른 모임 찾기',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _QuickCategory(
                              '🔍',
                              '전체',
                              isSelected: _selectedCategory == null,
                              onTap: () =>
                                  setState(() => _selectedCategory = null),
                            ),
                            ..._kGatherCategories.map((c) => _QuickCategory(
                                  c['emoji']!,
                                  c['label']!,
                                  isSelected: _selectedCategory == c['label'],
                                  onTap: () => setState(() {
                                    _selectedCategory =
                                        _selectedCategory == c['label']
                                            ? null
                                            : c['label'];
                                  }),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                          _selectedCategory == null
                              ? '지금 모집 중'
                              : '"$_selectedCategory" 모임',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // 2. 데이터가 없을 때 표시할 화면
              if (docs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                      child: Text(
                    _selectedCategory == null
                        ? '주변에 열린 모임이 없어요.\n첫 모임을 만들어보세요! 👥'
                        : '"$_selectedCategory" 카테고리의 모임이 없어요.',
                    textAlign: TextAlign.center,
                  )),
                )
              else
                // 3. 실시간 게시글 목록 (ListView.separated와 유사한 SliverList)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // 구분선 처리 로직 (ListView.separated의 separatorBuilder 역할)
                        if (index.isOdd) return const SizedBox(height: 12);

                        final realIndex = index ~/ 2;
                        final data =
                            docs[realIndex].data() as Map<String, dynamic>;

                        // GatherPost 모델 변환
                        final post =
                            GatherPost.fromMap(docs[realIndex].id, data);
                        return _GatherCard(post: post);
                      },
                      childCount: docs.length * 2 - 1, // 아이템 수 + 구분선 수
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // 하단 여백
            ],
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateGatherSheet(),
    );
  }
}

class _QuickCategory extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickCategory(this.emoji, this.label,
      {required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gatherColor.withOpacity(0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gatherColor : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? AppColors.gatherColor
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _GatherCard extends StatefulWidget {
  final GatherPost post;
  const _GatherCard({required this.post});

  @override
  State<_GatherCard> createState() => _GatherCardState();
}

class _GatherCardState extends State<_GatherCard> {
  int? _walkMinutes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calcWalkMinutes();
  }

  Future<void> _calcWalkMinutes() async {
    final store = UserStoreProvider.of(context);
    if (store.homeAddress.isEmpty || widget.post.place.isEmpty) return;
    final minutes = await LocationService.getWalkMinutesBetween(
      store.homeAddress,
      widget.post.place,
    );
    if (mounted) setState(() => _walkMinutes = minutes);
  }

  String _genderLabel(GenderFilter f) {
    switch (f) {
      case GenderFilter.any:
        return '성별 무관';
      case GenderFilter.maleOnly:
        return '남성만';
      case GenderFilter.femaleOnly:
        return '여성만';
    }
  }

  String _ageLabel(AgeFilter f) {
    switch (f) {
      case AgeFilter.any:
        return '연령 무관';
      case AgeFilter.teens:
        return '10대';
      case AgeFilter.twenties:
        return '20대';
      case AgeFilter.thirties:
        return '30대';
    }
  }

  String _dateLabel(DateTime t) {
    return '${t.month}/${t.day} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final store = UserStoreProvider.of(context);
    final isAuthor = store.uid.isNotEmpty && store.uid == widget.post.authorUid;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAuthor
              ? AppColors.gatherColor.withOpacity(0.07)
              : widget.post.isFull
                  ? AppColors.textHint.withOpacity(0.07)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAuthor
                ? AppColors.gatherColor.withOpacity(0.5)
                : widget.post.isFull
                    ? AppColors.textHint.withOpacity(0.25)
                    : AppColors.gatherColor.withOpacity(0.3),
            width: (isAuthor || !widget.post.isFull) ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: widget.post.isFull
                    ? AppColors.cardBg
                    : AppColors.gatherColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(widget.post.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post.isPinned &&
                      widget.post.pinnedUntil != null &&
                      widget.post.pinnedUntil!.isAfter(DateTime.now())) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gatherColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('🔥', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text('상단 노출 중',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gatherColor)),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.post.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.post.isFull)
                        const TagBadge(label: '마감', color: AppColors.error),
                      if (_walkMinutes != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: WalkBadge(minutes: _walkMinutes!),
                        )
                      else if (widget.post.place.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: const WalkBadge(minutes: 5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.post.description,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Text(
                        widget.post.authorName,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.post.place,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      TagBadge(
                          label: _dateLabel(widget.post.meetTime),
                          color: AppColors.gatherColor),
                      TagBadge(
                          label: _genderLabel(widget.post.genderFilter),
                          color: AppColors.textSecondary),
                      TagBadge(
                          label: _ageLabel(widget.post.ageFilter),
                          color: AppColors.textSecondary),
                      TagBadge(
                        label:
                            '${widget.post.currentMembers}/${widget.post.maxMembers}명',
                        color: widget.post.isFull
                            ? AppColors.error
                            : AppColors.gatherColor,
                      ),
                    ],
                  ),
                  if (isAuthor) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showPinDialog(context),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('🔥 상단노출',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gatherColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () => _showEditSheet(context),
                          style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('수정',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gatherColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () => _deletePost(context),
                          style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('삭제',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GatherDetail(post: widget.post),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditGatherSheet(post: widget.post),
    );
  }

  Future<void> _showPinDialog(BuildContext context) async {
    final store = UserStoreProvider.of(context);
    await showDialog(
      context: context,
      builder: (ctx) => PinDialog(
        currentPoints: store.points,
        onConfirm: (cost, hours) async {
          final success = await store.deductPoints(cost);
          if (!success) {
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('포인트가 부족해요!')),
              );
            return;
          }
          final pinnedUntil = DateTime.now().add(Duration(hours: hours));
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.post.id)
              .update({
            'isPinned': true,
            'pinnedUntil': Timestamp.fromDate(pinnedUntil),
          });
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('🔥 ${hours}시간 상단 노출이 시작됐어요!')),
            );
        },
      ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('모임 삭제'),
            content: const Text('정말 이 모임을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('삭제',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .delete();
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('모임이 삭제되었습니다.')));
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }
}

class _GatherDetail extends StatelessWidget {
  final GatherPost post;

  const _GatherDetail({required this.post});

  String _genderLabel(GenderFilter f) {
    switch (f) {
      case GenderFilter.any:
        return '성별 무관';
      case GenderFilter.maleOnly:
        return '남성만';
      case GenderFilter.femaleOnly:
        return '여성만';
    }
  }

  String _ageLabel(AgeFilter f) {
    switch (f) {
      case AgeFilter.any:
        return '연령 무관';
      case AgeFilter.teens:
        return '10대';
      case AgeFilter.twenties:
        return '20대';
      case AgeFilter.thirties:
        return '30대';
    }
  }

  void _onJoinPressed(BuildContext context, GatherPost post) {
    // 이미 참여 중인지, 정원이 찼는지 1차 체크 후 함수 호출
    if (post.isFull) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미 마감된 모임입니다.')));
      return;
    }

    // 참여 로직 실행
    _joinGathering(context, post);
  }

  Future<void> _joinGathering(BuildContext context, GatherPost post) async {
    final userStore = UserStoreProvider.of(context);
    final firestore = FirebaseFirestore.instance;

    // ── 중복 참여 사전 체크 ──
    final postSnap = await firestore.collection('posts').doc(post.id).get();
    if (postSnap.exists) {
      final existingMembers =
          List<dynamic>.from(postSnap.data()?['members'] ?? []);
      if (existingMembers.contains(userStore.uid)) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content:
                const Text('이미 참여 중인 모임입니다.', style: TextStyle(fontSize: 15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인',
                    style: TextStyle(color: AppColors.gatherColor)),
              ),
            ],
          ),
        );
        return;
      }
    }

    try {
      await firestore.runTransaction((transaction) async {
        final postRef = firestore.collection('posts').doc(post.id);
        final snapshot = await transaction.get(postRef);

        if (!snapshot.exists) return;

        int current = snapshot.data()?['currentMembers'] ?? 0;
        int max = snapshot.data()?['maxMembers'] ?? 0;

        if (current >= max) throw Exception('이미 정원이 마감되었습니다.');

        // 1. 게시글 인원 업데이트
        transaction.update(postRef, {
          'currentMembers': current + 1,
          'members': FieldValue.arrayUnion([userStore.uid]),
        });

        // 2. 그룹 채팅방 생성/업데이트
        final chatRef = firestore.collection('chatRooms').doc(post.id);
        transaction.set(
            chatRef,
            {
              'postId': post.id,
              'title': post.title,
              'members': FieldValue.arrayUnion([userStore.uid]),
              'lastMessage': '${userStore.name}님이 참여하셨습니다.',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'type': 'gather',
              'avatarEmoji': post.emoji,
              'authorUid': post.authorUid,
              'unreadCount': 0,
              'joinedAt': {userStore.uid: FieldValue.serverTimestamp()},
            },
            SetOptions(merge: true));

        // 3. 시스템 메시지
        transaction.set(chatRef.collection('messages').doc(), {
          'senderName': 'system',
          'text': '${userStore.name}님이 참여하셨습니다.',
          'time': FieldValue.serverTimestamp(),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 참여 완료! 채팅방으로 이동합니다.')));

        // 모임 참여 알림 ㅡ 글 작성자한테 알림
        await NotificationService.send(
          toUid: post.authorUid,
          type: 'gather',
          title: '👥 모임에 새 참여자가 왔어요',
          body: '${userStore.name}님이 "${post.title}"에 참여했어요.',
          postId: post.id,
        );

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                room: ChatRoom(
                  id: post.id,
                  title: post.title,
                  lastMessage: '${userStore.name}님이 참여하셨습니다.',
                  lastMessageTime: DateTime.now(),
                  unreadCount: 0,
                  avatarEmoji: post.emoji,
                  type: ChatRoomType.gather,
                  members: [],
                  authorUid: post.authorUid,
                ),
              ),
            ));
      }
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(msg, style: const TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인',
                  style: TextStyle(color: AppColors.gatherColor)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetStr =
        '${post.meetTime.month}/${post.meetTime.day} ${post.meetTime.hour}:${post.meetTime.minute.toString().padLeft(2, '0')}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(post.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(post.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.description,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                  const SizedBox(height: 16),
                  // 모임 정보
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gatherColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(Icons.location_on_outlined, '장소', post.place),
                        const Divider(color: AppColors.divider, height: 16),
                        _InfoRow(Icons.access_time, '시간', meetStr),
                        const Divider(color: AppColors.divider, height: 16),
                        _InfoRow(Icons.people_outline, '인원',
                            '${post.currentMembers}/${post.maxMembers}명'),
                        const Divider(color: AppColors.divider, height: 16),
                        _InfoRow(Icons.person_outline, '성별',
                            _genderLabel(post.genderFilter)),
                        const Divider(color: AppColors.divider, height: 16),
                        _InfoRow(Icons.cake_outlined, '연령',
                            _ageLabel(post.ageFilter)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Builder(builder: (ctx) {
                    final store = UserStoreProvider.of(ctx);
                    final isAuthor =
                        store.uid.isNotEmpty && store.uid == post.authorUid;
                    // 내가 만든 모임
                    if (isAuthor) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.gatherColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('내가 만든 모임',
                              style: TextStyle(
                                  color: AppColors.gatherColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                      );
                    }
                    // 마감된 모임
                    if (post.isFull) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('마감된 모임입니다',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 15)),
                        ),
                      );
                    }
                    // 참여 가능
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _onJoinPressed(ctx, post),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gatherColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.group_add, color: Colors.white),
                        label: const Text('모임 참여하기',
                            style:
                                TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _InfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gatherColor),
        const SizedBox(width: 8),
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CreateGatherSheet extends StatefulWidget {
  const _CreateGatherSheet();

  @override
  State<_CreateGatherSheet> createState() => _CreateGatherSheetState();
}

class _CreateGatherSheetState extends State<_CreateGatherSheet> {
  bool _genderOnly = false;
  bool _ageOnly = false;
  int _maxMembers = 2;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _placeController = TextEditingController();

  String _selectedEmoji = '👥';
  String _selectedCategory = '기타';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  bool _isUploading = false;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isAfter(now) ? _selectedDateTime : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: _selectedDateTime.hour, minute: _selectedDateTime.minute),
    );
    if (time == null || !mounted) return;
    setState(() => _selectedDateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submitGathering() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final userStore = UserStoreProvider.of(context);
      final resolvedGender = !_genderOnly
          ? GenderFilter.any
          : (userStore.gender == '남성'
              ? GenderFilter.maleOnly
              : GenderFilter.femaleOnly);

      final resolvedAge = !_ageOnly
          ? AgeFilter.any
          : (userStore.ageCategory == 'teens'
              ? AgeFilter.teens
              : userStore.ageCategory == 'twenties'
                  ? AgeFilter.twenties
                  : userStore.ageCategory == 'thirties'
                      ? AgeFilter.thirties
                      : AgeFilter.any);

      final firestore = FirebaseFirestore.instance;

      final DateTime now = DateTime.now();

      final postRef = await firestore.collection('posts').add({
        'type': 'gathering',
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'emoji': _selectedEmoji,
        'place': _placeController.text.trim(),
        'meetTime': Timestamp.fromDate(_selectedDateTime),
        'maxMembers': _maxMembers,
        'currentMembers': 1,
        'authorName': userStore.name,
        'authorUid': userStore.uid,
        'location': userStore.location,
        'genderFilter': resolvedGender.name,
        'ageFilter': resolvedAge.name,
        'category': _selectedCategory,
        'members': [userStore.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('chatRooms').doc(postRef.id).set({
        'id': postRef.id,
        'title': _titleController.text.trim(),
        'lastMessage': '모임이 생성되었습니다! 👋',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'type': 'gather',
        'members': [userStore.uid],
        'avatarEmoji': _selectedEmoji,
        'unreadCount': 0,
        'authorUid': userStore.uid,
      });

      await firestore
          .collection('chatRooms')
          .doc(postRef.id)
          .collection('messages')
          .add({
        'text': '${userStore.name}님이 모임을 생성하셨습니다.',
        'senderName': 'system',
        'time': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();

        // 새 글 알림 ㅡ 같은 동네 사람들한테 새 글 알림
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('location', isEqualTo: userStore.location)
            .get();
        final otherUids = usersSnap.docs
            .map((d) => d.id)
            .where((id) => id != userStore.uid)
            .toList();
        await NotificationService.sendToMany(
          toUids: otherUids,
          type: 'gather',
          title: '👥 새 모임이 생겼어요',
          body: '${userStore.location} • ${_titleController.text.trim()}',
          postId: postRef.id,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              room: ChatRoom(
                id: postRef.id,
                title: _titleController.text.trim(),
                lastMessage: '모임이 생성되었습니다! 👋',
                type: ChatRoomType.gather,
                lastMessageTime: now,
                unreadCount: 0,
                avatarEmoji: _selectedEmoji,
                members: [userStore.name],
                authorUid: userStore.uid,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 모임 생성 및 채팅방 이동 실패: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('모임 만들기',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('카테고리',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kGatherCategories.map((c) {
                      final isSelected = _selectedCategory == c['label'];
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = c['label']!;
                          _selectedEmoji = c['emoji']!;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gatherColor
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gatherColor
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            '${c['emoji']} ${c['label']}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('모임 제목',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                          hintText: '예) 오늘 저녁 혼밥 메이트 구해요')),
                  const SizedBox(height: 16),
                  const Text('장소',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _placeController,
                    decoration: const InputDecoration(
                      hintText: '약속 장소를 입력해주세요',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('날짜 및 시간',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.gatherColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.gatherColor),
                          const SizedBox(width: 10),
                          Text(
                            '${_selectedDateTime.year}년 ${_selectedDateTime.month}월 ${_selectedDateTime.day}일  '
                            '${_selectedDateTime.hour.toString().padLeft(2, '0')}:'
                            '${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios,
                              size: 13, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('최대 인원',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_maxMembers > 2) setState(() => _maxMembers--);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.gatherColor,
                      ),
                      Text('$_maxMembers명',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: () {
                          if (_maxMembers < 10) setState(() => _maxMembers++);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.gatherColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('성별 제한',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: '성별 무관',
                        isSelected: !_genderOnly,
                        color: AppColors.gatherColor,
                        onTap: () => setState(() => _genderOnly = false),
                      ),
                      _FilterChip(
                        label: '내 성별만',
                        isSelected: _genderOnly,
                        color: AppColors.gatherColor,
                        onTap: () => setState(() => _genderOnly = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('연령 제한',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: '연령 무관',
                        isSelected: !_ageOnly,
                        color: AppColors.gatherColor,
                        onTap: () => setState(() => _ageOnly = false),
                      ),
                      _FilterChip(
                        label: '내 또래만',
                        isSelected: _ageOnly,
                        color: AppColors.gatherColor,
                        onTap: () => setState(() => _ageOnly = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('설명 (선택)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                        hintText: '모임에 대한 추가 설명이 있다면 입력해주세요'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitGathering,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gatherColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          const Text('모임 만들기', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 모임 수정 시트 ─────────────────────────────────────────────
class _EditGatherSheet extends StatefulWidget {
  final GatherPost post;
  const _EditGatherSheet({required this.post});

  @override
  State<_EditGatherSheet> createState() => _EditGatherSheetState();
}

class _EditGatherSheetState extends State<_EditGatherSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _placeController;
  late int _maxMembers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _descController = TextEditingController(text: widget.post.description);
    _placeController = TextEditingController(text: widget.post.place);
    _maxMembers = widget.post.maxMembers;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('모임 제목을 입력해주세요.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'place': _placeController.text.trim(),
        'maxMembers': _maxMembers,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ 수정되었습니다.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('모임 수정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('모임 제목',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: '모임 제목')),
                  const SizedBox(height: 16),
                  const Text('설명',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: '모임 설명')),
                  const SizedBox(height: 16),
                  const Text('장소',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _placeController,
                      decoration: const InputDecoration(hintText: '만날 장소')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('최대 인원',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      IconButton(
                        onPressed: _maxMembers > widget.post.currentMembers + 1
                            ? () => setState(() => _maxMembers--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.gatherColor,
                      ),
                      Text('$_maxMembers명',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: _maxMembers < 20
                            ? () => setState(() => _maxMembers++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.gatherColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gatherColor,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('수정 완료', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
