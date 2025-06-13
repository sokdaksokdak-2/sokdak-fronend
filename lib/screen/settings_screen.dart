import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:sdsd/config.dart';
import 'package:sdsd/main.dart'; // ← MyAppState 접근
import 'package:sdsd/onboarding/intro_screen.dart';
import 'package:sdsd/screen/login_screen.dart';
import 'package:sdsd/screen/settings/feedback_screen.dart';
import 'package:sdsd/screen/settings/nickname_edit_screen.dart';
import 'package:sdsd/screen/settings/notification_setting_screen.dart';
import 'package:sdsd/screen/settings/privacy_policy_screen.dart';
import 'package:sdsd/screen/settings/terms_of_service_screen.dart';
import 'package:sdsd/screen/settings/theme_setting_screen.dart';
import 'package:sdsd/widgets/custom_header.dart';
import 'package:sdsd/widgets/profile_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logoutAndGoToIntro(BuildContext context) async {
    debugPrint('🧼 로그아웃 시작');
    debugPrint('🧼 로그아웃 전 accessToken: ${Config.accessToken}');

    await _revokeNaverToken();
    await Config.clear();

    debugPrint('🧼 로그아웃 후 accessToken: ${Config.accessToken}');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IntroScreen()),
      (_) => false,
    );

    context.findAncestorStateOfType<MyAppState>()?.resetToIntro();
  }

  Future<void> _revokeNaverToken() async {
    if (Config.accessToken.isEmpty) return;

    const clientId = 'AuARYXdKUbOgxePEuV7_';
    const clientSecret = 'pdhpc9WwfW';

    final uri = Uri.parse(
      'https://nid.naver.com/oauth2.0/token'
      '?grant_type=delete'
      '&client_id=$clientId'
      '&client_secret=$clientSecret'
      '&access_token=${Uri.encodeComponent(Config.accessToken)}'
      '&service_provider=NAVER',
    );

    try {
      final res = await http.get(uri);
      debugPrint('네이버 토큰 폐기 응답 → ${res.statusCode} / ${res.body}');
    } catch (e) {
      debugPrint('네이버 토큰 폐기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '설정',
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 34),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProfileCard(),
                      const SizedBox(height: 12),
                      _buildCard(
                        context: context,
                        title: '내 정보 관리',
                        items: ['닉네임 변경', '감정 기록 알림 시간 설정', '테마 색상 변경'],
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        context: context,
                        title: '앱 정보 및 정책',
                        items: ['서비스 이용약관', '개인정보 처리방침', '의견 보내기'],
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        context: context,
                        title: '계정 관리',
                        items: ['로그아웃', '회원탈퇴'],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required List<String> items,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              minVerticalPadding: 0,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: _iconForTitle(title),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            const Divider(height: 0, thickness: 0.8),
            ...items.map(
              (item) => ListTile(
                dense: true,
                minVerticalPadding: 0,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(item, style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  switch (item) {
                    case '회원탈퇴':
                      _showDeleteAccountDialog(context);
                      break;
                    case '로그아웃':
                      _showLogoutDialog(context);
                      break;
                    case '테마 색상 변경':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ThemeSettingScreen(),
                        ),
                      );
                      break;
                    case '닉네임 변경':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NicknameEditScreen(),
                        ),
                      );
                      break;
                    case '감정 기록 알림 시간 설정':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingScreen(),
                        ),
                      );
                      break;
                    case '서비스 이용약관':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      );
                      break;
                    case '개인정보 처리방침':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                      break;
                    case '의견 보내기 / 도움 요청하기':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      );
                      break;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '로그아웃 하시겠습니까?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await _logoutAndGoToIntro(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('확인'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '모든 감정 기록은 삭제됩니다.\n탈퇴하시겠습니까?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              final uri = Uri.parse(
                                '${Config.baseUrl}/api/members/${Config.memberSeq}',
                              );
                              try {
                                final res = await http.delete(
                                  uri,
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization':
                                        'Bearer ${Config.accessToken}',
                                  },
                                );
                                if (res.statusCode == 200) {
                                  await Config.clear();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const IntroScreen(),
                                    ),
                                    (_) => false,
                                  );
                                  context
                                      .findAncestorStateOfType<MyAppState>()
                                      ?.resetToIntro();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('회원탈퇴에 실패했어요'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('탈퇴 중 예외: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('서버 오류')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('확인'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Icon _iconForTitle(String title) {
    if (title.contains('내 정보')) return const Icon(Icons.person_outline);
    if (title.contains('앱 정보')) return const Icon(Icons.info_outline);
    if (title.contains('계정')) return const Icon(Icons.logout_outlined);
    return const Icon(Icons.settings);
  }
}
