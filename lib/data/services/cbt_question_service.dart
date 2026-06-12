import 'package:uuid/uuid.dart';

import '../models/cbt_models.dart';

class CBTQuestionService {
  static final _uuid = const Uuid();

  // Later: fetch from backend by (schoolId, deptId, level, courseCode)
  static List<CBTQuestionModel> loadQuestions({
    required String courseCode,
    String? topic,
  }) {
    final all = <CBTQuestionModel>[
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: courseCode,
        topic: "Objective / MCQ",
        question:
            "In a binary search tree, the left subtree contains values that are:",
        options: [
          "Greater than root",
          "Less than root",
          "Equal to root only",
          "Random order",
        ],
        correctIndex: 1,
        explanation: "BST property: left < root < right.",
        sourceLabel: "$courseCode Past Qs 2019",
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: courseCode,
        topic: "Objective / MCQ",
        question:
            "Which sorting algorithm is generally O(n log n) average-case?",
        options: [
          "Bubble sort",
          "Insertion sort",
          "Quick sort",
          "Selection sort",
        ],
        correctIndex: 2,
        explanation: "Quick sort average is O(n log n), worst is O(n²).",
        sourceLabel: "$courseCode Past Qs 2020",
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: courseCode,
        topic: "Objective / MCQ",
        question: "BFS uses which data structure?",
        options: ["Stack", "Queue", "Tree", "Heap"],
        correctIndex: 1,
        explanation: "BFS explores level-by-level using a queue.",
        sourceLabel: "$courseCode Past Qs 2021",
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: courseCode,
        topic: "Multiple Choice",
        question: "Which option best describes encapsulation in programming?",
        options: [
          "Hiding implementation details behind a public interface",
          "Sorting data in descending order",
          "Running two programs at the same time",
          "Copying code into many files",
        ],
        correctIndex: 0,
        explanation:
            "Encapsulation groups data and behavior while exposing a controlled interface.",
        sourceLabel: "$courseCode Sample MCQ",
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: courseCode,
        topic: "True / False",
        question: "A queue normally follows First-In, First-Out behavior.",
        options: ["True", "False"],
        correctIndex: 0,
        explanation: "Queues remove the earliest inserted item first.",
        sourceLabel: "$courseCode Sample True/False",
      ),
      CBTQuestionModel(
        id: _uuid.v4(),
        courseCode: courseCode,
        topic: "Scenario",
        question:
            "A student app must keep working when internet is weak. Which feature helps most?",
        options: [
          "Offline cache and later sync",
          "Bigger buttons only",
          "Longer animations",
          "Removing all feedback",
        ],
        correctIndex: 0,
        explanation:
            "Offline cache with sync preserves learning progress during poor connectivity.",
        sourceLabel: "$courseCode Applied Sample",
      ),
    ];

    if (topic == null || topic == "Mixed") return all;
    return all.where((q) => q.topic == topic).toList();
  }

  static List<String> topicsForCourse(String courseCode) {
    return [
      "Mixed",
      "Objective / MCQ",
      "Multiple Choice",
      "True / False",
      "Scenario",
    ];
  }
}
