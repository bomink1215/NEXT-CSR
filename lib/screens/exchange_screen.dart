import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';

class ExchangeScreen extends StatelessWidget {
  const ExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('물물교환'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.exchangeColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('교환글 올리기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // 안내 배너
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.exchangeColor.withOpacity(0.1),
                  AppColors.exchangeColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.exchangeColor.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Text('🔄', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '남는 물건을 이웃과 교환해요!\n채팅으로 즉시 협의·거래',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: MockData.exchangePosts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _ExchangeCard(post: MockData.exchangePosts[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateExchangeSheet(),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  final ExchangePost post;

  const _ExchangeCard({required this.post});

  Color get _statusColor {
    switch (post.status) {
      case ExchangeStatus.open:
        return AppColors.success;
      case ExchangeStatus.chatting:
        return AppColors.accent;
      case ExchangeStatus.done:
        return AppColors.textHint;
    }
  }

  String get _statusLabel {
    switch (post.status) {
      case ExchangeStatus.open:
        return '교환 가능';
      case ExchangeStatus.chatting:
        return '채팅 중';
      case ExchangeStatus.done:
        return '교환 완료';
    }
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
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TagBadge(label: _statusLabel, color: _statusColor),
                const Spacer(),
                WalkBadge(minutes: post.walkMinutes),
              ],
            ),
            const SizedBox(height: 12),
            // 교환 아이템 표시
            Row(
              children: [
                Expanded(
                  child: _ItemBox(
                    label: '제공',
                    item: post.offerItem,
                    color: AppColors.exchangeColor,
                    icon: '📦',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.exchangeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.swap_horiz, color: AppColors.exchangeColor, size: 20),
                    ),
                  ),
                ),
                Expanded(
                  child: _ItemBox(
                    label: '원하는',
                    item: post.wantItem,
                    color: AppColors.secondary,
                    icon: '🙏',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(post.authorName, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(post.location, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
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
      builder: (_) => _ExchangeDetail(post: post),
    );
  }
}

class _ItemBox extends StatelessWidget {
  final String label;
  final String item;
  final Color color;
  final String icon;

  const _ItemBox({
    required this.label,
    required this.item,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $label',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            item,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ExchangeDetail extends StatelessWidget {
  final ExchangePost post;

  const _ExchangeDetail({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(post.description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _ItemBox(label: '제공', item: post.offerItem, color: AppColors.exchangeColor, icon: '📦')),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.swap_horiz, color: AppColors.exchangeColor, size: 28),
                      ),
                      Expanded(child: _ItemBox(label: '원하는', item: post.wantItem, color: AppColors.secondary, icon: '🙏')),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('💬 채팅방이 생성되었습니다!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.exchangeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: const Text('채팅으로 교환 제안하기', style: TextStyle(fontSize: 15, color: Colors.white)),
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
}

class _CreateExchangeSheet extends StatelessWidget {
  const _CreateExchangeSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('물물교환 올리기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('내가 제공할 물건', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const TextField(decoration: InputDecoration(hintText: '예) 신라면 5봉지', prefixText: '📦 ')),
                  const SizedBox(height: 16),
                  const Text('원하는 물건', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const TextField(decoration: InputDecoration(hintText: '예) 즉석밥 5개', prefixText: '🙏 ')),
                  const SizedBox(height: 16),
                  const Text('설명 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const TextField(
                    maxLines: 3,
                    decoration: InputDecoration(hintText: '물건 상태나 교환 조건을 자유롭게 적어주세요'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ 교환 게시글이 등록되었습니다!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.exchangeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('등록하기', style: TextStyle(fontSize: 16)),
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
