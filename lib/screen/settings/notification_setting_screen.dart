import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdsd/services/notification_service.dart';
import 'package:sdsd/widgets/custom_header.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool _isNotificationOn = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    print('[초기화] NotificationSettingScreen 시작됨');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isOn = prefs.getBool('isNotificationOn') ?? false;
    final hour = prefs.getInt('notificationHour') ?? 20;
    final minute = prefs.getInt('notificationMinute') ?? 0;

    print('[저장값 불러오기] isOn=$isOn, hour=$hour, minute=$minute');

    setState(() {
      _isNotificationOn = isOn;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });

    if (isOn) {
      print('[예약 호출] 저장된 값으로 알림 예약 시도');
      scheduleDailyNotification(_selectedTime);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationOn', _isNotificationOn);
    await prefs.setInt('notificationHour', _selectedTime.hour);
    await prefs.setInt('notificationMinute', _selectedTime.minute);
  }

  void _onTimeChanged(DateTime newTime) {
    setState(() {
      _selectedTime = TimeOfDay(hour: newTime.hour, minute: newTime.minute);
    });

    print('[시간변경] 새로운 시간: ${_selectedTime.hour}:${_selectedTime.minute}');

    _saveSettings();

    if (_isNotificationOn) {
      print('[시간변경] 알림 재예약 시도');
      scheduleDailyNotification(_selectedTime);
    }
  }

  void _toggleNotification(bool value) {
    print('[토글] 알림 스위치 변경됨: $value');

    setState(() {
      _isNotificationOn = value;
    });

    _saveSettings();

    if (value) {
      print('[토글] 알림 예약 시도');
      scheduleDailyNotification(_selectedTime);
    } else {
      print('[토글] 알림 취소 시도');
      cancelNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '알림 시간 설정',
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 34),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '알림 받기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CupertinoSwitch(
                          value: _isNotificationOn,
                          onChanged: _toggleNotification,
                          activeColor: const Color(0xFF28B960),
                          trackColor: Colors.grey[300],
                        ),
                      ],
                    ),
                    if (_isNotificationOn) ...[
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 240,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            height: 280,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              initialDateTime: DateTime(
                                2024,
                                1,
                                1,
                                _selectedTime.hour,
                                _selectedTime.minute,
                              ),
                              use24hFormat: false,
                              onDateTimeChanged: _onTimeChanged,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '감정 기록을 잊지 않도록\n원하는 시간에 알림을 받아보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
