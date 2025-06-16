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

  @override
  void initState() {
    super.initState();
    _loadMonthlySummary(_focusedDay);
  }

  Future<void> _loadMonthlySummary(DateTime month) async {
    print('[캘린더] _loadMonthlySummary($month)');
    final summaries = await EmotionService.fetchMonthlySummary(month);
    if (!mounted) return;
    setState(() {
      _monthlySummary = {
        for (final s in summaries) DateUtils.dateOnly(s.date): s.emotionSeq,
      };
    });
  }

  Future<void> _loadDailyEmotions(
    BuildContext dialogContext,
    DateTime date,
  ) async {
    print('[캘린더] _loadDailyEmotions($date)');
    final records = await EmotionService.fetchDailyEmotions(
      memberSeq: Config.memberSeq,
      date: date,
    );

    if (!mounted) return;

    if (records.isNotEmpty) {
      setState(() => _dailyRecords[date] = records);
      print('[캘린더] 기록 있음, 레코드뷰어 open');
      if (!mounted) return;
      _showEmotionRecordViewer(dialogContext, date, records);
    } else {
      print('[캘린더] 기록 없음, 인풋 다이얼로그 open');
      if (!mounted) return;
      _showEmotionInputDialog(dialogContext, date);
    }
  }

  void _onDaySelected(
    DateTime selectedDay,
    DateTime focusedDay,
    BuildContext calendarContext,
  ) {
    print('[캘린더] _onDaySelected($selectedDay)');
    final dateOnly = DateUtils.dateOnly(selectedDay);
    setState(() {
      _selectedDay = dateOnly;
      _focusedDay = focusedDay;
    });
    _loadDailyEmotions(calendarContext, dateOnly);
  }

  void _showEmotionInputDialog(
    BuildContext dialogContext,
    DateTime date, {
    int? existingIndex,
  }) {
    print('[캘린더] _showEmotionInputDialog($date)');
    final existingList = _dailyRecords[date];
    final existingRecord =
        (existingIndex != null &&
                existingList != null &&
                existingIndex >= 0 &&
                existingIndex < existingList.length)
            ? existingList[existingIndex]
            : null;

    showDialog(
      context: dialogContext,
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
                print('[캘린더] 감정 저장됨! 캘린더, 데일리 상태 갱신');
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

  void _showEmotionRecordViewer(
    BuildContext dialogContext,
    DateTime date,
    List<EmotionRecord> records,
  ) {
    print('[캘린더] _showEmotionRecordViewer($date, ${records.length}개)');
    showDialog(
      context: dialogContext,
      builder:
          (_) => EmotionRecordViewerDialog(
            records: records,
            memberSeq: Config.memberSeq,
            onEdit:
                (i) => _showEmotionInputDialog(
                  dialogContext,
                  date,
                  existingIndex: i,
                ),
            onDelete: (i) async {
              final rec = records[i];
              if (rec.detail_seq == 0) return;
              print('[캘린더] onDelete: ${rec.detail_seq}');

              try {
                await EmotionService.deleteEmotionRecord(rec.detail_seq);
                final updated = await EmotionService.fetchDailyEmotions(
                  memberSeq: Config.memberSeq,
                  date: date,
                );

                setState(() => _dailyRecords[date] = updated);
                await _loadMonthlySummary(_focusedDay);

                print('[캘린더] 삭제 후, 남은 기록: ${updated.length}');
                // EmotionRecordViewerDialog가 자기 context에서 pop 해줌!
              } catch (e, st) {
                debugPrint('[deleteEmotionRecord] error: $e');
                debugPrintStack(stackTrace: st);
              }
            },
            onAdd: () {
              print('[캘린더] onAdd');
              Navigator.of(dialogContext).pop('add');
              Future.microtask(
                () => _showEmotionInputDialog(dialogContext, date),
              );
            },
          ),
    ).then((result) async {
      print('[캘린더] Dialog 종료 result: $result');
      if (!mounted) return;

      // 추가, 닫기, 혹은 input_dialog에서 닫기 등등이면 다시 열지 않는다
      if (result == 'add' || result == 'closed' || result == null) return;

      // 삭제 등등만 갱신해서 필요하면 다시 열기
      final updated = await EmotionService.fetchDailyEmotions(
        memberSeq: Config.memberSeq,
        date: date,
      );
      if (!mounted) return;

      setState(() => _dailyRecords[date] = updated);

      if (updated.isNotEmpty) {
        print('[캘린더] 삭제 후, 기록 남아 있으니 다시 레코드뷰어 open');
        Future.microtask(
          () => _showEmotionRecordViewer(dialogContext, date, updated),
        );
      } else {
        print('[캘린더] 삭제 후, 기록 없음! 다이얼로그 재오픈 없음');
      }
    });
  }

  Widget _buildEmotionForDay(DateTime day) {
    final seq = _monthlySummary[DateUtils.dateOnly(day)];
    final asset = emotionAsset(seq ?? 0);

    return Opacity(
      opacity: (seq == null || seq == 0) ? 0.3 : 1.0,
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
        child: Builder(
          builder:
              (calendarContext) => Column(
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
                              selectedDayPredicate:
                                  (d) => isSameDay(d, _selectedDay),
                              onDaySelected: (selectedDay, focusedDay) {
                                _onDaySelected(
                                  selectedDay,
                                  focusedDay,
                                  calendarContext,
                                );
                              },
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
                                defaultBuilder:
                                    (c, d, _) => _buildDayCell(d, false),
                                todayBuilder:
                                    (c, d, _) => _buildDayCell(d, false),
                                selectedBuilder:
                                    (c, d, _) => _buildDayCell(d, true),
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
      ),
    );
  }
}
