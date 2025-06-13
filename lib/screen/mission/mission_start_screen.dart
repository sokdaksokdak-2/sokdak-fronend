import 'package:flutter/material.dart';
import 'package:sdsd/widgets/custom_header.dart';

class MissionStartScreen extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onViewList; // ✅ 추가: 미션 리스트로 이동할 콜백

  const MissionStartScreen({
    super.key,
    required this.onCancel,
    required this.onViewList,
  });

  @override
  Widget build(BuildContext context) {
    const String currentEmotion = 'fear';
    const String backPath = 'assets/back/';
    const double headerHeight = 80;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        top: false,
        bottom: false,
        left: false,
        right: false,
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
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + headerHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '미션 시작',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 34),
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
                        '차분한 음악과 함께\n산책하면서\n초록색 물건 3개 찾기!\n시~작',
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
                            onPressed: onViewList, // ✅ 미션 완료하면 리스트로
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF28B960),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '미션 완료하기',
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
                            onPressed: onCancel, // ✅ 그만둘래는 기존대로
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '그만둘래',
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
