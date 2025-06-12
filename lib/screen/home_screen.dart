import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/models/emotion_record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sdsd/widgets/custom_header.dart';
import 'package:sdsd/utils/bluetooth_controller_serial.dart';

class HomeScreen extends StatefulWidget {
  final DateTime date;           // ✅ 새 필드

  const HomeScreen({
    super.key,
    DateTime? date,                    // 🔄 nullable·옵션
  }) : date = date ?? DateTime.now();  // 🔄 기본값: 오늘
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech;
  BluetoothController? _bluetoothController; // ✅ nullable 처리
  bool isListening = false;
  bool isFirstMessage = true;
  String spokenText = '';
  String serverResponse = '';
  Map<DateTime, List<EmotionRecord>> emotionRecords = {};
  int? _previousEmotionSeq;
  DateTime? _selectedDay;                // 사용자가 화면에서 선택할 때 갱신

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _bluetoothController = BluetoothController();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    await _bluetoothController?.connectToArduino();
    if (!(_bluetoothController?.isConnected ?? false)) {
      print('⚠️ 블루투스 연결 실패 - 기기를 확인하세요.');
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _bluetoothController?.disconnect(); // ✅ 안전하게 종료
    super.dispose();
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
            if (result.finalResult) {
              sendTextToServer(result.recognizedWords);
            }
          },
        );
      }
    } else {
      setState(() => isListening = false);
      _speech.stop();
    }
  }

  Future<void> sendTextToServer(String text) async {
    final uri = Uri.parse('${Config.baseUrl}/api/chatbot/chat');

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

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);

        final chatbotMessage = data['chatbot_response'] ?? '(응답 없음)';
        final emotionSeq = data['emotion_seq'];

        setState(() {
          serverResponse = chatbotMessage;
          isFirstMessage = false;
        });

        // ── 1️⃣ 오늘 기준 날짜를 DateOnly 형태로 얻기 ──
        final DateTime picked = _selectedDay ?? widget.date;            // widget.date = 기본 날짜
        final DateTime key    = DateTime(picked.year, picked.month, picked.day);

        if (emotionSeq != null) {
          final record = EmotionRecord(
            seq         : 0,                    // ✅ 임시 PK (서버 저장 후 재조회하면 실제 detail_seq 로 교체)
            emotionSeq  : emotionSeq,           // 1‒5
            title       : '감정 분석 기록',
            content     : chatbotMessage,
            calendarDate: picked,  // ✅ 혹은 _focusedDay
          );



        setState(() {
            emotionRecords.putIfAbsent(key, () => []).add(record);
          });

          final colorCode = getColorCodeByEmotionSeq(emotionSeq);
          await _bluetoothController?.sendEmotionColor(colorCode); // ✅ 안전하게 전송
          print('✅ 감정 색상 전송 완료: $colorCode');

          _previousEmotionSeq = emotionSeq;
        } else {
          print('⚠️ 감정 번호 없음 → 감정 저장 생략');
        }
      } else {
        final errorMessage = () {
          try {
            return utf8.decode(response.bodyBytes);
          } catch (_) {
            return '(에러 메시지를 읽을 수 없음)';
          }
        }();

        setState(() {
          serverResponse = '잘못들었습니다?';
          isFirstMessage = false;
        });
      }
    } catch (e) {
      setState(() {
        serverResponse = '지금은 통신 중이 아니에요...\n 속닥이가 다시 연결 중!';
        isFirstMessage = false;
      });
      print('❌ 예외 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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

String getColorCodeByEmotionSeq(int seq) {
  switch (seq) {
    case 1:
      return '#FFD700'; // 기쁨 (노랑)
    case 2:
      return '#1E90FF'; // 슬픔 (파랑)
    case 3:
      return '#E53EF2'; // 불안 (보라)
    case 4:
      return '#960018'; // 화남 (핑크)
    case 5:
      return '#32CD32'; // 평온 (연녹)
    default:
      return '#FFFFFF'; // 기본값 (흰색)
  }
}
