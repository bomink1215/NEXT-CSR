import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gatchi_sapsida/main.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static const _vapidKey =
      'BOA6vEeblySOlXQBNjHoOrUU06vSyZE64dtFC0Tfn_hIBcLm2ODxx7CBNEkjpVCBHZmof_2aLSjnl0QcBNU1sYQ';

  // FCM 토큰 저장
  static Future<void> saveFcmToken(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = kIsWeb
          ? await FirebaseMessaging.instance.getToken(vapidKey: _vapidKey)
          : await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _db.collection('users').doc(uid).update({'fcmToken': token});

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(uid).update({'fcmToken': newToken});
      });
    } catch (_) {}
  }

  // 포그라운드 알림 표시 설정
  static void setupForegroundNotification() {
    if (kIsWeb) return; // 웹은 서비스워커에서 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gatchi_channel',
            '같이삽시다 알림',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

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

    await _sendFcmToUser(toUid: toUid, title: title, body: body);
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

    for (final uid in toUids) {
      await _sendFcmToUser(toUid: uid, title: title, body: body);
    }
  }

  // FCM 전송 큐에 추가
  static Future<void> _sendFcmToUser({
    required String toUid,
    required String title,
    required String body,
  }) async {
    final userDoc = await _db.collection('users').doc(toUid).get();
    final token = userDoc.data()?['fcmToken'] as String?;
    if (token == null || token.isEmpty) return;

    await _db.collection('fcmQueue').add({
      'token': token,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}