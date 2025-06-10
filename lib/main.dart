// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart'; // ✅ 딥링크 패키지
import 'package:flutter_timezone/flutter_timezone.dart'; // ✅ 현지 타임존 패키지
import 'package:sdsd/services/notification_service.dart'; // ✅ 알림 초기화

import 'package:sdsd/onboarding/intro_screen.dart';
import 'package:sdsd/onboarding/nickname_setup_screen.dart';
import 'package:sdsd/providers/theme_provider.dart';
import 'package:sdsd/screen/main_screen.dart';
import 'package:sdsd/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ 비동기 초기화 보장

  await initializeNotificationService(); // ✅ 알림 서비스 초기화

  // ✅ 현지 타임존 문자열 가져오기
  final String localTz = await FlutterTimezone.getLocalTimezone();
  debugPrint('내 디바이스 타임존 → $localTz');

  // 필요하다면 전역으로 저장해서 어디서든 사용 가능하게 합니다.
  // Config.localTz 는 Config 클래스에 String? localTz; 를 추가해 주세요.
  Config.localTz = localTz;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks(); // ✅ singleton
  StreamSubscription<String?>? _sub; // ✅ 타입 명시
  Widget _currentScreen = const IntroScreen();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      // cold‑start 링크
      final String? initialLink = await _appLinks.getInitialAppLinkString();
      if (initialLink != null) _handleDeepLink(initialLink);

      // background → foreground 링크
      _sub = _appLinks.stringLinkStream.listen((String? link) {
        if (link != null) _handleDeepLink(link);
      });
    } catch (e) {
      print('딥링크 처리 중 오류 발생: $e');
    }
  }

  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);

    if (uri.scheme == 'myapp' &&
        uri.host == 'oauth' &&
        uri.path == '/callback') {
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];
      final nickname = uri.queryParameters['nickname'];
      final memberSeq = int.tryParse(uri.queryParameters['member_seq'] ?? '');

      if (accessToken != null && memberSeq != null) {
        Config.accessToken = accessToken;
        Config.refreshToken = refreshToken ?? '';
        Config.nickname = nickname ?? '';
        Config.memberSeq = memberSeq;

        final needsNickname = nickname == null || nickname.isEmpty;

        setState(() {
          _currentScreen =
              needsNickname ? const NicknameSetupScreen() : const MainScreen();
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Provider.of<ThemeProvider>(context).themeColor;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        scaffoldBackgroundColor: themeColor,
        appBarTheme: AppBarTheme(backgroundColor: themeColor),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: themeColor,
        ),
      ),
      home: _currentScreen,
    );
  }
}
