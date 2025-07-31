import 'dart:convert';

class CategoryService {
  // 協議分類關鍵詞配置
  static const Map<String, List<String>> protocolCategories = {
    'OSPF': [
      'OSPF',
      'OPEN SHORTEST PATH FIRST',
      '区域',
      'LSA',
      'DR',
      'BDR',
      'OSPF AREA',
      'LINK STATE',
      'COST',
      'METRIC',
      'ROUTER ID',
    ],
    'BGP': [
      'BGP',
      'BORDER GATEWAY PROTOCOL',
      'AS',
      '自治系统',
      '路由通告',
      'BGP NEIGHBOR',
      'PEER',
      'ROUTE REFLECTOR',
      'COMMUNITY',
    ],
    'RIP': [
      'RIP',
      'ROUTING INFORMATION PROTOCOL',
      '跳数',
      'HOP COUNT',
      'RIP VERSION',
      'RIPNG',
    ],
    'EIGRP': [
      'EIGRP',
      'ENHANCED INTERIOR GATEWAY ROUTING PROTOCOL',
      'FEASIBLE SUCCESSOR',
      'SUCCESSOR',
      'FD',
      'AD',
    ],
    'VLAN': [
      'VLAN',
      '虚拟局域网',
      'TRUNK',
      'ACCESS',
      'VTP',
      'VLAN TRUNKING',
      'NATIVE VLAN',
      'VLAN ID',
    ],
    'STP': [
      'STP',
      'SPANNING TREE PROTOCOL',
      '生成树',
      '阻塞',
      '监听',
      'BLOCKING',
      'LISTENING',
      'LEARNING',
      'FORWARDING',
    ],
    'RSTP': [
      'RSTP',
      'RAPID SPANNING TREE PROTOCOL',
      '快速生成树',
      'RAPID STP',
      'PORT ROLES',
    ],
    'MSTP': [
      'MSTP',
      'MULTIPLE SPANNING TREE PROTOCOL',
      '多生成树',
      'MST INSTANCE',
      'MST REGION',
    ],
    'ACL': [
      'ACL',
      'ACCESS CONTROL LIST',
      '访问控制列表',
      '防火墙',
      'STANDARD ACL',
      'EXTENDED ACL',
      'WILDCARD',
    ],
    'NAT': [
      'NAT',
      'NETWORK ADDRESS TRANSLATION',
      '地址转换',
      'STATIC NAT',
      'DYNAMIC NAT',
      'PAT',
      'OVERLOAD',
    ],
    'VPN': [
      'VPN',
      'VIRTUAL PRIVATE NETWORK',
      '虚拟专用网',
      'IPSEC',
      'GRE',
      'L2TP',
      'PPTP',
    ],
    'QoS': [
      'QOS',
      'QUALITY OF SERVICE',
      '服务质量',
      '优先级',
      'BANDWIDTH',
      'QUEUING',
      'TRAFFIC SHAPING',
    ],
    'MPLS': [
      'MPLS',
      'MULTIPROTOCOL LABEL SWITCHING',
      '标签交换',
      'LSP',
      'LABEL',
      'MPLS VPN',
    ],
    'VRRP': [
      'VRRP',
      'VIRTUAL ROUTER REDUNDANCY PROTOCOL',
      'VIRTUAL ROUTER',
      'MASTER',
      'BACKUP',
    ],
    'HSRP': [
      'HSRP',
      'HOT STANDBY ROUTER PROTOCOL',
      'ACTIVE',
      'STANDBY',
      'VIRTUAL IP',
    ],
    'GLBP': [
      'GLBP',
      'GATEWAY LOAD BALANCING PROTOCOL',
      'LOAD BALANCING',
      'AVG',
      'AVF',
    ],
    'DHCP': [
      'DHCP',
      'DYNAMIC HOST CONFIGURATION PROTOCOL',
      '动态主机配置',
      'DHCP SERVER',
      'DHCP RELAY',
      'IP ADDRESS POOL',
    ],
    'DNS': [
      'DNS',
      'DOMAIN NAME SYSTEM',
      '域名系统',
      '解析',
      'DNS SERVER',
      'DOMAIN NAME',
      'RESOLUTION',
    ],
    'HTTP': [
      'HTTP',
      'HYPER TEXT TRANSFER PROTOCOL',
      'WEB SERVER',
      'HTTP REQUEST',
      'HTTP RESPONSE',
    ],
    'HTTPS': ['HTTPS', 'HTTP SECURE', '安全超文本传输', 'SSL', 'TLS', 'CERTIFICATE'],
    'FTP': [
      'FTP',
      'FILE TRANSFER PROTOCOL',
      '文件传输',
      'FTP SERVER',
      'FTP CLIENT',
      'PASSIVE MODE',
    ],
    'SMTP': [
      'SMTP',
      'SIMPLE MAIL TRANSFER PROTOCOL',
      '邮件传输',
      'EMAIL SERVER',
      'MAIL SERVER',
    ],
    'SNMP': [
      'SNMP',
      'SIMPLE NETWORK MANAGEMENT PROTOCOL',
      '网络管理',
      'SNMP AGENT',
      'SNMP MANAGER',
      'MIB',
      'OID',
    ],
    'SSH': [
      'SSH',
      'SECURE SHELL',
      '安全壳',
      'SSH CLIENT',
      'SSH SERVER',
      'KEY AUTHENTICATION',
    ],
    'TCP': [
      'TCP',
      'TRANSMISSION CONTROL PROTOCOL',
      '传输控制协议',
      'TCP CONNECTION',
      'TCP WINDOW',
      'TCP FLAGS',
    ],
    'UDP': [
      'UDP',
      'USER DATAGRAM PROTOCOL',
      '用户数据报协议',
      'UDP PACKET',
      'UDP PORT',
    ],
    'ICMP': [
      'ICMP',
      'INTERNET CONTROL MESSAGE PROTOCOL',
      '互联网控制消息',
      'PING',
      'ECHO REQUEST',
      'ECHO REPLY',
    ],
    'ARP': [
      'ARP',
      'ADDRESS RESOLUTION PROTOCOL',
      '地址解析协议',
      'MAC ADDRESS',
      'ARP TABLE',
      'ARP CACHE',
    ],
    'RARP': ['RARP', 'REVERSE ADDRESS RESOLUTION PROTOCOL', 'REVERSE ARP'],
    'IGMP': [
      'IGMP',
      'INTERNET GROUP MANAGEMENT PROTOCOL',
      'MULTICAST',
      'IGMP SNOOPING',
    ],
    'PIM': [
      'PIM',
      'PROTOCOL INDEPENDENT MULTICAST',
      'PIM DENSE',
      'PIM SPARSE',
      'MULTICAST ROUTING',
    ],
    'OSPFV3': [
      'OSPFV3',
      'OSPF VERSION 3',
      'OSPF版本3',
      'OSPFV3 AREA',
      'IPV6 OSPF',
    ],
    'IPV4': [
      'IPV4',
      'INTERNET PROTOCOL VERSION 4',
      '互联网协议版本4',
      'IPV4 ADDRESS',
      'SUBNET',
      'SUBNET MASK',
    ],
    'IPV6': [
      'IPV6',
      'INTERNET PROTOCOL VERSION 6',
      '互联网协议版本6',
      'IPV6 ADDRESS',
      'IPV6 PREFIX',
      'DUAL STACK',
    ],
    'RIPNG': ['RIPNG', 'RIP NEXT GENERATION', 'RIP下一代', 'RIP FOR IPV6'],
    'BGP4+': ['BGP4+', 'BGP4 PLUS', 'BGP4增强版', 'BGP4+ FOR IPV6'],
    'IS-IS': [
      'IS-IS',
      'INTERMEDIATE SYSTEM TO INTERMEDIATE SYSTEM',
      'ISIS',
      'LINK STATE PROTOCOL',
    ],
    'LDP': [
      'LDP',
      'LABEL DISTRIBUTION PROTOCOL',
      '标签分发',
      'MPLS LDP',
      'LABEL SWITCHING',
    ],
    'RSVP': [
      'RSVP',
      'RESOURCE RESERVATION PROTOCOL',
      '资源预留',
      'RSVP TE',
      'TRAFFIC ENGINEERING',
    ],
  };

