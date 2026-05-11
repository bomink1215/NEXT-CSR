import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('채팅')),
      body: MockData.chatRooms.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💬', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('채팅이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('공동구매, 물물교환, 모임에\n참여하면 채팅이 생겨요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: MockData.chatRooms.length,
              separatorBuilder: (_, __) =>
                  const Divider(indent: 80, height: 1, color: AppColors.divider),
              itemBuilder: (context, i) =>
                  _ChatRoomTile(room: MockData.chatRooms[i]),
            ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;

  const _ChatRoomTile({required this.room});

  Color get _typeColor {
    switch (room.type) {
      case ChatRoomType.groupBuy: return AppColors.buyColor;
      case ChatRoomType.exchange: return AppColors.exchangeColor;
      case ChatRoomType.gather: return AppColors.gatherColor;
    }
  }

  String get _typeLabel {
    switch (room.type) {
      case ChatRoomType.groupBuy: return '공동구매';
      case ChatRoomType.exchange: return '물물교환';
      case ChatRoomType.gather: return '모임';
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
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _typeColor),
            ),
          ),
          Expanded(
            child: Text(
              room.lastMessage,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
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
      MaterialPageRoute(builder: (_) => _ChatScreen(room: room)),
    );
  }
}

// ─── 채팅 화면 ────────────────────────────────────────────────────
class _ChatScreen extends StatefulWidget {
  final ChatRoom room;

  const _ChatScreen({required this.room});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
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
      case ChatRoomType.groupBuy: return '정문 앞 편의점';
      case ChatRoomType.exchange: return '건물 1층 로비';
      case ChatRoomType.gather: return '약속 장소 확인!';
    }
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, isMe: true, time: DateTime.now()));
      _ctrl.clear();
    });
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[_messages.length - 1 - i];
                return _MessageBubble(msg: msg);
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
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

  const _MessageBubble({required this.msg});

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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
        ),
      );
    }

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: msg.isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: msg.isMe ? const Radius.circular(4) : const Radius.circular(16),
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
    );
  }
}
