// lib/utils/oauth_launcher.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sdsd/config.dart';

Future<void> launchOAuth(BuildContext context, String provider) async {
  final url = Uri.parse('${Config.baseUrl}/api/oauth/login/$provider');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider 로그인 페이지를 열 수 없습니다.')),
    );
  }
}
