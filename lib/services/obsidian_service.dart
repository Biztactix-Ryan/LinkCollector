import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/link_model.dart';
import 'package:intl/intl.dart';

class ObsidianService {
  static const String _vaultPathKey = 'obsidian_vault_path';
  static const String _targetFolderKey = 'obsidian_target_folder';
  static const String _enabledKey = 'obsidian_enabled';
  
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }
  
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
  
  Future<String?> get vaultPath async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vaultPathKey);
  }
  
  Future<void> setVaultPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_vaultPathKey, path);
    } else {
      await prefs.remove(_vaultPathKey);
    }
  }
  
  Future<String> get targetFolder async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_targetFolderKey) ?? 'LinkCollector';
  }
  
  Future<void> setTargetFolder(String folder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetFolderKey, folder);
  }
  
  Future<bool> requestStoragePermission() async {
    final status = await Permission.manageExternalStorage.request();
    return status == PermissionStatus.granted;
  }
  
  Future<List<String>> findObsidianVaults() async {
    final vaults = <String>[];
    
    try {
      // Check common locations for Obsidian vaults
      final commonPaths = [
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Obsidian',
        '/storage/emulated/0/',
      ];
      
      for (final basePath in commonPaths) {
        final dir = Directory(basePath);
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is Directory) {
              // Check if this directory contains .obsidian folder
              final obsidianDir = Directory(path.join(entity.path, '.obsidian'));
              if (await obsidianDir.exists()) {
                vaults.add(entity.path);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error finding Obsidian vaults: $e');
    }
    
    return vaults;
  }
  
  Future<List<String>> getVaultFolders(String vaultPath) async {
    final folders = <String>['/']; // Root folder
    
    try {
      final vaultDir = Directory(vaultPath);
      if (await vaultDir.exists()) {
        await for (final entity in vaultDir.list(recursive: true, followLinks: false)) {
          if (entity is Directory && 
              !entity.path.contains('.obsidian') && 
              !entity.path.contains('.trash')) {
            final relativePath = path.relative(entity.path, from: vaultPath);
            folders.add(relativePath);
          }
        }
      }
    } catch (e) {
      print('Error getting vault folders: $e');
    }
    
    folders.sort();
    return folders;
  }
  
  Future<bool> saveLinkToObsidian(LinkModel link) async {
    try {
      final enabled = await isEnabled;
      if (!enabled) return false;
      
      final vault = await vaultPath;
      if (vault == null) return false;
      
      // Create target folder if it doesn't exist
      final folder = await targetFolder;
      final targetDir = Directory(path.join(vault, folder));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // Generate filename
      final dateFormat = DateFormat('yyyy-MM-dd-HHmmss');
      final timestamp = dateFormat.format(link.savedAt);
      final safeTitle = _sanitizeFilename(link.title);
      final filename = '$timestamp-$safeTitle.md';
      
      // Create markdown content
      final content = _generateMarkdownContent(link);
      
      // Write file
      final file = File(path.join(targetDir.path, filename));
      await file.writeAsString(content);
      
      // Also append to daily note if it exists
      await _appendToDailyNote(vault, link);
      
      return true;
    } catch (e) {
      print('Error saving to Obsidian: $e');
      return false;
    }
  }
  
  String _sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase()
        .substring(0, name.length > 50 ? 50 : name.length);
  }
  
  String _generateMarkdownContent(LinkModel link) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = dateFormat.format(link.savedAt);
    
    final buffer = StringBuffer();
    
    // Frontmatter
    buffer.writeln('---');
    buffer.writeln('title: "${link.title}"');
    buffer.writeln('url: "${link.url}"');
    buffer.writeln('saved_at: $formattedDate');
    buffer.writeln('tags: [link-capture${link.isRead ? "" : ", unread"}]');
    if (link.description != null) {
      buffer.writeln('description: "${link.description}"');
    }
    buffer.writeln('---');
    buffer.writeln();
    
    // Content
    buffer.writeln('# ${link.title}');
    buffer.writeln();
    
    if (link.description != null) {
      buffer.writeln('> ${link.description}');
      buffer.writeln();
    }
    
    buffer.writeln('**URL**: ${link.url}');
    buffer.writeln('**Saved**: $formattedDate');
    
    if (link.imageUrl != null) {
      buffer.writeln();
      buffer.writeln('![](${link.imageUrl})');
    }
    
    return buffer.toString();
  }
  
  Future<void> _appendToDailyNote(String vaultPath, LinkModel link) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dailyNotePath = path.join(vaultPath, 'Daily Notes', '$today.md');
      final dailyNoteFile = File(dailyNotePath);
      
      if (await dailyNoteFile.exists()) {
        final content = await dailyNoteFile.readAsString();
        final linkEntry = '\n- [${link.title}](${link.url}) - ${link.savedAt.hour}:${link.savedAt.minute.toString().padLeft(2, '0')}\n';
        
        await dailyNoteFile.writeAsString(content + linkEntry);
      }
    } catch (e) {
      // Daily note append is optional, so we just log the error
      print('Could not append to daily note: $e');
    }
  }
}