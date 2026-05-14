import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/user_store.dart';
import '../widgets/common_widgets.dart';

// ── 카테고리 상수 ───────────────────────────────────────────────
const _kReviewCategories = [
  '소음', '청결도', '위치', '집주인', '가격', '수압', '단열', '채광',
];

// ── 메인 화면 ──────────────────────────────────────────────────
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = UserStoreProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('원룸 솔직 리뷰'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.reviewColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '${store.points}P',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.reviewColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWriteSheet(context),
        backgroundColor: AppColors.reviewColor,
        icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
        label: const Text('리뷰 작성하기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // 포인트 안내 배너
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.reviewColor.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.05),
              ]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('🏠 실거주자 리뷰',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('광고 없는 솔직한 원룸 정보\n리뷰 작성 시 +30P 적립!',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                    ],
                  ),
                ),
                const _PointGuide(),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 검색바
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: '주소 또는 키워드(예: 신축, 원룸 등)로 검색',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textHint),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.reviewColor, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 리뷰 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('데이터를 불러오지 못했습니다.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final filtered = _searchQuery.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final q = _searchQuery.toLowerCase();
                        return (data['buildingName'] ?? '').toString().toLowerCase().contains(q) ||
                            (data['address'] ?? '').toString().toLowerCase().contains(q) ||
                            (data['reviewText'] ?? '').toString().toLowerCase().contains(q);
                      }).toList();

                if (filtered.isEmpty) {
                  return _searchQuery.isEmpty
                      ? const EmptyState(
                          emoji: '🏠',
                          title: '아직 리뷰가 없어요',
                          subtitle: '첫 번째 원룸 리뷰를 작성해보세요!')
                      : EmptyState(
                          emoji: '🔍',
                          title: '검색 결과가 없어요',
                          subtitle: '"$_searchQuery"에 해당하는 리뷰가 없습니다.');
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final data = doc.data() as Map<String, dynamic>;

                    // 태그 복원 + 정렬 (긍정 먼저)
                    final rawTags = (data['tags'] as List<dynamic>? ?? []);
                    final tags = rawTags
                        .map((t) => ReviewTag(
                              label: t['label'] ?? '',
                              isPositive: t['isPositive'] ?? true,
                            ))
                        .toList()
                      ..sort((a, b) {
                        if (a.isPositive && !b.isPositive) return -1;
                        if (!a.isPositive && b.isPositive) return 1;
                        return 0;
                      });

                    final unlockedBy = List<String>.from(data['unlockedBy'] ?? []);
                    final isUnlocked = unlockedBy.contains(store.uid) ||
                        data['authorUid'] == store.uid;

                    final review = RoomReview(
                      id: doc.id,
                      buildingName: data['buildingName'] ?? '',
                      address: data['address'] ?? '',
                      rating: (data['rating'] ?? 3.0).toDouble(),
                      summaryText: data['reviewText'] ?? '',
                      tags: tags,
                      reviewCount: 1,
                      isUnlocked: isUnlocked,
                      unlockPoints: 10,
                      authorName: data['authorName'] ?? '',
                      authorUid: data['authorUid'] ?? '',
                      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    );

                    return _ReviewCard(
                      review: review,
                      onUnlockConfirmed: () async {
                        if (store.uid.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('다시 앱을 시작한 후 이용해주세요.')),
                          );
                          return;
                        }
                        if (store.points < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('포인트가 부족해요. 리뷰를 작성해서 포인트를 적립하세요!')),
                          );
                          return;
                        }
                        try {
                          final firestore = FirebaseFirestore.instance;
                          await firestore.runTransaction((tx) async {
                            final userRef =
                                firestore.collection('users').doc(store.uid);
                            final userSnap = await tx.get(userRef);
                            final current =
                                (userSnap.data()?['points'] ?? 0) as int;
                            if (current < 10) throw '포인트가 부족합니다.';
                            tx.update(userRef, {'points': current - 10});
                            tx.update(
                              firestore.collection('reviews').doc(doc.id),
                              {'unlockedBy': FieldValue.arrayUnion([store.uid])},
                            );
                          });
                          store.setPoints(store.points - 10);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ 리뷰가 잠금 해제되었습니다!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('오류: $e')));
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showWriteSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(messenger: messenger),
    );
  }
}

// ── 포인트 안내 위젯 ───────────────────────────────────────────
class _PointGuide extends StatelessWidget {
  const _PointGuide();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _PointRow('리뷰 작성', '+30P'),
        _PointRow('광고 시청', '+10P'),
        _PointRow('열람', '-10P'),
      ],
    );
  }

  Widget _PointRow(String label, String point) {
    final isEarn = point.startsWith('+');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Text(point,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isEarn ? AppColors.success : AppColors.error,
              )),
        ],
      ),
    );
  }
}