  /// 根據問題內容智能分類
  static String categorizeQuestion(String content) {
    if (content.isEmpty) return '其他';

    final upperContent = content.toUpperCase();

    // 特殊處理：HTTPS 應該優先於 HTTP 匹配
    if (upperContent.contains('HTTPS') ||
        upperContent.contains('HTTP SECURE') ||
        upperContent.contains('SSL') ||
        upperContent.contains('TLS') ||
        upperContent.contains('CERTIFICATE')) {
      return 'HTTPS';
    }

    // 檢查每個協議類別
    for (var entry in protocolCategories.entries) {
      final category = entry.key;
      final keywords = entry.value;

      // 跳過 HTTP，因為我們已經處理了 HTTPS
      if (category == 'HTTP') continue;

      // 檢查是否包含該類別的任何關鍵詞
      for (var keyword in keywords) {
        if (upperContent.contains(keyword.toUpperCase())) {
          return category;
        }
      }
    }

    // 最後檢查 HTTP（在 HTTPS 之後）
    if (upperContent.contains('HTTP') ||
        upperContent.contains('HYPER TEXT TRANSFER PROTOCOL') ||
        upperContent.contains('WEB SERVER') ||
        upperContent.contains('HTTP REQUEST') ||
        upperContent.contains('HTTP RESPONSE')) {
      return 'HTTP';
    }

    // 如果沒有找到匹配的類別，歸入"其他"
    return '其他';
  }

  /// 獲取所有可用的分類
  static List<String> getAvailableCategories() {
    return protocolCategories.keys.toList()..add('其他');
  }

