import 'package:flutter/material.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/widgets/report_chart.dart';
import 'package:sdsd/widgets/report_ranking.dart';
import 'package:sdsd/utils/emotion_helper.dart';
import 'package:dio/dio.dart';
import '../../widgets/custom_header.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  Map<int, double> emotionDistribution = {};
  List<int> topEmotions = [];
  double emotionTemperature = 0.0;

  @override
  void initState() {
    super.initState();
    print('🟢 ReportScreen initState 호출됨');
    fetchEmotionReport();
  }

  Future<void> fetchEmotionReport() async {
    print('🚀 fetchEmotionReport() called');
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final memberSeq = Config.memberSeq;

    try {
      final response = await Dio().get(
        '${Config.baseUrl}/api/emo_report/',
        queryParameters: {
          'year': year,
          'month': month,
          'member_seq': memberSeq,
        },
        options: Options(validateStatus: (_) => true),
      );

      print('📦 statusCode: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data =
            response.data['emotion_distribution'] as Map<String, dynamic>;
        final parsed = data.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        );

        final sortedEmotions =
            parsed.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        print('✅ emotionDistribution: $parsed');
        print('🏅 topEmotions: ${sortedEmotions.map((e) => e.key).toList()}');

        setState(() {
          emotionDistribution = parsed;
          topEmotions =
              sortedEmotions.map((e) => e.key).toList().take(5).toList();
          emotionTemperature =
              parsed.values.isNotEmpty
                  ? parsed.values.reduce((a, b) => a + b) / 100.0
                  : 0.0;
        });
      } else {
        print('⚠️ 서버 응답 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 리포트 조회 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🖥 ReportScreen build 실행됨');
    final paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "월간 리포트",
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 34),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      children: [
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 8),
                              ],
                            ),
                            child: ReportRanking(topEmotions: topEmotions),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 8),
                              ],
                            ),
                            child: ReportChart(
                              emotionDistribution: emotionDistribution,
                              emotionTemperature: emotionTemperature,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/report2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (idx) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 8,
                  height: 8,
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
