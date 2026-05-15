import 'package:flutter/material.dart';

class InAppNotificationService {
  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required String roomId,
    String emoji = '💬',
    VoidCallback? onTap,
  }) {
    if (_isShowing) {
      _currentEntry?.remove();
      _isShowing = false;
    }

    _currentEntry = OverlayEntry(
      builder: (ctx) => _InAppBanner(
        title: title,
        message: message,
        emoji: emoji,
        onTap: onTap,
        onDismiss: () {
          _currentEntry?.remove();
          _isShowing = false;
        },
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
    _isShowing = true;

    // 4초 후 자동 제거
    Future.delayed(const Duration(seconds: 4), () {
      if (_isShowing) {
        _currentEntry?.remove();
        _isShowing = false;
      }
    });
  }
}

class _InAppBanner extends StatefulWidget {
  final String title;
  final String message;
  final String emoji;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _InAppBanner({
    required this.title,
    required this.message,
    required this.emoji,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0) widget.onDismiss();
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEECE8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(widget.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B6B6B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFFB0B0B0)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
