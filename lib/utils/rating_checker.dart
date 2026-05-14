import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class RatingChecker {
  static Future<void> checkAndComplete() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    // isFull이고 아직 completed 아닌 공동구매 글 조회
    final snap = await firestore
        .collection('posts')
        .where('type', isEqualTo: 'groupBuy')
        .where('isFull', isEqualTo: true)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['status'] == 'completed') continue;

      final deadline = (data['deadline'] as Timestamp?)?.toDate();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final base = deadline ?? createdAt ?? now;
      final autoCompleteAt = base.add(const Duration(days: 7));

      if (now.isAfter(autoCompleteAt)) {
        final ratingDeadline = now.add(const Duration(hours: 24));
        await doc.reference.update({
          'status': 'completed',
          'completedAt': Timestamp.fromDate(now),
          'ratingDeadline': Timestamp.fromDate(ratingDeadline),
          'ratings': {},
          'ratingCompleted': false,
        });

        // 채팅방에서 멤버 목록 가져오기
        final chatSnap =
            await firestore.collection('chatRooms').doc(doc.id).get();
        if (chatSnap.exists) {
          final members = List<String>.from(chatSnap.data()?['members'] ?? []);
          final authorUid = data['authorUid'] as String? ?? '';
          final participants =
              members.where((uid) => uid != authorUid).toList();

          await NotificationService.sendToMany(
            toUids: participants,
            type: 'groupBuy',
            title: '⭐ 총대를 평가해주세요!',
            body: '"${data['title']}" 공동구매가 완료됐어요. 48시간 내에 별점을 남겨주세요.',
            postId: doc.id,
          );
        }
      }
    }

    // 별점 평가 기한(48시간) 지난 것들 포인트 자동 지급
    final completedSnap = await firestore
        .collection('posts')
        .where('type', isEqualTo: 'groupBuy')
        .where('status', isEqualTo: 'completed')
        .where('ratingCompleted', isEqualTo: false)
        .get();

    for (final doc in completedSnap.docs) {
      final data = doc.data();
      final ratingDeadline = (data['ratingDeadline'] as Timestamp?)?.toDate();
      if (ratingDeadline == null) continue;
      if (now.isBefore(ratingDeadline)) continue;

      await _calcAndGivePoints(doc.id, data, firestore);
    }
  }

  static Future<void> _calcAndGivePoints(
    String postId,
    Map<String, dynamic> data,
    FirebaseFirestore firestore,
  ) async {
    final ratings = Map<String, dynamic>.from(data['ratings'] ?? {});
    if (ratings.isEmpty) return;

    final avg = ratings.values
            .map((v) => (v as num).toDouble())
            .reduce((a, b) => a + b) /
        ratings.length;

    // 별점 평균 → 포인트
    int points = 0;
    if (avg >= 5.0) points = 30;
    else if (avg >= 4.0) points = 20;
    else if (avg >= 3.0) points = 10;
    else points = 0;

    final authorUid = data['authorUid'] as String? ?? '';
    if (authorUid.isEmpty || points == 0) {
      await firestore.collection('posts').doc(postId).update({
        'ratingCompleted': true,
        'ratingAvg': avg,
      });
      return;
    }

    // 포인트 지급 + 누적 별점 업데이트
    await firestore.runTransaction((tx) async {
      final userRef = firestore.collection('users').doc(authorUid);
      final userSnap = await tx.get(userRef);
      final currentPoints = (userSnap.data()?['points'] ?? 0) as int;
      final totalSum =
          ((userSnap.data()?['totalRatingSum'] ?? 0) as num).toDouble();
      final totalCount = (userSnap.data()?['totalRatingCount'] ?? 0) as int;

      tx.update(userRef, {
        'points': currentPoints + points,
        'totalRatingSum': totalSum + avg,
        'totalRatingCount': totalCount + 1,
        'avgRating': (totalSum + avg) / (totalCount + 1),
      });

      tx.update(firestore.collection('posts').doc(postId), {
        'ratingCompleted': true,
        'ratingAvg': avg,
      });
    });
  }
}
