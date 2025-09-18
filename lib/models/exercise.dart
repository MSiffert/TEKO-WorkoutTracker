class Exercise {
  final String id;
  final String name;
  final String category; // Push, Pull, Legs, Full, Other
  final List<String> tags;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'tags': tags,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'Other',
        tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      );
}