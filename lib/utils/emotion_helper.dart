import 'package:flutter/material.dart';

/// emotion_seq 1‒5 ↔︎ 이미지 에셋 매핑
const Map<int, String> kEmotionAsset = {
  4: 'assets/emotions/cropped_angry.png',
  3: 'assets/emotions/cropped_fear.png',
  1: 'assets/emotions/cropped_happy.png',
  2: 'assets/emotions/cropped_sad.png',
  5: 'assets/emotions/cropped_soso.png',
};

/// 감정 시퀀스에 해당하는 이미지 에셋 경로 반환
String emotionAsset(int emotionSeq) {
  switch (emotionSeq) {
    case 4:
      return 'assets/emotions/cropped_angry.png';
    case 3:
      return 'assets/emotions/cropped_fear.png';
    case 1:
      return 'assets/emotions/cropped_happy.png';
    case 2:
      return 'assets/emotions/cropped_sad.png';
    case 5:
      return 'assets/emotions/cropped_soso.png';
    default:
      return 'assets/emotions/none.png'; // 기본값
  }
}

/// 감정 시퀀스에 해당하는 한글 레이블 반환
String emotionLabel(int emotionSeq) {
  switch (emotionSeq) {
    case 4:
      return '분노';
    case 3:
      return '불안';
    case 1:
      return '행복';
    case 2:
      return '슬픔';
    case 5:
      return '평온';
    default:
      return '행복'; // 기본값
  }
}

/// ✅ 감정 색상 + 레이블 묶음 클래스
class EmotionInfo {
  final String label;
  final Color color;

  const EmotionInfo({required this.label, required this.color});
}

/// ✅ 감정 시퀀스 → 레이블 + 색상 매핑
const Map<int, EmotionInfo> kEmotionInfoMap = {
  1: EmotionInfo(label: '행복', color: Color(0xAAFFED66)),
  2: EmotionInfo(label: '슬픔', color: Color(0xAA80CAFF)),
  3: EmotionInfo(label: '불안', color: Color(0x88FFB356)),
  4: EmotionInfo(label: '분노', color: Color(0xAAFFAFA3)),
  5: EmotionInfo(label: '평온', color: Color(0xAA85E0A3)),
};
