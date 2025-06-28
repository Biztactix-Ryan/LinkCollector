import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class MetadataService {
  static Future<Map<String, String?>> extractMetadata(String url) async {
    try {
      print('MetadataService: Starting metadata extraction for URL: $url');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('MetadataService: HTTP request timed out after 10 seconds');
          throw Exception('Request timed out');
        },
      );
      
      print('MetadataService: HTTP response status code: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('MetadataService: Non-200 status code, returning default metadata');
        return {'title': url, 'description': null, 'imageUrl': null};
      }
      
      final document = html_parser.parse(response.body);
      
      // Extract title
      String? title = document.querySelector('title')?.text?.trim();
      
      // Try meta og:title
      final ogTitle = document.querySelector('meta[property="og:title"]');
      if (ogTitle != null) {
        title = ogTitle.attributes['content']?.trim() ?? title;
      }
      
      // Extract description
      String? description;
      final metaDescription = document.querySelector('meta[name="description"]');
      if (metaDescription != null) {
        description = metaDescription.attributes['content']?.trim();
      }
      
      // Try meta og:description
      final ogDescription = document.querySelector('meta[property="og:description"]');
      if (ogDescription != null) {
        description = ogDescription.attributes['content']?.trim() ?? description;
      }
      
      // Extract image
      String? imageUrl;
      final ogImage = document.querySelector('meta[property="og:image"]');
      if (ogImage != null) {
        imageUrl = ogImage.attributes['content']?.trim();
      }
      
      // Convert relative URLs to absolute
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        final uri = Uri.parse(url);
        imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
      }
      
      print('MetadataService: Successfully extracted metadata - title: $title');
      return {
        'title': title ?? url,
        'description': description,
        'imageUrl': imageUrl,
      };
    } catch (e, stackTrace) {
      print('MetadataService ERROR: $e');
      print('MetadataService Stack trace: $stackTrace');
      return {'title': url, 'description': null, 'imageUrl': null};
    }
  }
}