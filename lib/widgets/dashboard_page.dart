import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 32.0),
              child: TabBar(
                tabs: [
                  Tab(text: '总览'),
                  Tab(text: '用户'),
                  Tab(text: '数据'),
                  Tab(text: '反馈'),
                ],
                indicatorColor: Color(0xFFFF4B2B),
                labelColor: Color(0xFFFF4B2B),
                unselectedLabelColor: Colors.grey,
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(32),
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
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(24),
                      children: [DashboardOverviewTab()],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(24),
                      children: [DashboardUserTab()],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(24),
                      children: [DashboardDataTab()],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(24),
                      children: [DashboardFeedbackTab()],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  // 模拟柱状图数据
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
  // 模拟热力图数据
  final protocols = ['OSPF', 'BGP', 'VLAN', 'STP', 'ACL', 'DHCP'];
  final categories = ['配置', '故障', '优化', '安全'];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 标题行
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
      // 热力图格子
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

Widget buildFeedbackList() {
  final feedbacks = [
    {
      'user': '张工程师',
      'rating': 5,
      'content': '回答非常准确，解决了我的OSPF邻居问题，感谢！',
      'time': '2024-01-15',
    },
    {
      'user': '李网络',
      'rating': 4,
      'content': '知识库内容丰富，但希望能增加更多BGP相关的实例。',
      'time': '2024-01-14',
    },
    {
      'user': '王技术',
      'rating': 5,
      'content': '界面友好，搜索功能强大，推荐给同事使用。',
      'time': '2024-01-13',
    },
  ];

  return ListView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: feedbacks.length,
    itemBuilder: (context, index) {
      final feedback = feedbacks[index];
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
                  feedback['user'] as String,
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
                  feedback['time'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              feedback['content'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    },
  );
}

int getCoverage(String protocol, String category) {
  // 模拟覆盖度数据
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

class DashboardOverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Flexible(
                child: buildStatCard(
                  '总问题数',
                  '1,234',
                  Icons.question_answer,
                  const Color(0xFFE60012),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: buildStatCard(
                  '已解决',
                  '1,089',
                  Icons.check_circle,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: buildStatCard(
                  '知识条目',
                  '567',
                  Icons.library_books,
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: buildStatCard(
                  '用户反馈',
                  '89',
                  Icons.feedback,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ),
        // 如果還有其他內容，繼續添加在這裡
      ],
    );
  }
}

class DashboardUserTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 將你的用戶相關內容放在這個 Column 中
    // 如果內容會超出螢幕，ListView/SingleChildScrollView 會確保它可以滾動
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 範例：用戶統計卡片
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

        // 範例：用戶列表標題
        const Text(
          '用户列表',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 範例：用戶列表 (如果列表很長，它會在這個區域內滾動)
        // 注意：這裡只是一個 placeholder，你需要用真實的用戶列表代替
        Container(
          height: 300, // 給列表一個固定的高度
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('将你的用户列表放在这里')),
        ),
      ],
    );
  }
}

class DashboardDataTab extends StatefulWidget {
  const DashboardDataTab({super.key});
  @override
  _DashboardDataTabState createState() => _DashboardDataTabState();
}

class _DashboardDataTabState extends State<DashboardDataTab> {
  int touchedIndex = -1;
  @override
  Widget build(BuildContext context) {
    // 將你的數據相關內容放在這個 Column 中
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '技术主题分布',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // 範例：數據圖表
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildNewPieChart(), // 使用新的餅圖
        ),
        const SizedBox(height: 24),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: buildBarChart(), // 使用你已經有的長條圖
        ),
      ],
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

class DashboardFeedbackTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
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
            buildFeedbackList(),
          ],
        ),
      ),
    );
  }
}
