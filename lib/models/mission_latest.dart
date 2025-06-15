class MissionLatest {
  final int memberMissionSeq;
  final bool completed;
  final String content;
  final int emotionSeq;
  final int emotionScore;
  final String title;

  MissionLatest({
    required this.memberMissionSeq,
    required this.completed,
    required this.content,
    required this.emotionSeq,
    required this.emotionScore,
    required this.title,
  });

  factory MissionLatest.fromJson(Map<String, dynamic> json) {
    return MissionLatest(
      memberMissionSeq: json['member_mission_seq'],
      completed: json['completed'] == 1,
      content: json['content'],
      emotionSeq: json['emotion_seq'],
      emotionScore: json['emotion_score'],
      title: json['title'],
    );
  }
}
