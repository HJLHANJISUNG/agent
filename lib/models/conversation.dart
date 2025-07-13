import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String? solutionId; // 新增：用於關聯後端解決方案
  final String role; // 'user' 或 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    this.solutionId, // 新增到建構函式
    DateTime? timestamp,
  }) : id = const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();
}

class Conversation {
  final String id;
  String title;
  final List<Message> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  Conversation({
    required this.title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = const Uuid().v4(),
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  Conversation copyWith({String? title, DateTime? updatedAt}) {
    return Conversation(
      title: title ?? this.title,
      messages: messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
