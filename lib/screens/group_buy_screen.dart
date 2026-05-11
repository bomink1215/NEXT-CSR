import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_store.dart';
import './chat_list_screen.dart';
import 'package:provider/provider.dart';

class GroupBuyScreen extends StatefulWidget {
  const GroupBuyScreen({super.key});

  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> {
  String _selectedFilter = '전체';
  final List<String> _filters = ['전체', '식료품', '생활용품', '배달음식'];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == '전체'
        ? MockData.groupBuyPosts
        : MockData.groupBuyPosts
            .where((p) => p.category == _selectedFilter)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('공동구매'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.buyColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('글쓰기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // 필터 탭
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                            isSelected ? AppColors.buyColor : AppColors.divider,
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

                final filteredDocs = _selectedFilter == '전체'
                    ? docs
                    : docs
                        .where((doc) => doc['category'] == _selectedFilter)
                        .toList();

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = filteredDocs[i].data() as Map<String, dynamic>;

                    return _GroupBuyCard(
                      post: GroupBuyPost(
                        id: filteredDocs[i].id,
                        title: data['title'] ?? '',
                        category: data['category'] ?? '기타',
                        imageUrl: '', // 필요시 데이터 추가
                        totalPrice: data['totalPrice'] ?? 0,
                        unitPrice: data['unitPrice'] ?? 0,
                        maxParticipants: data['maxParticipants'] ?? 2,
                        currentParticipants: data['currentParticipants'] ?? 1,
                        walkMinutes: 5, // 임시값
                        location: data['location'] ?? '안암동',
                        authorName: data['authorName'] ?? '익명',
                        createdAt: (data['createdAt'] as Timestamp).toDate(),
                        isDelivery: data['category'] == '배달음식',
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

class _GroupBuyCard extends StatelessWidget {
  final GroupBuyPost post;

  const _GroupBuyCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final userStore = UserStoreProvider.of(context);
    final isAuthor = userStore.name.isNotEmpty &&
        userStore.name.trim() == post.authorName.trim();

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: post.isFull ? AppColors.divider : AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TagBadge(
                  label: post.category,
                  color: post.isDelivery
                      ? AppColors.secondary
                      : AppColors.buyColor,
                ),
                const SizedBox(width: 8),
                if (post.isDelivery)
                  TagBadge(label: '🛵 배달소분', color: AppColors.secondary),
                const Spacer(),
                WalkBadge(minutes: post.walkMinutes),
                if (isAuthor)
                  IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      onPressed: () =>
                          _deletePost(context, post.id, post.authorName)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(
                  post.location,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person_outline,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(
                  post.authorName,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ParticipantProgress(
              current: post.currentParticipants,
              max: post.maxParticipants,
              color: AppColors.buyColor,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 ${_formatPrice(post.totalPrice)}원',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '1인 ${_formatPrice(post.unitPrice)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (!post.isFull)
                  ElevatedButton(
                    onPressed: () => _showDetail(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buyColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text('참여하기'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '마감됨',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
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
      WriteBatch batch = firestore.batch();

      batch.delete(firestore.collection('posts').doc(postId));
      batch.delete(firestore.collection('chatRooms').doc(postId));

      await batch.commit();

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupBuyDetail(post: post),
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
    final userStore = UserStoreProvider.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TagBadge(label: post.category, color: AppColors.buyColor),
                      const SizedBox(width: 8),
                      WalkBadge(minutes: post.walkMinutes),
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
                  Text(
                    '📍 ${post.location}  •  👤 ${post.authorName}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem('전체 금액', '${_formatPrice(post.totalPrice)}원'),
                        Container(
                            width: 1,
                            height: 30,
                            color: AppColors.primary.withOpacity(0.2)),
                        _InfoItem('1인 부담', '${_formatPrice(post.unitPrice)}원',
                            highlight: true),
                        Container(
                            width: 1,
                            height: 30,
                            color: AppColors.primary.withOpacity(0.2)),
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
                  const Spacer(),
                  if (!post.isFull)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _handleJoin(context, post);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buyColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            const Text('참여하기', style: TextStyle(fontSize: 16)),
                      ),
                    ),
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
          updatedMembers.add(post.authorName);
        }
        if (!updatedMembers.contains(userStore.name)) {
          updatedMembers.add(userStore.name);
        }

        transaction.update(postRef, {
          'currentParticipants': current + 1,
          'isFull': (current + 1) >= max,
        });

        transaction.set(
            chatRef,
            {
              'postId': post.id,
              'postTitle': post.title,
              'members': updatedMembers,
              'lastMessage': "${userStore.name}님이 참여하셨습니다.",
              'lastMessageTime': FieldValue.serverTimestamp(),
              'type': 'groupBuy',
              'avatarEmoji': '🛒',
              'unreadCount': 0,
            },
            SetOptions(merge: true));

        // 시스템 메시지 추가 (일정 조율 독려)
        transaction.set(chatRef.collection('messages').doc(), {
          'senderId': 'system',
          'text': "${userStore.name}님이 참여했습니다. 일정을 정해보세요!",
          'timestamp': FieldValue.serverTimestamp(),
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
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류: $e')));
    }
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

  @override
  void dispose() {
    _titleController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: const [
                Text('공동구매 글쓰기',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                                    : AppColors.divider),
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
                      decoration:
                          InputDecoration(hintText: '예) 코스트코 두루마리 화장지 30롤')),
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
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        await FirebaseFirestore.instance
                            .collection('posts')
                            .add({
                          'type': 'groupBuy',
                          'title': _titleController.text.trim(),
                          'category': _type,
                          'totalPrice': int.parse(_totalPriceController.text),
                          'unitPrice':
                              int.parse(_totalPriceController.text) ~/ _members,
                          'maxParticipants': _members,
                          'currentParticipants': 1, // 총대 포함
                          'authorId': user.uid,
                          'authorName': UserStoreProvider.of(context).name,
                          'location': UserStoreProvider.of(context).location,
                          'createdAt': FieldValue.serverTimestamp(),
                          'isFull': false,
                        });

                        if (!mounted) return;

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ 공동구매 게시글이 등록되었습니다!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buyColor,
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
