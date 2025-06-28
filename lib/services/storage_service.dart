import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/link_model.dart';

class StorageService {
  static const String _linksKey = 'saved_links';
  
  Future<List<LinkModel>> getAllLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final linksJson = prefs.getString(_linksKey);
    
    if (linksJson == null) {
      return [];
    }
    
    final List<dynamic> linksList = json.decode(linksJson);
    return linksList.map((json) => LinkModel.fromJson(json)).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }
  
  Future<bool> linkExists(String url) async {
    final links = await getAllLinks();
    return links.any((link) => link.url == url);
  }
  
  Future<bool> saveLink(LinkModel link) async {
    try {
      print('StorageService: Saving link with ID: ${link.id}');
      final links = await getAllLinks();
      print('StorageService: Current links count: ${links.length}');
      
      // Check if link already exists
      if (links.any((l) => l.url == link.url)) {
        print('StorageService: Link already exists with URL: ${link.url}');
        return false;
      }
      
      links.add(link);
      await _saveLinks(links);
      print('StorageService: Link saved successfully, new count: ${links.length}');
      return true;
    } catch (e, stackTrace) {
      print('StorageService ERROR saving link: $e');
      print('StorageService Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  Future<void> updateLink(LinkModel link) async {
    final links = await getAllLinks();
    final index = links.indexWhere((l) => l.id == link.id);
    if (index != -1) {
      links[index] = link;
      await _saveLinks(links);
    }
  }
  
  Future<void> deleteLink(String id) async {
    final links = await getAllLinks();
    links.removeWhere((link) => link.id == id);
    await _saveLinks(links);
  }
  
  Future<void> markAsRead(String id) async {
    final links = await getAllLinks();
    final index = links.indexWhere((l) => l.id == id);
    if (index != -1) {
      links[index] = links[index].copyWith(isRead: true);
      await _saveLinks(links);
    }
  }
  
  Future<void> _saveLinks(List<LinkModel> links) async {
    final prefs = await SharedPreferences.getInstance();
    final linksJson = json.encode(links.map((link) => link.toJson()).toList());
    await prefs.setString(_linksKey, linksJson);
  }
}