class Feedback {
  final String feedbackId;
  final String userId;
  final String solutionId;
  final int rating;
  final String? comment;

  Feedback({
    required this.feedbackId,
    required this.userId,
    required this.solutionId,
    required this.rating,
    this.comment,
  });

  factory Feedback.fromMap(Map<String, dynamic> map) {
    return Feedback(
      feedbackId: map['feedback_id'],
      userId: map['user_id'],
      solutionId: map['solution_id'],
      rating: map['rating'],
      comment: map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feedback_id': feedbackId,
      'user_id': userId,
      'solution_id': solutionId,
      'rating': rating,
      'comment': comment,
    };
  }
}
