import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final int currentPageIndex;
  final Function(int) onPageChange;
  final String? currentUser;
  final bool isAdmin;
  final VoidCallback? onLogout;

  const TopBar({
    super.key,
    this.onMenuTap,
    required this.currentPageIndex,
    required this.onPageChange,
    this.currentUser,
    this.isAdmin = false,
    this.onLogout,
  });

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
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左側區域
              Row(
                children: [
                  if (onMenuTap != null)
                    IconButton(
                      onPressed: onMenuTap,
                      icon: const Icon(Icons.menu, color: Color(0xFF333333)),
                    ),
                  // 华为Logo
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
                  const SizedBox(width: 12),
                  // 系统名称
                  const Text(
                    'IP智慧解答专家',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 右侧区域
              Row(
                children: [
                  // 用户信息和登出按钮
                  if (currentUser != null) ...[
                    Text(
                      '欢迎，$currentUser',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE60012).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '管理员',
                          style: TextStyle(
                            color: Color(0xFFE60012),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onLogout,
                      child: const Text(
                        '登出',
                        style: TextStyle(
                          color: Color(0xFFE60012),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () {
                        // TODO: 实现登录功能
                      },
                      child: const Text(
                        '登录',
                        style: TextStyle(
                          color: Color(0xFFE60012),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: 实现注册功能
                      },
                      child: const Text('注册'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(String title, int index, IconData icon) {
    final isSelected = currentPageIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton.icon(
        onPressed: () => onPageChange(index),
        icon: Icon(
          icon,
          color: isSelected ? const Color(0xFFE60012) : const Color(0xFF666666),
          size: 20,
        ),
        label: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFE60012)
                : const Color(0xFF666666),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