  /// 獲取分類的顯示名稱
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'OSPF':
        return 'OSPF路由协议';
      case 'BGP':
        return 'BGP边界网关协议';
      case 'RIP':
        return 'RIP路由信息协议';
      case 'EIGRP':
        return 'EIGRP增强内部网关路由协议';
      case 'VLAN':
        return 'VLAN虚拟局域网';
      case 'STP':
        return 'STP生成树协议';
      case 'RSTP':
        return 'RSTP快速生成树协议';
      case 'MSTP':
        return 'MSTP多生成树协议';
      case 'ACL':
        return 'ACL访问控制列表';
      case 'NAT':
        return 'NAT网络地址转换';
      case 'VPN':
        return 'VPN虚拟专用网';
      case 'QoS':
        return 'QoS服务质量';
      case 'MPLS':
        return 'MPLS多协议标签交换';
      case 'VRRP':
        return 'VRRP虚拟路由器冗余协议';
      case 'HSRP':
        return 'HSRP热备份路由器协议';
      case 'GLBP':
        return 'GLBP网关负载均衡协议';
      case 'DHCP':
        return 'DHCP动态主机配置协议';
      case 'DNS':
        return 'DNS域名系统';
      case 'HTTP':
        return 'HTTP超文本传输协议';
      case 'HTTPS':
        return 'HTTPS安全超文本传输协议';
      case 'FTP':
        return 'FTP文件传输协议';
      case 'SMTP':
        return 'SMTP简单邮件传输协议';
      case 'SNMP':
        return 'SNMP简单网络管理协议';
      case 'SSH':
        return 'SSH安全壳协议';
      case 'TCP':
        return 'TCP传输控制协议';
      case 'UDP':
        return 'UDP用户数据报协议';
      case 'ICMP':
        return 'ICMP互联网控制消息协议';
      case 'ARP':
        return 'ARP地址解析协议';
      case 'RARP':
        return 'RARP反向地址解析协议';
      case 'IGMP':
        return 'IGMP互联网组管理协议';
      case 'PIM':
        return 'PIM协议无关组播';
      case 'OSPFV3':
        return 'OSPFv3 IPv6路由协议';
      case 'IPV4':
        return 'IPv4互联网协议版本4';
      case 'IPV6':
        return 'IPv6互联网协议版本6';
      case 'RIPNG':
        return 'RIPng IPv6路由协议';
      case 'BGP4+':
        return 'BGP4+增强版边界网关协议';
      case 'IS-IS':
        return 'IS-IS中间系统到中间系统协议';
      case 'LDP':
        return 'LDP标签分发协议';
      case 'RSVP':
        return 'RSVP资源预留协议';
      case '其他':
        return '其他问题';
      default:
        return category;
    }
  }

  /// 獲取分類的顏色
  static int getCategoryColor(String category) {
    // 為不同分類分配不同的顏色
    final colors = {
      'OSPF': 0xFF2196F3, // 藍色
      'BGP': 0xFF4CAF50, // 綠色
      'RIP': 0xFFFF9800, // 橙色
      'EIGRP': 0xFF9C27B0, // 紫色
      'VLAN': 0xFF607D8B, // 藍灰色
      'STP': 0xFF795548, // 棕色
      'RSTP': 0xFF795548, // 棕色
      'MSTP': 0xFF795548, // 棕色
      'ACL': 0xFFF44336, // 紅色
      'NAT': 0xFFE91E63, // 粉紅色
      'VPN': 0xFF3F51B5, // 靛藍色
      'QoS': 0xFF00BCD4, // 青色
      'MPLS': 0xFF8BC34A, // 淺綠色
      'VRRP': 0xFFFFEB3B, // 黃色
      'HSRP': 0xFFFFEB3B, // 黃色
      'GLBP': 0xFFFFEB3B, // 黃色
      'DHCP': 0xFF009688, // 青綠色
      'DNS': 0xFF673AB7, // 深紫色
      'HTTP': 0xFF3F51B5, // 靛藍色
      'HTTPS': 0xFF4CAF50, // 綠色
      'FTP': 0xFFFF5722, // 深橙色
      'SMTP': 0xFF9E9E9E, // 灰色
      'SNMP': 0xFF607D8B, // 藍灰色
      'SSH': 0xFF000000, // 黑色
      'TCP': 0xFF2196F3, // 藍色
      'UDP': 0xFFFF9800, // 橙色
      'ICMP': 0xFFE91E63, // 粉紅色
      'ARP': 0xFF795548, // 棕色
      'RARP': 0xFF795548, // 棕色
      'IGMP': 0xFF9C27B0, // 紫色
      'PIM': 0xFF9C27B0, // 紫色
      'OSPFV3': 0xFF2196F3, // 藍色
      'IPV4': 0xFF2196F3, // 藍色
      'IPV6': 0xFF2196F3, // 藍色
      'RIPNG': 0xFFFF9800, // 橙色
      'BGP4+': 0xFF4CAF50, // 綠色
      'IS-IS': 0xFF9C27B0, // 紫色
      'LDP': 0xFF8BC34A, // 淺綠色
      'RSVP': 0xFF00BCD4, // 青色
      '其他': 0xFF9E9E9E, // 灰色
    };

    return colors[category] ?? 0xFF9E9E9E; // 默認灰色
  }
}
