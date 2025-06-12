// lib/onboarding/intro_screen.dart
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/screen/main_screen.dart';
import 'package:sdsd/screen/start_screen.dart';
import 'package:sdsd/onboarding/nickname_setup_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // 딥링크 감지용
  final AppLinks _appLinks = AppLinks();

  // 온보딩 콘텐츠
  final List<Map<String, String>> pages = [
    {
      'title': '안녕!\n오늘부터 우리랑 이야기 나눠볼래?',
      'image': 'assets/gif_slow/angry1_slow_1_5x.gif',
      'description': '마음을 나누고,\n위로와 웃음을 함께 받아보세요',
    },
    {
      'title': '마음이 무거운 날엔,\n회복 미션을 추천해드려요.',
      'image': 'assets/images/intro_1.png',
      'description': '지친 마음엔 휴식이 필요해요.\n당신을 위한 작은 미션을 준비해두었어요!',
    },
    {
      'title': '오늘 기분,\n어떤 색으로 칠해볼까요?',
      'image': 'assets/images/intro_2.png',
      'description': '오늘의 기분을 조용히 남겨두면\n언젠가 당신의 이야기가 돼요',
    },
    {
      'title': '당신의 마음,\n이제 혼자 두지 마세요.',
      'image': 'assets/images/intro_3.png',
      'description': '감정의 흐름을 리포트로 정리해드릴게요.\n당신도 몰랐던 감정을 발견할 수 있어요',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkDeepLink(); // cold-start 시 한 번
  }

  /// OAuth 콜백 딥링크 처리
  Future<void> _checkDeepLink() async {
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri == null) return;

      final link = uri.toString();
      if (Config.accessToken.isNotEmpty) return;
      if (Config.lastOAuthLink == link) return;

      if (uri.scheme == 'myapp' &&
          uri.host == 'oauth' &&
          uri.path == '/callback') {
        final accessToken = uri.queryParameters['access_token'];
        final refreshToken = uri.queryParameters['refresh_token'];
        final nickname = uri.queryParameters['nickname'];
        final memberSeq = int.tryParse(uri.queryParameters['member_seq'] ?? '');

        if (accessToken != null && memberSeq != null) {
          Config.lastOAuthLink = link;

          // ❌ cascade(X) → ✅ 개별 대입(O)
          Config.accessToken = accessToken;
          Config.refreshToken = refreshToken ?? '';
          Config.nickname = nickname ?? '';
          Config.memberSeq = memberSeq;

          final Widget target =
              (nickname == null || nickname.isEmpty)
                  ? const NicknameSetupScreen()
                  : const MainScreen();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => target),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 딥링크 처리 오류: $e');
    }
  }

  // 다음으로
  void _nextPage() {
    if (_currentIndex < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StartScreen()),
      );
    }
  }

  // 이전으로
  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Image.asset(
              'assets/images/sdsd1.png',
              height: 45,
              fit: BoxFit.contain,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (_, idx) {
                  final page = pages[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                        Image.asset(
                          page['image']!,
                          height: 340,
                          fit: BoxFit.contain,
                        ),
                        Text(
                          page['description']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (idx) => Container(
                  margin: const EdgeInsets.all(10),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        _currentIndex == idx
                            ? const Color(0xFF28B960)
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide.none,
                        ),
                        child: const Text(
                          '이전',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 30),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF28B960),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentIndex == pages.length - 1 ? '완료' : '다음',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
