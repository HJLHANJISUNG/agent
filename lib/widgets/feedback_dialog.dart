import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../services/conversation_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart'; // Added import for DatabaseService

class FeedbackDialog extends StatefulWidget {
  final String solutionId;
  final Function? onFeedbackSubmitted;

  const FeedbackDialog({
    super.key,
    required this.solutionId,
    this.onFeedbackSubmitted,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _feedbackService = FeedbackService();
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _userName;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 加載用戶信息
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name');
      _userId = prefs.getString('user_id');
    });
  }

  // 提交反饋
  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      setState(() {
        _errorMessage = '請選擇評分';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final conversationService = Provider.of<ConversationService>(
        context,
        listen: false,
      );
      final userId = _userId ?? conversationService.userId ?? 'anonymous';

      final result = await _feedbackService.submitFeedback(
        userId: userId,
        solutionId: widget.solutionId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop(true);
          if (widget.onFeedbackSubmitted != null) {
            widget.onFeedbackSubmitted!();
          }
        }
      } else {
        setState(() {
          _errorMessage = '提交失敗，請稍後再試';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '發生錯誤: $e';
        _isSubmitting = false;
      });
    }
  }

  // 假設有一個方法 _handleSubmitFeedback(int rating, String comment, String solutionId, String userId) 處理反饋
  Future<void> _handleSubmitFeedback(
    int rating,
    String comment,
    String solutionId,
    String userId,
  ) async {
    final feedbackId = DateTime.now().millisecondsSinceEpoch.toString();
    await DatabaseService().addFeedback({
      'feedback_id': feedbackId,
      'user_id': userId,
      'solution_id': solutionId,
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
    // 其他 UI 處理...
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              children: [
                const Icon(
                  Icons.feedback_outlined,
                  color: Color(0xFFE60012),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '您的反饋很重要',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 評分
            const Text(
              '請為解答評分',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFF9800),
                    size: 32,
                  ),
                  splashRadius: 24,
                );
              }),
            ),
            const SizedBox(height: 16),

            // 評論
            const Text(
              '您的評論（可選）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '請分享您的使用體驗...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE60012)),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),

            // 錯誤信息
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 提交按鈕
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE60012),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('提交反饋'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
