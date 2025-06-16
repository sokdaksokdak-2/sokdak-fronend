import 'package:flutter/material.dart';
import '../models/emotion_record.dart';
import '../utils/emotion_helper.dart';

class EmotionRecordViewerDialog extends StatefulWidget {
  final List<EmotionRecord> records;
  final Future<void> Function(int index) onDelete; // awaitable 콜백
  final void Function(int index) onEdit;
  final VoidCallback onAdd;
  final int memberSeq;

  const EmotionRecordViewerDialog({
    super.key,
    required this.records,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
    required this.memberSeq,
  });

  @override
  State<EmotionRecordViewerDialog> createState() =>
      _EmotionRecordViewerDialogState();
}

class _EmotionRecordViewerDialogState extends State<EmotionRecordViewerDialog> {
  late List<EmotionRecord> _records;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.records);
  }

  Future<void> _confirmAndDelete(int index) async {
    print('[레코드뷰어] 삭제 시도 (idx: $index)');
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('정말 삭제하시겠어요?'),
            content: const Text('이 감정 기록은 삭제 후 복구할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (ok != true) return;

    setState(() => _loading = true);

    try {
      await widget.onDelete(index);
      _records.removeAt(index);

      print('[레코드뷰어] 삭제 완료, 남은 개수: ${_records.length}');
      if (_records.isEmpty) {
        if (mounted) {
          print('[레코드뷰어] 모두 삭제됨, dialog pop!');
          Navigator.of(context).pop('deleted'); // 항상 자신의 context!
        }
        return;
      }

      if (mounted) setState(() {});
    } catch (e) {
      print('[레코드뷰어] 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제 중 오류가 발생했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            constraints: const BoxConstraints(maxHeight: 550, maxWidth: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('감정 기록', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Scrollbar(
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(8),
                      child: SingleChildScrollView(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDADADA)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child:
                              _records.isEmpty
                                  ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: Text(
                                        '감정 기록이 없습니다.',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                  : Column(
                                    children: List.generate(_records.length * 2 - 1, (
                                      i,
                                    ) {
                                      if (i.isEven) {
                                        final idx = i ~/ 2;
                                        final record = _records[idx];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Image.asset(
                                                    emotionAsset(
                                                      record.emotionSeq,
                                                    ),
                                                    width: 32,
                                                    height: 32,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      record.title,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF4E4E4E,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                record.content,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed:
                                                        _loading
                                                            ? null
                                                            : () =>
                                                                _confirmAndDelete(
                                                                  idx,
                                                                ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.grey[200],
                                                      foregroundColor:
                                                          Colors.grey[800],
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                    child: const Text('삭제'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed:
                                                        _loading
                                                            ? null
                                                            : () => widget
                                                                .onEdit(idx),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF28B960,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                    child: const Text('수정'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const Divider(
                                        color: Color(0xFFE5E0E0),
                                        thickness: 0.5,
                                        height: 24,
                                      );
                                    }),
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F3F3),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.download,
                              size: 16,
                              color: Color(0xFF4E4E4E),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '저장',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4E4E4E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F3F3),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.share,
                              size: 16,
                              color: Color(0xFF4E4E4E),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '공유',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4E4E4E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop('closed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[500],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('닫기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('추가'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
