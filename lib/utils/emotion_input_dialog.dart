// // lib/widgets/emotion_input_dialog.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:sdsd/config.dart';
// import 'package:sdsd/services/emotion_service.dart';
// import '../models/emotion_record.dart';
// import '../utils/emotion_helper.dart';
//
// class EmotionInputDialog extends StatefulWidget {
//   final DateTime date;
//   final EmotionRecord? existingRecord;
//   final Function(EmotionRecord) onSave;
//
//   const EmotionInputDialog({
//     super.key,
//     required this.date,
//     this.existingRecord,
//     required this.onSave,
//   });
//
//   @override
//   State<EmotionInputDialog> createState() => _EmotionInputDialogState();
// }
//
// class _EmotionInputDialogState extends State<EmotionInputDialog> {
//   late final TextEditingController _titleController;
//   late final TextEditingController _contentController;
//   late int _selectedEmotionSeq;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _titleController = TextEditingController(text: widget.existingRecord?.title ?? '');
//     _contentController = TextEditingController(text: widget.existingRecord?.content ?? '');
//     _selectedEmotionSeq = widget.existingRecord?.emotionSeq ?? 0;
//   }
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _contentController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _saveEmotion() async {
//     if (_selectedEmotionSeq == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('감정을 선택해주세요')),
//       );
//       return;
//     }
//
//     if (_titleController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('제목을 입력해주세요')),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       EmotionRecord record;
//
//       if (widget.existingRecord != null) {
//         // 수정
//         record = await EmotionService.updateEmotionRecord(
//           detailSeq: widget.existingRecord!.detail_seq,
//           memberSeq: Config.memberSeq,
//           emotionSeq: _selectedEmotionSeq,
//           title: _titleController.text.trim(),
//           content: _contentController.text.trim(),
//         );
//       } else {
//         // 새로 추가
//         record = await EmotionService.createEmotionRecord(
//           memberSeq: Config.memberSeq,
//           date: widget.date,
//           emotionSeq: _selectedEmotionSeq,
//           title: _titleController.text.trim(),
//           content: _contentController.text.trim(),
//         );
//       }
//
//       if (!mounted) return;
//       widget.onSave(record);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('저장 실패: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text(
//             '${widget.date.year}년 ${widget.date.month}월 ${widget.date.day}일',
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//
//           // 감정 선택
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             alignment: WrapAlignment.center,
//             children: List.generate(5, (i) {
//               final seq = i + 1;
//               return GestureDetector(
//                 onTap: () => setState(() => _selectedEmotionSeq = seq),
//                 child: Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     border: Border.all(
//                       color: _selectedEmotionSeq == seq
//                           ? Theme.of(context).primaryColor
//                           : Colors.grey,
//                       width: 2,
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Image.asset(emotionAsset(seq)),
//                 ),
//               );
//             }),
//           ),
//           const SizedBox(height: 24),
//
//           // 제목 입력
//           TextField(
//             controller: _titleController,
//             decoration: const InputDecoration(
//               labelText: '제목',
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 1,
//           ),
//           const SizedBox(height: 16),
//
//           // 내용 입력
//           TextField(
//             controller: _contentController,
//             decoration: const InputDecoration(
//               labelText: '내용',
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 3,
//           ),
//           const SizedBox(height: 24),
//
//           // 저장 버튼
//           ElevatedButton(
//           ElevatedButton(
//             onPressed: _isLoading ? null : _saveEmotion,
//             child: _isLoading
//                 ? const CircularProgressIndicator()
//                 : Text(widget.existingRecord != null ? '수정하기' : '저장하기'),
//           ),
//         ],
//       ),
//     );
//   }
// }
