import 'package:flutter/material.dart';
import 'package:sdsd/screen/calendar/calendar_screen.dart';
import 'package:sdsd/screen/home_screen.dart';
import 'package:sdsd/screen/mission/mission_list_screen.dart';
import 'package:sdsd/screen/mission/mission_tab_screen.dart';
import 'package:sdsd/screen/report_screen.dart';
import 'package:sdsd/screen/settings_screen.dart';
import 'package:sdsd/globals.dart'; // ✅ 전역 탭 index 변수 import

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 2});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<Widget> _screens;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _screens = const [
      CalendarScreen(),
      ReportScreen(),
      HomeScreen(),
      MissionListScreen(),
      SettingsScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      debugPrint('📩 전달된 arguments: $args');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (args is int) {
          mainTabIndex.value = args;
          debugPrint('✅ MainScreen arguments 적용 완료: $args');
        } else {
          mainTabIndex.value = widget.initialIndex;
          debugPrint('✅ MainScreen 기본값 적용: ${widget.initialIndex}');
        }
      });

      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mainTabIndex,
      builder: (context, selectedIndex, _) {
        return Scaffold(
          body: _screens[selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey.shade400,
            onTap: (index) {
              mainTabIndex.value = index;
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '캘린더'),
              BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: '리포트'),
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
              BottomNavigationBarItem(icon: Icon(Icons.track_changes_outlined), label: '미션'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
            ],
          ),
        );
      },
    );
  }
}
