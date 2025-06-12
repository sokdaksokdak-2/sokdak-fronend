// lib/utils/emotion_helper.dart

/// emotion_seq 1‒5 ↔︎ 이미지 에셋 매핑
const Map<int, String> kEmotionAsset = {
  4: 'assets/emotions/cropped_angry.png',
  3: 'assets/emotions/cropped_fear.png',
  1: 'assets/emotions/cropped_happy.png',
  2: 'assets/emotions/cropped_sad.png',
  5: 'assets/emotions/cropped_soso.png',
};

String emotionAsset(int seq) =>
    kEmotionAsset[seq] ?? 'assets/emotions/none.png';