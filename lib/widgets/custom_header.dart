import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final Widget? rightWidget;
  final String? subtitle;

  const CustomHeader({
    this.showBackButton = false,
    this.rightWidget,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,                             // 하단 패딩 불필요
      child: Container(
        color: Colors.transparent,               // ★ 배경 투명
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ↙︎ 왼쪽 뒤로가기(선택)
            Align(
              alignment: Alignment.centerLeft,
              child: showBackButton
                  ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
                  : const SizedBox(width: 48),   // 버튼 없을 때 자리 확보
            ),

            // 중앙 로고 + 서브타이틀
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Image.asset('assets/images/sdsd1.png', height: 40),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
              ],
            ),

            // ↗︎ 우측 커스텀 위젯(선택)
            if (rightWidget != null)
              Align(alignment: Alignment.centerRight, child: rightWidget),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
