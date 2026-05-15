import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gatchi_sapsida/utils/storage_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_store.dart';
import './chat_list_screen.dart';
import 'package:provider/provider.dart';
import '../utils/notification_service.dart';

class GroupBuyScreen extends StatefulWidget {
  final String? initialPostId;
  const GroupBuyScreen({super.key, this.initialPostId});

  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> {
  String _selectedFilter = '전체';
  final List<String> _filters = ['전체', '식료품', '생활용품', '배달음식'];
  String _searchQuery = '';
  final _searchController = TextEditingController();

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
        final data = snap.data() as Map<String, dynamic>;
        final post = GroupBuyPost(
          id: snap.id,
          title: data['title'] ?? '',
          category: data['category'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          totalPrice: data['totalPrice'] ?? 0,
          unitPrice: data['unitPrice'] ?? 0,
          maxParticipants: data['maxParticipants'] ?? 0,
          currentParticipants: data['currentParticipants'] ?? 0,
          walkMinutes: data['walkMinutes'] ?? 0,
          location: data['location'] ?? '',
          authorName: data['authorName'] ?? '',
          authorUid: data['authorUid'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isDelivery: data['isDelivery'] ?? false,
          meetingPlace: data['meetingPlace'] ?? '',
          deadline: (data['deadline'] as Timestamp?)?.toDate(),
        );
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _GroupBuyDetail(post: post),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterLoc = UserStoreProvider.of(context).filterLocation;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('공동구매')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'groupBuyFab',
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.buyColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('글쓰기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // 안내 배너
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.buyColor.withOpacity(0.1),
                  AppColors.buyColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Text('🛒', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '이웃과 함께 사면 더 저렴해요!\n공동구매로 배송비·수량 부담 줄이기',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: '상품명으로 검색',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.close, color: AppColors.textHint),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.buyColorLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.buyColorLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.buyColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 필터 탭
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: _filters.map((f) {
                final isSelected = f == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.buyColor : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.buyColor : AppColors.buyColorLight,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('type', isEqualTo: 'groupBuy')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const EmptyState(
                    emoji: '🛒',
                    title: '게시글이 없어요',
                    subtitle: '첫 번째 공동구매를 직접 시작해보세요!',
                  );
                }

                final uid = UserStoreProvider.of(context).uid;
                final locationDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final loc = (data['location'] as String? ?? '');
                  if (loc.isEmpty || filterLoc.isEmpty) return true;
                  if (loc.startsWith(filterLoc)) return true;
                  final locParts = loc.split(' ').where((p) => p.isNotEmpty).toList();
                  final filterParts = filterLoc.split(' ').where((p) => p.isNotEmpty).toList();
                  // 같은 형식(첫 파트 동일): startsWith 실패 = 다른 지역 → 숨김
                  if (locParts.isNotEmpty && locParts[0] == filterParts[0]) return false;
                  // 이전 형식: 필터 수준에 따라 처리
                  if (filterParts.length == 1) return true; // 시/도 전체 → 모두 표시
                  if (filterParts.length == 2) {
                    // 구 수준: 동 이름만 있는 이전 글은 구 특정 불가 → 표시
                    if (locParts.length < 2) return true;
                    return locParts.contains(filterParts.last);
                  }
                  // 동 수준: 동 이름이 정확히 일치해야 함
                  return locParts.contains(filterParts.last);
                }).toList();
                final categoryDocs = _selectedFilter == '전체'
                    ? locationDocs
                    : locationDocs
                        .where((doc) => doc['category'] == _selectedFilter)
                        .toList();

                final filteredDocs = (_searchQuery.isEmpty
                    ? categoryDocs
                    : categoryDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final q = _searchQuery.toLowerCase();
                        return (data['title'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q);
                      }).toList())
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['status'] as String? ?? '') != 'completed';
                  }).toList()
                  ..sort((a, b) {
                    final aD = a.data() as Map;
                    final bD = b.data() as Map;
                    
                    // 🔥 상단 노출 우선
                    final now = DateTime.now();
                    final aPinned = (aD['isPinned'] == true) &&
                        (aD['pinnedUntil'] as Timestamp?)?.toDate().isAfter(now) == true;
                    final bPinned = (bD['isPinned'] == true) &&
                        (bD['pinnedUntil'] as Timestamp?)?.toDate().isAfter(now) == true;
                    if (aPinned && !bPinned) return -1;
                    if (!aPinned && bPinned) return 1;
                    
                    final aFull = (aD['isFull'] == true) ||
                        ((aD['currentParticipants'] ?? 0) >=
                            (aD['maxParticipants'] ?? 1));
                    final bFull = (bD['isFull'] == true) ||
                        ((bD['currentParticipants'] ?? 0) >=
                            (bD['maxParticipants'] ?? 1));
                    // 마감 여부 우선
                    if (!aFull && bFull) return -1;
                    if (aFull && !bFull) return 1;
                    // 같은 상태면 내 글 먼저
                    final aIsMe = aD['authorUid'] == uid;
                    final bIsMe = bD['authorUid'] == uid;
                    if (aIsMe && !bIsMe) return -1;
                    if (!aIsMe && bIsMe) return 1;
                    return 0;
                  });

                if (filteredDocs.isEmpty) {
                  return EmptyState(
                    emoji: '🔍',
                    title: '검색 결과가 없어요',
                    subtitle: '"$_searchQuery"에 해당하는 게시글이 없습니다.',
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = filteredDocs[i].data() as Map<String, dynamic>;
                    return RepaintBoundary(
                      child: _GroupBuyCard(
                        post: GroupBuyPost(
                          id: filteredDocs[i].id,
                          title: data['title'] ?? '',
                          category: data['category'] ?? '기타',
                          imageUrl: data['imageUrl'] ?? '',
                          totalPrice: data['totalPrice'] ?? 0,
                          unitPrice: data['unitPrice'] ?? 0,
                          maxParticipants: data['maxParticipants'] ?? 2,
                          currentParticipants: data['currentParticipants'] ?? 1,
                          walkMinutes: 5,
                          location: data['location'] ?? '안암동',
                          authorName: data['authorName'] ?? '익명',
                          authorUid: data['authorUid'] ?? '',
                          createdAt: (data['createdAt'] as Timestamp).toDate(),
                          isDelivery: data['category'] == '배달음식',
                          meetingPlace: data['meetingPlace'] ?? '', // ← 추가
                          deadline: (data['deadline'] as Timestamp?)?.toDate(),
                          isPinned: data['isPinned'] ?? false,
                          pinnedUntil: (data['pinnedUntil'] as Timestamp?)?.toDate(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateGroupBuySheet(),
    );
  }
}

class _GroupBuyCard extends StatefulWidget {
  final GroupBuyPost post;
  const _GroupBuyCard({required this.post});

  @override
  State<_GroupBuyCard> createState() => _GroupBuyCardState();
}

class _GroupBuyCardState extends State<_GroupBuyCard> {
  @override
  Widget build(BuildContext context) {
    final userStore = UserStoreProvider.of(context);
    final isAuthor =
        userStore.uid.isNotEmpty && userStore.uid == widget.post.authorUid;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAuthor
              ? AppColors.buyColorLight
              : widget.post.isFull
                  ? AppColors.textHint.withOpacity(0.07)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAuthor
                ? AppColors.buyColor.withOpacity(0.3)
                : widget.post.isFull
                    ? AppColors.textHint.withOpacity(0.25)
                    : AppColors.buyColorLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrl,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 150,
                    color: AppColors.cardBg,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // 🔥 상단 노출 배지 - Row 바로 위에
            if (widget.post.isPinned &&
                widget.post.pinnedUntil != null &&
                widget.post.pinnedUntil!.isAfter(DateTime.now())) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.buyColorLight,
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
                            color: AppColors.buyColor)),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                TagBadge(
                  label: widget.post.category,
                  color: widget.post.isDelivery
                      ? AppColors.secondary
                      : AppColors.buyColor,
                ),
                const SizedBox(width: 8),
                if (widget.post.isDelivery)
                  TagBadge(label: '🛵 배달소분', color: AppColors.secondary),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(
                  widget.post.authorName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(
                  widget.post.location,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
            if (widget.post.meetingPlace.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Text(
                    '거래 희망 장소: ${widget.post.meetingPlace}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ParticipantProgress(
              current: widget.post.currentParticipants,
              max: widget.post.maxParticipants,
              color: AppColors.buyColor,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 ${_formatPrice(widget.post.totalPrice)}원',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '1인 ${_formatPrice(widget.post.unitPrice)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.buyColor,
                      ),
                    ),
                  ],
                ),
                if (isAuthor)
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                                color: AppColors.buyColor,
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
                                color: AppColors.buyColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: () => _deletePost(
                            context,
                            widget.post.id,
                            widget.post.authorName),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(
      BuildContext context, String postId, String authorName) async {
    final firestore = FirebaseFirestore.instance;
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('게시글 삭제'),
            content: const Text('정말 이 게시글을 삭제하시겠습니까?\n연결된 채팅방도 모두 사라집니다.'),
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
      final batch = firestore.batch();
      batch.delete(firestore.collection('posts').doc(postId));
      batch.delete(firestore.collection('chatRooms').doc(postId));
      await batch.commit();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupBuyDetail(post: widget.post),
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

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditGroupBuySheet(post: widget.post),
    );
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

class _GroupBuyDetail extends StatelessWidget {
  final GroupBuyPost post;

  const _GroupBuyDetail({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.buyColorLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이미지
                  if (post.imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 200,
                          color: AppColors.cardBg,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      TagBadge(label: post.category, color: AppColors.buyColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '📍 ${post.location}  •  👤 ${post.authorName}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(post.authorUid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                          final avgRating = ((data['avgRating'] ?? 0.0) as num).toDouble();
                          if (avgRating == 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.buyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
                                const SizedBox(width: 3),
                                Text(
                                  avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.buyColor),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.buyColorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem('전체 금액', '${_formatPrice(post.totalPrice)}원'),
                        Container(
                            width: 1,
                            height: 30,
                            color: AppColors.buyColor.withOpacity(0.2)),
                        _InfoItem('1인 부담', '${_formatPrice(post.unitPrice)}원',
                            highlight: true),
                        Container(
                            width: 1,
                            height: 30,
                            color: AppColors.buyColor.withOpacity(0.2)),
                        _InfoItem('인원', '${post.maxParticipants}명'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ParticipantProgress(
                    current: post.currentParticipants,
                    max: post.maxParticipants,
                    color: AppColors.buyColor,
                  ),
                  const SizedBox(height: 24),
                  Builder(builder: (ctx) {
                    final store = UserStoreProvider.of(ctx);
                    final isAuthor =
                        store.uid.isNotEmpty && store.uid == post.authorUid;
                    // 내가 만든 글 → 배너 표시
                    if (isAuthor) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.buyColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '내가 올린 공동구매 글',
                            style: TextStyle(
                              color: AppColors.buyColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }
                    if (!post.isFull) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async => await _handleJoin(ctx, post),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buyColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('참여하기',
                              style: TextStyle(fontSize: 16)),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJoin(BuildContext context, GroupBuyPost post) async {
    final firestore = FirebaseFirestore.instance;
    final userStore = UserStoreProvider.of(context);

    // ── 중복 참여 사전 체크 (transaction 오류 방지) ──
    final existingChat =
        await firestore.collection('chatRooms').doc(post.id).get();
    if (existingChat.exists) {
      final currentMembers = List<String>.from(
          (existingChat.data() as Map<String, dynamic>)['members'] ?? []);
      if (currentMembers.contains(userStore.uid)) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content:
                const Text('이미 참여한 공동구매입니다.', style: TextStyle(fontSize: 15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인',
                    style: TextStyle(color: AppColors.buyColor)),
              ),
            ],
          ),
        );
        return;
      }
    }

    try {
      List<String> updatedMembers = [];

      await firestore.runTransaction((transaction) async {
        DocumentReference postRef = firestore.collection('posts').doc(post.id);
        DocumentSnapshot postSnapshot = await transaction.get(postRef);
        DocumentReference chatRef =
            firestore.collection('chatRooms').doc(post.id);
        DocumentSnapshot chatSnapshot = await transaction.get(chatRef);
        int current = postSnapshot['currentParticipants'] ?? 0;
        int max = postSnapshot['maxParticipants'] ?? 0;

        if (current >= max) throw Exception("이미 정원이 찼습니다.");

        updatedMembers = List<String>.from(chatSnapshot.exists
            ? (chatSnapshot.data() as Map<String, dynamic>)['members'] ?? []
            : []);

        if (updatedMembers.isEmpty) {
          updatedMembers.add(post.authorUid);
        }
        updatedMembers.add(userStore.uid);

        transaction.update(postRef, {
          'currentParticipants': current + 1,
          'isFull': (current + 1) >= max,
        });

        transaction.set(
            chatRef,
            {
              'postId': post.id,
              'title': post.title,
              'members': updatedMembers,
              'authorUid': post.authorUid,
              'lastMessage': "${userStore.name}님이 참여하셨습니다.",
              'lastMessageTime': FieldValue.serverTimestamp(),
              'type': 'groupBuy',
              'avatarEmoji': '🛒',
              'unreadCount': 0,
              'joinedAt': {userStore.uid: FieldValue.serverTimestamp()},
            },
            SetOptions(merge: true));

        // 시스템 메시지
        transaction.set(chatRef.collection('messages').doc(), {
          'senderName': 'system',
          'text': "${userStore.name}님이 참여하셨습니다.",
          'time': FieldValue.serverTimestamp(),
        });
      });

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            room: ChatRoom(
              id: post.id,
              title: post.title,
              lastMessage: "${userStore.name}님이 참여하셨습니다.",
              lastMessageTime: DateTime.now(),
              avatarEmoji: "🛒",
              type: ChatRoomType.groupBuy,
              unreadCount: 0,
              members: updatedMembers,
              authorUid: post.authorUid,
            ),
          ),
        ),
      );
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
              child:
                  const Text('확인', style: TextStyle(color: AppColors.buyColor)),
            ),
          ],
        ),
      );
    }

    // 참여 성공 후 ㅡ 글 작성자한테 알림
    await NotificationService.send(
      toUid: post.authorUid,
      type: 'groupBuy',
      title: '🛒 공동구매에 새 참여자가 왔어요',
      body: '${userStore.name}님이 "${post.title}"에 참여했어요.',
      postId: post.id,
    );
  }

  Widget _InfoItem(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

class _CreateGroupBuySheet extends StatefulWidget {
  const _CreateGroupBuySheet();

  @override
  State<_CreateGroupBuySheet> createState() => _CreateGroupBuySheetState();
}

class _CreateGroupBuySheetState extends State<_CreateGroupBuySheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  String _type = '생활용품';
  int _members = 2;
  bool _isUploading = false;
  bool _hasDeadline = false;
  DateTime? _deadline;
  bool _useCustomDate = false;
  final _deadlineDaysController = TextEditingController();
  final TextEditingController _meetingPlaceController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _totalPriceController.dispose();
    _deadlineDaysController.dispose();
    _meetingPlaceController.dispose();
    super.dispose();
  }

  int get _unitPrice {
    final total =
        int.tryParse(_totalPriceController.text.replaceAll(',', '')) ?? 0;
    return (total / _members).ceil(); // 올림 처리
  }

  @override
  Widget build(BuildContext context) {
    final userStore = UserStoreProvider.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.buyColorLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: const [
                      Text('공동구매 글쓰기',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
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
                        Row(
                          children: ['식료품', '생활용품', '배달음식'].map((t) {
                            return GestureDetector(
                              onTap: () => setState(() => _type = t),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _type == t
                                      ? AppColors.buyColor
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _type == t
                                          ? AppColors.buyColor
                                          : AppColors.buyColorLight),
                                ),
                                child: Text(t,
                                    style: TextStyle(
                                      color: _type == t
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('상품명',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                                hintText: '예) 코스트코 두루마리 화장지 30롤')),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('총 금액',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _totalPriceController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                        hintText: '0', suffixText: '원'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('모집 인원',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: AppColors.buyColorLight),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove,
                                              size: 18),
                                          onPressed: () => setState(() {
                                            if (_members > 2) _members--;
                                          }),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Text('$_members명',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          onPressed: () => setState(() {
                                            if (_members < 6) _members++;
                                          }),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Text('거래 희망 장소',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const Text('거래하고 싶은 장소를 미리 정해두세요',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textHint)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _meetingPlaceController,
                          decoration: const InputDecoration(
                            hintText: '예) 안암역 2번 출구',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        // ── 마감기한 ──
                        Row(
                          children: [
                            Checkbox(
                              value: _hasDeadline,
                              onChanged: (v) => setState(() {
                                _hasDeadline = v ?? false;
                                if (!_hasDeadline) {
                                  _deadline = null;
                                  _deadlineDaysController.clear();
                                }
                              }),
                              activeColor: AppColors.buyColor,
                            ),
                            const Text('마감기한 설정',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (_hasDeadline) ...[
                          const SizedBox(height: 8),
                          if (_type == '배달음식') ...[
                            // ── 배달음식: 몇 시간 후 / 시간 직접 선택 ──
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _useCustomDate = false;
                                    _deadline = null;
                                    _deadlineDaysController.clear();
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !_useCustomDate
                                          ? AppColors.buyColor
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: !_useCustomDate
                                              ? AppColors.buyColor
                                              : AppColors.buyColorLight),
                                    ),
                                    child: Text('몇 시간 후',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: !_useCustomDate
                                                ? Colors.white
                                                : AppColors.textSecondary)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _useCustomDate = true;
                                    _deadline = null;
                                    _deadlineDaysController.clear();
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _useCustomDate
                                          ? AppColors.buyColor
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _useCustomDate
                                              ? AppColors.buyColor
                                              : AppColors.buyColorLight),
                                    ),
                                    child: Text('시간 직접 선택',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _useCustomDate
                                                ? Colors.white
                                                : AppColors.textSecondary)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!_useCustomDate) ...[
                              // 몇 시간 후 입력
                              TextField(
                                controller: _deadlineDaysController,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final val = int.tryParse(v);
                                  if (val != null && val > 0) {
                                    setState(() => _deadline = DateTime.now()
                                        .add(Duration(hours: val)));
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: '예) 2',
                                  suffixText: '시간 후',
                                ),
                              ),
                            ] else ...[
                              // 시간 직접 선택
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      final now = DateTime.now();
                                      _deadline = DateTime(now.year, now.month,
                                          now.day, picked.hour, picked.minute);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.buyColor
                                            .withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 18, color: AppColors.buyColor),
                                      const SizedBox(width: 10),
                                      Text(
                                        _deadline != null
                                            ? '오늘 ${_deadline!.hour}시 ${_deadline!.minute.toString().padLeft(2, '0')}분까지'
                                            : '시간을 선택하세요',
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
                            ],
                            if (_deadline != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '마감시간: 오늘 ${_deadline!.hour}시 ${_deadline!.minute.toString().padLeft(2, '0')}분',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.buyColor),
                                ),
                              ),
                          ] else ...[
                            // ── 일반: 며칠 후 / 날짜 직접 선택 ──
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _useCustomDate = false;
                                    _deadline = null;
                                    _deadlineDaysController.clear();
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !_useCustomDate
                                          ? AppColors.buyColor
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: !_useCustomDate
                                              ? AppColors.buyColor
                                              : AppColors.buyColorLight),
                                    ),
                                    child: Text('며칠 후',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: !_useCustomDate
                                                ? Colors.white
                                                : AppColors.textSecondary)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _useCustomDate = true;
                                    _deadline = null;
                                    _deadlineDaysController.clear();
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _useCustomDate
                                          ? AppColors.buyColor
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _useCustomDate
                                              ? AppColors.buyColor
                                              : AppColors.buyColorLight),
                                    ),
                                    child: Text('날짜 직접 선택',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _useCustomDate
                                                ? Colors.white
                                                : AppColors.textSecondary)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!_useCustomDate) ...[
                              // 며칠 후 입력
                              TextField(
                                controller: _deadlineDaysController,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final val = int.tryParse(v);
                                  if (val != null && val > 0) {
                                    setState(() => _deadline = DateTime.now()
                                        .add(Duration(days: val)));
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: '예) 5',
                                  suffixText: '일 후',
                                ),
                              ),
                            ] else ...[
                              // 날짜 직접 선택
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now()
                                        .add(const Duration(days: 1)),
                                    firstDate: DateTime.now()
                                        .add(const Duration(days: 1)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (picked != null)
                                    setState(() => _deadline = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.buyColor
                                            .withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 18, color: AppColors.buyColor),
                                      const SizedBox(width: 10),
                                      Text(
                                        _deadline != null
                                            ? '${_deadline!.year}년 ${_deadline!.month}월 ${_deadline!.day}일'
                                            : '날짜를 선택하세요',
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
                            ],
                            if (_deadline != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '마감일: ${_deadline!.year}년 ${_deadline!.month}월 ${_deadline!.day}일',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.buyColor),
                                ),
                              ),
                          ],
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUploading
                                ? null
                                : () => _submitPost(userStore),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buyColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('등록하기',
                                style: TextStyle(fontSize: 16)),
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

  Future<void> _submitPost(UserStore userStore) async {
    if (_titleController.text.isEmpty || _totalPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('정보를 모두 입력해주세요.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final totalPrice =
          int.parse(_totalPriceController.text.replaceAll(',', ''));

      final newPostRef = await FirebaseFirestore.instance.collection('posts').add({
        'type': 'groupBuy',
        'title': _titleController.text.trim(),
        'category': _type,
        'totalPrice': totalPrice,
        'unitPrice': _unitPrice,
        'maxParticipants': _members,
        'currentParticipants': 1,
        'location': userStore.location,
        'authorName': userStore.name,
        'authorUid': userStore.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'isFull': false,
        'members': [userStore.name],
        'meetingPlace': _meetingPlaceController.text.trim(),
        'deadline': _deadline != null ? Timestamp.fromDate(_deadline!) : null,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ 공동구매 글이 등록되었습니다!')));

      // 같은 동네 사용자들한테 새 글 알림
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
        type: 'groupBuy',
        title: '🛒 새 공동구매 글이 올라왔어요',
        body: '${userStore.location} • ${_titleController.text.trim()}',
        postId: newPostRef.id,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

// ── 공동구매 수정 시트 ─────────────────────────────────────────
class _EditGroupBuySheet extends StatefulWidget {
  final GroupBuyPost post;
  const _EditGroupBuySheet({required this.post});

  @override
  State<_EditGroupBuySheet> createState() => _EditGroupBuySheetState();
}

class _EditGroupBuySheetState extends State<_EditGroupBuySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _totalPriceController;
  late String _type;
  late int _members;
  bool _isSaving = false;
  DateTime? _deadline;
  bool _hasDeadline = false;
  bool _useCustomDate = false;
  final _deadlineDaysController = TextEditingController();

  final List<String> _types = ['식료품', '생활용품', '배달음식'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _totalPriceController =
        TextEditingController(text: widget.post.totalPrice.toString());
    _type = widget.post.category;
    _members = widget.post.maxParticipants;
    _deadline = widget.post.deadline;
    _hasDeadline = _deadline != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalPriceController.dispose();
    super.dispose();
    _deadlineDaysController.dispose();
  }

  int get _unitPrice {
    final total =
        int.tryParse(_totalPriceController.text.replaceAll(',', '')) ?? 0;
    return _members == 0 ? 0 : (total / _members).ceil();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _totalPriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('정보를 모두 입력해주세요.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final totalPrice =
          int.parse(_totalPriceController.text.replaceAll(',', ''));
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({
        'title': _titleController.text.trim(),
        'category': _type,
        'totalPrice': totalPrice,
        'unitPrice': _unitPrice,
        'maxParticipants': _members,
        'deadline': _deadline != null ? Timestamp.fromDate(_deadline!) : null,
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
                color: AppColors.buyColorLight,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('공동구매 수정',
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
                  const Text('제목',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: '공동구매 제목')),
                  const SizedBox(height: 16),
                  const Text('카테고리',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _types.map((t) {
                      final sel = t == _type;
                      return GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.buyColor : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? AppColors.buyColor
                                    : AppColors.buyColorLight),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('총 금액',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _totalPriceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '원',
                      suffixText: '1인 ${_unitPrice}원',
                      suffixStyle: const TextStyle(
                          color: AppColors.buyColor,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('인원수',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      IconButton(
                        onPressed: _members > 2
                            ? () => setState(() => _members--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.buyColor,
                      ),
                      Text('$_members명',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: _members < 10
                            ? () => setState(() => _members++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.buyColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── 마감기한 ──
                  Row(
                    children: [
                      Checkbox(
                        value: _hasDeadline,
                        onChanged: (v) => setState(() {
                          _hasDeadline = v ?? false;
                          if (!_hasDeadline) {
                            _deadline = null;
                            _deadlineDaysController.clear();
                          }
                        }),
                        activeColor: AppColors.buyColor,
                      ),
                      const Text('마감기한 설정',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (_hasDeadline) ...[
                    const SizedBox(height: 8),
                    if (_type == '배달음식') ...[
                      // ── 배달음식: 몇 시간 후 / 시간 직접 선택 ──
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              _useCustomDate = false;
                              _deadline = null;
                              _deadlineDaysController.clear();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_useCustomDate
                                    ? AppColors.buyColor
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: !_useCustomDate
                                        ? AppColors.buyColor
                                        : AppColors.buyColorLight),
                              ),
                              child: Text('몇 시간 후',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: !_useCustomDate
                                          ? Colors.white
                                          : AppColors.textSecondary)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _useCustomDate = true;
                              _deadline = null;
                              _deadlineDaysController.clear();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _useCustomDate
                                    ? AppColors.buyColor
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _useCustomDate
                                        ? AppColors.buyColor
                                        : AppColors.buyColorLight),
                              ),
                              child: Text('시간 직접 선택',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _useCustomDate
                                          ? Colors.white
                                          : AppColors.textSecondary)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!_useCustomDate) ...[
                        // 몇 시간 후 입력
                        TextField(
                          controller: _deadlineDaysController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final val = int.tryParse(v);
                            if (val != null && val > 0) {
                              setState(() => _deadline =
                                  DateTime.now().add(Duration(hours: val)));
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: '예) 2',
                            suffixText: '시간 후',
                          ),
                        ),
                      ] else ...[
                        // 시간 직접 선택
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                final now = DateTime.now();
                                _deadline = DateTime(now.year, now.month,
                                    now.day, picked.hour, picked.minute);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.buyColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 18, color: AppColors.buyColor),
                                const SizedBox(width: 10),
                                Text(
                                  _deadline != null
                                      ? '오늘 ${_deadline!.hour}시 ${_deadline!.minute.toString().padLeft(2, '0')}분까지'
                                      : '시간을 선택하세요',
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
                      ],
                      if (_deadline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '마감시간: 오늘 ${_deadline!.hour}시 ${_deadline!.minute.toString().padLeft(2, '0')}분',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.buyColor),
                          ),
                        ),
                    ] else ...[
                      // ── 일반: 며칠 후 / 날짜 직접 선택 ──
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              _useCustomDate = false;
                              _deadline = null;
                              _deadlineDaysController.clear();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_useCustomDate
                                    ? AppColors.buyColor
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: !_useCustomDate
                                        ? AppColors.buyColor
                                        : AppColors.buyColorLight),
                              ),
                              child: Text('며칠 후',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: !_useCustomDate
                                          ? Colors.white
                                          : AppColors.textSecondary)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _useCustomDate = true;
                              _deadline = null;
                              _deadlineDaysController.clear();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _useCustomDate
                                    ? AppColors.buyColor
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _useCustomDate
                                        ? AppColors.buyColor
                                        : AppColors.buyColorLight),
                              ),
                              child: Text('날짜 직접 선택',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _useCustomDate
                                          ? Colors.white
                                          : AppColors.textSecondary)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!_useCustomDate) ...[
                        // 며칠 후 입력
                        TextField(
                          controller: _deadlineDaysController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final val = int.tryParse(v);
                            if (val != null && val > 0) {
                              setState(() => _deadline =
                                  DateTime.now().add(Duration(days: val)));
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: '예) 5',
                            suffixText: '일 후',
                          ),
                        ),
                      ] else ...[
                        // 날짜 직접 선택
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 1)),
                              firstDate:
                                  DateTime.now().add(const Duration(days: 1)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null)
                              setState(() => _deadline = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.buyColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18, color: AppColors.buyColor),
                                const SizedBox(width: 10),
                                Text(
                                  _deadline != null
                                      ? '${_deadline!.year}년 ${_deadline!.month}월 ${_deadline!.day}일'
                                      : '날짜를 선택하세요',
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
                      ],
                      if (_deadline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '마감일: ${_deadline!.year}년 ${_deadline!.month}월 ${_deadline!.day}일',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.buyColor),
                          ),
                        ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buyColor,
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
