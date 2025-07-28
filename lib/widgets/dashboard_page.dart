import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../services/conversation_service.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:async';

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

class DashboardPage extends StatefulWidget {
  final bool isAdmin;
  const DashboardPage({super.key, this.isAdmin = false});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // 静态变量用于跟踪页面实例
  static DashboardPageState? _currentInstance;

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

  // 自動刷新計時器
  Timer? _refreshTimer;

  // 最后更新时间
  DateTime? _lastUpdateTime;

  @override
  bool get wantKeepAlive => true;

  // 静态方法，供其他页面调用刷新看板
  static void refreshDashboard() {
    _currentInstance?.refreshData();
  }

  @override
  void initState() {
    super.initState();
    _currentInstance = this;
    WidgetsBinding.instance.addObserver(this);
    loadStats();
    _startAutoRefresh();
    _listenToConversationService();
    _listenToFeedbackChanges();
  }

  @override
  void dispose() {
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当依赖项改变时（比如页面切换），刷新数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadStats();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 應用恢復時刷新數據
      loadStats();
    }
  }

  // 開始自動刷新
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        loadStats();
      } else {
        timer.cancel();
      }
    });
  }

  // 刷新數據
  Future<void> refreshData() async {
    await loadStats();
  }

  // 加載統計數據
  Future<void> loadStats() async {
    if (!mounted) return;

    try {
      print('DashboardPage: loadStats start');
      final db = DatabaseService();
      final userId = await db.getCurrentUserId();
      print('DashboardPage: userId = $userId');

      // 獲取實際的問題數量
      final questions = await db.getAllQuestions();
      final qCount = questions.length;
      print('DashboardPage: qCount = $qCount');

      // 獲取實際的解決問題數量
      final solvedQuestions = questions.where((q) => q['solved'] == 1).length;
      final sCount = solvedQuestions;
      print('DashboardPage: sCount = $sCount');

      // 獲取實際的知識條目數量
      final knowledge = await db.getAllKnowledge();
      print(
        '【调试】Knowledge 條目：' + knowledge.map((k) => k.toString()).join('\n'),
      );
      final kCount = knowledge.length;
      print('DashboardPage: kCount = $kCount');

      // 獲取實際的反饋數量
      final feedbacks = await db.getFeedbacks();
      print(
        '【调试】DashboardPage: 反饋數據 = ' +
            feedbacks.map((f) => f.toString()).join('\n'),
      );
      final fCount = feedbacks.length;
      print('DashboardPage: fCount = $fCount');

      // 獲取實際的用戶統計
      final users = await db.getAllUsers();
      final totalUsers = users.length;
      final activeUsers = users.where((u) {
        final lastLogin = DateTime.tryParse(u['last_login'] ?? '');
        return lastLogin != null &&
            DateTime.now().difference(lastLogin).inDays < 30;
      }).length;
      final newUsers = users.where((u) {
        final createdAt = DateTime.tryParse(u['created_at'] ?? '');
        return createdAt != null &&
            DateTime.now().difference(createdAt).inDays < 7;
      }).length;

      print('DashboardPage: activeUsers = $activeUsers');
      print('DashboardPage: newUsers = $newUsers');

      // 計算解決率
      final solvedRateVal = qCount > 0 ? sCount / qCount : 0.0;
      print('DashboardPage: solvedRate = $solvedRateVal');

      // 獲取平均回答時間
      final avgAnswer = await db.getAverageAnswerTime();
      print('DashboardPage: avgAnswer = $avgAnswer');

      // 獲取最後知識庫更新時間
      final lastKnowledge = knowledge.isNotEmpty
          ? knowledge.first['update_time'] ?? ''
          : '';
      print('DashboardPage: lastKnowledge = $lastKnowledge');

      print('DashboardPage: totalUsers = $totalUsers');

      // 獲取實際的反饋統計
      final fbStats = await db.getFeedbackStats();
      print('DashboardPage: feedbacks count = $fCount');

      // 獲取實際的協議分布數據
      final protocols = await db.getProtocolDistribution();
      print('DashboardPage: protocols loaded from database');

      // 獲取實際的用戶列表
      final usersList = await db.getAllUsers();
      print('DashboardPage: users loaded from database');

      // 獲取實際的最近活動記錄
      final activities = await _getRecentActivities();
      print('DashboardPage: activities loaded from database');

      // 獲取實際的問題分類統計數據
      final categories = await _getQuestionCategories();
      print('DashboardPage: categories loaded from database');

      // 獲取實際的知識庫覆蓋度數據
      final coverage = await _getKnowledgeCoverage();
      print('【调试】热力图 coverage = $coverage');
      print('DashboardPage: coverage loaded from database');

      if (mounted) {
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
          userList = usersList;
          recentActivities = activities;
          questionCategories = categories;
          knowledgeCoverage = coverage;

          _loading = false;
          _lastUpdateTime = DateTime.now();
        });
      }
      print('DashboardPage: loadStats end successfully');
    } catch (innerError) {
      print('DashboardPage: Inner error during data loading: $innerError');
      // 如果數據庫查詢失敗，使用空數據而不是模擬數據
      if (mounted) {
        setState(() {
          // 設置空數據
          questionCount = 0;
          solvedCount = 0;
          knowledgeCount = 0;
          feedbackCount = 0;
          activeUserCount = 0;
          newUserCount = 0;
          solvedRate = 0.0;
          avgAnswerTime = 0.0;
          lastKnowledgeUpdate = '';

          // 設置其他空數據
          totalUserCount = 0;
          recentFeedbacks = [];
          protocolDistribution = {};
          feedbackStats = {
            'total_count': 0,
            'average_rating': 0.0,
            'pending_count': 0,
          };
          userList = [];
          recentActivities = [];
          questionCategories = [];
          knowledgeCoverage = {};

          _loading = false;
        });
      }
      print('DashboardPage: loadStats end with empty data');
    } catch (e, stack) {
      print('DashboardPage: loadStats error: $e');
      print(stack);
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // 獲取實際的最近活動記錄
  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    try {
      final db = DatabaseService();
      final activities = <Map<String, dynamic>>[];

      // 獲取最近的問題
      final recentQuestions = await db.getRecentQuestions(
        limit: 10,
      ); // 增加限制以獲取更多數據進行去重

      // 使用 Set 來去重，基於 user_id+content+ask_time
      final seenQuestions = <String>{};
      final uniqueQuestions = <Map<String, dynamic>>[];

      for (var question in recentQuestions) {
        final userId = question['user_id']?.toString() ?? '';
        final content = question['content']?.toString() ?? '';
        final askTime = question['ask_time']?.toString() ?? '';
        final key = '$userId-$content-$askTime';

        if (!seenQuestions.contains(key)) {
          seenQuestions.add(key);
          uniqueQuestions.add(question);
        }
      }

      // 只取前3個去重後的問題
      for (var i = 0; i < uniqueQuestions.length && i < 3; i++) {
        final question = uniqueQuestions[i];
        activities.add({
          'type': 'question',
          'user': question['user_id'] ?? '未知用戶',
          'content': question['content'] ?? '未知问题',
          'time': DateTime.parse(
            question['ask_time'] ?? DateTime.now().toIso8601String(),
          ),
        });
      }

      // 獲取最近的反饋
      final recentFeedbacks = await db.getFeedbacks(
        limit: 5,
      ); // 增加限制以獲取更多數據進行去重

      // 使用 Set 來去重反饋
      final seenFeedbacks = <String>{};
      final uniqueFeedbacks = <Map<String, dynamic>>[];

      for (var feedback in recentFeedbacks) {
        final feedbackId = feedback['feedback_id']?.toString() ?? '';
        final rating = feedback['rating']?.toString() ?? '';
        final comment = feedback['comment']?.toString() ?? '';
        final createdAt = feedback['created_at']?.toString() ?? '';
        final key = '$feedbackId-$rating-$comment-$createdAt';

        if (!seenFeedbacks.contains(key)) {
          seenFeedbacks.add(key);
          uniqueFeedbacks.add(feedback);
        }
      }

      // 只取前2個去重後的反饋
      for (var i = 0; i < uniqueFeedbacks.length && i < 2; i++) {
        final feedback = uniqueFeedbacks[i];
        activities.add({
          'type': 'feedback',
          'user': feedback['user_id'] ?? '未知用戶',
          'content': '给出了${feedback['rating'] ?? 0}星评价',
          'time': DateTime.parse(
            feedback['created_at'] ?? DateTime.now().toIso8601String(),
          ),
        });
      }

      // 按時間排序
      activities.sort((a, b) => b['time'].compareTo(a['time']));
      return activities.take(5).toList(); // 只返回最近5條
    } catch (e) {
      print('获取最近活动记录失败: $e');
      return [];
    }
  }

  // 獲取實際的問題分類統計數據
  Future<List<Map<String, dynamic>>> _getQuestionCategories() async {
    try {
      final db = DatabaseService();
      final questions = await db.getAllQuestions();

      // 統計問題分類（去重）
      final categoryCount = <String, int>{};
      int totalCount = 0;

      // 使用 Set 來去重問題
      final seenQuestions = <String>{};
      final uniqueQuestions = <Map<String, dynamic>>[];

      for (var question in questions) {
        final content = question['content']?.toString() ?? '';
        final askTime = question['ask_time']?.toString() ?? '';
        final key = '$content-$askTime';

        if (!seenQuestions.contains(key)) {
          seenQuestions.add(key);
          uniqueQuestions.add(question);
        }
      }

      for (var question in uniqueQuestions) {
        final content = question['content']?.toString().toUpperCase() ?? '';

        // 檢查協議關鍵詞
        final protocols = [
          'OSPF',
          'BGP',
          'RIP',
          'EIGRP',
          'VLAN',
          'STP',
          'RSTP',
          'MSTP',
          'ACL',
          'NAT',
          'VPN',
          'QoS',
          'MPLS',
          'VRRP',
          'HSRP',
          'GLBP',
          'DHCP',
          'DNS',
          'HTTP',
          'HTTPS',
          'FTP',
          'SMTP',
          'SNMP',
          'SSH',
          'TCP',
          'UDP',
          'ICMP',
          'ARP',
          'RARP',
          'IGMP',
          'PIM',
          'OSPFV3',
          'IPV4',
          'IPV6',
          'RIPNG',
          'BGP4+',
          'IS-IS',
          'LDP',
          'RSVP',
        ];

        String? foundProtocol;
        for (var protocol in protocols) {
          if (content.contains(protocol)) {
            foundProtocol = protocol;
            break;
          }
        }

        final category = foundProtocol ?? '其他';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        totalCount++;
      }

      // 轉換為列表格式
      final categories = <Map<String, dynamic>>[];
      for (var entry in categoryCount.entries) {
        final percentage = totalCount > 0
            ? (entry.value / totalCount * 100).round()
            : 0;
        categories.add({
          'category': entry.key,
          'count': entry.value,
          'percentage': percentage,
        });
      }

      // 按數量排序
      categories.sort((a, b) => b['count'].compareTo(a['count']));
      return categories;
    } catch (e) {
      print('获取问题分类统计失败: $e');
      return [];
    }
  }

  // 獲取實際的知識庫覆蓋度數據
  Future<Map<String, Map<String, int>>> _getKnowledgeCoverage() async {
    try {
      final db = DatabaseService();
      final knowledge = await db.getAllKnowledge();
      print(
        '【调试】_getKnowledgeCoverage 知识库条目：' +
            knowledge.map((k) => k.toString()).join('\n'),
      );

      // 使用 Set 來去重知識條目，基於內容
      final seenKnowledge = <String>{};
      final uniqueKnowledge = <Map<String, dynamic>>[];

      for (var item in knowledge) {
        final content = item['content']?.toString() ?? '';
        if (!seenKnowledge.contains(content)) {
          seenKnowledge.add(content);
          uniqueKnowledge.add(item);
        }
      }

      final coverage = <String, Map<String, int>>{};

      for (var item in uniqueKnowledge) {
        final protocolId = item['protocol_id']?.toString() ?? '';
        final content = item['content']?.toString().toUpperCase() ?? '';

        // 獲取協議名稱
        final protocol = await db.getProtocolById(protocolId);
        final protocolName = protocol?['name']?.toString() ?? '未知协议';

        if (!coverage.containsKey(protocolName)) {
          coverage[protocolName] = {'配置': 0, '故障': 0, '优化': 0, '安全': 0};
        }

        // 根據內容關鍵詞計算覆蓋度
        final configKeywords = ['配置', 'CONFIG', 'SETUP', 'INSTALL'];
        final faultKeywords = ['故障', 'TROUBLESHOOT', 'ERROR', 'PROBLEM'];
        final optimizeKeywords = ['优化', 'OPTIMIZE', 'PERFORMANCE', 'IMPROVE'];
        final securityKeywords = ['安全', 'SECURITY', 'FIREWALL', 'ACL'];

        int configScore = 0,
            faultScore = 0,
            optimizeScore = 0,
            securityScore = 0;

        for (var keyword in configKeywords) {
          if (content.contains(keyword.toUpperCase())) configScore += 20;
        }
        for (var keyword in faultKeywords) {
          if (content.contains(keyword.toUpperCase())) faultScore += 20;
        }
        for (var keyword in optimizeKeywords) {
          if (content.contains(keyword.toUpperCase())) optimizeScore += 20;
        }
        for (var keyword in securityKeywords) {
          if (content.contains(keyword.toUpperCase())) securityScore += 20;
        }

        coverage[protocolName]!['配置'] =
            (coverage[protocolName]!['配置']! + configScore).clamp(0, 100);
        coverage[protocolName]!['故障'] =
            (coverage[protocolName]!['故障']! + faultScore).clamp(0, 100);
        coverage[protocolName]!['优化'] =
            (coverage[protocolName]!['优化']! + optimizeScore).clamp(0, 100);
        coverage[protocolName]!['安全'] =
            (coverage[protocolName]!['安全']! + securityScore).clamp(0, 100);
      }

      return coverage;
    } catch (e) {
      print('获取知识库覆盖度失败: $e');
      return {};
    }
  }

  // 监听ConversationService变化
  void _listenToConversationService() {
    final conversationService = Provider.of<ConversationService>(
      context,
      listen: false,
    );

    // 添加监听器，但只在特定情况下刷新
    conversationService.addListener(() {
      if (mounted) {
        // 只在有新对话或消息时刷新，避免频繁刷新
        if (conversationService.conversations.isNotEmpty) {
          // 延迟刷新，确保数据已保存
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              loadStats();
            }
          });
        }
      }
    });
  }

  // 添加反饋監聽機制
  void _listenToFeedbackChanges() {
    // 定期檢查反饋數據是否有更新
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        // 檢查是否有新的反饋數據
        _checkForNewFeedback();
      } else {
        timer.cancel();
      }
    });
  }

  // 檢查新反饋
  Future<void> _checkForNewFeedback() async {
    try {
      final db = DatabaseService();
      final currentFeedbacks = await db.getFeedbacks();

      // 如果反饋數量有變化，刷新看板
      if (currentFeedbacks.length != recentFeedbacks.length) {
        print('DashboardPage: 检测到新的反馈数据，正在刷新...');
        await loadStats();
      }
    } catch (e) {
      print('检查新反馈时出错: $e');
    }
  }

  // 強制刷新看板（供外部調用）
  static void forceRefresh() {
    if (_currentInstance != null && _currentInstance!.mounted) {
      _currentInstance!.loadStats();
    }
  }

  // 页面焦点变化监听
  void _onPageFocusChanged(bool hasFocus) {
    if (hasFocus && mounted) {
      // 当页面获得焦点时刷新数据
      loadStats();
    }
  }

  // 格式化时间显示
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 最后更新时间显示
            if (_lastUpdateTime != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '最后更新: ${_formatDateTime(_lastUpdateTime!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                            '最近活动',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (recentActivities.isNotEmpty)
                      ...recentActivities.map(
                        (activity) => _buildActivityItem(activity),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            '暂无活动记录',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 管理員專用統計
            if (widget.isAdmin) ...[
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Color(0xFFE60012),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '管理员统计',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAdminStatItem(
                                '活跃用户',
                                activeUserCount.toString(),
                                Icons.people,
                                const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAdminStatItem(
                                '新用户',
                                newUserCount.toString(),
                                Icons.person_add,
                                const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAdminStatItem(
                                '解决率',
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
                                '新用户增长',
                                newUserCount.toString(),
                                Icons.person_add,
                                const Color(0xFF9C27B0),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAdminStatItem(
                                '知识库更新',
                                lastKnowledgeUpdate.isNotEmpty
                                    ? lastKnowledgeUpdate
                                    : '无',
                                Icons.update,
                                const Color(0xFFFF9800),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAdminStatItem(
                                '系统负载',
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
              ),
            ],

            // 評分分布圖表
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFB400)),
                          const SizedBox(width: 8),
                          const Text(
                            '评分分布',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildRatingDistribution(),
                    ],
                  ),
                ),
              ),
            ),

            // 問題分類統計
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

            // 知識庫覆蓋度熱力圖
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
          ],
        ),
      ),
    );
  }

  // 構建管理員統計項目
  Widget _buildAdminStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
      timeText = '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      timeText = '${difference.inHours} 小时前';
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
          SizedBox(
            width: 40,
            child: Text(
              '${(percentage * 100).round()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 構建評分分布
  Widget _buildRatingDistribution() {
    // 計算評分分布
    final ratingCounts = <int, int>{};
    for (var feedback in recentFeedbacks) {
      final rating = feedback['rating'] as int? ?? 0;
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    final totalFeedbacks = recentFeedbacks.length;
    if (totalFeedbacks == 0) {
      return const Center(
        child: Text('暂无评分数据', style: TextStyle(color: Colors.grey)),
      );
    }

    // 計算百分比
    final ratingPercentages = <int, double>{};
    for (int i = 1; i <= 5; i++) {
      final count = ratingCounts[i] ?? 0;
      ratingPercentages[i] = totalFeedbacks > 0 ? count / totalFeedbacks : 0.0;
    }

    return Column(
      children: [
        for (int i = 5; i >= 1; i--)
          _buildRatingBar(i, ratingPercentages[i] ?? 0.0),
      ],
    );
  }

  // 構建問題分類統計視覺化
  Widget _buildQuestionCategoriesChart() {
    if (questionCategories.isEmpty) {
      return const Center(
        child: Text('暂无分类数据', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '问题分类统计',
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
                      '$count 个问题',
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
    if (knowledgeCoverage.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }
    final protocols = knowledgeCoverage.keys.toList();
    final categories = knowledgeCoverage.values.isNotEmpty
        ? knowledgeCoverage.values.first.keys.toList()
        : <String>[];
    if (categories.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '知识库覆盖度热力图',
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
                '用户${index + 1}',
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
            '管理员控制台',
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
                    hintText: '搜索用户...',
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
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('添加用户'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                        label: const Text('批量编辑'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
    DateTime lastActive, {
    bool isAdmin = false,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE60012).withOpacity(0.1),
        child: Text(
          name[0],
          style: const TextStyle(
            color: Color(0xFFE60012),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name),
      subtitle: Text(email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${lastActive.difference(DateTime.now()).inDays.abs()}天前',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 18),
              tooltip: '编辑用户',
              color: const Color(0xFF2196F3),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.delete, size: 18),
              tooltip: '删除用户',
              color: const Color(0xFFE60012),
            ),
          ],
        ],
      ),
    );
  }
}
