// lib/screens/calendar/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:sdsd/config.dart';
import '../../widgets/custom_header.dart';
import '../../models/emotion_record.dart';
import '../../services/emotion_service.dart';
import '../../utils/emotion_helper.dart';
import 'package:sdsd/widgets/emoion_input_dialog.dart';
import '../../widgets/emotion_record_viewer_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, int?> _monthlySummary = {};
  Map<DateTime, List<EmotionRecord>> _dailyRecords = {};

  bool _openedFromAddButton = false;
  bool _isDeletingLastRecord = false;

  @override
  void initState() {
    super.initState();
    _loadMonthlySummary(_focusedDay);
  }

  Future<void> _loadMonthlySummary(DateTime month) async {
    final summaries = await EmotionService.fetchMonthlySummary(month);
    if (!mounted) return;
    setState(() {
      _monthlySummary = {
        for (final s in summaries) DateUtils.dateOnly(s.date): s.emotionSeq,
      };
    });
  }

  Future<void> _loadDailyEmotions(DateTime date) async {
    final records = await EmotionService.fetchDailyEmotions(
      memberSeq: Config.memberSeq,
      date: date,
    );

    if (!mounted) return;

    if (records.isNotEmpty) {
      setState(() => _dailyRecords[date] = records);
      if (!mounted) return;
      _showEmotionRecordViewer(date, records);
    } else {
      if (!mounted) return;
      _showEmotionInputDialog(date);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final dateOnly = DateUtils.dateOnly(selectedDay);
    setState(() {
      _selectedDay = dateOnly;
      _focusedDay = focusedDay;
    });
    _loadDailyEmotions(dateOnly);
  }

  void _showEmotionInputDialog(DateTime date, {int? existingIndex}) {
    final existingList = _dailyRecords[date];
    final existingRecord =
        (existingIndex != null &&
                existingList != null &&
                existingIndex >= 0 &&
                existingIndex < existingList.length)
            ? existingList[existingIndex]
            : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: EmotionInputDialog(
              date: date,
              existingRecord: existingRecord,
              onSave: (_) async {
                await Future.delayed(const Duration(milliseconds: 300));
                if (!mounted) return;
                await _loadMonthlySummary(_focusedDay);
                if (!mounted) return;
                final updated = await EmotionService.fetchDailyEmotions(
                  memberSeq: Config.memberSeq,
                  date: date,
                );
                if (!mounted) return;
                setState(() => _dailyRecords[date] = updated);
              },
            ),
          ),
    );
  }

  void _showEmotionRecordViewer(DateTime date, List<EmotionRecord> records) {
    _openedFromAddButton = false;
    _isDeletingLastRecord = false;

    showDialog(
      context: context,
      builder: (_) => EmotionRecordViewerDialog(
        records: records,
        memberSeq: Config.memberSeq,
        onEdit: (i) => _showEmotionInputDialog(date, existingIndex: i),
        onDelete: (i) async {
          final rec = records[i];
          if (rec.detail_seq == 0) return;

          try {
            await EmotionService.deleteEmotionRecord(rec.detail_seq);
            final updated = await EmotionService.fetchDailyEmotions(
              memberSeq: Config.memberSeq,
              date: date,
            );

            setState(() => _dailyRecords[date] = updated);
            await _loadMonthlySummary(_focusedDay);

            _isDeletingLastRecord = updated.isEmpty;

            Navigator.of(context).pop('deleted'); // ✅ 값 전달!
          } catch (e, st) {
            debugPrint('[deleteEmotionRecord] error: $e');
            debugPrintStack(stackTrace: st);
          }
        },
        onAdd: () {
          _openedFromAddButton = true;
          Navigator.pop(context, 'add'); // ✅ 값 전달!
          Future.microtask(() => _showEmotionInputDialog(date));
        },
      ),
    ).then((result) async {
      if (!mounted) return;

      // ✅ 사용자가 닫기 버튼 눌렀다면 그냥 리턴
      if (result != null) return;

      final updated = await EmotionService.fetchDailyEmotions(
        memberSeq: Config.memberSeq,
        date: date,
      );
      if (!mounted) return;

      setState(() => _dailyRecords[date] = updated);

      // ✅ 기록 있을 때만 다시 열기
      if (updated.isNotEmpty) {
        Future.microtask(() => _showEmotionRecordViewer(date, updated));
      }
    });


  }

  Widget _buildEmotionForDay(DateTime day) {
    final seq = _monthlySummary[DateUtils.dateOnly(day)];

    final asset = emotionAsset(seq ?? 0);

    return Opacity(
      opacity: (seq == null || seq == 0) ? 0.3 : 1.0, // 감정 없을 때만 반투명
      child: Image.asset(asset, width: 40, height: 40),
    );
  }


  Widget _buildDayCell(DateTime day, bool selected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        selected
            ? Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF28B960),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
            : Text('${day.day}', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        _buildEmotionForDay(day),
      ],
    );
  }

  void _moveMonth(int offset) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset);
    });
    _loadMonthlySummary(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        child: Column(
          children: [
            const Text('감정 캘린더', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                        daysOfWeekHeight: 32,
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        headerVisible: false,
                        calendarFormat: CalendarFormat.month,
                        selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                        onDaySelected: _onDaySelected,
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(fontSize: 18),
                          weekendStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarStyle: const CalendarStyle(
                          outsideDaysVisible: false,
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (c, d, _) => _buildDayCell(d, false),
                          todayBuilder: (c, d, _) => _buildDayCell(d, false),
                          selectedBuilder: (c, d, _) => _buildDayCell(d, true),
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
