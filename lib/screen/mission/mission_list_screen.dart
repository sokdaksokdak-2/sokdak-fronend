import 'package:flutter/material.dart';
import 'package:sdsd/widgets/custom_header.dart';

class MissionListScreen extends StatelessWidget {
  const MissionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final missions = [
      {
        'title': '친구들과의 이별',
        'description': '울어도 괜찮아. 지금 이 감정을 ‘편지’로 써봐!',
        'icon': 'assets/emotions/mission_stamp.png',
      },
      {
        'title': '끝내주는 날씨',
        'description': '이럴 땐! 이 순간을 영상으로 찍어서 남겨봐~',
        'icon': 'assets/emotions/mission_stamp.png',
      },
      {
        'title': '프로젝트 발표',
        'description': '조금 떨려도 괜찮아~ 가벼운 산책 해보는 건 어때?',
        'icon': 'assets/emotions/mission_none.png',
      },
    ];

    const double headerHeight = 80;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // 🔹 배경 이미지 넣고 싶다면 여기에 Positioned.fill 추가 가능
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + headerHeight,
              ),
              child: Column(
                children: [
                  const Text(
                    '미션 기록',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 34),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: missions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final mission = missions[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                mission['icon']!,
                                width: 32,
                                height: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mission['title']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      mission['description']!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
