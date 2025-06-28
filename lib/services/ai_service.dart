import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _cohereApiUrl = 'https://api.cohere.ai/v1/summarize';
  static const String _apiKeyPref = 'ai_api_key';
  static const String _apiProviderPref = 'ai_provider';
  
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }
  
  static Future<void> setApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key != null && key.isNotEmpty) {
      await prefs.setString(_apiKeyPref, key);
    } else {
      await prefs.remove(_apiKeyPref);
    }
  }
  
  static Future<String> getProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiProviderPref) ?? 'cohere';
  }
  
  static Future<void> setProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiProviderPref, provider);
  }
  
  static Future<Map<String, String?>> enhanceMetadata({
    required String url,
    required String? title,
    required String? description,
    String? pageContent,
  }) async {
    try {
      print('AIService: Enhancing metadata for URL: $url');
      
      // Get API key and provider from preferences
      final apiKey = await getApiKey();
      final provider = await getProvider();
      
      if (apiKey == null || apiKey.isEmpty) {
        print('AIService: No API key configured, returning original metadata');
        return {
          'title': title,
          'description': description,
        };
      }
      
      // Use different API based on provider
      if (provider == 'openai') {
        return await _enhanceWithOpenAI(
          url: url,
          title: title,
          description: description,
          apiKey: apiKey,
        );
      }
      
      // Prepare text for summarization
      String textToSummarize = '';
      if (pageContent != null && pageContent.isNotEmpty) {
        textToSummarize = pageContent;
      } else if (description != null && description.isNotEmpty) {
        textToSummarize = '$title\n\n$description';
      } else if (title != null) {
        textToSummarize = title;
      } else {
        return {'title': title, 'description': description};
      }
      
      // Limit text length to avoid API limits
      if (textToSummarize.length > 4000) {
        textToSummarize = textToSummarize.substring(0, 4000);
      }
      
      // Call Cohere API
      final response = await http.post(
        Uri.parse(_cohereApiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': textToSummarize,
          'length': 'short',
          'format': 'bullets',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summary = data['summary'] as String?;
        
        if (summary != null && summary.isNotEmpty) {
          // Generate a better title from the summary
          final enhancedTitle = _generateTitleFromSummary(summary, title ?? url);
          
          print('AIService: Enhanced title: $enhancedTitle');
          return {
            'title': enhancedTitle,
            'description': summary,
          };
        }
      } else {
        print('AIService: API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('AIService ERROR: $e');
    }
    
    // Return original metadata if enhancement fails
    return {
      'title': title,
      'description': description,
    };
  }
  
  static String _generateTitleFromSummary(String summary, String originalTitle) {
    // Extract the first bullet point or sentence as a title
    final lines = summary.split('\n');
    for (final line in lines) {
      final cleaned = line.replaceAll(RegExp(r'^[-•*]\s*'), '').trim();
      if (cleaned.isNotEmpty && cleaned.length > 10 && cleaned.length < 100) {
        // Capitalize first letter and ensure it ends properly
        return cleaned[0].toUpperCase() + cleaned.substring(1).replaceAll(RegExp(r'[.!?]+$'), '');
      }
    }
    
    // Fallback to original title
    return originalTitle;
  }
  
  // Use OpenAI API
  static Future<Map<String, String?>> _enhanceWithOpenAI({
    required String url,
    required String? title,
    required String? description,
    required String apiKey,
  }) async {
    const String apiUrl = 'https://api.openai.com/v1/chat/completions';
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that creates concise, descriptive titles and summaries for web pages.'
            },
            {
              'role': 'user',
              'content': '''Given this webpage information:
URL: $url
Title: ${title ?? 'No title'}
Description: ${description ?? 'No description'}

Please provide:
1. A better, more descriptive title (max 80 characters)
2. A concise summary (max 150 characters)

Format your response as JSON:
{"title": "your title here", "description": "your summary here"}'''
            }
          ],
          'temperature': 0.7,
          'max_tokens': 150,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        final result = json.decode(content);
        
        return {
          'title': result['title'] ?? title,
          'description': result['description'] ?? description,
        };
      }
    } catch (e) {
      print('OpenAI API ERROR: $e');
    }
    
    return {'title': title, 'description': description};
  }
}