// ── 리뷰 카드 ─────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final RoomReview review;
  final Future<void> Function() onUnlockConfirmed;

  const _ReviewCard({required this.review, required this.onUnlockConfirmed});

  @override
  Widget build(BuildContext context) {
    final store = UserStoreProvider.of(context);
    final isAuthor = store.uid.isNotEmpty &&
        store.uid == review.authorUid;

    return GestureDetector(
      onTap: () {
        if (!review.isUnlocked) {
          _showUnlockDialog(context);
        } else {
          _showDetail(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAuthor
              ? AppColors.reviewColor.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAuthor
                ? AppColors.reviewColor.withOpacity(0.35)
                : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.buildingName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(review.address,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StarRating(rating: review.rating),
                    const SizedBox(height: 4),
                    Text('${review.rating.toStringAsFixed(1)}점',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (review.isUnlocked)
              Text(
                review.summaryText,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              )
            else
              Stack(
                children: [
                  Text(
                    review.summaryText,
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.surface.withOpacity(0),
                            AppColors.surface.withOpacity(0.9),
                            AppColors.surface,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                if (isAuthor)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _showEditSheet(context),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('수정',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.reviewColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  )
                else if (!review.isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.reviewColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 13, color: AppColors.reviewColor),
                        const SizedBox(width: 4),
                        Text('${review.unlockPoints}P로 열람',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.reviewColor)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditReviewSheet(review: review),
    );
  }

  Future<void> _deleteReview(BuildContext context) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('리뷰 삭제'),
            content: const Text('정말 이 리뷰를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('삭제',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(review.id)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('리뷰가 삭제되었습니다.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }

  void _showUnlockDialog(BuildContext context) {
    final store = UserStoreProvider.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('리뷰 열람', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏠', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              '${review.buildingName}의\n심층 리뷰를 열람할까요?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.reviewColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${review.unlockPoints}P 사용 (보유: ${store.points}P)',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.reviewColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onUnlockConfirmed();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.reviewColor),
            child: const Text('열람하기'),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(review.buildingName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(review.address,
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
              const SizedBox(height: 12),
              Row(children: [
                StarRating(rating: review.rating, size: 18),
                const SizedBox(width: 8),
                Text('${review.rating.toStringAsFixed(1)}점',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              if (review.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: review.tags
                      .map((t) => TagBadge(
                            label: t.isPositive ? '✓ ${t.label}' : '✗ ${t.label}',
                            color: t.isPositive ? AppColors.success : AppColors.error,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(review.summaryText,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 리뷰 작성 시트 ────────────────────────────────────────────
class _WriteReviewSheet extends StatefulWidget {
  final ScaffoldMessengerState messenger;
  const _WriteReviewSheet({required this.messenger});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  double _rating = 3.0;
  bool _isSubmitting = false;
  final _buildingController = TextEditingController();
  final _addressController = TextEditingController();
  final _reviewController = TextEditingController();

  // 카테고리별 평가: null = 미선택, 'good' | 'normal' | 'bad'
  final Map<String, String?> _ratings = {
    for (final c in _kReviewCategories) c: null,
  };

  @override
  void dispose() {
    _buildingController.dispose();
    _addressController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인', style: TextStyle(color: AppColors.reviewColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final reviewText = _reviewController.text.trim();

    if (_buildingController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showErrorDialog('건물명과 주소를 입력해주세요.');
      return;
    }

    // 8개 카테고리 전부 선택 필수
    final unselected = _kReviewCategories
        .where((c) => _ratings[c] == null)
        .toList();
    if (unselected.isNotEmpty) {
      _showErrorDialog('항목별 평가를 전부 선택해 주세요.');
      return;
    }

    if (reviewText.length < 30) {
      _showErrorDialog('리뷰는 30자 이상 작성해 주세요.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final store = UserStoreProvider.of(context);
      final firestore = FirebaseFirestore.instance;

      // 선택된 평가를 태그로 변환 (좋음 먼저, 나쁨 나중)
      final tags = <Map<String, dynamic>>[];
      for (final category in _kReviewCategories) {
        final v = _ratings[category];
        if (v == 'good') {
          tags.add({'label': '$category 좋음', 'isPositive': true});
        } else if (v == 'bad') {
          tags.add({'label': '$category 나쁨', 'isPositive': false});
        }
        // 보통/미선택은 태그 안 붙임
      }
      // 긍정 먼저 정렬
      tags.sort((a, b) {
        final aPos = a['isPositive'] as bool;
        final bPos = b['isPositive'] as bool;
        if (aPos && !bPos) return -1;
        if (!aPos && bPos) return 1;
        return 0;
      });

      // Firestore에 리뷰 저장
      await firestore.collection('reviews').add({
        'buildingName': _buildingController.text.trim(),
        'address': _addressController.text.trim(),
        'rating': _rating,
        'reviewText': reviewText,
        'authorName': store.name,
        'authorUid': store.uid,
        'tags': tags,
        'unlockedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 포인트 +30P (uid가 있는 경우만)
      if (store.uid.isNotEmpty) {
        await firestore
            .collection('users')
            .doc(store.uid)
            .update({'points': FieldValue.increment(30)});
        store.setPoints(store.points + 30);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.messenger.showSnackBar(
          const SnackBar(content: Text('✅ 리뷰 작성 완료! +30P 적립되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        widget.messenger
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('리뷰 작성하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 건물명
                  const Text('건물명',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _buildingController,
                    decoration: const InputDecoration(
                        hintText: '예) 안암 원룸, 행복빌라'),
                  ),
                  const SizedBox(height: 16),
                  // 주소
                  const Text('주소',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        hintText: '예) 서울 성북구 안암동 12-5'),
                  ),
                  const SizedBox(height: 16),
                  // 별점
                  const Text('별점',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _rating,
                          min: 1, max: 5, divisions: 8,
                          activeColor: AppColors.accent,
                          onChanged: (v) => setState(() => _rating = v),
                        ),
                      ),
                      Text('${_rating.toStringAsFixed(1)}점',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 항목별 평가
                  const Text('항목별 평가',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  const Text('모든 항목을 선택해야 등록할 수 있어요',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  const SizedBox(height: 12),
                  ..._kReviewCategories.map((category) {
                    return _CategoryRow(
                      category: category,
                      selected: _ratings[category],
                      onChanged: (v) =>
                          setState(() => _ratings[category] = v),
                    );
                  }),
                  const SizedBox(height: 8),
                  // 솔직 리뷰
                  const Text('솔직 리뷰',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '30자 이상 작성해 주세요.',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      counterText:
                          '${_reviewController.text.length}자',
                      counterStyle: TextStyle(
                        fontSize: 12,
                        color: _reviewController.text.length >= 30
                            ? AppColors.success
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.reviewColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.monetization_on,
                            color: AppColors.reviewColor, size: 18),
                        SizedBox(width: 8),
                        Text('리뷰 작성 완료 시 +30P 적립!',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.reviewColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.reviewColor,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('리뷰 등록하기',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 항목별 평가 행 ─────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final String category;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryRow({
    required this.category,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(category,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                _RatingChip(
                  label: '좋음',
                  value: 'good',
                  selected: selected,
                  selectedColor: AppColors.success,
                  onTap: () => onChanged(selected == 'good' ? null : 'good'),
                ),
                const SizedBox(width: 6),
                _RatingChip(
                  label: '보통',
                  value: 'normal',
                  selected: selected,
                  selectedColor: AppColors.textSecondary,
                  onTap: () => onChanged(selected == 'normal' ? null : 'normal'),
                ),
                const SizedBox(width: 6),
                _RatingChip(
                  label: '나쁨',
                  value: 'bad',
                  selected: selected,
                  selectedColor: AppColors.error,
                  onTap: () => onChanged(selected == 'bad' ? null : 'bad'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _RatingChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.12) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? selectedColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── 리뷰 수정 시트 ────────────────────────────────────────────
class _EditReviewSheet extends StatefulWidget {
  final RoomReview review;
  const _EditReviewSheet({required this.review});

  @override
  State<_EditReviewSheet> createState() => _EditReviewSheetState();
}

class _EditReviewSheetState extends State<_EditReviewSheet> {
  late final TextEditingController _buildingController;
  late final TextEditingController _addressController;
  late final TextEditingController _reviewController;
  late double _rating;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _buildingController =
        TextEditingController(text: widget.review.buildingName);
    _addressController = TextEditingController(text: widget.review.address);
    _reviewController = TextEditingController(text: widget.review.summaryText);
    _rating = widget.review.rating;
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _addressController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_buildingController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text('건물명과 주소를 입력해주세요.',
              style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인',
                    style: TextStyle(color: AppColors.reviewColor))),
          ],
        ),
      );
      return;
    }
    if (_reviewController.text.trim().length < 30) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text('리뷰는 30자 이상 작성해 주세요.',
              style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인',
                    style: TextStyle(color: AppColors.reviewColor))),
          ],
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.review.id)
          .update({
        'buildingName': _buildingController.text.trim(),
        'address': _addressController.text.trim(),
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ 수정되었습니다.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('수정 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
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
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('리뷰 수정',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('건물명',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _buildingController,
                    decoration:
                        const InputDecoration(hintText: '예) 안암 원룸, 행복빌라'),
                  ),
                  const SizedBox(height: 16),
                  const Text('주소',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        hintText: '예) 서울 성북구 안암동 12-5'),
                  ),
                  const SizedBox(height: 16),
                  const Text('별점',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _rating,
                          min: 1,
                          max: 5,
                          divisions: 8,
                          activeColor: AppColors.accent,
                          onChanged: (v) => setState(() => _rating = v),
                        ),
                      ),
                      Text('${_rating.toStringAsFixed(1)}점',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('솔직 리뷰',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '30자 이상 작성해 주세요.',
                      hintStyle:
                          const TextStyle(color: AppColors.textHint),
                      counterText:
                          '${_reviewController.text.length}자',
                      counterStyle: TextStyle(
                        fontSize: 12,
                        color: _reviewController.text.length >= 30
                            ? AppColors.success
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.reviewColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('수정 완료',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
