class Question {
  final String questionId;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime askTime;

  Question({
    required this.questionId,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.askTime,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionId: map['question_id'],
      userId: map['user_id'],
      content: map['content'],
      imageUrl: map['image_url'],
      askTime: DateTime.parse(map['ask_time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'ask_time': askTime.toIso8601String(),
    };
  }
}
