import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  // 알림 1개 생성
  static Future<void> send({
    required String toUid,
    required String type,
    required String title,
    required String body,
    String postId = '',
    String chatRoomId = '',
  }) async {
    if (toUid.isEmpty) return;
    await _db
        .collection('notifications')
        .doc(toUid)
        .collection('items')
        .add({
      'type': type,
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (postId.isNotEmpty) 'postId': postId,
      if (chatRoomId.isNotEmpty) 'chatRoomId': chatRoomId,
    });
  }

  static Future<void> sendToMany({
    required List<String> toUids,
    required String type,
    required String title,
    required String body,
    String postId = '',
    String chatRoomId = '',
  }) async {
    final batch = _db.batch();
    for (final uid in toUids) {
      if (uid.isEmpty) continue;
      final ref = _db
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc();
      batch.set(ref, {
        'type': type,
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (postId.isNotEmpty) 'postId': postId,
        if (chatRoomId.isNotEmpty) 'chatRoomId': chatRoomId,
      });
    }
    await batch.commit();
  }
}