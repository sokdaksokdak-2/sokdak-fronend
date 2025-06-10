// lib/models/mission_record.dart
class MissionRecord {
  final String title; // 미션 제목
  final String description; // 미션 설명 or 미션 메시지
  final bool cleared; // 완료 여부 (true=완료, false=미완료)
  final int? seq; // 서버 PK (나중에 필요하면)

  MissionRecord({
    required this.title,
    required this.description,
    required this.cleared,
    this.seq,
  });

  // ▷ 서버 JSON 을 모델로 변환
  factory MissionRecord.fromJson(Map<String, dynamic> json) {
    return MissionRecord(
      title: json['title'] as String,
      description: json['description'] as String,
      cleared: json['cleared'] as bool,
      seq: json['seq'],
    );
  }

  // ▷ 모델을 JSON 으로 (필요 시)
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'cleared': cleared,
    if (seq != null) 'seq': seq,
  };
}
