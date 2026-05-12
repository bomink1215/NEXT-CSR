import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gatchi_sapsida/models/user_store.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';
import './chat_list_screen.dart';

class GatherScreen extends StatefulWidget {
  const GatherScreen({super.key});

  @override
  State<GatherScreen> createState() => _GatherScreenState();
}

class _GatherScreenState extends State<GatherScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('모임 찾기')),
      floatingActionButton: FloatingActionButton.extended(
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

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
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
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _QuickCategory('🍜', '혼밥 메이트'),
                            _QuickCategory('🚶', '산책'),
                            _QuickCategory('☕', '카페'),
                            _QuickCategory('🎮', '게임'),
                            _QuickCategory('📚', '스터디'),
                            _QuickCategory('🏃', '운동'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('지금 모집 중',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // 2. 데이터가 없을 때 표시할 화면
              if (docs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                      child: Text('주변에 열린 모임이 없어요.\n첫 모임을 만들어보세요! 👥',
                          textAlign: TextAlign.center)),
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

  const _QuickCategory(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _GatherCard extends StatelessWidget {
  final GatherPost post;

  const _GatherCard({required this.post});

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
      case AgeFilter.twenties:
        return '20대';
      case AgeFilter.thirties:
        return '30대';
      case AgeFilter.mixed:
        return '혼합';
    }
  }

  String _timeLabel(DateTime t) {
    final diff = t.difference(DateTime.now());
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 후';
    if (diff.inHours < 24) return '${diff.inHours}시간 후';
    return '${diff.inDays}일 후';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: post.isFull
                ? AppColors.divider
                : AppColors.gatherColor.withOpacity(0.3),
            width: post.isFull ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이모지
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: post.isFull
                    ? AppColors.cardBg
                    : AppColors.gatherColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(post.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (post.isFull)
                        const TagBadge(label: '마감', color: AppColors.error)
                      else
                        TagBadge(
                            label: _timeLabel(post.meetTime),
                            color: AppColors.gatherColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.description,
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
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          post.place,
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
                    children: [
                      TagBadge(
                          label: _genderLabel(post.genderFilter),
                          color: AppColors.textSecondary),
                      TagBadge(
                          label: _ageLabel(post.ageFilter),
                          color: AppColors.textSecondary),
                      TagBadge(
                        label: '${post.currentMembers}/${post.maxMembers}명',
                        color: post.isFull
                            ? AppColors.error
                            : AppColors.gatherColor,
                      ),
                    ],
                  ),
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
      builder: (_) => _GatherDetail(post: post),
    );
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
      case AgeFilter.twenties:
        return '20대';
      case AgeFilter.thirties:
        return '30대';
      case AgeFilter.mixed:
        return '혼합';
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

    try {
      await firestore.runTransaction((transaction) async {
        final postRef = firestore.collection('posts').doc(post.id);
        final snapshot = await transaction.get(postRef);

        if (!snapshot.exists) return;

        List<dynamic> members = List.from(snapshot.data()?['members'] ?? []);
        int current = snapshot.data()?['currentMembers'] ?? 0;
        int max = snapshot.data()?['maxMembers'] ?? 0;

        // 중복 참여 및 정원 체크
        if (members.contains(userStore.name)) throw '이미 참여 중인 모임입니다.';
        if (current >= max) throw '이미 정원이 마감되었습니다.';

        // 1. 게시글 인원 업데이트
        transaction.update(postRef, {
          'currentMembers': current + 1,
          'members': FieldValue.arrayUnion([userStore.name]),
        });

        // 2. 그룹 채팅방 생성/업데이트
        // 채팅방 ID를 postId와 동일하게 설정하여 참여자들을 한 곳에 모음
        final chatRef = firestore.collection('chatRooms').doc(post.id);
        transaction.set(
            chatRef,
            {
              'postId': post.id,
              'roomTitle': post.title,
              'members': FieldValue.arrayUnion([userStore.name]),
              'lastMessage': '${userStore.name}님이 합류했습니다!',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'type': 'gathering',
            },
            SetOptions(merge: true));
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 참여 완료! 채팅방으로 이동합니다.')));

        // 참여 성공 시 해당 채팅방으로 즉시 이동
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                room: ChatRoom(
                  id: post.id,
                  title: post.title,
                  lastMessage: '',
                  lastMessageTime: DateTime.now(),
                  unreadCount: 0,
                  avatarEmoji: post.emoji,
                  type: ChatRoomType.gather,
                  members: [],
                ),
              ),
            ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetStr =
        '${post.meetTime.month}/${post.meetTime.day} ${post.meetTime.hour}:${post.meetTime.minute.toString().padLeft(2, '0')}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
            child: Padding(
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
                  const Spacer(),
                  if (!post.isFull)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _onJoinPressed(context, post),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gatherColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.group_add, color: Colors.white),
                        label: const Text('모임 참여하기',
                            style:
                                TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    )
                  else
                    Container(
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
                    ),
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
  GenderFilter _genderFilter = GenderFilter.any;
  AgeFilter _ageFilter = AgeFilter.any;
  int _maxMembers = 2;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _placeController = TextEditingController();

  String _selectedEmoji = '👥'; // 기본 아이콘
  DateTime _selectedDateTime = DateTime.now();

  bool _isUploading = false;

  Future<void> _submitGathering() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final userStore = UserStoreProvider.of(context);
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
        'location': userStore.location,
        'genderFilter': _genderFilter.name,
        'ageFilter': _ageFilter.name,
        'members': [userStore.name],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('chatRooms').doc(postRef.id).set({
        'id': postRef.id,
        'title': _titleController.text.trim(),
        'lastMessage': '모임이 생성되었습니다! 👋',
        'lastMessageTime': FieldValue.serverTimestamp(), // DB 저장용
        'type': 'gather',
        'members': [userStore.name],
        'avatarEmoji': _selectedEmoji,
        'unreadCount': 0,
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
                members: [userStore.name], // Enum 타입 확인 필요
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
                    children: GenderFilter.values.map((f) {
                      final labels = ['성별 무관', '남성만', '여성만'];
                      return GestureDetector(
                        onTap: () => setState(() => _genderFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _genderFilter == f
                                ? AppColors.gatherColor
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _genderFilter == f
                                    ? AppColors.gatherColor
                                    : AppColors.divider),
                          ),
                          child: Text(labels[f.index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _genderFilter == f
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              )),
                        ),
                      );
                    }).toList(),
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
                    children: AgeFilter.values.map((f) {
                      final labels = ['연령 무관', '20대', '30대', '혼합'];
                      return GestureDetector(
                        onTap: () => setState(() => _ageFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ageFilter == f
                                ? AppColors.gatherColor
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _ageFilter == f
                                    ? AppColors.gatherColor
                                    : AppColors.divider),
                          ),
                          child: Text(labels[f.index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _ageFilter == f
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              )),
                        ),
                      );
                    }).toList(),
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
