import 'package:flutter/material.dart';
import '../../widgets/custom_header.dart';
import 'calendar_screen.dart';
import 'mission_calendar_screen.dart';

class CalendarChooserScreen extends StatelessWidget {
  const CalendarChooserScreen({super.key});

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String assetPath,
    required VoidCallback onTap,
    double imageWidth = 100,
    double imageHeight = 100,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(.05),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Image.asset(
                assetPath,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomHeader(showBackButton: false),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              '어떤 캘린더를\n열어볼까?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildCard(
                    context: context,
                    title: '감정 캘린더',
                    subtitle: '감정 흐름 보기',
                    assetPath: 'assets/images/team.png',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalendarScreen(),
                          ),
                        ),
                    imageWidth: 150,
                    imageHeight: 150,
                  ),
                  const SizedBox(width: 16),
                  _buildCard(
                    context: context,
                    title: '미션 캘린더',
                    subtitle: '미션 기록 보기',
                    assetPath: 'assets/images/mission_complete.png',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MissionCalendarScreen(),
                          ),
                        ),
                    imageWidth: 150,
                    imageHeight: 150,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
