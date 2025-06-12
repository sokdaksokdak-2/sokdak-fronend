import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../network/dio_client.dart';

class Config {
  // ✅ 개발 중엔 이걸 사용

  static const String baseUrl = 'http://192.168.219.141:8000';


  // 로그인 후 저장되는 값
  static int memberSeq = -1;
  static String nickname = '';
  static String email = ''; // ✅ 추가
  static String accessToken = '';
  static String refreshToken = '';

  /// 중복 딥링크 재처리를 막기 위한 최근 링크
  static String lastOAuthLink = '';

  // 디바이스 타임존
  static String localTz = 'UTC';

  /// 앱 시작 시 SharedPreferences에서 값 불러오기
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    memberSeq = prefs.getInt('memberSeq') ?? -1;
    nickname = prefs.getString('nickname') ?? '';
    email = prefs.getString('email') ?? ''; // ✅ 추가
    accessToken = prefs.getString('accessToken') ?? '';
    refreshToken = prefs.getString('refreshToken') ?? '';
    lastOAuthLink = prefs.getString('lastOAuthLink') ?? '';
    localTz = prefs.getString('localTz') ?? 'UTC';
  }

  /// 로그인 성공 시 Config와 SharedPreferences에 저장
  static Future<void> saveAuth({
    required int seq,
    required String nick,
    required String emailAddr,
    required String access,
    required String refresh,
  }) async {
    memberSeq     = seq;
    nickname      = nick;
    email         = emailAddr;
    accessToken   = access;
    refreshToken  = refresh;

    // ✅✅ 바로 아래 두 줄만 추가!
    // 이미 만들어진 dio의 Authorization 헤더 교체
    DioClient.instance.dio.options.headers['Authorization'] = 'Bearer $access';
    // 혹시 인터셉터가 있다면 options.extra 등으로도 동기화 가능

    debugPrint('✅ saveAuth: access=$access, refresh=$refresh, email=$emailAddr');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('memberSeq', seq);
    await prefs.setString('nickname', nick);
    await prefs.setString('email', emailAddr);
    await prefs.setString('accessToken', access);
    await prefs.setString('refreshToken', refresh);
  }

  /// 로그아웃 / 회원탈퇴 시 모든 값 초기화 (메모리 + SharedPreferences)
  static Future<void> clear() async {
    memberSeq = -1;
    nickname = '';
    email = ''; // ✅ 초기화
    accessToken = '';
    refreshToken = '';
    lastOAuthLink = '';
    localTz = 'UTC';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('memberSeq');
    await prefs.remove('nickname');
    await prefs.remove('email'); // ✅ 삭제
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('lastOAuthLink');
    await prefs.remove('localTz');
  }

  // 🚀 배포 시 baseUrl 교체
  // static const String baseUrl = 'https://api.mysite.com';
}
