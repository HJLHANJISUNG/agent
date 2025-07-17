import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/conversation_service.dart';

class Sidebar extends StatelessWidget {
  final bool open;
  final VoidCallback onCollapse;
  final int currentPageIndex;
  final Function(int) onPageChange;
  final VoidCallback onLogout; // 新增登出回呼
  final bool isAdmin;
  final String userName; // 新增用戶名參數

  Sidebar({
    super.key,
    required this.open,
    required this.onCollapse,
    required this.currentPageIndex,
    required this.onPageChange,
    required this.onLogout, // 新增到建構函式
    this.isAdmin = false,
    required this.userName, // 新增到建構函式
  });

  final Color sidebarColor = const Color(0xFFFF4B2B); // 主紅橙色
  final Color sidebarHighlight = const Color(0xFFFF6A3D); // 高亮橙

  @override
  Widget build(BuildContext context) {
    // 假設用戶資訊可從 Provider 或 context 取得，這裡用假資料 admin/isAdmin
    final bool isAdmin = this.isAdmin;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sidebarColor, sidebarHighlight],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      width: open ? 280 : 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // LOGO + 標題
          Padding(
            padding: EdgeInsets.symmetric(horizontal: open ? 24 : 0),
            child: Row(
              mainAxisAlignment: open
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE60012),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'H',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (open) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'IP智慧解答专家',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (open) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '欢迎 · $userName',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '管理员',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: onLogout, // 呼叫登出函式
                    child: const Text(
                      '登出',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          // 導航按鈕
          _buildNavItem('首页', Icons.home, 0, context),
          // 如果不是管理員，才顯示問答按鈕
          if (!isAdmin) _buildNavItem('问答', Icons.chat, 1, context),
          _buildNavItem('知识库', Icons.library_books, isAdmin ? 1 : 2, context),
          _buildNavItem(
            '看板',
            Icons.dashboard,
            isAdmin ? 2 : 3,
            context,
          ), // 所有用戶都能看到看板
          const Spacer(),

          // 收合按鈕
          const Divider(color: Colors.white30, indent: 16, endIndent: 16),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: open ? 12 : 0,
              vertical: 8,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCollapse,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 48,
                  padding: EdgeInsets.symmetric(horizontal: open ? 12 : 0),
                  child: Row(
                    mainAxisAlignment: open
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        open ? Icons.chevron_left : Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (open) ...[
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            '收合侧栏',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String title,
    IconData icon,
    int index,
    BuildContext context,
  ) {
    final bool isSelected = currentPageIndex == index;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: open ? 12 : 0, vertical: 4),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onPageChange(index),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: open ? 12 : 0),
            child: Row(
              mainAxisAlignment: open
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                if (open) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
