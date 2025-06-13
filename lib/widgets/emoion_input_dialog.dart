// lib/widgets/emotion_input_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/services/emotion_service.dart';
import '../models/emotion_record.dart';

class EmotionInputDialog extends StatefulWidget {
  final DateTime date;
  final EmotionRecord? existingRecord;
  final void Function(EmotionRecord) onSave;

  const EmotionInputDialog({
    super.key,
    required this.date,
    required this.onSave,
    this.existingRecord,
  });

  @override
  State<EmotionInputDialog> createState() => _EmotionInputDialogState();
}

class _EmotionInputDialogState extends State<EmotionInputDialog> {
  String? selectedEmotion; // 예: 'cropped_angry'
  late TextEditingController titleController;
  late TextEditingController contentController;

  /// 감정 키 ↔︎ emotion_seq 매핑
  static const Map<String, int> _emotionMap = {
    'cropped_angry': 1,
    'cropped_fear': 2,
    'cropped_happy': 3,
    'cropped_sad': 4,
    'cropped_soso': 5,
  };

  @override
  void initState() {
    super.initState();

    // 기존 레코드가 있으면 emotionSeq → 키 역매핑
    selectedEmotion =
    widget.existingRecord != null
        ? _emotionMap.entries
        .firstWhere(
          (e) => e.value == widget.existingRecord!.emotionSeq,
      orElse: () => const MapEntry('cropped_soso', 5),
    )
        .key
        : null;

    titleController = TextEditingController(
      text: widget.existingRecord?.title ?? '',
    );
    contentController = TextEditingController(
      text: widget.existingRecord?.content ?? '',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  String _emotionLabel(String emotion) {
    switch (emotion) {
      case 'cropped_happy':
        return '행복';
      case 'cropped_fear':
        return '불안';
      case 'cropped_angry':
        return '분노';
      case 'cropped_sad':
        return '슬픔';
      case 'cropped_soso':
        return '평온';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const emotions = [
      'cropped_happy',
      'cropped_fear',
      'cropped_angry',
      'cropped_sad',
      'cropped_soso',
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 550, maxWidth: 325),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 22),

            // ───────── 감정 선택 ─────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  '기분 어때?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                  emotions.map((emotion) {
                    final isSelected = selectedEmotion == emotion;
                    return GestureDetector(
                      onTap:
                          () => setState(() => selectedEmotion = emotion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Opacity(
                          opacity: isSelected ? 1.0 : 0.3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/emotions/$emotion.png',
                                width: 36,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _emotionLabel(emotion),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ───────── 제목 ─────────
            _fieldLabel('제목'),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 25),

            // ───────── 내용 ─────────
            _fieldLabel('내용'),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              maxLines: 6,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            // ───────── 버튼 ─────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: _cancelStyle(),
                    child: const Text('취소', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: _saveStyle(),
                    child: const Text('저장', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────── 저장 로직 ─────────
  Future<void> _save() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (selectedEmotion == null || title.isEmpty || content.isEmpty) return;

    final emotionSeq = _emotionMap[selectedEmotion]!;
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.date);

    try {
      if (widget.existingRecord?.detail_seq != null) {
        // ─── 수정 ───
        await EmotionService.updateEmotionRecord(
          detailSeq: widget.existingRecord!.detail_seq!,
          memberSeq: Config.memberSeq,
          emotionSeq: emotionSeq,
          title: title,
          content: content,
        );
      } else {
        // ─── 신규 저장 ───
        await EmotionService.createEmotionManually(
          memberSeq: Config.memberSeq,
          calendarDate: formattedDate,
          title: title,
          context: content,
          emotionSeq: emotionSeq,
        );
      }

      // ※ 인풋 다이얼로그 내부 예시
      widget.onSave(
        EmotionRecord(
          detail_seq         : widget.existingRecord?.detail_seq ?? 0,   // 신규 기록이면 0(임시); 저장 후 다시 조회 시 실제 값으로 교체
          emotionSeq  : emotionSeq,
          title       : title,
          content     : content,
          calendarDate: widget.date,                       // 다이얼로그에 넘겨받은 해당 날짜(DateTime)
        ),
      );


      Navigator.pop(context);
    } catch (e) {
      print('감정 저장 실패: $e');
    }
  }

  // ───────── 공통 위젯/스타일 ─────────
  Padding _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
  );

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.green),
    ),
  );

  ButtonStyle _cancelStyle() => ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(vertical: 8),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Colors.black12),
    ),
  );

  ButtonStyle _saveStyle() => ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
