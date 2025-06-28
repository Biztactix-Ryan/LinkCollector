import 'enhanced_metadata_service.dart';
import '../models/enhanced_link_model.dart';

/// Example integration showing how to use the enhanced metadata service
class MetadataIntegrationExample {
  
  /// Enhanced link creation with rich metadata
  static Future<EnhancedLinkModel> createEnhancedLink(String url) async {
    try {
      Map<String, dynamic> metadata;
      
      // Use specialized extractors for specific platforms
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        metadata = await EnhancedMetadataService.extractYouTubeMetadata(url);
      } else if (url.contains('github.com')) {
        metadata = await EnhancedMetadataService.extractGitHubMetadata(url);
      } else {
        metadata = await EnhancedMetadataService.extractMetadata(url);
      }
      
      return EnhancedLinkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        title: metadata['title'] ?? url,
        description: metadata['description'],
        imageUrl: metadata['imageUrl'],
        savedAt: DateTime.now(),
        tags: List<String>.from(metadata['tags'] ?? []),
        siteName: metadata['siteName'],
        author: metadata['author'],
        publishedDate: metadata['publishedDate'],
        type: metadata['type'] ?? 'article',
        favicon: metadata['favicon'],
        wordCount: metadata['wordCount'],
        readingTime: metadata['readingTime'],
        language: metadata['language'],
        additionalData: _extractAdditionalData(metadata),
      );
      
    } catch (e) {
      print('Error creating enhanced link: $e');
      // Fallback to basic link
      return EnhancedLinkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        title: url,
        savedAt: DateTime.now(),
      );
    }
  }
  
  static Map<String, dynamic>? _extractAdditionalData(Map<String, dynamic> metadata) {
    final additionalData = <String, dynamic>{};
    
    // Store platform-specific data
    if (metadata['duration'] != null) {
      additionalData['duration'] = metadata['duration'];
    }
    if (metadata['channel'] != null) {
      additionalData['channel'] = metadata['channel'];
    }
    if (metadata['stars'] != null) {
      additionalData['stars'] = metadata['stars'];
    }
    if (metadata['forks'] != null) {
      additionalData['forks'] = metadata['forks'];
    }
    
    return additionalData.isNotEmpty ? additionalData : null;
  }
}

/// Example usage in your existing code:
/// 
/// ```dart
/// // In your link saving method:
/// final enhancedLink = await MetadataIntegrationExample.createEnhancedLink(url);
/// await storageService.saveEnhancedLink(enhancedLink);
/// ```