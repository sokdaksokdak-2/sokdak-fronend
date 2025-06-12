// lib/models/emotion_record.dart
class EmotionRecord {
  final int    seq;          // detail_seq – 삭제·수정 PK
  final int    emotionSeq;   // 1‒5
  final String title;
  final String content;
  final DateTime calendarDate; // yyyy-MM-dd → DateTime

  EmotionRecord({
    required this.seq,
    required this.emotionSeq,
    required this.title,
    required this.content,
    required this.calendarDate,
  });

  factory EmotionRecord.fromJson(Map<String, dynamic> json) => EmotionRecord(
    seq          : json['detail_seq']      as int,
    emotionSeq   : json['emotion_seq']     as int,
    title        : json['title']           ?? '',
    content      : json['context']         ?? '',
    calendarDate : DateTime.parse(json['calendar_date']),
  );

  /// 필요 시 서버로 다시 보낼 때 사용
  Map<String, dynamic> toJson() => {
    'detail_seq'    : seq,
    'emotion_seq'   : emotionSeq,
    'title'         : title,
    'context'       : content,
    'calendar_date' : calendarDate.toIso8601String().split('T').first,
  };
}
