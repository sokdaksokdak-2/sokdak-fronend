import 'package:dio/dio.dart';
import '../config.dart';
import '../models/mission_suggestion.dart';

class ChatService {
  /// 대화 종료 → 챗봇 요약 저장 & 미션 제안 받기
  static Future<MissionSuggestion> completeChat() async {
    try {
      final response = await Dio().post(
        '${Config.baseUrl}/api/chatbot/complete/${Config.memberSeq}',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${Config.accessToken}',
          },
        ),
      );

      return MissionSuggestion.fromJson(response.data);
    } catch (e) {
      print('❌ completeChat 오류: $e');
      throw Exception('대화 종료 처리 실패: $e');
    }
  }
}
