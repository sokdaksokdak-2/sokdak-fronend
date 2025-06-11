/// emotion_seq (1~5) → 로컬 에셋 경로 매핑
String emotionAsset(int seq) {
  switch (seq) {
    case 1:
      return 'assets/emotions/cropped_angry.png';
    case 2:
      return 'assets/emotions/cropped_fear.png';
    case 3:
      return 'assets/emotions/cropped_happy.png';
    case 4:
      return 'assets/emotions/cropped_sad.png';
    case 5:
      return 'assets/emotions/cropped_soso.png';
    default:
      return 'assets/emotions/none.png';
  }
}
