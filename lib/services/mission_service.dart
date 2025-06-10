// lib/services/mission_service.dart
import 'dart:math';
import 'package:sdsd/models/mission_record.dart';

class MissionService {
  /// 월별 요약 (날짜별로 완료/미완료만 알면 되므로 List 길이를 1로 사용)
  static Future<Map<DateTime, List<MissionRecord>>> fetchMonthlySummary(
      DateTime month) async {
    //-------------------------------//
    // TODO: 실제 API 붙이기 전 임시 더미
    //-------------------------------//
    final random = Random();
    final Map<DateTime, List<MissionRecord>> map = {};
    final lastDay =
        DateTime(month.year, month.month + 1, 0).day; // 그 달 마지막 날짜
    for (int d = 1; d <= lastDay; d++) {
      final date = DateTime(month.year, month.month, d);
      map[date] = [
        MissionRecord(
          title: 'dummy',
          description: '',
          cleared: random.nextBool(), // 랜덤 완료/미완료
        )
      ];
    }
    return map;
  }

  /// 일별 상세 (해당 날짜의 미션 기록 모두 조회)
  static Future<List<MissionRecord>> fetchDailyMissions(DateTime date) async {
    //-------------------------------//
    // TODO: 실제 API 붙이기 전 임시 더미
    //-------------------------------//
    return [
      MissionRecord(
        title: '친구들과의 이별',
        description: '울어도 괜찮아. 지금 이 감정을 편지로 써봐!',
        cleared: true,
      ),
      MissionRecord(
        title: '끝내주는 날씨',
        description: '이럴 땐! 이 순간을 영상으로 찍어서 남겨봐~',
        cleared: true,
      ),
    ];
  }
}
