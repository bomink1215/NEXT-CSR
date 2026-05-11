import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';

class GatherScreen extends StatefulWidget {
  const GatherScreen({super.key});

  @override
  State<GatherScreen> createState() => _GatherScreenState();
}

class _GatherScreenState extends State<GatherScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('모임 찾기')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.gatherColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('모임 만들기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 빠른 모임 카테고리
          const Text('빠른 모임 찾기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _QuickCategory('🍜', '혼밥 메이트'),
                _QuickCategory('🚶', '산책'),
                _QuickCategory('☕', '카페'),
                _QuickCategory('🎮', '게임'),
                _QuickCategory('📚', '스터디'),
                _QuickCategory('🏃', '운동'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('지금 모집 중', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...MockData.gatherPosts.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GatherCard(post: p),
          )),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateGatherSheet(),
    );
  }
}

class _QuickCategory extends StatelessWidget {
  final String emoji;
  final String label;

  const _QuickCategory(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _GatherCard extends StatelessWidget {
  final GatherPost post;

  const _GatherCard({required this.post});

  String _genderLabel(GenderFilter f) {
    switch (f) {
      case GenderFilter.any: return '성별 무관';
      case GenderFilter.maleOnly: return '남성만';
      case GenderFilter.femaleOnly: return '여성만';
    }
  }

  String _ageLabel(AgeFilter f) {
    switch (f) {
      case AgeFilter.any: return '연령 무관';
      case AgeFilter.twenties: return '20대';
      case AgeFilter.thirties: return '30대';
      case AgeFilter.mixed: return '혼합';
    }
  }

  String _timeLabel(DateTime t) {
    final diff = t.difference(DateTime.now());
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 후';
    if (diff.inHours < 24) return '${diff.inHours}시간 후';
    return '${diff.inDays}일 후';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: post.isFull ? AppColors.divider : AppColors.gatherColor.withOpacity(0.3),
            width: post.isFull ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이모지
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: post.isFull
                    ? AppColors.cardBg
                    : AppColors.gatherColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(post.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (post.isFull)
                        const TagBadge(label: '마감', color: AppColors.error)
                      else
                        TagBadge(label: _timeLabel(post.meetTime), color: AppColors.gatherColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          post.place,
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      TagBadge(label: _genderLabel(post.genderFilter), color: AppColors.textSecondary),
                      TagBadge(label: _ageLabel(post.ageFilter), color: AppColors.textSecondary),
                      TagBadge(
                        label: '${post.currentMembers}/${post.maxMembers}명',
                        color: post.isFull ? AppColors.error : AppColors.gatherColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GatherDetail(post: post),
    );
  }
}

class _GatherDetail extends StatelessWidget {
  final GatherPost post;

  const _GatherDetail({required this.post});

  String _genderLabel(GenderFilter f) {
    switch (f) {
      case GenderFilter.any: return '성별 무관';
      case GenderFilter.maleOnly: return '남성만';
      case GenderFilter.femaleOnly: return '여성만';
    }
  }

  String _ageLabel(AgeFilter f) {
    switch (f) {
      case AgeFilter.any: return '연령 무관';
      case AgeFilter.twenties: return '20대';
      case AgeFilter.thirties: return '30대';
      case AgeFilter.mixed: return '혼합';
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetStr =
        '${post.meetTime.month}/${post.meetTime.day} ${post.meetTime.hour}:${post.meetTime.minute.toString().padLeft(2, '0')}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(post.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(post.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 16),
                  // 모임 정보
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gatherColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(Icons.location_on_outlined, '장소', post.place),
                        const Divider(color: AppColors.divider, height: 16),
                        _InfoRow(Icons.access_time, '시간', meetStr),
                        const Divider(color: AppColors.divider, height: 16),
                        _InfoRow(Icons.people_outline, '인원', '${post.currentMembers}/${post.maxMembers}명'),
                        const Divider(color: AppColors.divider, height: 16),
                        _InfoRow(Icons.person_outline, '성별', _genderLabel(post.genderFilter)),
                        const Divider(color: AppColors.divider, height: 16),
                        _InfoRow(Icons.cake_outlined, '연령', _ageLabel(post.ageFilter)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!post.isFull)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✅ "${post.title}" 모임에 참여했습니다! 약속 장소: ${post.place}')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gatherColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.group_add, color: Colors.white),
                        label: const Text('모임 참여하기', style: TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('마감된 모임입니다', style: TextStyle(color: AppColors.textHint, fontSize: 15)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _InfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gatherColor),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CreateGatherSheet extends StatefulWidget {
  const _CreateGatherSheet();

  @override
  State<_CreateGatherSheet> createState() => _CreateGatherSheetState();
}

class _CreateGatherSheetState extends State<_CreateGatherSheet> {
  GenderFilter _genderFilter = GenderFilter.any;
  AgeFilter _ageFilter = AgeFilter.any;
  int _maxMembers = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
            child: Align(alignment: Alignment.centerLeft, child: Text('모임 만들기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('모임 제목', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const TextField(decoration: InputDecoration(hintText: '예) 오늘 저녁 혼밥 메이트 구해요')),
                  const SizedBox(height: 16),
                  const Text('장소', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const TextField(decoration: InputDecoration(hintText: '약속 장소를 입력해주세요', prefixIcon: Icon(Icons.location_on_outlined))),
                  const SizedBox(height: 16),
                  const Text('최대 인원', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () { if (_maxMembers > 2) setState(() => _maxMembers--); },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.gatherColor,
                      ),
                      Text('$_maxMembers명', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: () { if (_maxMembers < 10) setState(() => _maxMembers++); },
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.gatherColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('성별 제한', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: GenderFilter.values.map((f) {
                      final labels = ['성별 무관', '남성만', '여성만'];
                      return GestureDetector(
                        onTap: () => setState(() => _genderFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _genderFilter == f ? AppColors.gatherColor : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _genderFilter == f ? AppColors.gatherColor : AppColors.divider),
                          ),
                          child: Text(labels[f.index], style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _genderFilter == f ? Colors.white : AppColors.textSecondary,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('연령 제한', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AgeFilter.values.map((f) {
                      final labels = ['연령 무관', '20대', '30대', '혼합'];
                      return GestureDetector(
                        onTap: () => setState(() => _ageFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ageFilter == f ? AppColors.gatherColor : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _ageFilter == f ? AppColors.gatherColor : AppColors.divider),
                          ),
                          child: Text(labels[f.index], style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _ageFilter == f ? Colors.white : AppColors.textSecondary,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ 모임이 생성되었습니다! 참여자를 기다려요.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gatherColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('모임 만들기', style: TextStyle(fontSize: 16)),
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
