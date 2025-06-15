// lib/services/emotion_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sdsd/config.dart';
import '../network/dio_client.dart';
import '../models/emotion_calendar_summary.dart';
import '../models/emotion_record.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmotionService {
  static final Dio _dio = DioClient.instance.dio;
  static const String _baseUrl = '${Config.baseUrl}/api/emo_calendar';

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
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final res = await _dio.get(
      '/api/emo_calendar/daily',
      queryParameters: {
        'member_seq'   : memberSeq,
        'calendar_date': dateStr,
      },
      options: Options(headers: {
        'Authorization': 'Bearer ${Config.accessToken}',
      }),
    );


    return (res.data as List)
        .map((e) => EmotionRecord.fromJson(e))
        .toList();
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

  static Future<EmotionRecord> createEmotionManually({
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

    final data = res.data;
    if (data == null || data['detail_seq'] == null) {
      throw Exception('❌ 서버 응답에 detail_seq가 없음');
    }

// 👉 EmotionRecord.fromJson에 맞는 필드가 없을 경우 직접 매핑
    return EmotionRecord(
      detail_seq: data['detail_seq'],
      emotionSeq: data['emotion_seq'],
      title: data['title'] ?? '',
      content: data['context'] ?? '',
      calendarDate: data['calendar_date'] != null
          ? DateTime.parse(data['calendar_date'])
          : DateTime.now(), // 또는 null 허용
    );
  }

  /// 감정 기록 추가
  static Future<EmotionRecord> createEmotionRecord({
    required int memberSeq,
    required DateTime date,
    required int emotionSeq,
    required String title,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_seq': memberSeq,
          'calendar_date': date.toIso8601String().split('T').first,
          'emotion_seq': emotionSeq,
          'title': title,
          'context': content,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return EmotionRecord.fromJson(json);
      } else {
        throw Exception('감정 기록 추가 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('감정 기록 추가 중 오류 발생: $e');
    }
  }

  /// 감정 기록 수정
  static Future<EmotionRecord> updateEmotionRecord({
    required int detailSeq,
    required int memberSeq,
    required int emotionSeq,
    required String title,
    required String content,
  }) async {
    final res = await _dio.put(
      '$_baseUrl/$detailSeq',
      queryParameters: {
        'member_seq': memberSeq,
      },
      data: {
        'emotion_seq': emotionSeq,
        'title': title,
        'context': content,
      },
      options: Options(validateStatus: (_) => true),
    );

    if (res.statusCode != 200) {
      throw Exception('감정 기록 수정 실패: ${res.statusCode}');
    }

    final data = res.data;
    if (data == null || data['detail_seq'] == null) {
      throw Exception('❌ 서버 응답에 detail_seq가 없음');
    }

    return EmotionRecord(
      detail_seq: data['detail_seq'],
      emotionSeq: data['emotion_seq'],
      title: data['title'] ?? '',
      content: data['context'] ?? '',
      calendarDate: data['calendar_date'] != null
          ? DateTime.parse(data['calendar_date'])
          : DateTime.now(),
    );
  }


  /// 감정 기록 삭제
  static Future<void> deleteEmotionRecord(int detailSeq) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/delete/$detailSeq?member_seq=${Config.memberSeq}'),
      );

      if (response.statusCode != 200) {
        throw Exception('감정 기록 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('감정 기록 삭제 중 오류 발생: $e');
    }
  }
}
