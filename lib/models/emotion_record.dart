class EmotionRecord {
  final int      seq;           // detail_seq – 삭제·수정 PK
  final int      emotionSeq;    // 1‒5
  final String   title;
  final String   content;
  final DateTime calendarDate;  // yyyy-MM-dd → DateTime

  EmotionRecord({
    required this.seq,
    required this.emotionSeq,
    required this.title,
    required this.content,
    required this.calendarDate,
  });

  factory EmotionRecord.fromJson(Map<String, dynamic> json) => EmotionRecord(
    seq          : (json['detail_seq'] ?? 0) as int,          // ← 기본값 0
    emotionSeq   : json['emotion_seq']     as int? ?? 0,
    title        : json['title']           ?? '',             // 없으면 빈 문자열
    content      : json['context']         ?? '',
    calendarDate : DateTime.parse(json['calendar_date']),
  );

  Map<String, dynamic> toJson() => {
    'detail_seq'    : seq,
    'emotion_seq'   : emotionSeq,
    'title'         : title,
    'context'       : content,
    'calendar_date' : calendarDate.toIso8601String().split('T').first,
  };
}
