const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

// fcmQueue 처리 (기존)
exports.sendFcmOnQueue = onDocumentCreated(
  { document: 'fcmQueue/{docId}', region: 'asia-northeast3' },
  async (event) => {
    const data = event.data.data();
    const { token, title, body } = data;

    const message = {
      token,
      notification: { title, body },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    };

    try {
      await admin.messaging().send(message);
      await event.data.ref.delete();
      console.log('✅ FCM 전송 성공');
    } catch (e) {
      console.error('❌ FCM 전송 실패:', e);
    }
  }
);

// 채팅 메시지 푸시 알림 (새로 추가)
exports.sendChatNotification = onDocumentCreated(
  { document: 'chatRooms/{roomId}/messages/{msgId}', region: 'asia-northeast3' },
  async (event) => {
    const msg = event.data.data();
    const roomId = event.params.roomId;

    // 시스템 메시지 무시
    if (msg.senderName === 'system') return;
    if (!msg.senderUid) return;

    // 채팅방 멤버 가져오기
    const roomSnap = await admin.firestore()
        .collection('chatRooms').doc(roomId).get();
    if (!roomSnap.exists) return;

    const roomData = roomSnap.data();
    const members = roomData.members || [];
    const title = roomData.title || '새 메시지';

    // 보낸 사람 제외한 멤버들에게 알림
    for (const uid of members) {
      if (uid === msg.senderUid) continue;

      const userSnap = await admin.firestore()
          .collection('users').doc(uid).get();
      if (!userSnap.exists) continue;

      const token = userSnap.data().fcmToken;
      if (!token) continue;

      try {
        await admin.messaging().send({
          token,
          notification: {
            title,
            body: `${msg.senderName}: ${msg.text}`,
          },
          android: { priority: 'high' },
          apns: { payload: { aps: { sound: 'default' } } },
        });
        console.log(`✅ 채팅 알림 전송 성공 → ${uid}`);
      } catch (e) {
        console.error(`❌ 채팅 알림 전송 실패 → ${uid}:`, e);
      }
    }
  }
);