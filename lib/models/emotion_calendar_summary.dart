/// 월별 감정 요약(날짜-별 가장 강한 감정) 모델
class EmotionCalendarSummary {
  final DateTime date; // yyyy-MM-dd
  final int emotionSeq; // 1~5

  const EmotionCalendarSummary(this.date, this.emotionSeq);

  factory EmotionCalendarSummary.fromJson(Map<String, dynamic> json) {
    return EmotionCalendarSummary(
      DateTime.parse(json['calendar_date'] as String),
      json['emotion_seq'] as int,
    );
  }
}
