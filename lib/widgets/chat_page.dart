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
import '../widgets/feedback_dialog.dart';
import '../services/database_service.dart';
import '../widgets/dashboard_page.dart';
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
  final DatabaseService _databaseService = DatabaseService();

  // 熱點問題列表結構
  List<Map<String, dynamic>> _hotQuestionData = [];
  List<String> get _hotQuestions =>
      _hotQuestionData.map((q) => q['question'] as String).toList();

  // 記錄熱點問題點擊次數
  Map<String, int> _questionClickCount = {};

  // 動畫控制器
  bool _isHotQuestionsExpanded = true;

  @override
  void initState() {
    super.initState();
    _fetchHotQuestions();
  }

  // 從後端獲取熱點問題
  Future<void> _fetchHotQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('${_databaseService.baseUrl}/chat/hot-questions'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
          setState(() {
            _hotQuestionData = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (e) {
      print('獲取熱點問題失敗: $e');
      // 使用默認問題
      setState(() {
        _hotQuestionData = [
          {"id": "1", "question": "如何配置 OSPF 协议？", "count": 156},
          {"id": "2", "question": "BGP 路由通告失敗的常见问题", "count": 142},
          {"id": "3", "question": "VLAN 间通信问题排查步骤", "count": 128},
          {"id": "4", "question": "ACL 规则配置最佳实践", "count": 115},
          {"id": "5", "question": "STP 根桥选举机制说明", "count": 98},
        ];
      });
    }
  }

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

    // 過濾重複的 assistant 氣泡，只保留最後一條內容不為空的 assistant 訊息
    final List<Message> filteredMessages = [];
    for (int i = 0; i < conversation.messages.length; i++) {
      final msg = conversation.messages[i];
      // 如果是 assistant，且內容為空，且不是最後一條，則跳過
      if (msg.role == 'assistant' &&
          msg.content.trim().isEmpty &&
          i != conversation.messages.length - 1) {
        continue;
      }
      // 如果是 assistant，且上一條也是 assistant，且內容為空，則跳過
      if (msg.role == 'assistant' &&
          msg.content.trim().isEmpty &&
          i > 0 &&
          conversation.messages[i - 1].role == 'assistant') {
        continue;
      }
      filteredMessages.add(msg);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredMessages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredMessages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        final message = filteredMessages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildFeedbackButtons(Message message) {
    if (message.solutionId == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.star_border),
          iconSize: 16,
          color: Colors.amber[600],
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: '評價',
          onPressed: () {
            _showFeedbackDialog(message);
          },
        ),
      ],
    );
  }

  void _showFeedbackDialog(Message message) {
    if (message.solutionId == null) return;

    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(
        solutionId: message.solutionId!,
        onFeedbackSubmitted: () {
          // 使用静态方法通知看板刷新
          DashboardPageState.refreshDashboard();
          // 強制刷新看板
          DashboardPageState.forceRefresh();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('感谢您的反馈！')));
        },
      ),
    );
  }

  // 舊的反饋對話框，已被替換
  void _showOldFeedbackDialog(Message message, int rating) {
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

    // 檢查消息內容是否顯示為思考中狀態
    final isThinking = message.content == '思考中...';

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
              constraints: const BoxConstraints(maxWidth: 600), // 限制最大宽度
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFE60012) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 确保Column不会占用过多空间
                children: [
                  if (!isUser)
                    Flexible(
                      child: SingleChildScrollView(
                        child: _buildEnhancedContent(message.content),
                      ),
                    )
                  else
                    Flexible(
                      child: SelectableText(
                        message.content,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black,
                        ),
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

  Widget _buildEnhancedContent(String content) {
    // 检测是否包含代码块
    final codeBlockPattern = RegExp(r'```(\w+)?\n([\s\S]*?)```');
    final matches = codeBlockPattern.allMatches(content);

    if (matches.isEmpty) {
      // 没有代码块，正常显示
      return _buildFormattedText(content);
    }

    // 有代码块，分段显示
    List<Widget> widgets = [];
    int lastEnd = 0;

    for (final match in matches) {
      // 添加代码块前的文本
      if (match.start > lastEnd) {
        final beforeText = content.substring(lastEnd, match.start);
        if (beforeText.isNotEmpty) {
          widgets.add(_buildFormattedText(beforeText));
        }
      }

      // 添加代码块
      final language = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      widgets.add(_buildCodeBlock(code, language));

      lastEnd = match.end;
    }

    // 添加代码块后的文本
    if (lastEnd < content.length) {
      final afterText = content.substring(lastEnd);
      if (afterText.isNotEmpty) {
        widgets.add(_buildFormattedText(afterText));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildFormattedText(String text) {
    // 处理Markdown格式
    final List<Widget> widgets = [];
    final List<String> parts = [];

    // 分割文本，保留分隔符
    final pattern = RegExp(
      r'(#{1,6}\s+.*?(?=\n|$)|(\*\*.*?\*\*)|(`.*?`)|(\*\*.*?\*\*))',
      dotAll: true,
    );
    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      // 添加匹配前的普通文本
      if (match.start > lastIndex) {
        parts.add(text.substring(lastIndex, match.start));
      }
      // 添加匹配的格式文本
      parts.add(match.group(0)!);
      lastIndex = match.end;
    }

    // 添加剩余的普通文本
    if (lastIndex < text.length) {
      parts.add(text.substring(lastIndex));
    }

    // 处理每个部分
    for (final part in parts) {
      if (part.isEmpty) continue;

      if (part.startsWith('#')) {
        // 标题格式
        final level = part.split(' ')[0].length;
        final spaceIndex = part.indexOf(' ');
        if (spaceIndex > 0 && spaceIndex < part.length - 1) {
          final title = part.substring(spaceIndex + 1);
          widgets.add(
            Padding(
              padding: EdgeInsets.only(
                top: level == 1 ? 16 : 8,
                bottom: level == 1 ? 8 : 4,
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: level == 1 ? 24 : (level == 2 ? 20 : 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          );
        } else {
          // 如果没有空格或格式不正确，按普通文本处理
          widgets.add(
            SelectableText(part, style: const TextStyle(color: Colors.black)),
          );
        }
      } else if (part.startsWith('**') &&
          part.endsWith('**') &&
          part.length > 4) {
        // 粗体格式
        final boldText = part.substring(2, part.length - 2);
        widgets.add(
          Text(
            boldText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        );
      } else if (part.startsWith('`') &&
          part.endsWith('`') &&
          part.length > 2) {
        // 行内代码格式
        final codeText = part.substring(1, part.length - 1);
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              codeText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        );
      } else {
        // 普通文本
        widgets.add(
          SelectableText(part, style: const TextStyle(color: Colors.black)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildCodeBlock(String code, String language) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // 改为浅色背景
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 代码块头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // 浅色头部
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                if (language.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      language.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Colors.grey.shade600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // 复制代码到剪贴板
                    // 这里需要添加剪贴板功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('代码已复制到剪贴板'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: '复制代码',
                ),
              ],
            ),
          ),
          // 代码内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                code,
                style: const TextStyle(
                  color: Colors.black87, // 改为深色文字
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 閃爍的光標點
  Widget _buildBlinkingDot() {
    return StatefulBuilder(
      builder: (context, setState) {
        // 啟動一個計時器來閃爍光標
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {});
          }
        });

        return Text(
          DateTime.now().millisecondsSinceEpoch % 1000 < 500 ? '|' : '',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return SizedBox.shrink(); // 直接不顯示任何內容
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
          // 熱點問題提示框
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            constraints: _isHotQuestionsExpanded
                ? const BoxConstraints()
                : const BoxConstraints(minHeight: 40, maxHeight: 40),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isHotQuestionsExpanded = !_isHotQuestionsExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 16,
                          color: Color(0xFFE60012),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '热门问题：',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isHotQuestionsExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: const Color(0xFF666666),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isHotQuestionsExpanded)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _hotQuestionData.map((questionData) {
                        final question = questionData['question'] as String;
                        final count = questionData['count'] as int? ?? 0;
                        final clickCount = _questionClickCount[question] ?? 0;
                        final hasBeenClicked = clickCount > 0;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => _onHotQuestionTap(questionData),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: hasBeenClicked
                                    ? const Color(0xFFFFF8E1)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasBeenClicked
                                      ? const Color(0xFFFFB74D)
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    question,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hasBeenClicked
                                          ? const Color(0xFFE65100)
                                          : const Color(0xFF333333),
                                      fontWeight: hasBeenClicked
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasBeenClicked
                                          ? const Color(0xFFFFB74D)
                                          : const Color(
                                              0xFFE60012,
                                            ).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      hasBeenClicked
                                          ? clickCount.toString()
                                          : '$count+',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
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
              ],
            ),
          ),

          const SizedBox(height: 8),

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

    // --- 新增：本地寫入 Question 表 ---
    try {
      final userId = service.userId;
      if (userId != null) {
        final questionId = DateTime.now().millisecondsSinceEpoch.toString();
        await DatabaseService().database.then(
          (db) => db.insert('Question', {
            'question_id': questionId,
            'user_id': userId,
            'content': text,
            'image_url': null,
            'ask_time': DateTime.now().toIso8601String(),
            'solved': 0,
          }),
        );
      }
    } catch (e) {
      print('本地写入 Question 失败: ' + e.toString());
    }
    // --- 新增結束 ---

    try {
      // 使用新的流式回應方法替代原來的方法
      await service.sendMessageWithStream(text, files: _selectedFiles);
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

  // 向後端報告熱點問題點擊
  Future<void> _reportQuestionClick(String questionId) async {
    try {
      await http.post(
        Uri.parse(
          '${_databaseService.baseUrl}/chat/hot-questions/$questionId/click',
        ),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('报告问题点击失败: $e');
      // 失敗時不做任何處理，這只是統計數據
    }
  }

  void _onHotQuestionTap(Map<String, dynamic> questionData) {
    final question = questionData['question'] as String;
    final questionId = questionData['id'] as String;
    final clickCount = _questionClickCount[question] ?? 0;

    setState(() {
      _questionClickCount[question] = clickCount + 1;
    });

    _controller.text = question;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: question.length),
    );

    // 向後端報告點擊
    _reportQuestionClick(questionId);
  }
}
