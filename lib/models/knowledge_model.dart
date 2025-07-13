class Knowledge {
  final String knowledgeId;
  final String protocolId;
  final String content;
  final String? source;
  final DateTime updateTime;

  Knowledge({
    required this.knowledgeId,
    required this.protocolId,
    required this.content,
    this.source,
    required this.updateTime,
  });

  factory Knowledge.fromMap(Map<String, dynamic> map) {
    return Knowledge(
      knowledgeId: map['knowledge_id'],
      protocolId: map['protocol_id'],
      content: map['content'],
      source: map['source'],
      updateTime: DateTime.parse(map['update_time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'knowledge_id': knowledgeId,
      'protocol_id': protocolId,
      'content': content,
      'source': source,
      'update_time': updateTime.toIso8601String(),
    };
  }
}
