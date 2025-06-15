import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sdsd/utils/emotion_helper.dart';

class ReportChart extends StatelessWidget {
  final Map<int, double> emotionDistribution;
  final double emotionTemperature;

  const ReportChart({
    super.key,
    required this.emotionDistribution,
    required this.emotionTemperature,
  });

  @override
  Widget build(BuildContext context) {
    final sections = emotionDistribution.entries.map((entry) {
      final info = kEmotionInfoMap[entry.key]!;
      return PieChartSectionData(
        value: entry.value,
        color: info.color,
        title: '${entry.value.toInt()}%',
      );
    }).toList();

    final legends = emotionDistribution.keys.map((key) {
      final info = kEmotionInfoMap[key]!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: info.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(info.label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 온도 수치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '이번달 감정온도',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '36.5℃',
                style: TextStyle(
                  color: Color(0xFF28B960),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.365, // 36.5도 고정 비율
              color: const Color(0xFF28B960),
              backgroundColor: Colors.grey.shade200,
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                    startDegreeOffset: 270,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: legends,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
