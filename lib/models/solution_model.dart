class Solution {
  final String solutionId;
  final String questionId;
  final String steps;
  final double confidenceScore;

  Solution({
    required this.solutionId,
    required this.questionId,
    required this.steps,
    required this.confidenceScore,
  });

  factory Solution.fromMap(Map<String, dynamic> map) {
    return Solution(
      solutionId: map['solution_id'],
      questionId: map['question_id'],
      steps: map['steps'],
      confidenceScore: map['confidence_score'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'solution_id': solutionId,
      'question_id': questionId,
      'steps': steps,
      'confidence_score': confidenceScore,
    };
  }
}
