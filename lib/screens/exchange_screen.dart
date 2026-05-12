import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gatchi_sapsida/models/user_store.dart';
import 'package:gatchi_sapsida/screens/chat_list_screen.dart';
import 'package:gatchi_sapsida/utils/storage_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';

class ExchangeScreen extends StatelessWidget {
  const ExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('물물교환'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
                  AppColors.exchangeColor.withOpacity(0.1),
                  AppColors.exchangeColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.exchangeColor.withOpacity(0.2)),
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

                  if (docs.isEmpty) {
                    return const EmptyState(
                      emoji: '🔄',
                      title: '등록된 교환글이 없어요',
                      subtitle: '안 쓰는 물건을 이웃과 바꿔보세요!',
                    );
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;

                      return _ExchangeCard(
                        post: ExchangePost(
                          id: docs[i].id,
                          title: data['title'] ?? '',
                          description: data['description'] ?? '',
                          offerItem: data['offerItem'] ?? '',
                          wantItem: data['wantItem'] ?? '',
                          imageUrl: data['imageUrl'] ?? '',
                          walkMinutes: 5, // 임시값
                          location: data['location'] ?? '안암동',
                          authorName: data['authorName'] ?? '익명',
                          createdAt: (data['createdAt'] as Timestamp).toDate(),
                          status: data['status'] == 'completed'
                              ? ExchangeStatus.done
                              : ExchangeStatus.open, // 임시값
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
    final bool isAuthor = widget.post.authorName == userStore.name;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TagBadge(label: _statusLabel, color: _statusColor),
                const Spacer(),
                WalkBadge(minutes: widget.post.walkMinutes),
                if (isAuthor)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textHint, size: 20),
                    onSelected: (value) {
                      if (value == 'complete') {
                        _completeExchange(context, widget.post.id);
                      } else if (value == 'delete') {
                        _showDeleteConfirm(context, widget.post);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text('교환 완료로 변경'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child:
                            Text('삭제하기', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
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
                      color: AppColors.exchangeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.swap_horiz,
                          color: AppColors.exchangeColor, size: 20),
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
      height: MediaQuery.of(context).size.height * 0.6,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final userStore = UserStoreProvider.of(context);
                        final firestore = FirebaseFirestore.instance;

                        try {
                          final String chatId = "${post.id}_${userStore.name}";

                          await firestore.runTransaction((transaction) async {
                            DocumentReference postRef =
                                firestore.collection('posts').doc(post.id);

                            transaction.update(postRef, {'status': 'chatting'});

                            DocumentReference chatRef =
                                firestore.collection('chatRooms').doc(chatId);
                            transaction.set(chatRef, {
                              'id': chatId,
                              'title': '${post.offerItem} ↔ ${post.wantItem}',
                              'lastMessage': '물물교환 채팅이 시작되었습니다.',
                              'lastMessageTime': FieldValue.serverTimestamp(),
                              'unreadCount': 0,
                              'type': 'exchange',
                              'members': [post.authorName, userStore.name],
                              'avatarEmoji': '🔄',
                            });

                            DocumentReference msgRef =
                                chatRef.collection('messages').doc();
                            transaction.set(msgRef, {
                              'text': '물물교환 채팅방에 입장하셨습니다.\n📍 일정을 정해보아요!',
                              'senderId': 'system',
                              'isMe': false,
                              'isSystem': true,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                          });

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
                          style: TextStyle(fontSize: 15, color: Colors.white)),
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
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _offerController.dispose();
    _wantController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isUploading = true);
    if (_offerController.text.trim().isEmpty ||
        _wantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📦 드릴 물건과 🙏 원하는 물건을 모두 적어주세요!')),
      );
      return;
    }
    setState(() => _isUploading = true);

    try {
      String imageUrl = '';
      if (_selectedFile != null) {
        try {
          print("이미지 업로드 중...");
          imageUrl =
              await StorageService.uploadPostImage('exchange', _selectedFile!);
          print("업로드 성공: $imageUrl");
        } catch (e) {
          print("이미지 업로드 실패(건너뜀): $e");
          // 업로드 실패해도 글은 써지도록 imageUrl을 빈 값으로 유지
        }
      }

      final userStore = UserStoreProvider.of(context);

      await FirebaseFirestore.instance.collection('posts').add({
        'type': 'exchange',
        'title': '${_offerController.text} 교환해요',
        'description': _descController.text.trim(),
        'offerItem': _offerController.text.trim(),
        'wantItem': _wantController.text.trim(),
        'imageUrl': imageUrl,
        'status': ExchangeStatus.open.name,
        'authorName': userStore.name,
        'createdAt': FieldValue.serverTimestamp(),
        'location': userStore.location,
      });

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
                color: AppColors.divider,
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
                  ImagePickerModule(
                    label: '물건 상태가 잘 보이게 찍어주세요!',
                    onImageSelected: (file) {
                      setState(() {
                        _selectedFile = file;
                      });
                    },
                  ),
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
