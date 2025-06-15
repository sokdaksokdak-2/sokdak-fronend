// lib/services/mission_service.dart
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:sdsd/models/mission_list_item.dart';
import 'package:sdsd/models/mission_record.dart';
import '../config.dart';
import '../models/mission_suggestion.dart';


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

  /// 특정 회원의 미션 목록 (최신 생성일 순)
  static Future<List<MissionListItem>> fetchAllMissions() async {
    try {
      final response = await Dio().get(
        '${Config.baseUrl}/api/members/${Config.memberSeq}/missions',
        options: Options(headers: {
          'Authorization': 'Bearer ${Config.accessToken}',
        }),
      );

      final data = response.data as List<dynamic>;
      return data.map((item) => MissionListItem.fromJson(item)).toList();
    } catch (e) {
      print('$e');
      throw Exception('미션 목록 불러오기 실패: $e');
    }
  }
  /// 특정 회원의 최근 생성 미션

  /// 미션 수락 (서버로 미션 제안 수락 요청)
  static Future<void> acceptMission(MissionSuggestion suggestion) async {
    try {
      final response = await Dio().post(
        '${Config.baseUrl}/api/members/${Config.memberSeq}/missions/accept',
        data: {
          'mission_seq': suggestion.missionSeq,
          'title': suggestion.title,
        },
        options: Options(headers: {
          'Authorization': 'Bearer ${Config.accessToken}',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('미션 수락 실패');
      }
    } catch (e) {
      print('❌ 미션 수락 오류: $e');
      throw Exception('미션 수락 실패: $e');
    }
  }

  /// 미션 완료
  static Future<void> completeMission(int memberMissionSeq) async {
    try {
      final response = await Dio().patch(
        '${Config.baseUrl}/api/members/missions/$memberMissionSeq/complete',
        options: Options(headers: {
          'Authorization': 'Bearer ${Config.accessToken}',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('미션 완료 실패');
      }
    } catch (e) {
      print('❌ 미션 완료 오류: $e');
      throw Exception('미션 완료 실패: $e');
    }
  }

  /// 미션 포기 (삭제)
  static Future<void> deleteMission(int memberMissionSeq) async {
    try {
      final response = await Dio().delete(
        '${Config.baseUrl}/api/members/missions/$memberMissionSeq',
        options: Options(headers: {
          'Authorization': 'Bearer ${Config.accessToken}',
        }),
      );

      if (response.statusCode != 204) {
        throw Exception('미션 삭제 실패');
      }
    } catch (e) {
      print('❌ 미션 삭제 오류: $e');
      throw Exception('미션 삭제 실패: $e');
    }
  }




}
