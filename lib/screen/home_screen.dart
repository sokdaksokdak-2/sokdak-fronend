import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/models/emotion_record.dart';
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
    final uri = Uri.parse('${Config.baseUrl}/api/chatbot/chat');
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

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        print('📥 응답 디코딩 완료: $data');

        final chatbotMessage = data['chatbot_response'] ?? '(응답 없음)';
        final emotionSeq = data['emotion_seq'];
        final emotionScore = data['emotion_score'];

        setState(() {
          serverResponse = chatbotMessage;
          isFirstMessage = false;
        });

        final now = DateTime.now();
        final key = DateTime(now.year, now.month, now.day);

        if (emotionSeq != null) {
          final record = EmotionRecord(
            emotion: 'assets/emotions/${emotionSeq}_emoji.png',
            title: '감정 분석 기록',
            content: chatbotMessage,
          );

          setState(() {
            if (emotionRecords.containsKey(key)) {
              emotionRecords[key]!.add(record);
            } else {
              emotionRecords[key] = [record];
            }
          });

          print('✅ 감정 기록 저장 완료: $record');
        } else {
          print('⚠️ 감정 번호 없음 → 감정 저장 생략');
        }
      } else {
        final errorMessage = utf8.decode(response.bodyBytes);
        print('❌ 서버 오류 응답 본문: $errorMessage');
        setState(() {
          serverResponse = '서버 오류: ${response.statusCode}\n$errorMessage';
          isFirstMessage = false;
        });
      }
    } catch (e) {
      print("❗예외 발생: $e");
      setState(() {
        serverResponse = '지금은 통신 중이 아니에요...\n 속닥이가 다시 연결 중!';
        isFirstMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentEmotion = 'happy';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/gif/fear3.gif',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Container(
                      width: double.infinity,
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
                        isFirstMessage
                            ? '안녕 ${Config.nickname.isNotEmpty ? Config.nickname : '속닥'}!\n오늘 하루는 어땠어??'
                            : serverResponse,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      SizedBox(height: 250),
                      SizedBox(height: 8),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
                if (isListening)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Lottie.asset(
                          'assets/lottie/mic.json',
                          repeat: true,
                          animate: true,
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              isListening
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFFBDBDBD),
                                      Color(0xFF8E8E8E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : const LinearGradient(
                                    colors: [
                                      Color(0xFFDADADA),
                                      Color(0xFFAAAAAA),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          boxShadow:
                              isListening
                                  ? [
                                    const BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-2, -2),
                                      blurRadius: 2,
                                    ),
                                    const BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(2, 2),
                                      blurRadius: 2,
                                    ),
                                  ]
                                  : [
                                    const BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(4, 4),
                                      blurRadius: 8,
                                    ),
                                    const BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-4, -4),
                                      blurRadius: 8,
                                    ),
                                  ],
                        ),
                        child: const Center(
                          child: Icon(Icons.mic, size: 45, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
