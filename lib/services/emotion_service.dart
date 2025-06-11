import 'package:dio/dio.dart';
import 'package:sdsd/config.dart';
import '../models/emotion_calendar_summary.dart';
import '../models/emotion_record.dart';

/// 💡 여기 상수를 다시 넣어 줍니다 ────────────────────────────
const Map<String, int> emotionSeqMap = {
  'cropped_angry': 1,
  'cropped_fear': 2,
  'cropped_happy': 3,
  'cropped_sad': 4,
  'cropped_soso': 5,
};
/// ──────────────────────────────────────────────────────────

/// 감정 관련 네트워크 요청 모음
class EmotionService {
  // ───────────────── 월별 요약 ─────────────────
  static Future<List<EmotionCalendarSummary>> fetchMonthlySummary(
      DateTime targetMonth) async {
    final response = await Dio().get(
      '${Config.baseUrl}/api/emo_calendar/monthly_summary',
      queryParameters: {
        'year': targetMonth.year,
        'month': targetMonth.month,
        'member_seq': Config.memberSeq,
      },
      options: Options(
        headers: {'Authorization': 'Bearer ${Config.accessToken}'},
      ),
    );

    return (response.data as List)
        .map((e) => EmotionCalendarSummary.fromJson(e))
        .toList();
  }

  // ───────────────── 일별 조회 ─────────────────
  static Future<List<EmotionRecord>> fetchDailyEmotions(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await Dio().get(
      '${Config.baseUrl}/api/emo_calendar/daily',
      queryParameters: {
        'member_seq': Config.memberSeq,
        'calendar_date': dateStr,
      },
      options: Options(
        headers: {'Authorization': 'Bearer ${Config.accessToken}'},
      ),
    );

    return (response.data as List).map<EmotionRecord>((item) {
      return EmotionRecord(
        emotion: item['character_image_url'] ?? '', // null이면 빈 문자열
        title: item['title'] ?? '',                 // null이면 빈 문자열
        content: item['context'] ?? '',             // null이면 빈 문자열
        seq: item['calendar_seq'],                  // 필요시 null도 OK
      );
    }).toList();

  }


  static Future<EmotionRecord> analyzeAndSave({
    required DateTime date,
    required String text,
    required String title,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await Dio().post(
        '${Config.baseUrl}/api/chatbot/complete/${Config.memberSeq}',
        data: {
          'calendar_date': dateStr,
          'text': text,
          'title': title,
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${Config.accessToken}'},
          responseType: ResponseType.json,
        ),
      );


      final data = response.data;
      print('📥 분석 응답 데이터: $data');

      final emotionStr = data['emotion']?.toString();
      final imageUrl = data['character_image_url'] ?? '';
      final context = data['context'] ?? '';
      print('➡️ 감정 번호: $emotionStr');
      print('📝 감정 설명(context): $context');
      print('🖼 캐릭터 이미지 URL: $imageUrl');

      final emotionSeq = int.tryParse(emotionStr ?? '');
      if (emotionSeq == null || emotionSeq < 1 || emotionSeq > 5) {
        throw Exception("⚠️ 서버에서 잘못된 감정 번호 받음: $emotionStr");
      }

      final recordTitle = (title.isNotEmpty ? title : '감정 기록').substring(
        0,
        title.length > 100 ? 100 : title.length,
      );
      final recordContext =
          context.length > 500 ? context.substring(0, 500) : context;

      final requestData = {
        'member_seq': Config.memberSeq,
        'calendar_date': dateStr,
        'title': recordTitle,
        'context': recordContext,
        'emotion_seq': emotionSeq,
      };

      print('📤 감정 기록 저장 요청 데이터: $requestData');

      final saveResponse = await Dio().post(
        '${Config.baseUrl}/api/emo_calendar/',
        data: requestData,
        options: Options(
          headers: {'Authorization': 'Bearer ${Config.accessToken}'},
          validateStatus: (_) => true,
        ),
      );

      print('📥 감정 저장 응답 상태: ${saveResponse.statusCode}');
      print('📥 감정 저장 응답 본문: ${saveResponse.data}');

      if (saveResponse.statusCode != 200 && saveResponse.statusCode != 201) {
        throw Exception("❌ 감정 저장 실패: ${saveResponse.statusCode}");
      }

      return EmotionRecord(
        emotion: imageUrl,
        title: recordTitle,
        content: recordContext,
      );
    } catch (e) {
      print("❗ analyzeAndSave 예외 발생: ${e.toString()}");

      if (e is DioError) {
        print('❗ DioError 응답: ${e.response}');
        print('❗ DioError 메시지: ${e.message}');
      }
      rethrow;
    }
  }

  static Future<void> createEmotionManually({
    required int memberSeq,
    required String calendarDate,
    required String title,
    required String context,
    required int emotionSeq,
  }) async {
    final requestData = {
      'member_seq': memberSeq,
      'calendar_date': calendarDate,
      'title': title,
      'context': context,
      'emotion_seq': emotionSeq,
    };

    print('📤 직접 감정 기록 요청 데이터: $requestData');

    final response = await Dio().post(
      '${Config.baseUrl}/api/emo_calendar/',
      data: requestData,
      options: Options(
        headers: {'Authorization': 'Bearer ${Config.accessToken}'},
        validateStatus: (_) => true,
      ),
    );

    print('📥 감정 저장 응답 상태: ${response.statusCode}');
    print('📥 감정 저장 응답 본문: ${response.data}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("❌ 감정 저장 실패: ${response.statusCode}");
    }
  }

  static Future<void> updateEmotionRecord({
    required int calendarSeq,
    required String title,
    required String content,
    required String emotion,
  }) async {
    final emotionSeq = emotionSeqMap[emotion];
    if (emotionSeq == null) {
      throw Exception('Unknown emotion: $emotion');
    }

    await Dio().put(
      '${Config.baseUrl}/api/emo_calendar/$calendarSeq',
      data: {
        'title': title,
        'context': content,
        'emotion_seq': emotionSeq,
        'character_image_url': '',
      },
      options: Options(
        headers: {'Authorization': 'Bearer ${Config.accessToken}'},
      ),
    );
  }

  static Future<void> deleteEmotionRecord(int calendarSeq) async {
    await Dio().delete(
      '${Config.baseUrl}/api/emo_calendar/$calendarSeq',
      options: Options(
        headers: {'Authorization': 'Bearer ${Config.accessToken}'},
      ),
    );
  }
}
