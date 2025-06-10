import 'package:flutter/material.dart';
import 'package:sdsd/widgets/custom_header.dart';

class MissionSuggestScreen extends StatelessWidget {
  const MissionSuggestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String currentEmotion = 'angry'; // 감정 키워드
    const String backPath = 'assets/back/'; // 배경 이미지 폴더
    const double headerHeight = 80; // CustomHeader 높이

    return Scaffold(
      extendBodyBehindAppBar: true, // ★ 배경을 헤더 뒤까지
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        // 배경은 SafeArea 바깥, 콘텐츠는 안쪽 → top:false 로 둠
        top: false,
        bottom: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            // 🌄 1) 배경 이미지 (가장 뒤)
            Positioned.fill(
              child: Image.asset(
                '${backPath}${currentEmotion}_back.png',
                fit: BoxFit.fill,
              ),
            ),

            // 😡 2) 캐릭터 이미지 (하단 고정)
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              child: Image.asset(
                'assets/images/$currentEmotion.png',
                height: 330,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),

            // 🗨️ 3) 말풍선 + 버튼 UI (헤더만큼 아래로)
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + headerHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '미션 제안',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 34),

                  // --- 말풍선 ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
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
                      child: const Text(
                        '으~~ 듣는 내가 다 화나네\n열도 식힐 겸\n산책 한바퀴 어때?\n내가 신나는 노래 추천해줄게!',
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // --- 버튼들 ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '지금 해볼래',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '그냥 쉴래',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
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
