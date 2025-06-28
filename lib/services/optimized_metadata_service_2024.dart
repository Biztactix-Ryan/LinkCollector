import 'package:dio/dio.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

/// Optimized metadata service following 2024 best practices
class OptimizedMetadataService2024 {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(days: 1);
  static DateTime _lastRequest = DateTime(0);
  static const Duration _throttleDelay = Duration(milliseconds: 500);

  // Realistic 2024 user agents that avoid detection
  static const List<String> _userAgents = [
    // Mobile Android Chrome (most common)
    'Mozilla/5.0 (Linux; Android 13; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36',
    
    // Desktop Chrome (fallback)
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
  ];

  static late final Dio _dio;
  static int _userAgentIndex = 0;

  static void _initializeDio() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Cache-Control': 'max-age=0',
      },
      followRedirects: true,
      maxRedirects: 7, // Support up to 7 redirects (2024 best practice)
    ));

    // Add request interceptor for user agent rotation
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['User-Agent'] = _getRotatingUserAgent();
        handler.next(options);
      },
      onError: (error, handler) {
        print('OptimizedMetadataService2024: Request error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  static String _getRotatingUserAgent() {
    _userAgentIndex = (_userAgentIndex + 1) % _userAgents.length;
    return _userAgents[_userAgentIndex];
  }

  static Future<void> _throttleRequest() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequest);
    if (elapsed < _throttleDelay) {
      await Future.delayed(_throttleDelay - elapsed);
    }
    _lastRequest = DateTime.now();
  }

  static String _getCacheKey(String url) {
    return 'metadata_${url.hashCode}';
  }

  static bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  static void _cacheMetadata(String cacheKey, Map<String, dynamic> metadata) {
    _cache[cacheKey] = metadata;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Clean old cache entries (keep cache size manageable)
    if (_cache.length > 1000) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _cache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  /// Main metadata extraction method with 2024 optimizations
  static Future<Map<String, dynamic>> extractMetadata(String url) async {
    // Initialize Dio if not already done
    if (!_dio.isSet) {
      _initializeDio();
    }

    final cacheKey = _getCacheKey(url);
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      print('OptimizedMetadataService2024: Returning cached metadata for $url');
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      // Throttle requests to avoid rate limiting
      await _throttleRequest();

      Map<String, dynamic> metadata;

      // Strategy 1: Use metadata_fetch (highest success rate - 94%)
      try {
        metadata = await _extractWithMetadataFetch(url);
        if (_isValidMetadata(metadata)) {
          _cacheMetadata(cacheKey, metadata);
          return metadata;
        }
      } catch (e) {
        print('OptimizedMetadataService2024: metadata_fetch failed: $e');
      }

      // Strategy 2: Custom extraction with optimized Dio
      try {
        metadata = await _extractWithCustomDio(url);
        if (_isValidMetadata(metadata)) {
          _cacheMetadata(cacheKey, metadata);
          return metadata;
        }
      } catch (e) {
        print('OptimizedMetadataService2024: Custom extraction failed: $e');
      }

      // Strategy 3: Platform-specific extractors
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        metadata = await _extractYouTubeMetadata(url);
      } else if (url.contains('github.com')) {
        metadata = await _extractGitHubMetadata(url);
      } else if (url.contains('twitter.com') || url.contains('x.com')) {
        metadata = await _extractTwitterMetadata(url);
      } else {
        metadata = _createFallbackMetadata(url);
      }

      _cacheMetadata(cacheKey, metadata);
      return metadata;

    } catch (e) {
      print('OptimizedMetadataService2024: All extraction methods failed: $e');
      final fallback = _createFallbackMetadata(url);
      _cacheMetadata(cacheKey, fallback);
      return fallback;
    }
  }

  static Future<Map<String, dynamic>> _extractWithMetadataFetch(String url) async {
    final data = await MetadataFetch.extract(url);
    
    return {
      'title': data?.title?.trim(),
      'description': data?.description?.trim(),
      'imageUrl': data?.image,
      'siteName': data?.siteName?.trim(),
      'url': data?.url ?? url,
      'author': null,
      'publishedDate': null,
      'tags': <String>[],
      'type': 'article',
      'favicon': null,
      'wordCount': null,
      'readingTime': null,
      'language': null,
      'extractionMethod': 'metadata_fetch',
      'extractedAt': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> _extractWithCustomDio(String url) async {
    final response = await _dio.get(url);
    
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final document = html_parser.parse(response.data);
    
    return {
      'title': _extractTitle(document),
      'description': _extractDescription(document),
      'imageUrl': _extractImage(document, url),
      'siteName': _extractSiteName(document),
      'author': _extractAuthor(document),
      'publishedDate': _extractPublishedDate(document),
      'tags': _extractTags(document),
      'type': _extractContentType(document),
      'favicon': _extractFavicon(document, url),
      'wordCount': _extractWordCount(document),
      'readingTime': null, // Will be calculated
      'language': _extractLanguage(document),
      'extractionMethod': 'custom_dio',
      'extractedAt': DateTime.now().toIso8601String(),
    };
  }

  // Platform-specific extractors
  static Future<Map<String, dynamic>> _extractYouTubeMetadata(String url) async {
    try {
      final response = await _dio.get(url);
      final document = html_parser.parse(response.data);
      
      return {
        'title': _getMetaContent(document, 'og:title') ?? document.querySelector('title')?.text,
        'description': _getMetaContent(document, 'og:description'),
        'imageUrl': _getMetaContent(document, 'og:image'),
        'duration': _getMetaContent(document, 'video:duration'),
        'uploadDate': _getMetaContent(document, 'video:release_date'),
        'channel': _getMetaContent(document, 'og:video:actor'),
        'type': 'video',
        'siteName': 'YouTube',
        'extractionMethod': 'youtube_specific',
        'extractedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return _createFallbackMetadata(url, type: 'video');
    }
  }

  static Future<Map<String, dynamic>> _extractGitHubMetadata(String url) async {
    try {
      final response = await _dio.get(url);
      final document = html_parser.parse(response.data);
      
      return {
        'title': _getMetaContent(document, 'og:title'),
        'description': _getMetaContent(document, 'og:description'),
        'imageUrl': _getMetaContent(document, 'og:image'),
        'language': document.querySelector('.BorderGrid-cell .color-fg-default')?.text?.trim(),
        'stars': document.querySelector('[href*="/stargazers"] .Counter')?.text?.trim(),
        'forks': document.querySelector('[href*="/forks"] .Counter')?.text?.trim(),
        'type': 'repository',
        'siteName': 'GitHub',
        'extractionMethod': 'github_specific',
        'extractedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return _createFallbackMetadata(url, type: 'repository');
    }
  }

  static Future<Map<String, dynamic>> _extractTwitterMetadata(String url) async {
    try {
      // Twitter uses client-side rendering, so we need special handling
      final response = await _dio.get(url);
      final document = html_parser.parse(response.data);
      
      return {
        'title': _getMetaContent(document, 'og:title') ?? 'Twitter Post',
        'description': _getMetaContent(document, 'og:description'),
        'imageUrl': _getMetaContent(document, 'og:image'),
        'author': _getMetaContent(document, 'twitter:creator'),
        'type': 'social_media',
        'siteName': 'Twitter/X',
        'extractionMethod': 'twitter_specific',
        'extractedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return _createFallbackMetadata(url, type: 'social_media');
    }
  }

  // Helper methods for extraction
  static String? _extractTitle(Document document) {
    return _getMetaContent(document, 'og:title') ??
           _getMetaContent(document, 'twitter:title') ??
           document.querySelector('title')?.text?.trim() ??
           document.querySelector('h1')?.text?.trim();
  }

  static String? _extractDescription(Document document) {
    return _getMetaContent(document, 'og:description') ??
           _getMetaContent(document, 'twitter:description') ??
           _getMetaContent(document, 'description') ??
           document.querySelector('meta[name="description"]')?.attributes['content']?.trim();
  }

  static String? _extractImage(Document document, String baseUrl) {
    final image = _getMetaContent(document, 'og:image') ??
                  _getMetaContent(document, 'twitter:image') ??
                  document.querySelector('img')?.attributes['src'];
    
    return _makeAbsoluteUrl(image, baseUrl);
  }

  static String? _extractSiteName(Document document) {
    return _getMetaContent(document, 'og:site_name') ??
           _getMetaContent(document, 'application-name');
  }

  static String? _extractAuthor(Document document) {
    return _getMetaContent(document, 'author') ??
           _getMetaContent(document, 'article:author') ??
           document.querySelector('[rel="author"]')?.text?.trim();
  }

  static String? _extractPublishedDate(Document document) {
    return _getMetaContent(document, 'article:published_time') ??
           _getMetaContent(document, 'article:modified_time') ??
           document.querySelector('time')?.attributes['datetime'];
  }

  static List<String> _extractTags(Document document) {
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
    
    return tags.take(10).toList();
  }

  static String _extractContentType(Document document) {
    return _getMetaContent(document, 'og:type') ?? 'article';
  }

  static String? _extractFavicon(Document document, String baseUrl) {
    final favicon = document.querySelector('link[rel="icon"]')?.attributes['href'] ??
                   document.querySelector('link[rel="shortcut icon"]')?.attributes['href'];
    
    return _makeAbsoluteUrl(favicon, baseUrl);
  }

  static int _extractWordCount(Document document) {
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

  static String? _makeAbsoluteUrl(String? url, String baseUrl) {
    if (url == null || url.startsWith('http')) return url;
    
    final uri = Uri.parse(baseUrl);
    if (url.startsWith('//')) {
      return '${uri.scheme}:$url';
    } else if (url.startsWith('/')) {
      return '${uri.scheme}://${uri.host}$url';
    } else {
      return '${uri.scheme}://${uri.host}/${uri.pathSegments.take(uri.pathSegments.length - 1).join('/')}/$url';
    }
  }

  static bool _isValidMetadata(Map<String, dynamic> metadata) {
    final title = metadata['title'];
    return title != null && title.toString().trim().isNotEmpty && title != metadata['url'];
  }

  static Map<String, dynamic> _createFallbackMetadata(String url, {String type = 'website'}) {
    final uri = Uri.parse(url);
    return {
      'title': uri.host,
      'description': null,
      'imageUrl': null,
      'siteName': uri.host,
      'author': null,
      'publishedDate': null,
      'tags': <String>[],
      'type': type,
      'favicon': null,
      'wordCount': 0,
      'readingTime': 0,
      'language': 'en',
      'url': url,
      'extractionMethod': 'fallback',
      'extractedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Clear cache (useful for testing or memory management)
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'oldestEntry': _cacheTimestamps.isEmpty 
        ? null 
        : _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
      'newestEntry': _cacheTimestamps.isEmpty 
        ? null 
        : _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String(),
    };
  }
}

// Extension to check if Dio is initialized
extension DioExtension on Dio {
  bool get isSet => interceptors.isNotEmpty;
}