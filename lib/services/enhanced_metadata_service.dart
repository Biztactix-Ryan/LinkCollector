import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

class EnhancedMetadataService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36',
    },
  ));

  /// Enhanced metadata extraction with multiple fallback strategies
  static Future<Map<String, dynamic>> extractMetadata(String url) async {
    try {
      // Strategy 1: Use metadata_fetch for specialized extraction
      final metadata = await _extractWithMetadataFetch(url);
      if (metadata['title'] != null && metadata['title'] != url) {
        return metadata;
      }

      // Strategy 2: Custom extraction with Dio + Beautiful Soup
      final customMetadata = await _extractWithCustomParser(url);
      return _mergeMetadata(metadata, customMetadata);
      
    } catch (e) {
      print('EnhancedMetadataService: Error extracting metadata: $e');
      return _createFallbackMetadata(url);
    }
  }

  /// Use metadata_fetch library for Open Graph, Twitter Cards, etc.
  static Future<Map<String, dynamic>> _extractWithMetadataFetch(String url) async {
    try {
      final data = await MetadataFetch.extract(url);
      
      return {
        'title': data?.title?.trim(),
        'description': data?.description?.trim(),
        'imageUrl': data?.image,
        'siteName': data?.siteName?.trim(),
        'url': data?.url ?? url,
        'author': null, // metadata_fetch doesn't extract author
        'publishedDate': null,
        'tags': <String>[],
        'type': 'article',
      };
    } catch (e) {
      print('MetadataFetch failed: $e');
      return {};
    }
  }

  /// Custom extraction using Dio + Beautiful Soup for more detailed scraping
  static Future<Map<String, dynamic>> _extractWithCustomParser(String url) async {
    try {
      final response = await _dio.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final document = html_parser.parse(response.data);
      final soup = BeautifulSoup(response.data);

      return {
        'title': _extractTitle(document, soup),
        'description': _extractDescription(document, soup),
        'imageUrl': _extractImage(document, soup, url),
        'siteName': _extractSiteName(document, soup),
        'author': _extractAuthor(document, soup),
        'publishedDate': _extractPublishedDate(document, soup),
        'tags': _extractTags(document, soup),
        'type': _extractContentType(document, soup),
        'favicon': _extractFavicon(document, soup, url),
        'wordCount': _extractWordCount(document),
        'readingTime': null, // Will be calculated from word count
        'language': _extractLanguage(document),
      };
    } catch (e) {
      print('Custom parser failed: $e');
      return {};
    }
  }

  static String? _extractTitle(Document document, BeautifulSoup soup) {
    // Priority order: og:title -> twitter:title -> title tag -> h1
    return _getMetaContent(document, 'og:title') ??
           _getMetaContent(document, 'twitter:title') ??
           document.querySelector('title')?.text?.trim() ??
           document.querySelector('h1')?.text?.trim();
  }

  static String? _extractDescription(Document document, BeautifulSoup soup) {
    // Priority: og:description -> twitter:description -> meta description
    return _getMetaContent(document, 'og:description') ??
           _getMetaContent(document, 'twitter:description') ??
           _getMetaContent(document, 'description') ??
           document.querySelector('meta[name="description"]')?.attributes['content']?.trim();
  }

  static String? _extractImage(Document document, BeautifulSoup soup, String baseUrl) {
    final image = _getMetaContent(document, 'og:image') ??
                  _getMetaContent(document, 'twitter:image') ??
                  document.querySelector('img')?.attributes['src'];
    
    if (image != null && !image.startsWith('http')) {
      // Convert relative URLs to absolute
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}$image';
    }
    return image;
  }

  static String? _extractSiteName(Document document, BeautifulSoup soup) {
    return _getMetaContent(document, 'og:site_name') ??
           _getMetaContent(document, 'application-name') ??
           document.querySelector('meta[name="application-name"]')?.attributes['content'];
  }

  static String? _extractAuthor(Document document, BeautifulSoup soup) {
    return _getMetaContent(document, 'author') ??
           _getMetaContent(document, 'article:author') ??
           document.querySelector('meta[name="author"]')?.attributes['content']?.trim() ??
           document.querySelector('[rel="author"]')?.text?.trim() ??
           document.querySelector('.author')?.text?.trim();
  }

  static String? _extractPublishedDate(Document document, BeautifulSoup soup) {
    return _getMetaContent(document, 'article:published_time') ??
           _getMetaContent(document, 'article:modified_time') ??
           _getMetaContent(document, 'pubdate') ??
           document.querySelector('time')?.attributes['datetime'];
  }

  static List<String> _extractTags(Document document, BeautifulSoup soup) {
    final tags = <String>[];
    
    // Extract from meta keywords
    final keywords = _getMetaContent(document, 'keywords');
    if (keywords != null) {
      tags.addAll(keywords.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty));
    }
    
    // Extract from article tags
    final articleTags = document.querySelectorAll('meta[property="article:tag"]');
    for (final tag in articleTags) {
      final content = tag.attributes['content']?.trim();
      if (content != null && content.isNotEmpty) {
        tags.add(content);
      }
    }
    
    // Extract from common tag classes
    final tagElements = document.querySelectorAll('.tag, .tags, .category, .categories');
    for (final element in tagElements) {
      final text = element.text?.trim();
      if (text != null && text.isNotEmpty) {
        tags.add(text);
      }
    }
    
    return tags.take(10).toList(); // Limit to 10 tags
  }

  static String _extractContentType(Document document, BeautifulSoup soup) {
    return _getMetaContent(document, 'og:type') ?? 'article';
  }

  static String? _extractFavicon(Document document, BeautifulSoup soup, String baseUrl) {
    final favicon = document.querySelector('link[rel="icon"]')?.attributes['href'] ??
                   document.querySelector('link[rel="shortcut icon"]')?.attributes['href'] ??
                   document.querySelector('link[rel="apple-touch-icon"]')?.attributes['href'];
    
    if (favicon != null && !favicon.startsWith('http')) {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}$favicon';
    }
    return favicon;
  }

  static int _extractWordCount(Document document) {
    // Remove script and style content
    document.querySelectorAll('script, style').forEach((element) => element.remove());
    
    final text = document.body?.text ?? '';
    final words = text.split(RegExp(r'\s+'));
    return words.where((word) => word.isNotEmpty).length;
  }

  static String? _extractLanguage(Document document) {
    return document.documentElement?.attributes['lang'] ??
           _getMetaContent(document, 'language');
  }

  static String? _getMetaContent(Document document, String property) {
    return document.querySelector('meta[property="$property"]')?.attributes['content'] ??
           document.querySelector('meta[name="$property"]')?.attributes['content'];
  }

  static Map<String, dynamic> _mergeMetadata(Map<String, dynamic> primary, Map<String, dynamic> secondary) {
    final merged = Map<String, dynamic>.from(secondary);
    
    for (final entry in primary.entries) {
      if (entry.value != null && (entry.value is! String || (entry.value as String).isNotEmpty)) {
        merged[entry.key] = entry.value;
      }
    }
    
    // Calculate reading time from word count
    if (merged['wordCount'] != null) {
      final wordCount = merged['wordCount'] as int;
      merged['readingTime'] = (wordCount / 200).ceil(); // Assuming 200 words per minute
    }
    
    return merged;
  }

  static Map<String, dynamic> _createFallbackMetadata(String url) {
    return {
      'title': url,
      'description': null,
      'imageUrl': null,
      'siteName': Uri.parse(url).host,
      'author': null,
      'publishedDate': null,
      'tags': <String>[],
      'type': 'website',
      'favicon': null,
      'wordCount': 0,
      'readingTime': 0,
      'language': 'en',
      'url': url,
    };
  }

  /// Extract metadata for specific content types
  static Future<Map<String, dynamic>> extractYouTubeMetadata(String url) async {
    // Enhanced YouTube metadata extraction
    try {
      final response = await _dio.get(url);
      final document = html_parser.parse(response.data);
      
      return {
        'title': _getMetaContent(document, 'og:title'),
        'description': _getMetaContent(document, 'og:description'),
        'imageUrl': _getMetaContent(document, 'og:image'),
        'duration': _getMetaContent(document, 'video:duration'),
        'uploadDate': _getMetaContent(document, 'video:release_date'),
        'channel': _getMetaContent(document, 'og:video:actor'),
        'type': 'video',
      };
    } catch (e) {
      return _createFallbackMetadata(url);
    }
  }

  /// Extract metadata for GitHub repositories
  static Future<Map<String, dynamic>> extractGitHubMetadata(String url) async {
    try {
      final response = await _dio.get(url);
      final document = html_parser.parse(response.data);
      
      return {
        'title': _getMetaContent(document, 'og:title'),
        'description': _getMetaContent(document, 'og:description'),
        'language': document.querySelector('.BorderGrid-cell .color-fg-default')?.text?.trim(),
        'stars': document.querySelector('[href*="/stargazers"] .Counter')?.text?.trim(),
        'forks': document.querySelector('[href*="/forks"] .Counter')?.text?.trim(),
        'type': 'repository',
      };
    } catch (e) {
      return _createFallbackMetadata(url);
    }
  }
}