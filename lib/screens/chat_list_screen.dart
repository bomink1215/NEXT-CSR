import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../models/user_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _selectedFilter = '전체';

  final List<Map<String, String>> _filters = [
    {'label': '전체', 'type': ''},
    {'label': '공동구매', 'type': 'groupBuy'},
    {'label': '물물교환', 'type': 'exchange'},
    {'label': '모임', 'type': 'gather'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('채팅')),
      body: Column(
        children: [
          // 필터 탭
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: _filters.map((f) {
                final isSelected = f['label'] == _selectedFilter;
                Color chipColor;
                switch (f['type']) {
                  case 'groupBuy':
                    chipColor = AppColors.buyColor;
                    break;
                  case 'exchange':
                    chipColor = AppColors.exchangeColor;
                    break;
                  case 'gather':
                    chipColor = AppColors.gatherColor;
                    break;
                  default:
                    chipColor = AppColors.primary;
                }
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f['label']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? chipColor : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? chipColor : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      f['label']!,
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
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .where('members',
                      arrayContains: UserStoreProvider.of(context).uid)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final allRooms = snapshot.data!.docs;
                final selectedType = _filters
                    .firstWhere((f) => f['label'] == _selectedFilter)['type']!;
                final rooms = selectedType.isEmpty
                    ? allRooms
                    : allRooms.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['type'] ?? '') == selectedType;
                      }).toList();

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💬',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == '전체'
                              ? '참여 중인 채팅방이 없어요'
                              : '$_selectedFilter 채팅방이 없어요',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) =>
                      const Divider(indent: 80),
                  itemBuilder: (context, i) {
                    final doc = rooms[i];
                    final room = ChatRoom.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id);
                    return RepaintBoundary(child: _ChatRoomTile(room: room));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;

  const _ChatRoomTile({required this.room});

  Color get _typeColor {
    switch (room.type) {
      case ChatRoomType.groupBuy:
        return AppColors.buyColor;
      case ChatRoomType.exchange:
        return AppColors.exchangeColor;
      case ChatRoomType.gather:
        return AppColors.gatherColor;
    }
  }

  String get _typeLabel {
    switch (room.type) {
      case ChatRoomType.groupBuy:
        return '공동구매';
      case ChatRoomType.exchange:
        return '물물교환';
      case ChatRoomType.gather:
        return '모임';
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _openChat(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _typeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(room.avatarEmoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              room.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeAgo(room.lastMessageTime),
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _typeLabel,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: _typeColor),
            ),
          ),
          Expanded(
            child: Text(
              room.lastMessage,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (room.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${room.unreadCount}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
    );
  }
}

// ─── 채팅 화면 ────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final ChatRoom room;

  const ChatScreen({required this.room});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final List<_Message> _messages = [];

  @override
  void initState() {
    super.initState();
    // 초기 시스템 메시지
    _messages.addAll([
      _Message(
        text: '채팅방에 입장하셨습니다.\n📍 ${_getPlaceHint()} 에서 만나요!',
        isMe: false,
        isSystem: true,
        time: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      _Message(
        text: widget.room.lastMessage,
        isMe: false,
        time: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ]);
  }

  String _getPlaceHint() {
    switch (widget.room.type) {
      case ChatRoomType.groupBuy:
        return '정문 앞 편의점';
      case ChatRoomType.exchange:
        return '건물 1층 로비';
      case ChatRoomType.gather:
        return '약속 장소 확인!';
    }
  }

  Future<void> _confirmComplete(BuildContext context) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('채팅방 종료'),
            content: const Text('채팅방이 삭제됩니다. 완료하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('아니요',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('예'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final firestore = FirebaseFirestore.instance;
      // 물물교환 채팅방이면 해당 게시글을 마감(done) 처리
      if (widget.room.type == ChatRoomType.exchange) {
        final chatDoc = await firestore
            .collection('chatRooms')
            .doc(widget.room.id)
            .get();
        final postId = chatDoc.data()?['postId'] as String?;
        if (postId != null && postId.isNotEmpty) {
          await firestore
              .collection('posts')
              .doc(postId)
              .update({'status': 'done'});
        }
      }
      await firestore.collection('chatRooms').doc(widget.room.id).delete();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('채팅 나가기'),
            content: const Text('채팅방을 나가시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('아니요',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('예',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final store = UserStoreProvider.of(context);
      final firestore = FirebaseFirestore.instance;
      final roomRef =
          firestore.collection('chatRooms').doc(widget.room.id);

      // 시스템 메시지: "<이름>님이 나가셨습니다."
      await roomRef.collection('messages').add({
        'senderName': 'system',
        'text': '${store.name}님이 나가셨습니다.',
        'time': FieldValue.serverTimestamp(),
      });

      // chatRoom members 에서 본인 UID 제거
      await roomRef.update({
        'members': FieldValue.arrayRemove([store.uid]),
        'lastMessage': '${store.name}님이 나가셨습니다.',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // ── 공동구매 채팅방이면 게시글 참여 인원도 감소 ──
      // 채팅방 ID == 게시글 ID 이므로 widget.room.id 를 그대로 사용
      if (widget.room.type == ChatRoomType.groupBuy) {
        await firestore.runTransaction((transaction) async {
          final postRef =
              firestore.collection('posts').doc(widget.room.id);
          final postSnap = await transaction.get(postRef);
          if (postSnap.exists) {
            final data = postSnap.data() as Map<String, dynamic>;
            final current =
                (data['currentParticipants'] as int?) ?? 1;
            final max = (data['maxParticipants'] as int?) ?? 2;
            // 최소 1 (작성자는 항상 남아 있음)
            final newCount = (current - 1).clamp(1, max);
            transaction.update(postRef, {
              'currentParticipants': newCount,
              'isFull': newCount >= max,
            });
          }
        });
      }

      // ── 모임 채팅방이면 게시글 참여 인원 감소 + members 배열에서 UID 제거 ──
      if (widget.room.type == ChatRoomType.gather) {
        await firestore.runTransaction((transaction) async {
          final postRef =
              firestore.collection('posts').doc(widget.room.id);
          final postSnap = await transaction.get(postRef);
          if (postSnap.exists) {
            final data = postSnap.data() as Map<String, dynamic>;
            final current = (data['currentMembers'] as int?) ?? 1;
            final max = (data['maxMembers'] as int?) ?? 2;
            // 최소 1 (작성자는 항상 남아 있음)
            final newCount = (current - 1).clamp(1, max);
            transaction.update(postRef, {
              'currentMembers': newCount,
              'members': FieldValue.arrayRemove([store.uid]),
            });
          }
        });
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final userName = UserStoreProvider.of(context).name;

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.room.id)
        .collection('messages')
        .add({
      'text': text,
      'senderName': userName,
      'time': FieldValue.serverTimestamp(),
      'isSystem': false,
    });
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.room.id)
        .update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.room.title),
        actions: [
          Builder(builder: (ctx) {
            final store = UserStoreProvider.of(ctx);
            final isAuthor =
                store.uid.isNotEmpty && store.uid == widget.room.authorUid;
            if (isAuthor) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ElevatedButton(
                  onPressed: () => _confirmComplete(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('완료',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton(
                onPressed: () => _confirmLeave(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('나가기',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.room.id)
                  .collection('messages')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;

                    final isMe = data['senderName'] ==
                        UserStoreProvider.of(context).name;

                    return _MessageBubble(
                      msg: _Message(
                        text: data['text'] ?? '',
                        isMe: isMe,
                        isSystem: data['senderName'] == 'system',
                        time: (data['time'] as Timestamp?)?.toDate() ??
                            DateTime.now(),
                      ),
                      senderName: data['senderName'],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isMe;
  final bool isSystem;
  final DateTime time;

  _Message({
    required this.text,
    required this.isMe,
    this.isSystem = false,
    required this.time,
  });
}

class _MessageBubble extends StatelessWidget {
  final _Message msg;
  final String? senderName;

  const _MessageBubble({required this.msg, this.senderName});

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary, height: 1.5),
        ),
      );
    }

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!msg.isMe && !msg.isSystem && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                senderName!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: msg.isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: msg.isMe
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: msg.isMe
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              border: msg.isMe ? null : Border.all(color: AppColors.divider),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: msg.isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
