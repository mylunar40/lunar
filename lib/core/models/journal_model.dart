import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
//  JOURNAL ENTRY
// ══════════════════════════════════════════════════════════════

class JournalEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final String mood;
  final List<String> tags;
  final bool isFavorite;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.mood = '😊',
    this.tags = const [],
    this.isFavorite = false,
  });

  JournalEntry copyWith({
    String? title,
    String? content,
    String? mood,
    List<String>? tags,
    bool? isFavorite,
  }) =>
      JournalEntry(
        id: id,
        date: date,
        title: title ?? this.title,
        content: content ?? this.content,
        mood: mood ?? this.mood,
        tags: tags ?? this.tags,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'title': title,
        'content': content,
        'mood': mood,
        'tags': tags,
        'isFavorite': isFavorite,
      };

  factory JournalEntry.fromMap(
          Map<String, dynamic> map, String docId) =>
      JournalEntry(
        id: docId,
        date: (map['date'] as Timestamp).toDate(),
        title: (map['title'] as String?) ?? '',
        content: (map['content'] as String?) ?? '',
        mood: (map['mood'] as String?) ?? '😊',
        tags: List<String>.from(map['tags'] ?? []),
        isFavorite: (map['isFavorite'] as bool?) ?? false,
      );
}
