class CitationModel {
  CitationModel({
    required this.title,
    required this.pageLabel,
    required this.snippet,
  });

  final String title; // e.g. Lecture 5
  final String pageLabel; // e.g. p.12
  final String snippet; // short quote/snippet
}

class ChatMessageModel {
  ChatMessageModel({
    required this.id,
    required this.role, // "user" | "ai"
    required this.text,
    this.citations = const [],
    this.createdAt,
  });

  final String id;
  final String role;
  final String text;
  final List<CitationModel> citations;
  final DateTime? createdAt;

  bool get isAi => role == "ai";
}
