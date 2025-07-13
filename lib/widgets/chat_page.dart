import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 导入 intl 套件
import '../services/conversation_service.dart';
import '../models/conversation.dart'; // <--- 新增匯入
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
// import 'aurora_background.dart'; // 不再需要引入

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _typingText = '';
  List<PlatformFile> _selectedFiles = [];

  // API 配置
  // final String kimiApiKey =
  //     'sk-1cB1S9UI7xy0rYI0OE34TKLlqvHbkHztt5OXcl9AxSV91sAp';
  // final String kimiApiUrl = 'https://api.moonshot.cn/v1/chat/completions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 保持透明以显示背景
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 左側對話歷史面板
            Consumer<ConversationService>(
              builder: (context, service, child) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _buildHistoryPanel(service),
                );
              },
            ),

            // 右側主聊天視窗
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Consumer<ConversationService>(
                  builder: (context, service, child) {
                    return Column(
                      children: [
                        // 頂部標題
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFFE60012),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              if (service.currentConversation != null)
                                Text(
                                  service.currentConversation!.title ?? '新对话',
                                  style: const TextStyle(
                                    fontSize: 20, // 放大字體
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                tooltip: '新对话',
                                onPressed: () {
                                  service.createNewConversation();
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // 主內容區（對話歷史 + 輸入框）
                        Expanded(
                          child: Column(
                            children: [
                              // 對話歷史
                              Expanded(child: _buildChatHistory(service)),
                              // 輸入區域
                              _buildInputArea(service),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistory(ConversationService service) {
    final conversation = service.currentConversation;
    if (conversation == null || conversation.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFFCCCCCC)),
            SizedBox(height: 16),
            Text(
              '开始您的第一个问题',
              style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
            ),
            SizedBox(height: 8),
            Text(
              '您可以询问任何网络协议相关问题',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: conversation.messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == conversation.messages.length && _isLoading) {
          return _buildTypingIndicator();
        }

        final message = conversation.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildFeedbackButtons(Message message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.thumb_up_outlined),
          iconSize: 16,
          color: Colors.grey[600],
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: '赞同',
          onPressed: () {
            // TODO: Handle positive feedback
            _showFeedbackDialog(message, 1);
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.thumb_down_outlined),
          iconSize: 16,
          color: Colors.grey[600],
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: '不认同',
          onPressed: () {
            // TODO: Handle negative feedback
            _showFeedbackDialog(message, 0);
          },
        ),
      ],
    );
  }

  void _showFeedbackDialog(Message message, int rating) {
    final TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(rating == 1 ? '提供表扬' : '提供建议'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: '您可以留下更详细的评论...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('提交'),
              onPressed: () async {
                // 改为 async
                // TODO: Connect to service and send API request
                final comment = commentController.text;

                // 临时解决方案：如果 solutionId 为空，则使用一个假的 ID
                final solutionId =
                    message.solutionId ?? 'fake-solution-id-for-testing';

                final success =
                    await Provider.of<ConversationService>(
                      context,
                      listen: false,
                    ).sendFeedback(
                      solutionId: solutionId,
                      rating: rating,
                      comment: comment,
                    );

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '感谢您的反馈！' : '反馈提交失败，请稍后重试。'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFFE60012),
              child: Text('AI', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFE60012) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                  if (!isUser && message.solutionId != null) ...[
                    const SizedBox(height: 8),
                    _buildFeedbackButtons(message),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE60012),
            child: Text('AI', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('正在思考中...'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ConversationService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // 文件预览区域
          if (_selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFiles.map((file) {
                  bool isImage =
                      file.extension != null &&
                      [
                        'jpg',
                        'jpeg',
                        'png',
                        'gif',
                        'bmp',
                        'webp',
                      ].contains(file.extension!.toLowerCase());

                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(file.path!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.grey.shade600,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    file.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, size: 20),
                          color: Colors.grey.shade600,
                          onPressed: () {
                            setState(() {
                              _selectedFiles.remove(file);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

          // 输入区域
          DropTarget(
            onDragDone: (details) async {
              for (final file in details.files) {
                final bytes = await file.readAsBytes();
                final platformFile = PlatformFile(
                  name: file.name,
                  size: bytes.length,
                  path: file.path,
                );
                setState(() {
                  _selectedFiles.add(platformFile);
                });
              }
            },
            onDragEntered: (details) {
              setState(() => _dragging = true);
            },
            onDragExited: (details) {
              setState(() => _dragging = false);
            },
            child: Container(
              decoration: BoxDecoration(
                color: _dragging ? Colors.grey.shade100 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _dragging ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickFiles,
                    tooltip: '上传文件',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: '输入您的问题...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isLoading ? null : () => _handleSubmit(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  bool _dragging = false;

  Widget _buildHistoryPanel(ConversationService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.history, color: Color(0xFF666666), size: 20),
              SizedBox(width: 8),
              Text(
                '对话历史',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: service.conversations.length,
            itemBuilder: (context, index) {
              final conversation = service.conversations[index];
              final isSelected = service.currentConversation == conversation;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  leading: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF666666),
                    size: 16,
                  ),
                  title: Text(
                    conversation.title ?? '新对话',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFFE60012)
                          : const Color(0xFF333333),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFFE60012).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => service.switchConversation(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleSubmit(BuildContext context) async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;
    setState(() => _isLoading = true);

    final service = Provider.of<ConversationService>(context, listen: false);

    try {
      await service.sendMessage(text, files: _selectedFiles);
      _controller.clear();
      setState(() {
        _selectedFiles.clear();
      });

      // 滚动到底部
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发送失败：$e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
