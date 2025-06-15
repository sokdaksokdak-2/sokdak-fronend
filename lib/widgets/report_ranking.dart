import 'package:flutter/material.dart';
import 'package:sdsd/utils/emotion_helper.dart';

class ReportRanking extends StatelessWidget {
  final List<int> topEmotions; // 감정 seq 순서대로: [1등, 2등, 3등, 4등, 5등]

  const ReportRanking({super.key, required this.topEmotions});

  final _positions = const {
    'background': Offset(22, 40),
    'podium': Offset(22, 0),
    'char1': Offset(117, -25),
    'char2': Offset(52, 0),
    'char3': Offset(182, 12),
    'char4': Offset(82, 110),
    'char5': Offset(142, 110),
  };

  @override
  Widget build(BuildContext context) {
    final List<Widget> characterWidgets = [];
    for (int i = 0; i < topEmotions.length; i++) {
      final positionKey = 'char${i + 1}';
      final asset = emotionAsset(topEmotions[i]);
      characterWidgets.add(
        Positioned(
          top: _positions[positionKey]!.dy,
          left: _positions[positionKey]!.dx,
          child: Image.asset(asset, width: 70),
        ),
      );
    }

    return SizedBox(
      width: 260,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: _positions['background']!.dy,
            left: _positions['background']!.dx,
            child: Image.asset('assets/images/ranking2.png', width: 260),
          ),
          Positioned(
            top: _positions['podium']!.dy,
            left: _positions['podium']!.dx,
            child: Image.asset('assets/images/ranking1.png', width: 260),
          ),
          ...characterWidgets,
          Positioned(
            top: -20,
            left: 0,
            child: Image.asset(
              'assets/images/medal.png',
              width: 50,
              height: 50,
            ),
          ),
          Positioned(
            top: -15,
            right: 10,
            child: GestureDetector(
              onTap: () {
                // 저장 동작
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 20, color: Colors.black54),
                    SizedBox(height: 2),
                    Text(
                      '저장',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
