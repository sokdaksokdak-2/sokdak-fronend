import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/models/emotion_record.dart';
import 'package:sdsd/services/emotion_service.dart';
import 'package:sdsd/widgets/cloud_bubble_svg.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sdsd/widgets/custom_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech;
  bool isListening = false;
  bool isFirstMessage = true;
  String spokenText = '';
  String serverResponse = '';

  Map<DateTime, List<EmotionRecord>> emotionRecords = {};

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleListening() async {
    if (!isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('✅ STT 상태: $status'),
        onError: (error) => print('❌ STT 오류: $error'),
      );
      if (available) {
        setState(() {
          isListening = true;
          spokenText = '';
        });
        _speech.listen(
          localeId: 'ko_KR',
          onResult: (result) {
            setState(() {
              spokenText = result.recognizedWords;
            });
            print('🎤 인식된 텍스트: ${result.recognizedWords}');

            if (result.finalResult) {
              print('✅ 최종 인식 텍스트: ${result.recognizedWords}');
              sendTextToServer(result.recognizedWords);
            }
          },
        );
      }
    } else {
      setState(() => isListening = false);
      _speech.stop();
      print('🛑 음성 인식 중지');
    }
  }

  Future<void> sendTextToServer(String text) async {
    final uri = Uri.parse('${Config.baseUrl}/api/chatbot/stream');
    print('📤 서버로 보낼 텍스트: $text');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_message': text,
          'member_seq': Config.memberSeq,
        }),
      );

      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          serverResponse = response.body.isNotEmpty ? response.body : '(응답은 200이지만 본문이 없음)';
          isFirstMessage = false;
        });

        final now = DateTime.now();
        final key = DateTime(now.year, now.month, now.day);

        final emotionRecord = await EmotionService.analyzeAndSave(
          date: now,
          text: text,
          title: '감정 분석 기록',
        );

        setState(() {
          if (emotionRecords.containsKey(key)) {
            emotionRecords[key]!.add(emotionRecord);
          } else {
            emotionRecords[key] = [emotionRecord];
          }
        });

        print('✅ 감정 기록 저장 완료: $emotionRecord');
      } else {
        setState(() {
          serverResponse = '서버 오류: ${response.statusCode}';
          isFirstMessage = false;
        });
      }
    } catch (e) {
      print("❗예외 발생: $e");
      setState(() {
        serverResponse = '지금은 통신 중이 아니에요...\n 속닥이가 다시 연결 중! ';
        isFirstMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double bubbleVertical = size.height * 0.2;
    final double bubbleHorizontal = size.width * 0.3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/moving_happy4.gif',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final width = constraints.maxWidth;

                return Column(
                  children: [
                    SizedBox(height: height * 0.02),

                    // 말풍선
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                      child: CloudBubbleSvg(
                        text: isFirstMessage
                            ? '안녕 ${Config.nickname.isNotEmpty ? Config.nickname : '속닥'}!\n오늘 하루는 어땠어??'
                            : serverResponse,
                        maxWidth: width * 0.9,
                        extraHorizontal: bubbleHorizontal,
                        extraVertical: bubbleVertical,
                        bubbleColor: Colors.white,
                        style: const TextStyle(fontSize: 20, color: Colors.black),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                    ),

                    SizedBox(height: height * 0.05),

                    // 캐릭터 이미지
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/happy.png', // 예시: currentEmotion 상태에 따라 변경 가능
                          fit: BoxFit.contain,
                          height: height * 0.4,
                        ),
                      ),
                    ),

                    // 마이크 애니메이션
                    if (isListening)
                      SizedBox(
                        width: width * 0.25,
                        height: width * 0.25,
                        child: Lottie.asset(
                          'assets/lottie/mic.json',
                          repeat: true,
                          animate: true,
                        ),
                      ),

                    // 마이크 버튼
                    Padding(
                      padding: EdgeInsets.only(bottom: height * 0.05),
                      child: GestureDetector(
                        onTap: _toggleListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isListening
                                ? const LinearGradient(
                              colors: [Color(0xFFBDBDBD), Color(0xFF8E8E8E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : const LinearGradient(
                              colors: [Color(0xFFDADADA), Color(0xFFAAAAAA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: isListening
                                ? [
                              const BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 2),
                              const BoxShadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 2),
                            ]
                                : [
                              const BoxShadow(color: Colors.black26, offset: Offset(4, 4), blurRadius: 8),
                              const BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.mic, size: 45, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
