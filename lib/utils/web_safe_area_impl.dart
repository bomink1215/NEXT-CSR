// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

double webSafeAreaBottom() {
  try {
    final el = html.DivElement();
    // bottom: env(safe-area-inset-bottom) → 요소 바닥이 safe area 위에 위치
    // rect.bottom = window.innerHeight - safe_area_inset_bottom
    // 따라서 safe_area = window.innerHeight - rect.bottom
    el.style.cssText =
        'position:fixed;'
        'bottom:env(safe-area-inset-bottom,0px);'
        'height:0;width:0;'
        'pointer-events:none;visibility:hidden;';
    html.document.documentElement!.append(el);
    final rect = el.getBoundingClientRect();
    final windowH = (html.window.innerHeight ?? 0).toDouble();
    el.remove();
    final sab = windowH - rect.bottom;
    return sab > 0 ? sab : 0;
  } catch (_) {
    return 0;
  }
}
