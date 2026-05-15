import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gatchi_sapsida/models/user_store.dart';
import 'package:gatchi_sapsida/screens/chat_list_screen.dart';
import 'package:gatchi_sapsida/utils/storage_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';
import '../utils/notification_service.dart';

class ExchangeScreen extends StatefulWidget {
  final String? initialPostId;
  const ExchangeScreen({super.key, this.initialPostId});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
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
        final post = ExchangePost.fromMap(snap.data() as Map<String, dynamic>, snap.id);
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ExchangeDetail(post: post),
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
      appBar: AppBar(title: const Text('물물교환')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'exchangeFab',
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.exchangeColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('교환글 올리기',
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
                  AppColors.exchangeColorLight,
                  AppColors.exchangeColor.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Text('🔄', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '남는 물건을 이웃과 교환해요!\n채팅으로 즉시 협의·거래',
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
                hintText: '물건명으로 검색',
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
                  borderSide: const BorderSide(color: AppColors.exchangeColorLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.exchangeColorLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.exchangeColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('type', isEqualTo: 'exchange')
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
                  final uid = UserStoreProvider.of(context).uid;
                  final locationDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final loc = (data['location'] as String? ?? '');
                    if (loc.isEmpty || filterLoc.isEmpty) return true;
                    if (loc.startsWith(filterLoc)) return true;
                    final locParts = loc.split(' ').where((p) => p.isNotEmpty).toList();
                    final filterParts = filterLoc.split(' ').where((p) => p.isNotEmpty).toList();
                    if (locParts.isNotEmpty && locParts[0] == filterParts[0]) return false;
                    if (filterParts.length == 1) return true;
                    if (filterParts.length == 2) {
                      if (locParts.length < 2) return true;
                      return locParts.contains(filterParts.last);
                    }
                    return locParts.contains(filterParts.last);
                  }).toList();

                  final filteredDocs = (_searchQuery.isEmpty
                      ? locationDocs
                      : locationDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final q = _searchQuery.toLowerCase();
                          return (data['title'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(q) ||
                              (data['offerItem'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(q) ||
                              (data['wantItem'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(q);
                        }).toList())
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['status'] as String? ?? '') != 'done';
                    }).toList()
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
                      
                      final aDone = aD['status'] == 'done';
                      final bDone = bD['status'] == 'done';
                      if (!aDone && bDone) return -1;
                      if (aDone && !bDone) return 1;
                      final aIsMe = aD['authorUid'] == uid;
                      final bIsMe = bD['authorUid'] == uid;
                      if (aIsMe && !bIsMe) return -1;
                      if (!aIsMe && bIsMe) return 1;
                      return 0;
                    });

                  if (filteredDocs.isEmpty) {
                    return _searchQuery.isEmpty
                        ? const EmptyState(
                            emoji: '🔄',
                            title: '등록된 교환글이 없어요',
                            subtitle: '안 쓰는 물건을 이웃과 바꿔보세요!',
                          )
                        : EmptyState(
                            emoji: '🔍',
                            title: '검색 결과가 없어요',
                            subtitle: '"$_searchQuery"에 해당하는 교환글이 없습니다.',
                          );
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final data =
                          filteredDocs[i].data() as Map<String, dynamic>;
                      return RepaintBoundary(
                        child: _ExchangeCard(
                          post: ExchangePost(
                            id: filteredDocs[i].id,
                            title: data['title'] ?? '',
                            description: data['description'] ?? '',
                            offerItem: data['offerItem'] ?? '',
                            wantItem: data['wantItem'] ?? '',
                            imageUrl: data['imageUrl'] ?? '',
                            walkMinutes: 5,
                            location: data['location'] ?? '안암동',
                            authorName: data['authorName'] ?? '익명',
                            authorUid: data['authorUid'] ?? '',
                            createdAt:
                                (data['createdAt'] as Timestamp).toDate(),
                            status: (data['status'] == 'done' ||
                                    data['status'] == 'completed')
                                ? ExchangeStatus.done
                                : ExchangeStatus.open,
                            meetingPlace: data['meetingPlace'] ?? '',
                            isPinned: data['isPinned'] ?? false,        
                            pinnedUntil: (data['pinnedUntil'] as Timestamp?)?.toDate(),
                          ),
                        ),
                      );
                    },
                  );
                }),
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
      builder: (_) => const _CreateExchangeSheet(),
    );
  }
}

