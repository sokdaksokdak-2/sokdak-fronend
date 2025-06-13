// lib/widgets/emotion_input_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sdsd/config.dart';
import 'package:sdsd/services/emotion_service.dart';
import '../models/emotion_record.dart';
import '../utils/emotion_helper.dart';

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
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late int _selectedEmotionSeq;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingRecord?.title ?? '');
    _contentController = TextEditingController(text: widget.existingRecord?.content ?? '');
    _selectedEmotionSeq = widget.existingRecord?.emotionSeq ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEmotion() async {
    if (_selectedEmotionSeq == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감정을 선택해주세요')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      EmotionRecord record;

      if (widget.existingRecord != null) {
        record = await EmotionService.updateEmotionRecord(
          detailSeq: widget.existingRecord!.detail_seq,
          memberSeq: Config.memberSeq,
          emotionSeq: _selectedEmotionSeq,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      } else {
        record = await EmotionService.createEmotionManually(
          memberSeq: Config.memberSeq,
          calendarDate: DateFormat('yyyy-MM-dd').format(widget.date),
          emotionSeq: _selectedEmotionSeq,
          title: _titleController.text.trim(),
          context: _contentController.text.trim(),
        );
      }

      if (!mounted) return;
      widget.onSave(record);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(5, (i) {
                final seq = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmotionSeq = seq),
                  child: Opacity(
                    opacity: _selectedEmotionSeq == seq ? 1.0 : 0.3,
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Image.asset(emotionAsset(seq)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emotionLabelFromSeq(seq),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _selectedEmotionSeq == seq ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 25),
            _fieldLabel('제목'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 25),
            _fieldLabel('내용'),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),
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
                    onPressed: _isLoading ? null : _saveEmotion,
                    style: _saveStyle(),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('저장', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

// 👉 여기 아래에 추가!
String emotionLabelFromSeq(int seq) {
  switch (seq) {
    case 1:
      return '행복';
    case 2:
      return '슬픔';
    case 3:
      return '불안';
    case 4:
      return '분노';
    case 5:
      return '평온';
    default:
      return '행복';
  }
}
