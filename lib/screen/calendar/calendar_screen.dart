import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../widgets/custom_header.dart';
import '../../models/emotion_record.dart';
import '../../widgets/emotion_input_dialog.dart';
import '../../widgets/emotion_record_viewer_dialog.dart';
import '../../widgets/emotion_from_text_dialog.dart';
import '../../services/emotion_service.dart';
import '../../utils/emotion_helper.dart'; // 💎 새 헬퍼 (seq→asset)

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// 월별 요약: 날짜 → emotionSeq(1~5)
  Map<DateTime, int?> _monthlySummary = {};

  /// 일별 상세: 날짜 → EmotionRecord 목록
  Map<DateTime, List<EmotionRecord>> _dailyRecords = {};

  @override
  void initState() {
    super.initState();
    _loadMonthlySummary(_focusedDay);
  }

  /* ───────────────── 월별 요약 로딩 ───────────────── */
  Future<void> _loadMonthlySummary(DateTime month) async {
    try {
      final summaries = await EmotionService.fetchMonthlySummary(month);
      setState(() {
        _monthlySummary = {
          for (final s in summaries) DateUtils.dateOnly(s.date): s.emotionSeq,
        };
      });
    } catch (e) {
      print('월별 감정 로딩 실패: $e');
    }
  }

  /* ───────────────── 일별 상세 로딩 ───────────────── */
  Future<void> _loadDailyEmotions(DateTime date) async {
    try {
      final records = await EmotionService.fetchDailyEmotions(date);

      if (records.isNotEmpty) {
        setState(() {
          _dailyRecords[date] = records;
        });
        _showEmotionRecordViewer(date, records);
      } else {
        _showEmotionInputDialog(date);
      }
    } catch (e) {
      print('일별 감정 로딩 실패: $e');
      _showEmotionInputDialog(date);
    }
  }

  /* ───────────────── 날짜 선택 ───────────────── */
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final dateOnly = DateUtils.dateOnly(selectedDay);
    setState(() {
      _selectedDay = dateOnly;
      _focusedDay = focusedDay;
    });
    _loadDailyEmotions(dateOnly);
  }

  /* ───────────────── 입력 다이얼로그 ───────────────── */
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
      barrierColor: Colors.black.withOpacity(0),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: EmotionInputDialog(
            date: date,
            existingRecord: existingRecord,
            onSave: (_) async {
              Navigator.pop(context); // 다이얼로그 닫기
              await Future.delayed(const Duration(milliseconds: 300));
              await _loadMonthlySummary(_focusedDay);

              try {
                final updated = await EmotionService.fetchDailyEmotions(date);
                setState(() {
                  _dailyRecords[date] = updated;
                });
              } catch (e) {
                print("❗ 저장 후 감정 재불러오기 실패: $e");
              }
            },
          ),
        );
      },
    );
  }

  /* ───────────────── 기록 뷰어 다이얼로그 ───────────────── */
  void _showEmotionRecordViewer(DateTime date, List<EmotionRecord> records) {
    showDialog(
      context: context,
      builder:
          (context) => EmotionRecordViewerDialog(
            records: records,
            onEdit:
                (index) => _showEmotionInputDialog(date, existingIndex: index),
            onDelete: (index) async {
              final record = records[index];
              if (record.seq != null) {
                try {
                  await EmotionService.deleteEmotionRecord(record.seq!);
                } catch (e) {
                  print('서버 삭제 실패: $e');
                }
              }

              setState(() {
                _dailyRecords[date]!.removeAt(index);
                if (_dailyRecords[date]!.isEmpty) {
                  _dailyRecords.remove(date);
                }
              });

              Navigator.pop(context);

              final updated = _dailyRecords[date];
              if (updated != null && updated.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _showEmotionRecordViewer(date, updated);
                });
              }
            },
            onAdd: () {
              Navigator.pop(context);
              _showEmotionInputDialog(date);
            },
          ),
    );
  }

  /* ───────────────── 셀 하단 감정 아이콘 ───────────────── */
  Widget _buildEmotionForDay(DateTime day) {
    final seq = _monthlySummary[DateUtils.dateOnly(day)];
    if (seq == null) {
      return Image.asset('assets/emotions/none.png', width: 35, height: 35);
    }
    return Image.asset(
      emotionAsset(seq), // 💎 새 헬퍼로 바로 경로 변환
      width: 40,
      height: 40,
    );
  }

  /* ───────────────── 날짜 셀 빌더 ───────────────── */
  Widget _buildDayCell(DateTime day, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        isSelected
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

  /* ───────────────── 월 이동 ───────────────── */
  void _moveMonth(int offset) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset);
    });
    _loadMonthlySummary(_focusedDay);
  }

  /* ───────────────── UI ───────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "감정 캘린더",
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /* ─── 상단 년/월 헤더 ─── */
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
                    /* ─── 캘린더 ─── */
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
                            (day) => isSameDay(day, _selectedDay),
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
                          defaultBuilder:
                              (context, day, _) => _buildDayCell(day, false),
                          todayBuilder:
                              (context, day, _) => _buildDayCell(day, false),
                          selectedBuilder:
                              (context, day, _) => _buildDayCell(day, true),
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
