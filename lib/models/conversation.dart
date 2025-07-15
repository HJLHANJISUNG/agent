import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String? solutionId; // 新增：用於關聯後端解決方案
  final String role; // 'user' 或 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    String? id,
    required this.role,
    required this.content,
    this.solutionId, // 新增到建構函式
    DateTime? timestamp,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  // 轉換為數據庫可用的Map
  Map<String, dynamic> toMap({required String conversationId}) {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'solution_id': solutionId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // 從Map創建Message對象
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      role: map['role'],
      content: map['content'],
      solutionId: map['solution_id'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  // 創建Message副本
  Message copyWith({
    String? id,
    String? role,
    String? content,
    String? solutionId,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      solutionId: solutionId ?? this.solutionId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class Conversation {
  final String id;
  String title;
  final List<Message> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  String? userId; // 添加用戶ID關聯

  Conversation({
    String? id,
    required this.title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userId,
  }) : id = id ?? const Uuid().v4(),
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // 轉換為數據庫可用的Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 獲取消息的Map列表
  List<Map<String, dynamic>> messagesToMapList() {
    return messages
        .map((message) => message.toMap(conversationId: id))
        .toList();
  }

  // 從Map創建Conversation對象
  factory Conversation.fromMap(
    Map<String, dynamic> map,
    List<Map<String, dynamic>> messagesMaps,
  ) {
    final List<Message> messages = messagesMaps
        .map((messageMap) => Message.fromMap(messageMap))
        .toList();

    return Conversation(
      id: map['id'],
      title: map['title'],
      messages: messages,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      userId: map['user_id'],
    );
  }

  Conversation copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}
