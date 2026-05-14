import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/user_store.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = UserStoreProvider.of(context).uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .doc(uid)
              .collection('items')
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snap) {
            final unread = snap.data?.docs.length ?? 0;
            return Row(
              children: [
                const Text('알림'),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .doc(uid)
                .collection('items')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snap) {
              final hasUnread = (snap.data?.docs.length ?? 0) > 0;
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllRead(uid),
                child: const Text(
                  '모두 읽음',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _buildEmpty();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final n = AppNotification(
                id: docs[i].id,
                type: NotificationType.values.firstWhere(
                  (e) => e.name == (data['type'] ?? 'system'),
                  orElse: () => NotificationType.system,
                ),
                title: data['title'] ?? '',
                body: data['body'] ?? '',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                isRead: data['isRead'] ?? false,
              );
              return _NotificationTile(
                notification: n,
                postId: data['postId'] as String? ?? '',
                onTap: () async {
                  await _markRead(uid, docs[i].id);
                  if (n.title.contains('총대를 평가') &&
                      context.mounted &&
                      (data['postId'] as String? ?? '').isNotEmpty) {
                    _showRatingDialog(
                      context,
                      uid,
                      data['postId'] as String,
                      n.body,
                    );
                  }
                },
                onDismiss: () => _delete(uid, docs[i].id),
              );
            },
          );
        },
      ),
    );
  }

  void _showRatingDialog(
      BuildContext context, String uid, String postId, String body) {
    showDialog(
      context: context,
      builder: (ctx) => _RatingDialog(
        uid: uid,
        postId: postId,
        body: body,
      ),
    );
  }

  Future<void> _markRead(String uid, String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(docId)
        .update({'isRead': true});
  }

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _delete(String uid, String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(docId)
        .delete();
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔔', style: TextStyle(fontSize: 52)),
          SizedBox(height: 16),
          Text('알림이 없어요',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            '공동구매, 모임, 교환 소식이 오면\n여기서 알려드릴게요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── 별점 다이얼로그 ───────────────────────────────────────────
class _RatingDialog extends StatefulWidget {
  final String uid;
  final String postId;
  final String body;

  const _RatingDialog({
    required this.uid,
    required this.postId,
    required this.body,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double _rating = 0;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해주세요.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final postSnap =
          await firestore.collection('posts').doc(widget.postId).get();
      if (!postSnap.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final data = postSnap.data() as Map<String, dynamic>;
      final ratings = Map<String, dynamic>.from(data['ratings'] ?? {});
      if (ratings.containsKey(widget.uid)) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 별점을 부여했어요.')),
          );
        }
        return;
      }

      ratings[widget.uid] = _rating;
      final maxParticipants = (data['maxParticipants'] ?? 2) as int;
      final authorUid = data['authorUid'] as String? ?? '';
      final expectedRaters = maxParticipants - 1;
      final allRated = ratings.length >= expectedRaters;

      await firestore.collection('posts').doc(widget.postId).update({
        'ratings': ratings,
        if (allRated) 'ratingCompleted': true,
      });

      if (allRated && authorUid.isNotEmpty) {
        final avg = ratings.values
                .map((v) => (v as num).toDouble())
                .reduce((a, b) => a + b) /
            ratings.length;

        int points = 0;
        if (avg >= 5.0) points = 30;
        else if (avg >= 4.0) points = 20;
        else if (avg >= 3.0) points = 10;
        else points = 0;

        if (points > 0) {
          await firestore.runTransaction((tx) async {
            final userRef = firestore.collection('users').doc(authorUid);
            final userSnap = await tx.get(userRef);
            final currentPoints = (userSnap.data()?['points'] ?? 0) as int;
            final totalSum =
                ((userSnap.data()?['totalRatingSum'] ?? 0) as num).toDouble();
            final totalCount =
                (userSnap.data()?['totalRatingCount'] ?? 0) as int;
            tx.update(userRef, {
              'points': currentPoints + points,
              'totalRatingSum': totalSum + avg,
              'totalRatingCount': totalCount + 1,
              'avgRating': (totalSum + avg) / (totalCount + 1),
            });
            tx.update(
              firestore.collection('posts').doc(widget.postId),
              {'ratingAvg': avg},
            );
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 별점이 등록되었습니다! 감사합니다.')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('총대 별점 평가',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            widget.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            _rating == 0 ? '별점을 선택해주세요' : '${_rating.toInt()}점',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _rating == 0
                    ? AppColors.textHint
                    : AppColors.primary),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () =>
                    setState(() => _rating = (index + 1).toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    index < _rating.toInt()
                        ? Icons.star
                        : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 36,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('나중에',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('평가하기'),
        ),
      ],
    );
  }
}

// ─── 알림 타일 ────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String postId;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.postId,
    required this.onTap,
    required this.onDismiss,
  });

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.groupBuy:
        return AppColors.buyColor;
      case NotificationType.exchange:
        return AppColors.exchangeColor;
      case NotificationType.gather:
        return AppColors.gatherColor;
      case NotificationType.review:
        return AppColors.reviewColor;
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }

  String get _typeLabel {
    switch (notification.type) {
      case NotificationType.groupBuy:
        return '공동구매';
      case NotificationType.exchange:
        return '물물교환';
      case NotificationType.gather:
        return '모임';
      case NotificationType.review:
        return '리뷰';
      case NotificationType.system:
        return '시스템';
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primaryLight.withOpacity(0.35),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    notification.title.split(' ').first,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _typeColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.title.replaceFirst(
                        notification.title.split(' ').first + ' ',
                        '',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
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
        ),
      ),
    );
  }
}
