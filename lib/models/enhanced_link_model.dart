class EnhancedLinkModel {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime savedAt;
  final bool isRead;
  final List<String> tags;
  
  // Enhanced metadata fields
  final String? siteName;
  final String? author;
  final String? publishedDate;
  final String type; // article, video, repository, etc.
  final String? favicon;
  final int? wordCount;
  final int? readingTime; // in minutes
  final String? language;
  final Map<String, dynamic>? additionalData; // For platform-specific data

  EnhancedLinkModel({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
    required this.savedAt,
    this.isRead = false,
    this.tags = const [],
    this.siteName,
    this.author,
    this.publishedDate,
    this.type = 'article',
    this.favicon,
    this.wordCount,
    this.readingTime,
    this.language,
    this.additionalData,
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
      'siteName': siteName,
      'author': author,
      'publishedDate': publishedDate,
      'type': type,
      'favicon': favicon,
      'wordCount': wordCount,
      'readingTime': readingTime,
      'language': language,
      'additionalData': additionalData,
    };
  }

  factory EnhancedLinkModel.fromJson(Map<String, dynamic> json) {
    return EnhancedLinkModel(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      savedAt: DateTime.parse(json['savedAt']),
      isRead: json['isRead'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      siteName: json['siteName'],
      author: json['author'],
      publishedDate: json['publishedDate'],
      type: json['type'] ?? 'article',
      favicon: json['favicon'],
      wordCount: json['wordCount'],
      readingTime: json['readingTime'],
      language: json['language'],
      additionalData: json['additionalData'] != null 
        ? Map<String, dynamic>.from(json['additionalData'])
        : null,
    );
  }

  // Convert from basic LinkModel for backward compatibility
  factory EnhancedLinkModel.fromLinkModel(dynamic linkModel) {
    if (linkModel is Map<String, dynamic>) {
      return EnhancedLinkModel.fromJson(linkModel);
    }
    
    // Handle the basic LinkModel class
    return EnhancedLinkModel(
      id: linkModel.id,
      url: linkModel.url,
      title: linkModel.title,
      description: linkModel.description,
      imageUrl: linkModel.imageUrl,
      savedAt: linkModel.savedAt,
      isRead: linkModel.isRead,
      tags: linkModel.tags,
    );
  }

  EnhancedLinkModel copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? savedAt,
    bool? isRead,
    List<String>? tags,
    String? siteName,
    String? author,
    String? publishedDate,
    String? type,
    String? favicon,
    int? wordCount,
    int? readingTime,
    String? language,
    Map<String, dynamic>? additionalData,
  }) {
    return EnhancedLinkModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      savedAt: savedAt ?? this.savedAt,
      isRead: isRead ?? this.isRead,
      tags: tags ?? this.tags,
      siteName: siteName ?? this.siteName,
      author: author ?? this.author,
      publishedDate: publishedDate ?? this.publishedDate,
      type: type ?? this.type,
      favicon: favicon ?? this.favicon,
      wordCount: wordCount ?? this.wordCount,
      readingTime: readingTime ?? this.readingTime,
      language: language ?? this.language,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper getters
  bool get isVideo => type == 'video' || url.contains('youtube.com') || url.contains('vimeo.com');
  bool get isRepository => type == 'repository' || url.contains('github.com') || url.contains('gitlab.com');
  bool get isArticle => type == 'article';
  
  String get displayType {
    switch (type) {
      case 'video': return '🎥 Video';
      case 'repository': return '💻 Repository';
      case 'article': return '📄 Article';
      default: return '🔗 Link';
    }
  }

  String? get estimatedReadTime {
    if (readingTime != null && readingTime! > 0) {
      return '${readingTime}m read';
    }
    return null;
  }
}