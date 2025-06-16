import 'package:flutter/material.dart';
import 'package:sdsd/models/mission_suggestion.dart';
import 'package:sdsd/screen/mission/mission_ready_screen.dart';
import 'package:sdsd/services/mission_service.dart';
import 'package:sdsd/widgets/custom_header.dart';

import '../../models/mission_list_item.dart';

class MissionSuggestScreen extends StatelessWidget {
  final MissionSuggestion suggestion;

  const MissionSuggestScreen({
    super.key,
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    final String emotion = _getEmotionName(suggestion.emotionSeq);
    // 배경 이미지 경로
    final String backImage = 'assets/back/${emotion}_back.png';
    // 캐릭터(정지 이미지) 경로로 변경
    final String characterImage = 'assets/images/$emotion.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // 배경
            Positioned.fill(
              child: Image.asset(
                backImage,
                fit: BoxFit.cover,
              ),
            ),
            // 캐릭터 이미지 추가
            Positioned(
              left: 0,
              right: 0,
              bottom: 180,
              child: Image.asset(
                characterImage,
                // fit: BoxFit.contain,
                height: 350,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 80,
              ),
              child: Column(
                children: [
                  const Text(
                    '미션',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 34),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
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
                        suggestion.content,
                        style: const TextStyle(fontSize: 20),
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
                            onPressed: () async {
                              final currentContext = context;
                              try {
                                final memberMissionSeq = await MissionService.acceptMission(suggestion);

                                final item = MissionListItem(
                                  memberMissionSeq: memberMissionSeq,
                                  title: suggestion.title,
                                  content: suggestion.content,
                                  completed: false,
                                  emotionSeq: suggestion.emotionSeq,
                                  emotionScore: suggestion.emotionScore,
                                );

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MissionReadyScreen(
                                        mission: item,
                                        onCancel: () async {
                                          Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
                                        },
                                        onComplete: () async {
                                          try {
                                            await MissionService.completeMission(memberMissionSeq);
                                          } catch (e) {
                                            debugPrint('미션 완료 실패: $e');
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                });

                              } catch (e) {
                                ScaffoldMessenger.of(currentContext).showSnackBar(
                                  const SnackBar(content: Text('미션 수락 실패')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28B960),
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
                            onPressed: () {
                              Navigator.pop(context);
                            },
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

  String _getEmotionName(int seq) {
    switch (seq) {
      case 1:
        return 'happy';
      case 2:
        return 'sad';
      case 3:
        return 'fear';
      case 4:
        return 'angry';
      case 5:
        return 'soso';
      default:
        return 'happy';
    }
  }
}
