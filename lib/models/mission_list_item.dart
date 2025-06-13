class MissionListItem {
  final int memberMissionSeq;
  final String content;
  final String title;
  final bool completed;

  MissionListItem({
    required this.memberMissionSeq,
    required this.content,
    required this.title,
    required this.completed,
  });

  factory MissionListItem.fromJson(Map<String, dynamic> json) {
    return MissionListItem(
      memberMissionSeq: json['member_mission_seq'],
      content: json['content'],
      title: json['title'],
      completed: json['completed'],
    );
  }
}
