import 'package:flutter/material.dart';

class ReportRanking extends StatelessWidget {
  final List<int> topEmotions; // 감정 seq 순서대로: [1등, 2등, 3등, 4등, 5등]

  const ReportRanking({super.key, required this.topEmotions});

  final _positions = const {
    'background': Offset(8, 25),
    'podium': Offset(8, 5),
    'char1': Offset(123, -5),
    'char2': Offset(57, 20),
    'char3': Offset(187, 32),
    'char4': Offset(92, 112),
    'char5': Offset(147, 112),
  };

  // 랭킹 전용(더 큰) 이미지 경로 매핑
  static const Map<int, String> kRankingEmotionAsset = {
    4: 'assets/images/angry.png',
    3: 'assets/images/fear.png',
    1: 'assets/images/happy.png',
    2: 'assets/images/sad.png',
    5: 'assets/images/soso.png',
  };

  @override
  Widget build(BuildContext context) {
    final List<Widget> characterWidgets = [];
    for (int i = 0; i < topEmotions.length; i++) {
      final positionKey = 'char${i + 1}';
      // 랭킹 전용 이미지 맵에서 경로 선택, 없으면 none.png로 fallback
      final asset = kRankingEmotionAsset[topEmotions[i]] ?? 'assets/images/none.png';
      characterWidgets.add(
        Positioned(
          top: _positions[positionKey]!.dy,
          left: _positions[positionKey]!.dx,
          child: Image.asset(asset, width: 70), // ← width도 더 크게 조정
        ),
      );
    }

    return SizedBox(
      width: 300,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: _positions['background']!.dy,
            left: _positions['background']!.dx,
            child: Image.asset('assets/images/ranking2.png', width: 300),
          ),
          Positioned(
            top: _positions['podium']!.dy,
            left: _positions['podium']!.dx,
            child: Image.asset('assets/images/ranking1.png', width: 300),
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
