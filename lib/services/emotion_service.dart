// lib/services/emotion_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sdsd/config.dart';
import '../network/dio_client.dart';
import '../models/emotion_calendar_summary.dart';
import '../models/emotion_record.dart';

class EmotionService {
  static final Dio _dio = DioClient.instance.dio;

  // ───────── 월별 요약 ─────────
  static Future<List<EmotionCalendarSummary>> fetchMonthlySummary(
    DateTime targetMonth,
  ) async {
    final res = await _dio.get(
      '/api/emo_calendar/monthly_summary',
      queryParameters: {
        'member_seq': Config.memberSeq,
        'year': targetMonth.year,
        'month': targetMonth.month,
      },
      options: Options(validateStatus: (_) => true),
    );
    return (res.data as List?)
            ?.map((e) => EmotionCalendarSummary.fromJson(e))
            .toList() ??
        [];
  }

  // ───────── 일별 조회 ─────────
  static Future<List<EmotionRecord>> fetchDailyEmotions({
    required int memberSeq,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final res = await _dio.get(
      '/api/emo_calendar/daily',
      queryParameters: {'member_seq': memberSeq, 'calendar_date': dateStr},
      options: Options(validateStatus: (_) => true),
    );

    return (res.data as List?)
            ?.map((item) => EmotionRecord.fromJson(item))
            .toList() ??
        [];
  }

  // ───────── 분석 + 저장 (AI) ─────────
  static Future<EmotionRecord> analyzeAndSave({
    required DateTime date,
    required String text,
    required String title,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final aiRes = await _dio.post(
      '/api/chatbot/complete/${Config.memberSeq}',
      data: {'calendar_date': dateStr, 'text': text, 'title': title},
      options: Options(responseType: ResponseType.json),
    );

    final data = aiRes.data;
    final emotionSeq =
        (data['emotion'] is int)
            ? data['emotion'] as int
            : int.tryParse(data['emotion']?.toString() ?? '') ?? 0;

    if (emotionSeq < 1 || emotionSeq > 5) {
      throw Exception('⚠️ 잘못된 emotion_seq 수신: $emotionSeq');
    }

    final saveRes = await _dio.post(
      '/api/emo_calendar/',
      data: {
        'member_seq': Config.memberSeq,
        'calendar_date': dateStr,
        'title': title.isNotEmpty ? title : '감정 기록',
        'context': data['context'] ?? '',
        'emotion_seq': emotionSeq,
      },
      options: Options(validateStatus: (_) => true),
    );

    if (saveRes.statusCode != 200 && saveRes.statusCode != 201) {
      throw Exception('❌ 감정 저장 실패: ${saveRes.statusCode}');
    }

    return EmotionRecord.fromJson(saveRes.data as Map<String, dynamic>);
  }

  // ───────── 직접 생성 ─────────
  static Future<void> createEmotionManually({
    required int memberSeq,
    required String calendarDate,
    required String title,
    required String context,
    required int emotionSeq,
  }) async {
    final res = await _dio.post(
      '/api/emo_calendar/',
      data: {
        'member_seq': memberSeq,
        'calendar_date': calendarDate,
        'title': title,
        'context': context,
        'emotion_seq': emotionSeq,
      },
      options: Options(validateStatus: (_) => true),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('❌ 감정 저장 실패: ${res.statusCode}');
    }
  }

  // ───────── 수정 ─────────
  static Future<void> updateEmotionRecord({
    required int detailSeq,
    required int memberSeq,
    required int emotionSeq,
    required String title,
    required String content,
  }) async {
    final res = await _dio.put(
      '/api/emo_calendar/$detailSeq',
      queryParameters: {'member_seq': memberSeq},
      data: {'title': title, 'context': content, 'emotion_seq': emotionSeq},
      options: Options(validateStatus: (_) => true),
    );

    if (res.statusCode != 200) {
      throw Exception('❌ 감정 수정 실패: ${res.statusCode}');
    }
  }

  // ───────── 삭제 ─────────
  // == 제안 : DELETE 개선안 ==
  // == DELETE (detailSeq 단독 버전) ==
  static Future<void> deleteEmotionRecord({
    required int detailSeq,   // ← 이제 detailSeq 하나만 필요
    required int memberSeq,
  }) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        // 백엔드가 detailSeq 단독 엔드포인트로 열어둔 경우
        // 예: DELETE /api/emo_calendar/detail/{detail_seq}
        '/api/emo_calendar/detail/$detailSeq',
        queryParameters: {
          'member_seq': memberSeq,   // 권한 확인용
        },
        options: Options(
          // interceptor에서 공통 헤더를 주입한다면 생략 가능
          headers: {
            'Authorization': 'Bearer ${Config.accessToken}',
            'accept': 'application/json',
          },
          // 404(존재하지 않음)까지는 throw 하지 않고 직접 처리
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      print('[DELETE-RESP] ${res.statusCode}  ${res.data}');

      if (res.statusCode == 200) return;               // ✅ 삭제 성공
      if (res.statusCode == 404) {
        throw Exception('이미 삭제되었거나 존재하지 않는 항목입니다.');
      }
      throw Exception('알 수 없는 오류: ${res.statusCode}');
    } catch (e, st) {
      debugPrint('[DELETE-ERR] $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }


}
