import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/models/emotion_record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:sdsd/widgets/custom_header.dart';
import 'package:sdsd/utils/bluetooth_controller_serial.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech;
  BluetoothController? _bluetoothController;

  bool isListening = false;
  bool isFirstMessage = true;
  String spokenText = '';
  String serverResponse = '';
  Timer? silenceTimer;

  Map<DateTime, List<EmotionRecord>> emotionRecords = {};
  List<Map<String, dynamic>> conversationHistory = [];
  int? _previousEmotionSeq;

  String backgroundImage = 'assets/back/happy_back.png';
  String gifImage = 'assets/gif/happy1.gif';

  final Map<int, String> emotionMap = {
    1: 'happy',
    2: 'sad',
    3: 'fear',
    4: 'angry',
    5: 'soso',
  };

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
    _bluetoothController?.disconnect();
    silenceTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('🎧 onStatus: $status');
          if (status == 'notListening' && isListening) {
            // 말 안 하고 멈췄을 때 다음 인식 루프를 위한 짧은 대기시간
            Future.delayed(const Duration(milliseconds: 300), () {
              startListeningLoop();
            });
          }
        },
        onError: (error) {
          print('❌ STT 오류: $error');
          if (isListening) {
            // STT 초기화 시 상태 체크 후 대기시간
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!_speech.isListening) {
                startListeningLoop();
              }
            });
          }
        },
      );

      if (available) {
        setState(() {
          isListening = true;
          spokenText = '';
          conversationHistory.clear();
          isFirstMessage = true;
        });
        startListeningLoop();
      }
    } else {
      setState(() => isListening = false);
      _speech.stop();
      silenceTimer?.cancel();

      if (conversationHistory.isNotEmpty) {
        final now = DateTime.now();
        final key = DateTime(now.year, now.month, now.day);

        final summary = conversationHistory
            .map((entry) => "나: ${entry['user']}\n속닥이: ${entry['bot']}")
            .join('\n');

        final latestEmotionSeq = conversationHistory.last['emotion_seq'];
        final emotionPath = 'assets/emotions/${latestEmotionSeq}_emoji.png';

        final record = EmotionRecord(
          emotion: emotionPath,
          title: '오늘의 감정 대화 요약',
          content: summary,
        );

        emotionRecords.putIfAbsent(key, () => []).add(record);
        conversationHistory.clear();

        print('✅ 대화 종료: 요약 서버로 전송됨 (${summary.length}자)');
      }
    }
  }

  void startListeningLoop() {
    if (!_speech.isAvailable || !isListening) return;

    _speech.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        silenceTimer?.cancel();
        spokenText = result.recognizedWords;

        if (spokenText.trim().length < 2) {
          startListeningLoop();
          return;
        }

        // STT 음성 인식 시작 후 2초간 침묵하면 서버로 전송
        silenceTimer = Timer(const Duration(milliseconds: 1500), () async {
          await sendTextToServer(spokenText);

          if (isListening) {
            Future.delayed(const Duration(milliseconds: 300), () {
              startListeningLoop();
            });
          }
        });
      },
      // STT 자동 종료 전에 '침묵 허용 시간': 8초 동안 말 안 하면 종료됨
      pauseFor: const Duration(seconds: 8),
      // 한 번의 음성 인식 최대 지속 시간: 1분
      listenFor: const Duration(minutes: 1),
    );
  }

  Future<void> sendTextToServer(String text) async {
    final uri = Uri.parse('${Config.baseUrl}/api/chatbot/chat');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
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
        final emotionScore = data['emotion_score'];

        setState(() {
          serverResponse = chatbotMessage;
          isFirstMessage = false;
        });

        if (emotionSeq != null && emotionScore != null) {
          final emotionName = emotionMap[emotionSeq] ?? 'happy';

          setState(() {
            gifImage = 'assets/gif/${emotionName}${emotionScore}.gif';
            backgroundImage = 'assets/back/${emotionName}_back.png';
          });

          conversationHistory.add({
            'user': text,
            'bot': chatbotMessage,
            'emotion_seq': emotionSeq,
          });

          final colorCode = getColorCodeByEmotionSeq(emotionSeq);
          await _bluetoothController?.sendEmotionColor(colorCode);
          _previousEmotionSeq = emotionSeq;
        }
      } else {
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
    }
  }

  String getColorCodeByEmotionSeq(int seq) {
    switch (seq) {
      case 1:
        return '#FFD700';
      case 2:
        return '#1E90FF';
      case 3:
        return '#E53EF2';
      case 4:
        return '#960018';
      case 5:
        return '#32CD32';
      default:
        return '#FFFFFF';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: const CustomHeader(),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
            child: Image.asset(
              gifImage,
              key: ValueKey(gifImage),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 40, right: 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(serverResponse),
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
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
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isListening)
                        Positioned(
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
                      GestureDetector(
                        onTap: _toggleListening,
                        child: AnimatedContainer(
                          // 마이크 버튼 누를 때 애니메이션 효과 시간
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
                            boxShadow: [
                              BoxShadow(
                                color:
                                    isListening ? Colors.white : Colors.black26,
                                offset:
                                    isListening
                                        ? const Offset(-2, -2)
                                        : const Offset(4, 4),
                                blurRadius: isListening ? 2 : 8,
                              ),
                              BoxShadow(
                                color:
                                    isListening ? Colors.black26 : Colors.white,
                                offset:
                                    isListening
                                        ? const Offset(2, 2)
                                        : const Offset(-4, -4),
                                blurRadius: isListening ? 2 : 8,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mic,
                              size: 45,
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
    );
  }
}
