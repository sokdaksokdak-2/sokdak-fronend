// lib/screen/oauth_buttons.dart
import 'package:flutter/material.dart';
import 'package:sdsd/utils/oauth_launcher.dart';

class OAuthButtons extends StatelessWidget {
  const OAuthButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Center(child: Text('또는')),
        const SizedBox(height: 16),

        // ✅ Kakao
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => launchOAuth(context, 'kakao'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: Image.asset('assets/images/kakao_icon.png', height: 20, width: 20),
            label: const Text(
              '카카오톡으로 계속하기',
              style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ✅ Google
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => launchOAuth(context, 'google'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Image.asset('assets/images/google_icon.png', height: 20, width: 20),
            label: const Text(
              'Google로 계속하기',
              style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ✅ Naver
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => launchOAuth(context, 'naver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Image.asset('assets/images/naver_icon.png', height: 20, width: 20),
            label: const Text(
              'Naver로 계속하기',
              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
