// screen/calendar/mission_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/custom_header.dart';
import '../../models/mission_record.dart';
import '../../services/mission_service.dart';

class MissionCalendarScreen extends StatefulWidget {
  const MissionCalendarScreen({super.key});

  @override
  State<MissionCalendarScreen> createState() => _MissionCalendarScreenState();
}

class _MissionCalendarScreenState extends State<MissionCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<MissionRecord>> missionRecords = {};

  @override
  void initState() {
    super.initState();
    _loadMonthlyMissions(_focusedDay);
  }

  Future<void> _loadMonthlyMissions(DateTime month) async {
    missionRecords = await MissionService.fetchMonthlySummary(month);
    setState(() {});
  }

  Future<void> _loadDailyMissions(DateTime date) async {
    final records = await MissionService.fetchDailyMissions(date);
    if (records.isNotEmpty) _showMissionViewer(records);
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    final dateOnly = DateTime(selected.year, selected.month, selected.day);
    setState(() {
      _selectedDay = dateOnly;
      _focusedDay = focused;
    });
    _loadDailyMissions(dateOnly);
  }

  // ────── 다이얼로그 (보기 전용) ──────
  void _showMissionViewer(List<MissionRecord> records) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '미션 기록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...records.map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                          color: Colors.black.withOpacity(.06),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          r.cleared
                              ? 'assets/images/mission_complete.png'
                              : 'assets/images/mission_none.png',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.description,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 달력 셀 이미지
  Widget _buildMissionForDay(DateTime day) {
    final record = missionRecords[day]?.first;
    final img =
        (record != null && record.cleared)
            ? 'assets/emotions/mission_stamp.png'
            : 'assets/emotions/mission_none.png';
    return Image.asset(img, width: 35, height: 35);
  }

  Widget _buildDayCell(DateTime day, bool selected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        selected
            ? Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF28B960),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
            : Text('${day.day}', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        _buildMissionForDay(day),
      ],
    );
  }

  void _moveMonth(int offset) {
    setState(
      () =>
          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset),
    );
    _loadMonthlyMissions(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            const Text(
              '미션 캘린더',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 년·월 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _moveMonth(-1),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${_focusedDay.year}',
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                '${_focusedDay.month}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _moveMonth(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TableCalendar(
                        locale: 'ko_KR',
                        rowHeight: 80,
                        daysOfWeekHeight: 28,
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        headerVisible: false,
                        calendarFormat: CalendarFormat.month,
                        selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                        onDaySelected: _onDaySelected,
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          weekendStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarStyle: const CalendarStyle(
                          outsideDaysVisible: false,
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder:
                              (ctx, day, _) => _buildDayCell(day, false),
                          todayBuilder:
                              (ctx, day, _) => _buildDayCell(day, false),
                          selectedBuilder:
                              (ctx, day, _) => _buildDayCell(day, true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
