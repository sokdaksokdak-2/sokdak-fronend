import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/models/emotion_record_ui.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:sdsd/widgets/custom_header.dart';
import 'package:sdsd/utils/bluetooth_controller_serial.dart';

import '../services/chat_service.dart';
import 'mission/mission_suggest_screen.dart';

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

  Map<DateTime, List<EmotionRecordUI>> emotionRecords = {};
  List<Map<String, dynamic>> conversationHistory = [];
  int? _previousEmotionSeq;

  String backgroundImage = 'assets/back/happy_back.png';
  String gifImage = 'assets/gif_1_1x/happy1_1_1x.gif';

  // 로딩 상태 변수
  bool isLoading = false;

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
    if (!(_bluetoothController?.isConnected ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 블루투스 연결 실패 - 기기를 확인하세요.')),
      );
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
          if (status == 'notListening' && isListening) {
            Future.delayed(
              const Duration(milliseconds: 300),
              startListeningLoop,
            );
          }
        },
        onError: (error) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!_speech.isListening) startListeningLoop();
          });
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
      // 서버 호출 전 로딩 시작
      setState(() {
        isListening = false;
        isLoading = true;
      });

      _speech.stop();
      silenceTimer?.cancel();

      try {
        final suggestion = await ChatService.completeChat();
        if (!mounted) return;

        // 서버 응답 후 로딩 종료
        setState(() => isLoading = false);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MissionSuggestScreen(suggestion: suggestion),
            ),
          );
        });
      } catch (e) {
        if (!mounted) return;

        // 에러 시에도 로딩 종료
        setState(() => isLoading = false);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('대화 요약 및 미션 제안 실패')));
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
        silenceTimer = Timer(const Duration(milliseconds: 1200), () async {
          await sendTextToServer(spokenText);
          if (isListening) {
            Future.delayed(
              const Duration(milliseconds: 300),
              startListeningLoop,
            );
          }
        });
      },
      pauseFor: const Duration(seconds: 60),
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final chatbotMessage = data['chatbot_response'] ?? '(응답 없음)';
        final emotionSeq = data['emotion_seq'];
        final emotionScore = data['emotion_score'];

        if (emotionSeq != null && emotionScore != null) {
          updateEmotionState(emotionSeq, emotionScore, chatbotMessage, text);
        } else {
          setState(() {
            serverResponse = chatbotMessage;
            isFirstMessage = false;
          });
        }
      } else {
        setState(() {
          serverResponse = '잘못들었습니다?';
          isFirstMessage = false;
        });
      }
    } catch (e) {
      setState(() {
        serverResponse = '지금은 통신 중이 아니에요... 속닥이가 다시 연결 중!';
        isFirstMessage = false;
      });
    }
  }

  void updateEmotionState(
    int seq,
    int score,
    String chatbotMessage,
    String userMessage,
  ) {
    final emotionName = emotionMap[seq] ?? 'happy';
    setState(() {
      gifImage = 'assets/gif_1_1x/${emotionName}${score}_1_1x.gif';
      backgroundImage = 'assets/back/${emotionName}_back.png';
      serverResponse = chatbotMessage;
      isFirstMessage = false;
    });
    conversationHistory.add({
      'user': userMessage,
      'bot': chatbotMessage,
      'emotion_seq': seq,
    });
    final colorCode = getColorCodeByEmotionSeq(seq);
    _bluetoothController?.sendEmotionColor(colorCode);
    _previousEmotionSeq = seq;
  }

  void saveEmotionSummary() {
    final now = DateTime.now();
    final key = DateTime(now.year, now.month, now.day);
    final summary = conversationHistory
        .map((entry) => "나: ${entry['user']}\n속닥이: ${entry['bot']}")
        .join('\n');
    final latestEmotionSeq = conversationHistory.last['emotion_seq'];
    final emotionPath = 'assets/emotions/${latestEmotionSeq}_emoji.png';
    final record = EmotionRecordUI(
      emotion: emotionPath,
      title: '오늘의 감정 대화 요약',
      content: summary,
    );
    emotionRecords.putIfAbsent(key, () => []).add(record);
    conversationHistory.clear();
  }

  String getColorCodeByEmotionSeq(int seq) {
    switch (seq) {
      case 1:
        return 'FFEB3B';
      case 2:
        return '1565C0';
      case 3:
        return 'FF6F00';
      case 4:
        return 'FF2400';
      case 5:
        return '4CAF50';
      default:
        return 'FFEB3B';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                      padding: const EdgeInsets.only(
                        top: 30,
                        left: 40,
                        right: 40,
                      ),
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
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: AnimatedOpacity(
                              opacity: isListening ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
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
                                          BoxShadow(
                                            color: Colors.white,
                                            offset: Offset(-2, -2),
                                            blurRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: Colors.black26,
                                            offset: Offset(2, 2),
                                            blurRadius: 2,
                                          ),
                                        ]
                                        : [
                                          BoxShadow(
                                            color: Colors.black26,
                                            offset: Offset(4, 4),
                                            blurRadius: 8,
                                          ),
                                          BoxShadow(
                                            color: Colors.white,
                                            offset: Offset(-4, -4),
                                            blurRadius: 8,
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
        ),
        // 로딩 오버레이
        // 수정된 로딩 오버레이: Spinner 아래에 텍스트 추가
         if (isLoading)
           Positioned.fill(
             child: Container(
               color: Colors.black45,
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: const [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text(
                     '미션 생성중...',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 16,
                     ),
               ),
             ],
           ),
         ),
       ),
      ],
    );
  }
}
