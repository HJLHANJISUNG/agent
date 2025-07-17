import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../services/conversation_service.dart'; // Added for Provider
import '../services/database_service.dart'; // Added for DatabaseService
import 'package:provider/provider.dart'; // 補上 Provider import
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

// 頂層函數，供多個 widget 調用
Widget buildStatCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: const Color(0x0A000000),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildBarChart() {
  final data = [
    {'name': 'OSPF邻居问题', 'value': 45},
    {'name': 'BGP路由通告', 'value': 38},
    {'name': 'VLAN通信', 'value': 32},
    {'name': 'STP根桥选举', 'value': 28},
    {'name': 'ACL配置', 'value': 25},
  ];
  return Column(
    children: data.map((item) {
      final value = item['value'] as int;
      final name = item['name'] as String;
      final percentage = (value / 50 * 100).round();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                name,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE60012),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 30,
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

Widget buildHeatmap() {
  final protocols = ['OSPF', 'BGP', 'VLAN', 'STP', 'ACL', 'DHCP'];
  final categories = ['配置', '故障', '优化', '安全'];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const SizedBox(width: 80),
          ...categories.map(
            (category) => Expanded(
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...protocols.map((protocol) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  protocol,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              ...categories.map((category) {
                final coverage = getCoverage(protocol, category);
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: getHeatmapColor(coverage),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${coverage}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: coverage > 50
                              ? Colors.white
                              : const Color(0xFF333333),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      }).toList(),
    ],
  );
}

int getCoverage(String protocol, String category) {
  final coverageMap = {
    'OSPF': {'配置': 85, '故障': 90, '优化': 70, '安全': 60},
    'BGP': {'配置': 80, '故障': 85, '优化': 75, '安全': 65},
    'VLAN': {'配置': 90, '故障': 85, '优化': 80, '安全': 70},
    'STP': {'配置': 75, '故障': 80, '优化': 65, '安全': 55},
    'ACL': {'配置': 70, '故障': 75, '优化': 60, '安全': 85},
    'DHCP': {'配置': 85, '故障': 80, '优化': 75, '安全': 70},
  };
  return coverageMap[protocol]?[category] ?? 50;
}

Color getHeatmapColor(int coverage) {
  if (coverage >= 80) return const Color(0xFFE60012);
  if (coverage >= 60) return const Color(0xFFFF6B35);
  if (coverage >= 40) return const Color(0xFFFFB74D);
  return const Color(0xFFE0E0E0);
}

class DashboardPage extends StatefulWidget {
  final bool isAdmin;
  const DashboardPage({super.key, this.isAdmin = false});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  int questionCount = 0;
  int solvedCount = 0;
  int knowledgeCount = 0;
  int feedbackCount = 0;
  // 新增管理員統計變數
  int activeUserCount = 0;
  int newUserCount = 0;
  double solvedRate = 0.0;
  double avgAnswerTime = 0.0;
  String lastKnowledgeUpdate = '';
  bool _loading = true;

  // 新增更多用戶數據統計
  int totalUserCount = 0;
  List<Map<String, dynamic>> recentFeedbacks = [];
  Map<String, int> protocolDistribution = {};
  Map<String, dynamic> feedbackStats = {};
  List<Map<String, dynamic>> userList = [];

  // 問題分類統計
  List<Map<String, dynamic>> questionCategories = [];

  // 知識庫覆蓋度數據
  Map<String, Map<String, int>> knowledgeCoverage = {};

  // 最近活動記錄
  List<Map<String, dynamic>> recentActivities = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    print('DashboardPage: loadStats start');
    try {
      final userService = Provider.of<ConversationService>(
        context,
        listen: false,
      );
      final userId = userService.userId;
      print('DashboardPage: userId = ' + (userId?.toString() ?? 'null'));
      if (userId == null) {
        setState(() {
          _loading = false;
        });
        print('DashboardPage: userId is null, stop loading');
        return;
      }
      final db = DatabaseService();

      try {
        // 基本統計數據
        final qCount = await db.getUserQuestionCount(userId);
        print('DashboardPage: qCount = $qCount');
        final sCount = await db.getUserSolvedCount(userId);
        print('DashboardPage: sCount = $sCount');
        final kCount = await db.getUserKnowledgeCount(userId);
        print('DashboardPage: kCount = $kCount');
        final fCount = await db.getUserFeedbackCount(userId);
        print('DashboardPage: fCount = $fCount');

        // 管理員統計
        final activeUsers = await db.getActiveUserCount();
        print('DashboardPage: activeUsers = $activeUsers');
        final newUsers = await db.getNewUserCount();
        print('DashboardPage: newUsers = $newUsers');
        final solvedRateVal = await db.getSolvedRate();
        print('DashboardPage: solvedRate = $solvedRateVal');
        final avgAnswer = await db.getAverageAnswerTime();
        print('DashboardPage: avgAnswer = $avgAnswer');
        final lastKnowledge = await db.getLastKnowledgeUpdate();
        print('DashboardPage: lastKnowledge = $lastKnowledge');

        // 新增數據獲取
        final totalUsers = await db.getUserCount();
        print('DashboardPage: totalUsers = $totalUsers');
        final feedbacks = await db.getFeedbacks(limit: 5); // 只獲取最近5條反饋
        print('DashboardPage: feedbacks count = ${feedbacks.length}');
        final protocols = await db.getProtocolDistribution();
        print('DashboardPage: protocols = $protocols');
        final fbStats = await db.getFeedbackStats();
        print('DashboardPage: fbStats = $fbStats');

        // 獲取用戶列表
        final users = await db.getUsers();
        print('DashboardPage: users count = ${users.length}');

        // 生成最近活動記錄（模擬數據）
        final activities = _generateRecentActivities();
        print('DashboardPage: activities generated');

        // 生成問題分類統計數據（模擬數據）
        final categories = _generateQuestionCategories();
        print('DashboardPage: categories generated');

        // 生成知識庫覆蓋度數據
        final coverage = _generateKnowledgeCoverage();
        print('DashboardPage: coverage generated');

        setState(() {
          questionCount = qCount;
          solvedCount = sCount;
          knowledgeCount = kCount;
          feedbackCount = fCount;
          activeUserCount = activeUsers;
          newUserCount = newUsers;
          solvedRate = solvedRateVal;
          avgAnswerTime = avgAnswer;
          lastKnowledgeUpdate = lastKnowledge;

          // 設置新增的數據
          totalUserCount = totalUsers;
          recentFeedbacks = feedbacks;
          protocolDistribution = protocols;
          feedbackStats = fbStats;
          userList = users;
          recentActivities = activities;
          questionCategories = categories;
          knowledgeCoverage = coverage;

          _loading = false;
        });
        print('DashboardPage: loadStats end successfully');
      } catch (innerError) {
        print('DashboardPage: Inner error during data loading: $innerError');
        // 使用模擬數據
        final activities = _generateRecentActivities();
        final categories = _generateQuestionCategories();
        final coverage = _generateKnowledgeCoverage();

        setState(() {
          // 設置基本模擬數據
          questionCount = 15;
          solvedCount = 10;
          knowledgeCount = 25;
          feedbackCount = 8;
          activeUserCount = 5;
          newUserCount = 3;
          solvedRate = 0.67;
          avgAnswerTime = 45.0;
          lastKnowledgeUpdate = '2024-05-01';

          // 設置其他模擬數據
          totalUserCount = 20;
          recentFeedbacks = [];
          protocolDistribution = {
            'OSPF': 5,
            'BGP': 4,
            'VLAN': 3,
            'STP': 2,
            'ACL': 1,
          };
          feedbackStats = {
            'total_count': 8,
            'average_rating': 4.5,
            'pending_count': 2,
          };
          userList = [];
          recentActivities = activities;
          questionCategories = categories;
          knowledgeCoverage = coverage;

          _loading = false;
        });
        print('DashboardPage: loadStats end with mock data');
      }
    } catch (e, stack) {
      print('DashboardPage: loadStats error: $e');
      print(stack);
      setState(() {
        _loading = false;
      });
    }
  }

  // 生成最近活動記錄（模擬數據）
  List<Map<String, dynamic>> _generateRecentActivities() {
    final activities = [
      {
        'type': 'question',
        'user': '用戶1',
        'content': '如何配置OSPF協議？',
        'time': DateTime.now().subtract(Duration(minutes: 5)),
      },
      {
        'type': 'feedback',
        'user': '用戶2',
        'content': '給出了5星評價',
        'time': DateTime.now().subtract(Duration(minutes: 15)),
      },
      {
        'type': 'knowledge',
        'user': '管理員',
        'content': '更新了BGP協議知識庫',
        'time': DateTime.now().subtract(Duration(hours: 1)),
      },
      {
        'type': 'login',
        'user': '用戶3',
        'content': '登入系統',
        'time': DateTime.now().subtract(Duration(hours: 2)),
      },
      {
        'type': 'question',
        'user': '用戶4',
        'content': 'VLAN間通信問題排查',
        'time': DateTime.now().subtract(Duration(hours: 3)),
      },
    ];
    return activities;
  }

  // 生成問題分類統計數據（模擬數據）
  List<Map<String, dynamic>> _generateQuestionCategories() {
    final categories = [
      {'category': 'OSPF', 'count': 15, 'percentage': 30},
      {'category': 'BGP', 'count': 10, 'percentage': 20},
      {'category': 'VLAN', 'count': 8, 'percentage': 16},
      {'category': 'STP', 'count': 7, 'percentage': 14},
      {'category': 'ACL', 'count': 5, 'percentage': 10},
      {'category': 'DHCP', 'count': 3, 'percentage': 6},
      {'category': '其他', 'count': 2, 'percentage': 4},
    ];
    return categories;
  }

  // 生成知識庫覆蓋度數據
  Map<String, Map<String, int>> _generateKnowledgeCoverage() {
    final coverage = {
      'OSPF': {'配置': 85, '故障': 90, '优化': 70, '安全': 60},
      'BGP': {'配置': 80, '故障': 85, '优化': 75, '安全': 65},
      'VLAN': {'配置': 90, '故障': 85, '优化': 80, '安全': 70},
      'STP': {'配置': 75, '故障': 80, '优化': 65, '安全': 55},
      'ACL': {'配置': 70, '故障': 75, '优化': 60, '安全': 85},
      'DHCP': {'配置': 85, '故障': 80, '优化': 75, '安全': 70},
    };
    return coverage;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Flexible(
                child: buildStatCard(
                  '总问题数',
                  questionCount.toString(),
                  Icons.question_answer,
                  const Color(0xFFE60012),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: buildStatCard(
                  '知识条目',
                  knowledgeCount.toString(),
                  Icons.library_books,
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: buildStatCard(
                  '用户反馈',
                  feedbackCount.toString(),
                  Icons.feedback,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ),

        // 新增：最近活動列表
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.update, color: Color(0xFFE60012)),
                      const SizedBox(width: 8),
                      const Text(
                        '最近活動',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // 刷新數據
                          setState(() {
                            _loading = true;
                          });
                          loadStats();
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.refresh, size: 16),
                            SizedBox(width: 4),
                            Text('刷新'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity = recentActivities[index];
                    return _buildActivityItem(activity);
                  },
                ),
              ],
            ),
          ),
        ),

        // 新增：反饋統計卡片
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFF9800)),
                      const SizedBox(width: 8),
                      const Text(
                        '用戶反饋統計',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // 平均評分
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '平均評分',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFB400),
                                  size: 24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (feedbackStats['average_rating'] as num?)
                                          ?.toStringAsFixed(1) ??
                                      '0.0',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  '/5',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '共 ${feedbackStats['total_count'] ?? 0} 個評價',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 評分分佈
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '評分分佈',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            _buildRatingBar(5, 0.65),
                            _buildRatingBar(4, 0.25),
                            _buildRatingBar(3, 0.05),
                            _buildRatingBar(2, 0.03),
                            _buildRatingBar(1, 0.02),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 最近反饋
                if (recentFeedbacks.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '最近反饋',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...recentFeedbacks.take(3).map((feedback) {
                          return _buildFeedbackItem(feedback);
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 新增：問題分類統計
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildQuestionCategoriesChart(),
            ),
          ),
        ),

        // 新增：知識庫覆蓋度熱力圖
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildKnowledgeCoverageHeatmap(),
            ),
          ),
        ),

        // 管理員專用內容
        if (widget.isAdmin) ...[
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '管理員統計資料',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdminStatItem(
                          '活躍用戶數',
                          activeUserCount.toString(),
                          Icons.trending_up,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      Expanded(
                        child: _buildAdminStatItem(
                          '平均回答時間',
                          '${avgAnswerTime.toStringAsFixed(1)}秒',
                          Icons.timer,
                          const Color(0xFF2196F3),
                        ),
                      ),
                      Expanded(
                        child: _buildAdminStatItem(
                          '解決率',
                          '${(solvedRate * 100).toStringAsFixed(1)}%',
                          Icons.check_circle_outline,
                          const Color(0xFFE60012),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdminStatItem(
                          '新用戶增長',
                          newUserCount.toString(),
                          Icons.person_add,
                          const Color(0xFF9C27B0),
                        ),
                      ),
                      Expanded(
                        child: _buildAdminStatItem(
                          '知識庫更新',
                          lastKnowledgeUpdate.isNotEmpty
                              ? lastKnowledgeUpdate
                              : '無',
                          Icons.update,
                          const Color(0xFFFF9800),
                        ),
                      ),
                      Expanded(
                        child: _buildAdminStatItem(
                          '系統負載',
                          'N/A',
                          Icons.memory,
                          const Color(0xFF607D8B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 構建活動項目
  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final IconData icon;
    final Color color;

    switch (activity['type']) {
      case 'question':
        icon = Icons.question_answer;
        color = const Color(0xFF2196F3);
        break;
      case 'feedback':
        icon = Icons.star;
        color = const Color(0xFFFF9800);
        break;
      case 'knowledge':
        icon = Icons.library_books;
        color = const Color(0xFF4CAF50);
        break;
      case 'login':
        icon = Icons.login;
        color = const Color(0xFF9C27B0);
        break;
      default:
        icon = Icons.info;
        color = const Color(0xFF607D8B);
    }

    final DateTime time = activity['time'] as DateTime;
    final now = DateTime.now();
    final difference = now.difference(time);

    String timeText;
    if (difference.inMinutes < 60) {
      timeText = '${difference.inMinutes} 分鐘前';
    } else if (difference.inHours < 24) {
      timeText = '${difference.inHours} 小時前';
    } else {
      timeText = '${difference.inDays} 天前';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        '${activity['user']} ${activity['content']}',
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Text(
        timeText,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  // 構建評分條
  Widget _buildRatingBar(int rating, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Row(
              children: [
                Text('$rating', style: const TextStyle(fontSize: 12)),
                const Icon(Icons.star, size: 12, color: Color(0xFFFFB400)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 構建反饋項目
  Widget _buildFeedbackItem(Map<String, dynamic> feedback) {
    final int rating = feedback['rating'] as int? ?? 0;
    final String comment = feedback['comment'] as String? ?? '';
    final String userId = feedback['user_id'] as String? ?? '';
    final String createdAt = feedback['created_at'] as String? ?? '';

    DateTime? date;
    try {
      date = DateTime.parse(createdAt);
    } catch (e) {
      // 忽略解析錯誤
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE60012).withOpacity(0.1),
                child: Text(
                  userId.isNotEmpty ? userId[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFFE60012),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User-${userId.substring(0, math.min(6, userId.length))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (date != null)
                      Text(
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB400),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              comment,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 構建問題分類統計視覺化
  Widget _buildQuestionCategoriesChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '問題分類統計',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...questionCategories.map((category) {
          final String name = category['category'] as String;
          final int count = category['count'] as int;
          final int percentage = category['percentage'] as int;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count 個問題',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE60012),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(name),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // 獲取分類顏色
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'OSPF':
        return const Color(0xFFE60012);
      case 'BGP':
        return const Color(0xFF2196F3);
      case 'VLAN':
        return const Color(0xFF4CAF50);
      case 'STP':
        return const Color(0xFFFF9800);
      case 'ACL':
        return const Color(0xFF9C27B0);
      case 'DHCP':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF757575);
    }
  }

  // 構建知識庫覆蓋度熱力圖
  Widget _buildKnowledgeCoverageHeatmap() {
    final protocols = knowledgeCoverage.keys.toList();
    final categories = knowledgeCoverage.values.first.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '知識庫覆蓋度熱力圖',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(width: 80),
            ...categories.map(
              (category) => Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...protocols.map((protocol) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    protocol,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                ...categories.map((category) {
                  final coverage = knowledgeCoverage[protocol]?[category] ?? 0;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _getHeatmapColor(coverage),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '$coverage%',
                          style: TextStyle(
                            fontSize: 10,
                            color: coverage > 50
                                ? Colors.white
                                : const Color(0xFF333333),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // 獲取熱力圖顏色
  Color _getHeatmapColor(int coverage) {
    if (coverage >= 80) return const Color(0xFFE60012);
    if (coverage >= 60) return const Color(0xFFFF6B35);
    if (coverage >= 40) return const Color(0xFFFFB74D);
    return const Color(0xFFE0E0E0);
  }
}

class DashboardUserTab extends StatelessWidget {
  final bool isAdmin;
  const DashboardUserTab({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基本統計卡片（所有人可見）
        Row(
          children: [
            Flexible(
              child: buildStatCard('总用户', '2,345', Icons.people, Colors.blue),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: buildStatCard(
                '活跃用户',
                '1,890',
                Icons.person_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 用戶列表標題
        const Text(
          '用户列表',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 基本用戶列表（所有人可見，但有限制）
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: 5, // 非管理員只顯示前5個用戶
            itemBuilder: (context, index) {
              return _buildUserListItem(
                '用戶${index + 1}',
                'user${index + 1}@example.com',
                DateTime.now().subtract(Duration(days: index * 5)),
                isAdmin: isAdmin,
              );
            },
          ),
        ),

        // 管理員專用內容
        if (isAdmin) ...[
          const SizedBox(height: 24),
          const Text(
            '管理員控制台',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE60012),
            ),
          ),
          const SizedBox(height: 16),

          // 用戶管理功能
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用戶搜索欄
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索用戶...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // 用戶管理按鈕
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('新增用戶'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.block),
                      label: const Text('禁用選中用戶'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh),
                      label: const Text('重置密碼'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 詳細用戶列表
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: ListView(
                    children: [
                      // 表頭
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        color: const Color(0xFFF5F5F5),
                        child: const Row(
                          children: [
                            SizedBox(width: 24), // 勾選框空間
                            Expanded(
                              flex: 2,
                              child: Text(
                                '用戶名',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '電子郵件',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '註冊日期',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '狀態',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '操作',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 用戶數據行
                      ...List.generate(10, (index) {
                        return _buildAdminUserListItem(
                          '用戶${index + 1}',
                          'user${index + 1}@example.com',
                          DateTime.now().subtract(Duration(days: index * 5)),
                          index % 3 == 0 ? '已禁用' : '正常',
                        );
                      }),
                    ],
                  ),
                ),

                // 分頁控制
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE60012),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('2')),
                    TextButton(onPressed: () {}, child: const Text('3')),
                    const Text('...'),
                    TextButton(onPressed: () {}, child: const Text('10')),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 用戶賬號和密碼管理
          const SizedBox(height: 24),
          const Text(
            '系統賬號管理',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE60012),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '管理員賬號',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('用戶名')),
                      DataColumn(label: Text('密碼')),
                      DataColumn(label: Text('權限')),
                      DataColumn(label: Text('操作')),
                    ],
                    rows: [
                      _buildAdminAccountRow('admin', 'admin123', '超級管理員'),
                      _buildAdminAccountRow(
                        'administrator',
                        'admin456',
                        '系統管理員',
                      ),
                      _buildAdminAccountRow('manager', 'manager789', '內容管理員'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserListItem(
    String name,
    String email,
    DateTime registerDate, {
    bool isAdmin = false,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE60012).withOpacity(0.1),
        child: Text(
          name.substring(0, 1),
          style: const TextStyle(
            color: Color(0xFFE60012),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name),
      subtitle: Text(email),
      trailing: Text(
        '${registerDate.year}-${registerDate.month.toString().padLeft(2, '0')}-${registerDate.day.toString().padLeft(2, '0')}',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildAdminUserListItem(
    String name,
    String email,
    DateTime registerDate,
    String status,
  ) {
    final bool isDisabled = status == '已禁用';

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              child: Checkbox(value: false, onChanged: null),
            ),
            Expanded(
              flex: 2,
              child: Text(
                name,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.black,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                email,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.black,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${registerDate.year}-${registerDate.month.toString().padLeft(2, '0')}-${registerDate.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.black,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDisabled
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFF1B5E20),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 18),
                    color: const Color(0xFF2196F3),
                    tooltip: '編輯',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      isDisabled ? Icons.check_circle : Icons.block,
                      size: 18,
                    ),
                    color: isDisabled
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF5722),
                    tooltip: isDisabled ? '啟用' : '禁用',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildAdminAccountRow(String username, String password, String role) {
    return DataRow(
      cells: [
        DataCell(Text(username)),
        DataCell(
          Row(
            children: [
              Text('••••••••'),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.visibility, size: 16),
                tooltip: '顯示密碼',
              ),
            ],
          ),
        ),
        DataCell(Text(role)),
        DataCell(
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 16),
                tooltip: '編輯',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.refresh, size: 16),
                tooltip: '重置密碼',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardDataTab extends StatefulWidget {
  final bool isAdmin;
  const DashboardDataTab({super.key, this.isAdmin = false});
  @override
  _DashboardDataTabState createState() => _DashboardDataTabState();
}

class _DashboardDataTabState extends State<DashboardDataTab> {
  int touchedIndex = -1;
  String selectedTimeRange = '過去7天';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基本圖表（所有人可見）
        const Text(
          '技术主题分布',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: _buildNewPieChart(),
        ),
        const SizedBox(height: 24),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: buildBarChart(),
        ),

        // 管理員專用大數據統計
        if (widget.isAdmin) ...[
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '大數據統計分析',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE60012),
                ),
              ),
              // 時間範圍選擇器
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButton<String>(
                  value: selectedTimeRange,
                  underline: const SizedBox(),
                  items: ['過去7天', '過去30天', '過去90天', '過去一年'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedTimeRange = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 用戶活躍度趨勢圖
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '用戶活躍度趨勢',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildLineChart()),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 知識覆蓋熱力圖
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '知識覆蓋熱力圖',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                buildHeatmap(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 用戶地理分佈
          Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '用戶地理分佈',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildGeoDistributionChart()),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 系統性能監控
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '系統性能監控',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPerformanceCard(
                        'CPU使用率',
                        '32%',
                        const Color(0xFFE60012),
                        0.32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPerformanceCard(
                        '記憶體使用率',
                        '45%',
                        const Color(0xFF2196F3),
                        0.45,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPerformanceCard(
                        '磁碟使用率',
                        '68%',
                        const Color(0xFFFF9800),
                        0.68,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPerformanceCard(
                        '網絡流量',
                        '12MB/s',
                        const Color(0xFF4CAF50),
                        0.56,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF607D8B)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '系統運行正常，所有指標均在安全範圍內。上次維護時間：2024-05-01 03:00',
                          style: TextStyle(color: Color(0xFF607D8B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLineChart() {
    // 模擬用戶活躍度數據
    final List<FlSpot> spots = [
      const FlSpot(0, 3),
      const FlSpot(1, 2),
      const FlSpot(2, 5),
      const FlSpot(3, 3.1),
      const FlSpot(4, 4),
      const FlSpot(5, 3),
      const FlSpot(6, 4),
      const FlSpot(7, 4.5),
      const FlSpot(8, 5),
      const FlSpot(9, 5.5),
      const FlSpot(10, 4.7),
      const FlSpot(11, 6),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: 7,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFE60012),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFE60012).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const months = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];
    final int index = value.toInt();
    if (index >= 0 && index < months.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(months[index], style: const TextStyle(fontSize: 10)),
      );
    }
    return const SizedBox();
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${value.toInt()}K', style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildGeoDistributionChart() {
    // 這裡應該是一個地圖組件，但由於Flutter沒有內建的地圖可視化，
    // 所以我們用一個簡單的表格來代替

    final geoData = [
      {'region': '北京', 'users': 1245, 'percentage': 23.5},
      {'region': '上海', 'users': 987, 'percentage': 18.6},
      {'region': '廣州', 'users': 765, 'percentage': 14.4},
      {'region': '深圳', 'users': 654, 'percentage': 12.3},
      {'region': '杭州', 'users': 543, 'percentage': 10.2},
      {'region': '成都', 'users': 432, 'percentage': 8.1},
      {'region': '武漢', 'users': 321, 'percentage': 6.0},
      {'region': '其他', 'users': 365, 'percentage': 6.9},
    ];

    return Column(
      children: [
        // 模擬地圖
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '中國地區分佈地圖',
                style: TextStyle(color: Color(0xFF666666), fontSize: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 地區數據表格
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('地區')),
              DataColumn(label: Text('用戶數')),
              DataColumn(label: Text('百分比')),
              DataColumn(label: Text('趨勢')),
            ],
            rows: geoData.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item['region'] as String)),
                  DataCell(Text('${item['users']}')),
                  DataCell(Text('${item['percentage']}%')),
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          (item['region'] == '北京' ||
                                  item['region'] == '上海' ||
                                  item['region'] == '成都')
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color:
                              (item['region'] == '北京' ||
                                  item['region'] == '上海' ||
                                  item['region'] == '成都')
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE60012),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (item['region'] == '北京' ||
                                  item['region'] == '上海' ||
                                  item['region'] == '成都')
                              ? '+3.2%'
                              : '-1.5%',
                          style: TextStyle(
                            color:
                                (item['region'] == '北京' ||
                                    item['region'] == '上海' ||
                                    item['region'] == '成都')
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE60012),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    Color color,
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPieChart() {
    final data = [
      {'name': 'OSPF', 'value': 35.0, 'color': const Color(0xFFE60012)},
      {'name': 'BGP', 'value': 25.0, 'color': const Color(0xFF4CAF50)},
      {'name': 'VLAN', 'value': 20.0, 'color': const Color(0xFF2196F3)},
      {'name': 'STP', 'value': 15.0, 'color': const Color(0xFFFF9800)},
      {'name': '其他', 'value': 5.0, 'color': const Color(0xFF9C27B0)},
    ];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: data.asMap().entries.map((entry) {
                final int i = entry.key;
                final item = entry.value;
                final isTouched = i == touchedIndex;
                final fontSize = isTouched ? 25.0 : 16.0;
                final radius = isTouched ? 60.0 : 50.0;
                return PieChartSectionData(
                  color: item['color'] as Color,
                  value: item['value'] as double,
                  title: '${item['value']}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item['name']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class DashboardFeedbackTab extends StatefulWidget {
  final bool isAdmin;
  const DashboardFeedbackTab({super.key, this.isAdmin = false});

  @override
  State<DashboardFeedbackTab> createState() => _DashboardFeedbackTabState();
}

class _DashboardFeedbackTabState extends State<DashboardFeedbackTab> {
  final _feedbackService = FeedbackService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _feedbacks = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 獲取反饋列表
      final feedbacks = await _feedbackService.getFeedbacks(limit: 50);

      // 如果是管理員，獲取統計數據
      Map<String, dynamic> stats = {};
      if (widget.isAdmin) {
        stats = await _feedbackService.getFeedbackStats();
      }

      if (mounted) {
        setState(() {
          _feedbacks = feedbacks;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '載入數據失敗: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateFeedbackStatus(String feedbackId, String status) async {
    try {
      final success = await _feedbackService.updateFeedbackStatus(
        feedbackId: feedbackId,
        status: status,
      );

      if (success && mounted) {
        _loadData(); // 重新載入數據
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('狀態更新成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE60012)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('重試')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本反饋列表（所有人可見，但非管理員只能看到有限資訊）
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '用户反馈',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                _feedbacks.isEmpty
                    ? const Center(
                        child: Text(
                          '暫無反饋數據',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : _buildFeedbackList(_feedbacks, isAdmin: widget.isAdmin),
              ],
            ),
          ),

          // 管理員專用內容
          if (widget.isAdmin) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '反饋管理',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE60012),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 反饋統計卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFeedbackStatCard(
                      '總反饋數',
                      '${_stats['total_count'] ?? 0}',
                      Icons.feedback,
                      const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeedbackStatCard(
                      '平均評分',
                      '${_stats['average_rating']?.toStringAsFixed(1) ?? 0.0}',
                      Icons.star,
                      const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeedbackStatCard(
                      '待處理',
                      '${_stats['pending_count'] ?? 0}',
                      Icons.pending_actions,
                      const Color(0xFFE60012),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 反饋評分分佈
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '反饋評分分佈',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  _buildRatingDistribution(_stats['rating_distribution'] ?? []),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 反饋詳細列表
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '反饋詳細列表',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download),
                            label: const Text('導出數據'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.filter_list),
                            label: const Text('篩選'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF666666),
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _feedbacks.isEmpty
                      ? const Center(
                          child: Text(
                            '暫無反饋數據',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DataTable(
                            columnSpacing: 16,
                            columns: const [
                              DataColumn(label: Text('用戶')),
                              DataColumn(label: Text('評分')),
                              DataColumn(label: Text('反饋內容')),
                              DataColumn(label: Text('日期')),
                              DataColumn(label: Text('狀態')),
                              DataColumn(label: Text('操作')),
                            ],
                            rows: _feedbacks.map((feedback) {
                              return _buildFeedbackRow(
                                feedback['user_name'] ?? '未知用戶',
                                feedback['rating'] ?? 0,
                                feedback['comment'] ?? '',
                                feedback['created_at'] ?? '',
                                feedback['status'] ?? '待處理',
                                feedbackId: feedback['feedback_id'],
                              );
                            }).toList(),
                          ),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE60012),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(onPressed: () {}, child: const Text('2')),
                      TextButton(onPressed: () {}, child: const Text('3')),
                      const Text('...'),
                      TextButton(onPressed: () {}, child: const Text('10')),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 反饋問題分類
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '反饋問題分類',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  _buildFeedbackCategoryChart(
                    _stats['category_distribution'] ?? [],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackList(
    List<Map<String, dynamic>> feedbacks, {
    bool isAdmin = false,
  }) {
    // 非管理員只顯示有限的反饋，且隱藏用戶名等敏感信息
    final displayFeedbacks = isAdmin
        ? feedbacks
        : feedbacks.take(5).map((feedback) {
            // 創建一個新的 Map，只包含非敏感信息
            return {
              'rating': feedback['rating'],
              'comment': feedback['comment'],
              'created_at': feedback['created_at'],
              // 隱藏用戶名，只顯示匿名
              'user_name': '匿名用戶',
            };
          }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayFeedbacks.length,
      itemBuilder: (context, index) {
        final feedback = displayFeedbacks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    feedback['user_name'] ?? '未知用戶',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (feedback['rating'] as int)
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: const Color(0xFFFF9800),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feedback['created_at'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                feedback['comment'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),

              // 管理員專用的操作按鈕
              if (isAdmin) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (feedback['status'] != '已處理')
                      TextButton.icon(
                        onPressed: () => _updateFeedbackStatus(
                          feedback['feedback_id'],
                          '已處理',
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('標記為已處理'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(feedback['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feedback['status'] ?? '待處理',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 輔助方法：根據狀態獲取顏色
  Color _getStatusColor(String? status) {
    switch (status) {
      case '已處理':
        return const Color(0xFF4CAF50);
      case '處理中':
        return const Color(0xFF2196F3);
      case '待處理':
      default:
        return const Color(0xFFFF9800);
    }
  }

  Widget _buildFeedbackStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(List<dynamic> ratingData) {
    if (ratingData.isEmpty) {
      return const Center(
        child: Text('暫無評分數據', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: ratingData.map((data) {
        final Map<String, dynamic> item = data as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${item['rating']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Color(0xFFFF9800), size: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (item['percentage'] as double) / 100,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: item['rating'] == 5
                              ? const Color(0xFF4CAF50)
                              : item['rating'] == 4
                              ? const Color(0xFF8BC34A)
                              : item['rating'] == 3
                              ? const Color(0xFFFFEB3B)
                              : item['rating'] == 2
                              ? const Color(0xFFFF9800)
                              : const Color(0xFFE60012),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                child: Text(
                  '${item['count']} (${item['percentage'].toInt()}%)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  DataRow _buildFeedbackRow(
    String user,
    int rating,
    String content,
    String date,
    String status, {
    String? feedbackId,
  }) {
    Color statusColor;
    if (status == '已處理') {
      statusColor = const Color(0xFF4CAF50);
    } else if (status == '處理中') {
      statusColor = const Color(0xFF2196F3);
    } else {
      statusColor = const Color(0xFFFF9800);
    }

    return DataRow(
      cells: [
        DataCell(Text(user)),
        DataCell(
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFFF9800),
                size: 16,
              );
            }),
          ),
        ),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(content, overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
        ),
        DataCell(Text(date)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 12, color: statusColor),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.visibility, size: 18),
                tooltip: '查看詳情',
                color: const Color(0xFF2196F3),
              ),
              IconButton(
                onPressed: feedbackId != null && status != '已處理'
                    ? () => _updateFeedbackStatus(feedbackId, '已處理')
                    : null,
                icon: const Icon(Icons.check_circle, size: 18),
                tooltip: '標記為已處理',
                color: status == '已處理' ? Colors.grey : const Color(0xFF4CAF50),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCategoryChart(List<dynamic> categoryData) {
    if (categoryData.isEmpty) {
      return const Center(
        child: Text('暫無分類數據', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: categoryData.map((data) {
        final Map<String, dynamic> item = data as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getCategoryColor(item['category'] as String),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: Text(
                  item['category'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (item['percentage'] as double) / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getCategoryColor(item['category'] as String),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Text(
                  '${item['count']} (${item['percentage'].toInt()}%)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    if (category.contains('OSPF')) return const Color(0xFFE60012);
    if (category.contains('BGP')) return const Color(0xFF4CAF50);
    if (category.contains('VLAN')) return const Color(0xFF2196F3);
    if (category.contains('ACL')) return const Color(0xFFFF9800);
    return const Color(0xFF9C27B0); // 其他
  }
}