class _ExchangeCard extends StatefulWidget {
  final ExchangePost post;

  const _ExchangeCard({required this.post});

  @override
  State<_ExchangeCard> createState() => _ExchangeCardState();
}

class _ExchangeCardState extends State<_ExchangeCard> {
  Color get _statusColor {
    switch (widget.post.status) {
      case ExchangeStatus.open:
        return AppColors.success;
      case ExchangeStatus.chatting:
        return AppColors.accent;
      case ExchangeStatus.done:
        return AppColors.textHint;
    }
  }

  String get _statusLabel {
    switch (widget.post.status) {
      case ExchangeStatus.open:
        return '교환 가능';
      case ExchangeStatus.chatting:
        return '채팅 중';
      case ExchangeStatus.done:
        return '교환 완료';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStore = UserStoreProvider.of(context);
    final bool isAuthor =
        userStore.uid.isNotEmpty && userStore.uid == widget.post.authorUid;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isAuthor
              ? AppColors.exchangeColorLight
              : widget.post.status == ExchangeStatus.done
                  ? AppColors.textHint.withOpacity(0.07)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAuthor
                ? AppColors.exchangeColor.withOpacity(0.3)
                : widget.post.status == ExchangeStatus.done
                    ? AppColors.textHint.withOpacity(0.25)
                    : AppColors.exchangeColorLight,
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
            if (widget.post.isPinned &&
                widget.post.pinnedUntil != null &&
                widget.post.pinnedUntil!.isAfter(DateTime.now())) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.exchangeColor,
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
                            color: AppColors.exchangeColor)),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                TagBadge(label: _statusLabel, color: _statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ItemBox(
                    label: '제공',
                    item: widget.post.offerItem,
                    color: AppColors.exchangeColor,
                    icon: '📦',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.exchangeColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.swap_horiz,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                Expanded(
                  child: _ItemBox(
                    label: '원하는',
                    item: widget.post.wantItem,
                    color: AppColors.secondary,
                    icon: '🙏',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(widget.post.authorName,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(widget.post.location,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
                if (isAuthor) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showPinDialog(context),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('🔥 상단노출',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.exchangeColor,
                            fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () => _showEditSheet(context),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('수정',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.exchangeColor,
                            fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () => _showDeleteConfirm(context, widget.post),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('삭제',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
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
      builder: (_) => _ExchangeDetail(post: widget.post),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditExchangeSheet(post: widget.post),
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

  void _showDeleteConfirm(BuildContext context, ExchangePost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 삭제하시겠습니까?\n거래 중인 채팅방도 모두 삭제됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              _deleteExchangePost(context, post);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExchangePost(
      BuildContext context, ExchangePost post) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      if (post.imageUrl.isNotEmpty) {
        await StorageService.deleteImage(post.imageUrl);
      }
      final postRef = firestore.collection('posts').doc(post.id);
      batch.delete(postRef);

      final chatRooms = await firestore
          .collection('chatRooms')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: post.id)
          .where(FieldPath.documentId, isLessThan: post.id + '\uf8ff')
          .get();

      for (var doc in chatRooms.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글과 관련 대화가 모두 삭제되었습니다.')),
        );
      }
    } catch (e) {
      print('삭제 중 오류 발생: $e');
    }
  }

  Future<void> _completeExchange(BuildContext context, String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({'status': ExchangeStatus.done.name}); //

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 교환이 완료되었습니다! 따뜻한 이웃이 되어주셔서 감사합니다.')),
        );
      }
    } catch (e) {
      print('마감 처리 오류: $e');
    }
  }
}

class _ItemBox extends StatelessWidget {
  final String label;
  final String item;
  final Color color;
  final String icon;

  const _ItemBox({
    required this.label,
    required this.item,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $label',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            item,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ExchangeDetail extends StatelessWidget {
  final ExchangePost post;

  const _ExchangeDetail({required this.post});

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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.exchangeColorLight,
                borderRadius: BorderRadius.circular(2)),
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
                  Text(post.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(post.description,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _ItemBox(
                              label: '제공',
                              item: post.offerItem,
                              color: AppColors.exchangeColor,
                              icon: '📦')),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.swap_horiz,
                            color: AppColors.exchangeColor, size: 28),
                      ),
                      Expanded(
                          child: _ItemBox(
                              label: '원하는',
                              item: post.wantItem,
                              color: AppColors.secondary,
                              icon: '🙏')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Builder(builder: (ctx) {
                    final store = UserStoreProvider.of(ctx);
                    final isAuthor =
                        store.uid.isNotEmpty && store.uid == post.authorUid;
                    if (isAuthor) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.exchangeColorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('내가 올린 물물교환 글',
                              style: TextStyle(
                                  color: AppColors.exchangeColorLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final userStore = UserStoreProvider.of(context);
                          final firestore = FirebaseFirestore.instance;

                          try {
                            final String chatId =
                                "${post.id}_${userStore.name}";

                            // ── 중복 참여 사전 체크 ──
                            final existingChat = await firestore
                                .collection('chatRooms')
                                .doc(chatId)
                                .get();
                            if (existingChat.exists) {
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  content: const Text('이미 참여한 물물교환입니다.',
                                      style: TextStyle(fontSize: 15)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('확인',
                                          style: TextStyle(
                                              color: AppColors.exchangeColorLight)),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            await firestore.runTransaction((transaction) async {
                              DocumentReference postRef =
                                  firestore.collection('posts').doc(post.id);

                              transaction
                                  .update(postRef, {'status': 'chatting'});

                              DocumentReference chatRef =
                                  firestore.collection('chatRooms').doc(chatId);
                              transaction.set(chatRef, {
                                'id': chatId,
                                'title': '${post.offerItem} ↔ ${post.wantItem}',
                                'lastMessage': '${userStore.name}님이 참여하셨습니다.',
                                'lastMessageTime': FieldValue.serverTimestamp(),
                                'unreadCount': 0,
                                'type': 'exchange',
                                'members': [post.authorUid, userStore.uid],
                                'avatarEmoji': '🔄',
                                'authorUid': post.authorUid,
                                'postId': post.id,
                                'joinedAt': {
                                  userStore.uid: FieldValue.serverTimestamp()
                                },
                              });

                              DocumentReference msgRef =
                                  chatRef.collection('messages').doc();
                              transaction.set(msgRef, {
                                'text': '${userStore.name}님이 참여하셨습니다.',
                                'senderName': 'system',
                                'time': FieldValue.serverTimestamp(),
                              });
                            });

                            /// 교환 제안 알림 - 글 작성자한테 알림
                            await NotificationService.send(
                              toUid: post.authorUid,
                              type: 'exchange',
                              title: '🔄 물물교환 제안이 왔어요',
                              body:
                                  '${userStore.name}님이 "${post.offerItem} ↔ ${post.wantItem}"에 채팅을 걸었어요.',
                              chatRoomId: chatId,
                            );

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  room: ChatRoom(
                                    id: chatId,
                                    title: post.offerItem,
                                    lastMessage: '채팅이 시작되었습니다.',
                                    lastMessageTime: DateTime.now(),
                                    unreadCount: 0,
                                    avatarEmoji: '🔄',
                                    type: ChatRoomType.exchange,
                                    members: [post.authorName, userStore.name],
                                    authorUid: post.authorUid,
                                  ),
                                ),
                              ),
                            );
                          } catch (e) {
                            print('Error: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.exchangeColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: Colors.white),
                        label: const Text('채팅으로 교환 제안하기',
                            style:
                                TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateExchangeSheet extends StatefulWidget {
  const _CreateExchangeSheet();

  @override
  State<_CreateExchangeSheet> createState() => _CreateExchangeSheetState();
}

class _CreateExchangeSheetState extends State<_CreateExchangeSheet> {
  final _offerController = TextEditingController();
  final _wantController = TextEditingController();
  final _descController = TextEditingController();
  bool _isUploading = false;
  final _meetingPlaceController = TextEditingController();

  @override
  void dispose() {
    _offerController.dispose();
    _wantController.dispose();
    _descController.dispose();
    _meetingPlaceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_offerController.text.trim().isEmpty ||
        _wantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📦 드릴 물건과 🙏 원하는 물건을 모두 적어주세요!')),
      );
      return;
    }
    setState(() => _isUploading = true);

    try {
      final userStore = UserStoreProvider.of(context);

      await FirebaseFirestore.instance.collection('posts').add({
        'type': 'exchange',
        'title': '${_offerController.text} 교환해요',
        'description': _descController.text.trim(),
        'offerItem': _offerController.text.trim(),
        'wantItem': _wantController.text.trim(),
        'status': ExchangeStatus.open.name,
        'authorName': userStore.name,
        'authorUid': userStore.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'location': userStore.location,
        'meetingPlace': _meetingPlaceController.text.trim(),
      });

      // 새 글 알림 ㅡ 같은 동네 사람들한테 알림
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
        type: 'exchange',
        title: '🔄 새 물물교환 글이 올라왔어요',
        body:
            '${userStore.location} • ${_offerController.text.trim()} ↔ ${_wantController.text.trim()}',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 교환 게시글이 등록되었습니다!')),
        );
      }
    } catch (e) {
      print('등록 실패: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(bottom: bottomInset),
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
                color: AppColors.exchangeColorLight,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('물물교환 올리기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('내가 제공할 물건',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _offerController,
                      decoration: InputDecoration(
                          hintText: '예) 신라면 5봉지', prefixText: '📦 ')),
                  const SizedBox(height: 16),
                  const Text('원하는 물건',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _wantController,
                      decoration: InputDecoration(
                          hintText: '예) 즉석밥 5개', prefixText: '🙏 ')),
                  const SizedBox(height: 16),
                  const Text('거래 희망 장소',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  const Text('거래하고 싶은 장소를 미리 정해두세요',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _meetingPlaceController,
                    decoration: const InputDecoration(
                      hintText: '예) 안암역 2번 출구',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('설명 (선택)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration:
                        InputDecoration(hintText: '물건 상태나 교환 조건을 자유롭게 적어주세요'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        print("버튼 클릭됨!"); // 이게 안 찍히면 위젯 계층 구조 문제
                        _submit();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.exchangeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('등록하기', style: TextStyle(fontSize: 16)),
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

// ── 물물교환 수정 시트 ─────────────────────────────────────────
class _EditExchangeSheet extends StatefulWidget {
  final ExchangePost post;
  const _EditExchangeSheet({required this.post});

  @override
  State<_EditExchangeSheet> createState() => _EditExchangeSheetState();
}

class _EditExchangeSheetState extends State<_EditExchangeSheet> {
  late final TextEditingController _offerController;
  late final TextEditingController _wantController;
  late final TextEditingController _descController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _offerController = TextEditingController(text: widget.post.offerItem);
    _wantController = TextEditingController(text: widget.post.wantItem);
    _descController = TextEditingController(text: widget.post.description);
  }

  @override
  void dispose() {
    _offerController.dispose();
    _wantController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_offerController.text.trim().isEmpty ||
        _wantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('드릴 물건과 원하는 물건을 입력해주세요.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({
        'offerItem': _offerController.text.trim(),
        'wantItem': _wantController.text.trim(),
        'title': '${_offerController.text.trim()} 교환해요',
        'description': _descController.text.trim(),
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
      height: MediaQuery.of(context).size.height * 0.7,
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
                color: AppColors.exchangeColorLight,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('물물교환 수정',
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
                  const Text('📦 드릴 물건',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _offerController,
                      decoration: const InputDecoration(hintText: '예) 라면 5봉지')),
                  const SizedBox(height: 16),
                  const Text('🙏 원하는 물건',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _wantController,
                      decoration: const InputDecoration(hintText: '예) 세제')),
                  const SizedBox(height: 16),
                  const Text('설명 (선택)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(hintText: '추가 설명을 입력해주세요.')),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.exchangeColor,
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
