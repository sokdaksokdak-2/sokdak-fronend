import 'package:flutter/material.dart';
import 'package:sdsd/widgets/custom_header.dart';
import '../../models/mission_list_item.dart';

class MissionReadyScreen extends StatelessWidget {
  final MissionListItem mission;
  // final VoidCallback onCancel;
  // final VoidCallback onComplete;
  final Future<void> Function() onCancel;
  final Future<void> Function() onComplete;

  const MissionReadyScreen({
    super.key,
    required this.mission,
    required this.onCancel,
    required this.onComplete,
  });

  String getEmotionName(int seq) {
    switch (seq) {
      case 1: return 'happy';
      case 2: return 'sad';
      case 3: return 'fear';
      case 4: return 'angry';
      case 5: return 'soso';
      default: return 'happy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String emotion = getEmotionName(mission.emotionSeq);
    final String backImage = 'assets/back/${emotion}_back.png';
    final String characterImage = 'assets/images/$emotion.png';
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
            // 배경 이미지
            Positioned.fill(
              child: Image.asset(
                backImage,
                fit: BoxFit.fill,
              ),
            ),

            // 캐릭터 이미지
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              child: Image.asset(
                characterImage,
                height: 330,
              ),
            ),

            // 본문과 버튼
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + headerHeight,
              ),
              child: Column(
                children: [
                  const Text(
                    '미션 시작',
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
                      child: Text(
                        mission.content,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              await onComplete(); // 반드시 완료 기다리기
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false, arguments: 3);
                              }

                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28B960),
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
                            onPressed: () async{
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false, arguments: 3);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '나중에 할래',
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
