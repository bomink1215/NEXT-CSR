import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('원룸 솔직 리뷰'),
        actions: [
          // 포인트 표시
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.reviewColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Text('⭐', style: TextStyle(fontSize: 13)),
                SizedBox(width: 4),
                Text(
                  '120P',
                  style: TextStyle(
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
        label: const Text('리뷰 작성하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // 포인트 안내
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.reviewColor.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '🏠 실거주자 리뷰',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '광고 없는 솔직한 원룸 정보\n리뷰 작성 시 +30P 적립!',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
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
              decoration: InputDecoration(
                hintText: '건물명 또는 주소로 검색',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: MockData.roomReviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ReviewCard(review: MockData.roomReviews[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _showWriteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WriteReviewSheet(),
    );
  }
}

class _PointGuide extends StatelessWidget {
  const _PointGuide();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PointRow('리뷰 작성', '+30P'),
        _PointRow('광고 시청', '+10P'),
        _PointRow('열람', '-50P'),
      ],
    );
  }

  Widget _PointRow(String label, String point) {
    final isEarn = point.startsWith('+');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Text(
            point,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isEarn ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final RoomReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
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
                      Text(
                        review.buildingName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.address,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StarRating(rating: review.rating),
                    const SizedBox(height: 4),
                    Text(
                      '${review.rating}점',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 태그들
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.tags.map((tag) {
                return TagBadge(
                  label: tag.isPositive ? '✓ ${tag.label}' : '✗ ${tag.label}',
                  color: tag.isPositive ? AppColors.success : AppColors.error,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 미리보기 텍스트
            if (review.isUnlocked)
              Text(
                review.summaryText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              )
            else
              Stack(
                children: [
                  Text(
                    review.summaryText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.surface.withOpacity(0),
                            AppColors.surface.withOpacity(0.85),
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
                Text(
                  '리뷰 ${review.reviewCount}개',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                if (!review.isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.reviewColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 13, color: AppColors.reviewColor),
                        const SizedBox(width: 4),
                        Text(
                          '${review.unlockPoints}P로 열람',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.reviewColor,
                          ),
                        ),
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

  void _showUnlockDialog(BuildContext context) {
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
                    '${review.unlockPoints}P 사용',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.reviewColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 리뷰가 잠금 해제되었습니다!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.reviewColor),
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
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40, height: 4,
                alignment: Alignment.center,
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(review.buildingName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(review.address, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
              const SizedBox(height: 12),
              Row(children: [StarRating(rating: review.rating, size: 18), const SizedBox(width: 8), Text('${review.rating}점', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 16),
              Wrap(spacing: 6, runSpacing: 6, children: review.tags.map((t) => TagBadge(label: t.isPositive ? '✓ ${t.label}' : '✗ ${t.label}', color: t.isPositive ? AppColors.success : AppColors.error)).toList()),
              const SizedBox(height: 16),
              Text(review.summaryText, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet();

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  double _rating = 3.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(alignment: Alignment.centerLeft, child: Text('리뷰 작성하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('건물명 또는 주소', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const TextField(decoration: InputDecoration(hintText: '예) 안암동 원룸, 서울 성북구 안암동 12-5')),
                  const SizedBox(height: 16),
                  const Text('별점', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Slider(
                        value: _rating,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        activeColor: AppColors.accent,
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                      Text('$_rating점', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('솔직 리뷰', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const TextField(
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: '층간소음, 수압, 결로, 집주인 성향 등\n솔직하게 작성해주세요!',
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
                        Icon(Icons.monetization_on, color: AppColors.reviewColor, size: 18),
                        SizedBox(width: 8),
                        Text('리뷰 작성 완료 시 +30P 적립!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.reviewColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ 리뷰 작성 완료! +30P 적립되었습니다.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.reviewColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('리뷰 등록하기', style: TextStyle(fontSize: 16)),
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
