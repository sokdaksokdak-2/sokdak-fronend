class MissionListItem {
  final int memberMissionSeq;
  final String content;
  final String title;
  final bool completed;
  final int emotionSeq;
  final int emotionScore;

  MissionListItem({
    required this.memberMissionSeq,
    required this.content,
    required this.title,
    required this.completed,
    required this.emotionSeq,
    required this.emotionScore,
  });

  factory MissionListItem.fromJson(Map<String, dynamic> json) {
    return MissionListItem(
      memberMissionSeq: json['member_mission_seq'],
      content: json['content'],
      title: json['title'],
      completed: json['completed'] == 1 || json['completed'] == true,
      emotionSeq: json['emotion_seq'],
      emotionScore: json['emotion_score'],
    );
  }
}
