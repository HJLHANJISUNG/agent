import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/conversation_service.dart';
import '../screens/main_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import '../widgets/custom_card.dart';
import 'package:app/widgets/db_test_page.dart';
import '../widgets/knowledge_page.dart';
import '../widgets/dashboard_page.dart';

class HomePage extends StatefulWidget {
  final bool isAdmin;
  const HomePage({super.key, this.isAdmin = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<PlatformFile> _selectedFiles = [];
  bool _dragging = false;
  final FocusNode _focusNode = FocusNode();

  void _handleSubmit(BuildContext context) async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;
    setState(() => _isLoading = true);
    final service = Provider.of<ConversationService>(context, listen: false);
    String fileText = _selectedFiles
        .map((f) {
          final isImage =
              f.extension != null &&
              [
                'jpg',
                'jpeg',
                'png',
                'gif',
                'bmp',
                'webp',
              ].contains(f.extension!.toLowerCase());
          return isImage ? '[图片] ${f.name}' : '[文件] ${f.name}';
        })
        .join(' ');
    final sendText = (fileText.isNotEmpty ? (fileText + ' ') : '') + text;
    final title = sendText.length > 20 ? sendText.substring(0, 20) : sendText;
    service.createNewConversation(title: title);
    service.addMessageToCurrent('user', sendText.trim());
    _controller.clear();
    setState(() {
      _selectedFiles.clear();
    });
    final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
    mainLayoutState?.switchPage(1);
    await _sendAIMessage(service);
    setState(() => _isLoading = false);
  }

  Future<void> _autoAIReply(BuildContext context, String userMsg) async {
    final service = Provider.of<ConversationService>(context, listen: false);
    service.addMessageToCurrent('assistant', '（AI自动回复）已收到您的内容：$userMsg');
  }

  Future<void> _sendAIMessage(ConversationService service) async {
    try {
      // 使用後端服務而不是直接呼叫 Kimi API
      await service.sendMessage(
        service.currentConversation!.messages.last.content,
      );
    } catch (e) {
      service.addMessageToCurrent('assistant', '抱歉，發生錯誤: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3E9), Color(0xFFFFF8F3)],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 0),
            padding: const EdgeInsets.all(32),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isAdmin) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DbTestPage(),
                        ),
                      );
                    },
                    child: const Text('数据库测试页面'),
                  ),
                  const SizedBox(height: 16),
                ],
                // 標題
                Row(
                  children: [
                    Icon(Icons.dashboard, color: Color(0xFFFF4B2B), size: 36),
                    const SizedBox(width: 16),
                    Text(
                      '仪表盘',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // 圖表區塊
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        height: 180,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF3E9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            '（圆形进度图表区）',
                            style: TextStyle(
                              color: Color(0xFFFF4B2B),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        height: 180,
                        margin: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF3E9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            '（条形图区）',
                            style: TextStyle(
                              color: Color(0xFFFF4B2B),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // 主要功能分區
                Text(
                  '主要功能',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x1A000000),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ...原本的上傳/輸入/拖拽區塊內容...
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.chat,
                        '文字问答',
                        '智能文字对话，快速解答网络问题',
                        Color(0xFFFF4B2B),
                      ),
                    ),
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.image,
                        '图片分析',
                        '上传网络拓扑图或日志图进行分析',
                        Color(0xFF4CAF50),
                      ),
                    ),
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.library_books,
                        '知识库',
                        '浏览专业的网络协议知识库',
                        Color(0xFF2196F3),
                      ),
                    ),
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.feedback,
                        '反馈',
                        '提供使用反馈，帮助我们改进',
                        Color(0xFFFFC107),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // 熱門問題分區
                Text(
                  '热门问题',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 24),
                _buildHotQuestions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return _HoverCard(
      icon: icon,
      title: title,
      desc: desc,
      color: color,
      onTap: () {
        // 根据 title 跳转到对应页面
        if (title == '知识库') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KnowledgePage()),
          );
        } else if (title == '看板' && widget.isAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(isAdmin: true),
            ),
          );
        } else if (title == '文字问答') {
          // TODO: 跳转到问答页面
        } else if (title == '反馈') {
          // TODO: 跳转到反馈页面
        }
      },
    );
  }

  Widget _buildHotQuestions() {
    final hotQuestions = [
      'OSPF邻居状态卡在ExStart怎么办？',
      'BGP路由通告失败的常见原因',
      '如何排查VLAN间通信问题？',
      'STP根桥选举失败的解决方案',
      'ACL配置后无法生效的排查步骤',
      'DHCP服务器无法分配IP地址',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3,
      ),
      itemCount: hotQuestions.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: InkWell(
            onTap: () {
              // TODO: 实现问题点击
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE60012).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Color(0xFFE60012),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hotQuestions[index],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _ellipsisFileName(String name, {int max = 16}) {
    if (name.length <= max) return name;
    final ext = name.contains('.') ? name.split('.').last : '';
    final base = name.substring(0, max ~/ 2);
    final tail = name.substring(name.length - (max ~/ 2 - ext.length - 1));
    return '$base...$tail';
  }
}

class _HoverCard extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String title;
  final String desc;
  const _HoverCard({
    required this.onTap,
    required this.color,
    required this.icon,
    required this.title,
    required this.desc,
    Key? key,
  }) : super(key: key);

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          transform: _pressed
              ? (Matrix4.identity()..scale(0.97))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _hovering || _pressed
                    ? widget.color.withOpacity(0.18)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _hovering || _pressed ? 24 : 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _hovering
                  ? widget.color.withOpacity(0.25)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 40),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.desc,
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
