import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../models/user_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('채팅')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .where('members', arrayContains: UserStoreProvider.of(context).name)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final rooms = snapshot.data!.docs;
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(indent: 80),
            itemBuilder: (context, i) {
              final doc = rooms[i];
              final room =
                  ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              return _ChatRoomTile(room: room);
            },
          );
        },
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
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
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
