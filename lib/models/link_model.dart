class LinkModel {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime savedAt;
  final bool isRead;
  final List<String> tags;

  LinkModel({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
    required this.savedAt,
    this.isRead = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'savedAt': savedAt.toIso8601String(),
      'isRead': isRead,
      'tags': tags,
    };
  }

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      savedAt: DateTime.parse(json['savedAt']),
      isRead: json['isRead'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  LinkModel copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? savedAt,
    bool? isRead,
    List<String>? tags,
  }) {
    return LinkModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      savedAt: savedAt ?? this.savedAt,
      isRead: isRead ?? this.isRead,
      tags: tags ?? this.tags,
    );
  }
}