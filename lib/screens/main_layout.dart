import 'package:app/models/user_model.dart';
import 'package:app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/conversation_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/home_page.dart';
import '../widgets/chat_page.dart';
import '../widgets/knowledge_page.dart';
import '../widgets/dashboard_page.dart';
import '../widgets/auth_page.dart';
import '../widgets/aurora_background.dart';
import 'package:uuid/uuid.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  bool sidebarOpen = true;
  int currentPageIndex = 0; // 0: 首页, 1: 问答, 2: 知识库, 3: 看板
  bool isLoggedIn = false;
  String? currentUser;
  bool isAdmin = false;

  void toggleSidebar() {
    setState(() {
      sidebarOpen = !sidebarOpen;
    });
  }

  void switchPage(int index) {
    // 看板頁面對所有人開放，管理員可以看到更多詳細資料
    setState(() {
      currentPageIndex = index;
    });
  }

  void _handleAuthChanged(
    bool isLoggedIn,
    String? username,
    String? email,
  ) async {
    // 如果是登出
    if (!isLoggedIn) {
      // 清空对话服务中的历史记录和認證信息
      final conversationService = Provider.of<ConversationService>(
        context,
        listen: false,
      );
      conversationService.clearAll();
      await conversationService.clearAuthInfo();

      setState(() {
        this.isLoggedIn = false;
        this.currentUser = null;
        this.isAdmin = false;
      });
      return;
    }

    // 如果是登入或註冊
    if (username != null) {
      final dbService = DatabaseService();
      var existingUser = await dbService.getUserByUsername(username);

      // 如果用户不存在，并且 email 有效，则创建新用户
      if (existingUser == null && email != null) {
        final newUser = User(
          userId: Uuid().v4(), // 假设使用 uuid 生成 id
          username: username,
          email: email,
          registerDate: DateTime.now(),
        );
        await dbService.insertUser(newUser.toMap());
      }
    }

    setState(() {
      this.isLoggedIn = isLoggedIn;
      this.currentUser = username;
      // 检查是否为管理员
      this.isAdmin =
          username != null &&
          ['admin', 'administrator', 'manager'].contains(username);
    });
  }

  void _handleLogout() {
    _handleAuthChanged(false, null, null);
  }

  void _showAdminRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('权限不足'),
        content: const Text('只有管理员才能查看看板页面，请使用管理员账号登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果未登录，显示登录页面
    if (!isLoggedIn) {
      return AuthPage(onAuthChanged: _handleAuthChanged);
    }

    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Column(
        children: [
          // 顶部导航栏
          Expanded(
            child: AuroraBackground(
              child: Row(
                children: [
                  // 左侧功能栏
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: sidebarOpen && isWide ? 280 : 60,
                    curve: Curves.easeInOutCubic,
                    child: Sidebar(
                      open: sidebarOpen && isWide,
                      onCollapse: toggleSidebar,
                      currentPageIndex: currentPageIndex,
                      onPageChange: switchPage,
                      onLogout: _handleLogout, // 傳遞登出函式
                      isAdmin: isAdmin,
                      userName: currentUser ?? '', // 傳遞用戶名
                    ),
                  ),
                  // 主内容区
                  Expanded(child: _getCurrentPage()),
                ],
              ),
            ),
          ),
          // 底部信息栏
          Container(
            height: 40,
            color: const Color(0xFF333333),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '© 2025 华为技术有限公司. 版权所有.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (currentPageIndex) {
      case 0:
        return HomePage(isAdmin: isAdmin);
      case 1:
        return const ChatPage();
      case 2:
        return const KnowledgePage();
      case 3:
        return DashboardPage(isAdmin: isAdmin);
      default:
        return HomePage(isAdmin: isAdmin);
    }
  }
}
