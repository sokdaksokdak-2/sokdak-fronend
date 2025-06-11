import 'package:flutter/material.dart';
import 'package:sdsd/screen/main_screen.dart'; // ✅ 꼭 필요
import 'package:sdsd/widgets/custom_header.dart';
import 'package:sdsd/globals.dart'; // ✅ mainTabIndex 사용

class MissionRestScreen extends StatelessWidget {
  final VoidCallback onViewList; // ✅ 기록 보기 콜백

  const MissionRestScreen({super.key, required this.onViewList});

  void _goHome(BuildContext context) {
    mainTabIndex.value = 2; // 홈 탭 인덱스로 설정

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false, // 모든 이전 화면 제거 → MainScreen만 남음
    );
  }

  @override
  Widget build(BuildContext context) {
    const String currentEmotion = 'happy';
    const String backPath = 'assets/back/';
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
            Positioned.fill(
              child: Image.asset(
                '${backPath}${currentEmotion}_back.png',
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              child: Image.asset(
                'assets/images/$currentEmotion.png',
                height: 330,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + headerHeight,
              ),
              child: Column(
                children: [
                  const Text(
                    '미션 제안',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 34),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        '괜찮아 가끔은\n쉬는 것도 필요한 법이지!',
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Spacer(),
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
                            onPressed: () => _goHome(context), // ✅ 여기서 홈으로!
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28B960),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '홈으로 돌아가기',
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
                            onPressed: onViewList,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '미션 기록 보기',
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
