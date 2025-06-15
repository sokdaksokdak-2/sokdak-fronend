class MissionSuggestion {
  final int emotionSeq;
  final int emotionScore;
  final int missionSeq;
  final String title;
  final String content;

  MissionSuggestion({
    required this.emotionSeq,
    required this.emotionScore,
    required this.missionSeq,
    required this.title,
    required this.content,
  });

  factory MissionSuggestion.fromJson(Map<String, dynamic> json) {
    return MissionSuggestion(
      emotionSeq: json['emotion_seq'],
      emotionScore: json['emotion_score'],
      missionSeq: json['mission_seq'],
      title: json['title'],
      content: json['content'],
    );
  }
}
