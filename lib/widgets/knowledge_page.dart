import 'package:flutter/material.dart';
// import 'aurora_background.dart'; // 不再需要

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  String _selectedCategory = '全部';
  String _selectedProtocol = '全部';
  String _searchQuery = '';

  final List<String> _categories = ['全部', '配置', '故障', '优化', '安全'];
  final List<String> _protocols = [
    '全部',
    'OSPF',
    'BGP',
    'VLAN',
    'STP',
    'ACL',
    'DHCP',
  ];

  final List<Map<String, dynamic>> _knowledgeItems = [
    {
      'title': 'OSPF邻居状态机详解',
      'summary':
          '详细介绍OSPF邻居状态机的各种状态及其转换条件，包括Down、Init、Two-Way、ExStart、Exchange、Loading、Full等状态。',
      'protocol': 'OSPF',
      'category': '配置',
      'updateTime': '2024-01-15',
      'tags': ['邻居状态', '状态机', '路由协议'],
    },
    {
      'title': 'BGP路由通告失败排查指南',
      'summary': '系统性介绍BGP路由通告失败的常见原因和排查步骤，包括AS路径、社区属性、路由过滤等问题。',
      'protocol': 'BGP',
      'category': '故障',
      'updateTime': '2024-01-10',
      'tags': ['路由通告', '故障排查', 'BGP配置'],
    },
    {
      'title': 'VLAN间通信配置最佳实践',
      'summary': '介绍VLAN间通信的配置方法和最佳实践，包括三层交换机配置、路由配置、ACL配置等。',
      'protocol': 'VLAN',
      'category': '配置',
      'updateTime': '2024-01-08',
      'tags': ['VLAN配置', '三层交换', '路由配置'],
    },
    {
      'title': 'STP根桥选举机制详解',
      'summary': '详细解释STP根桥选举的机制和过程，包括桥ID、路径成本、端口角色等概念。',
      'protocol': 'STP',
      'category': '配置',
      'updateTime': '2024-01-05',
      'tags': ['生成树', '根桥选举', '桥ID'],
    },
    {
      'title': 'ACL配置后无法生效的排查步骤',
      'summary': '提供ACL配置后无法生效的系统性排查步骤，包括配置检查、应用位置、规则顺序等。',
      'protocol': 'ACL',
      'category': '故障',
      'updateTime': '2024-01-03',
      'tags': ['访问控制', '故障排查', '配置检查'],
    },
    {
      'title': 'DHCP服务器配置优化指南',
      'summary': '介绍DHCP服务器配置的优化方法，包括地址池配置、租约时间、保留地址等最佳实践。',
      'protocol': 'DHCP',
      'category': '优化',
      'updateTime': '2024-01-01',
      'tags': ['DHCP配置', '地址管理', '服务优化'],
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    return _knowledgeItems.where((item) {
      final matchesCategory =
          _selectedCategory == '全部' || item['category'] == _selectedCategory;
      final matchesProtocol =
          _selectedProtocol == '全部' || item['protocol'] == _selectedProtocol;
      final matchesSearch =
          _searchQuery.isEmpty ||
          item['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['summary'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['tags'].any(
            (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

      return matchesCategory && matchesProtocol && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
          padding: const EdgeInsets.all(24),
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
              // 頂部標題
              Row(
                children: [
                  const Icon(
                    Icons.library_books,
                    color: Color(0xFFE60012),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '知识库',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '共 ${_filteredItems.length} 条知识',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 過濾和搜索區域
              _buildFilterAndSearchSection(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // 知識卡片列表
              Expanded(
                child: _filteredItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Color(0xFFCCCCCC),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '没有找到相关知识',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '请尝试调整搜索条件',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildKnowledgeCard(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 抽出過濾和搜索區塊為一個獨立的方法，方便管理
  Widget _buildFilterAndSearchSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 搜索框
        Expanded(
          flex: 2,
          child: TextField(
            decoration: const InputDecoration(
              hintText: '搜索知识库...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(width: 24),
        // 過濾選項
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 分類過濾
              Row(
                children: [
                  const Text(
                    '分类：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories
                            .map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: _selectedCategory == category,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFFE60012,
                                  ).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFFE60012),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 協議過濾
              Row(
                children: [
                  const Text(
                    '协议：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _protocols
                            .map(
                              (protocol) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(protocol),
                                  selected: _selectedProtocol == protocol,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedProtocol = protocol;
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFFE60012,
                                  ).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFFE60012),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKnowledgeCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          // TODO: 实现知识详情页面
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getProtocolColor(
                        item['protocol'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['protocol'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getProtocolColor(item['protocol']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['summary'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // 标签
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: item['tags'].map<Widget>((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        item['category'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['category'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getCategoryColor(item['category']),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '更新时间：${item['updateTime']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProtocolColor(String protocol) {
    switch (protocol) {
      case 'OSPF':
        return const Color(0xFFE60012);
      case 'BGP':
        return const Color(0xFF4CAF50);
      case 'VLAN':
        return const Color(0xFF2196F3);
      case 'STP':
        return const Color(0xFFFF9800);
      case 'ACL':
        return const Color(0xFF9C27B0);
      case 'DHCP':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF666666);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '配置':
        return const Color(0xFF4CAF50);
      case '故障':
        return const Color(0xFFE60012);
      case '优化':
        return const Color(0xFF2196F3);
      case '安全':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF666666);
    }
  }
}
