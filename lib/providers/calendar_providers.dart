import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emotion_calendar_summary.dart';
import '../services/emotion_service.dart';

/// (월별) 날짜-별 가장 강한 감정 목록
///
/// ✅ ① autoDispose를 붙여서 메모리 누수 방지
/// ✅ ② 화살표 함수 대신 중괄호/return 도 OK – 취향 선택
final monthlySummaryProvider =
FutureProvider.autoDispose.family<List<EmotionCalendarSummary>, DateTime>(
      (ref, month) async {
    return EmotionService.fetchMonthlySummary(month);
  },
);
