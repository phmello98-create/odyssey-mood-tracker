
class Note {
  final String id;
  final String content;
  final DateTime createdAt;
  final String? title;
  final String? category;
  final String? color;
  final bool isPinned;
  final List<String>? tags;

  Note({
    required this.id, 
    required this.content, 
    required this.createdAt,
    this.title,
    this.category = 'note',
    this.color,
    this.isPinned = false,
    this.tags,
  });
}

class Quote {
  final String id;
  final String text;
  final String? author;
  final String? source;
  final DateTime createdAt;
  final bool isFavorite;
  final String? category;

  Quote({
    required this.id,
    required this.text,
    this.author,
    this.source,
    required this.createdAt,
    this.isFavorite = false,
    this.category,
  });
}
