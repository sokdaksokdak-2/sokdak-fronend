// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:sdsd/services/notification_service.dart';
import 'package:sdsd/onboarding/intro_screen.dart';
import 'package:sdsd/onboarding/nickname_setup_screen.dart';
import 'package:sdsd/providers/theme_provider.dart';
import 'package:sdsd/screen/main_screen.dart';
import 'package:sdsd/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotificationService();

  await Config.load(); // ✅ 반드시 먼저 호출
  debugPrint('앱 시작 시 accessToken: ${Config.accessToken}');

  final String localTz = await FlutterTimezone.getLocalTimezone();
  Config.localTz = localTz;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(
        initialScreen:
            (Config.accessToken.isNotEmpty)
                ? (Config.nickname.isEmpty
                    ? const NicknameSetupScreen()
                    : const MainScreen())
                : const IntroScreen(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription<String?>? _sub;
  late Widget _currentScreen;

  @override
  void initState() {
    super.initState();
    _currentScreen = widget.initialScreen; // ✅ 여기서 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDeepLinks());
  }

  Future<void> _initDeepLinks() async {
    try {
      final String? initial = await _appLinks.getInitialAppLinkString();
      if (initial != null) _handleDeepLink(initial);

      _sub = _appLinks.stringLinkStream.listen((link) {
        if (link != null) _handleDeepLink(link);
      });
    } catch (e) {
      debugPrint('딥링크 오류: $e');
    }
  }

  void _handleDeepLink(String link) {
    debugPrint('딥링크 진입: $link');
    debugPrint('현재 accessToken 상태: ${Config.accessToken}');

    if (Config.lastOAuthLink == link) return;
    if (Config.accessToken.isNotEmpty) return;

    Config.lastOAuthLink = link;
    final uri = Uri.parse(link);
    if (uri.scheme == 'myapp' &&
        uri.host == 'oauth' &&
        uri.path == '/callback') {
      final access = uri.queryParameters['access_token'];
      final refresh = uri.queryParameters['refresh_token'];
      final nick = uri.queryParameters['nickname'];
      final seq = int.tryParse(uri.queryParameters['member_seq'] ?? '');

      if (access != null && seq != null) {
        Config.accessToken = access;
        Config.refreshToken = refresh ?? '';
        Config.nickname = nick ?? '';
        Config.memberSeq = seq;

        setState(() {
          _currentScreen =
              (nick == null || nick.isEmpty)
                  ? const NicknameSetupScreen()
                  : const MainScreen();
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// 로그아웃 시 루트 화면을 IntroScreen 으로 교체
  void resetToIntro() => setState(() => _currentScreen = const IntroScreen());

  @override
  Widget build(BuildContext context) {
    final themeColor = context.watch<ThemeProvider>().themeColor;

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
