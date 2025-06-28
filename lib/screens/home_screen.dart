import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/link_model.dart';
import '../services/storage_service.dart';
import '../services/metadata_service.dart';
import '../services/obsidian_service.dart';
import '../services/ai_service.dart';
import '../widgets/link_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final bool isDarkMode;
  
  const HomeScreen({
    super.key,
    this.onThemeToggle,
    this.isDarkMode = true,
  });
  
  static final List<String> debugLogs = [];
  static VoidCallback? refreshLinks;
  
  static void addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    debugLogs.insert(0, '[$timestamp] $message');
    if (debugLogs.length > 50) {
      debugLogs.removeLast();
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  final _obsidianService = ObsidianService();
  List<LinkModel> _links = [];
  List<LinkModel> _filteredLinks = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;
  bool _showDebugLog = false;

  @override
  void initState() {
    super.initState();
    HomeScreen.refreshLinks = _loadLinks;
    _loadLinks();
    _searchController.addListener(_filterLinks);
  }

  @override
  void dispose() {
    HomeScreen.refreshLinks = null;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLinks() async {
    setState(() => _isLoading = true);
    final links = await _storageService.getAllLinks();
    setState(() {
      _links = links;
      _filteredLinks = links;
      _isLoading = false;
    });
  }

  void _filterLinks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLinks = _links;
      } else {
        _filteredLinks = _links.where((link) {
          return link.title.toLowerCase().contains(query) ||
              link.url.toLowerCase().contains(query) ||
              (link.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _openLink(LinkModel link) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await _storageService.markAsRead(link.id);
      _loadLinks();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _deleteLink(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link'),
        content: const Text('Are you sure you want to delete this link?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteLink(id);
      _loadLinks();
    }
  }

  Future<void> _testAddLink() async {
    final controller = TextEditingController(text: 'https://');
    
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            labelText: 'URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving link...'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Extract metadata
      final metadata = await MetadataService.extractMetadata(url);
      
      // Enhance metadata with AI
      final enhancedMetadata = await AIService.enhanceMetadata(
        url: url,
        title: metadata['title'],
        description: metadata['description'],
      );
      
      // Use enhanced metadata if available
      final finalTitle = enhancedMetadata['title'] ?? metadata['title'] ?? url;
      final finalDescription = enhancedMetadata['description'] ?? metadata['description'];
      
      // Create and save link
      final link = LinkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        title: finalTitle,
        description: finalDescription,
        imageUrl: metadata['imageUrl'],
        savedAt: DateTime.now(),
      );
      
      final saved = await _storageService.saveLink(link);
      
      if (!saved) {
        // Link already exists
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link already saved!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Save to Obsidian if enabled
      final obsidianSaved = await _obsidianService.saveLinkToObsidian(link);
      
      // Close dialog and reload
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(obsidianSaved 
              ? 'Link saved to app and Obsidian!' 
              : 'Link saved successfully!'),
          ),
        );
        _loadLinks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : null,
      appBar: AppBar(
        title: Text(
          'Link Capture',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : null,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.white : null,
            ),
            onPressed: widget.onThemeToggle,
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
          ),
          IconButton(
            icon: Icon(
              _showDebugLog ? Icons.link : Icons.bug_report,
              color: isDark ? Colors.white : null,
            ),
            onPressed: () {
              setState(() {
                _showDebugLog = !_showDebugLog;
              });
            },
            tooltip: _showDebugLog ? 'Show Links' : 'Show Debug Log',
          ),
          IconButton(
            icon: Icon(Icons.add, color: isDark ? Colors.white : null),
            onPressed: () => _testAddLink(),
            tooltip: 'Test Add Link',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: isDark ? Colors.white : null),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadLinks());
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? Colors.white : null,
              ),
              decoration: InputDecoration(
                hintText: 'Search links...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : null,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
              ),
            ),
          ),
          Expanded(
            child: _showDebugLog
                ? _buildDebugLogView()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredLinks.isEmpty
                        ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.link_off,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No saved links yet'
                                  : 'No links found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Share links from other apps to save them here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLinks,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredLinks.length,
                          itemBuilder: (context, index) {
                            final link = _filteredLinks[index];
                            return LinkCard(
                              link: link,
                              onTap: () => _openLink(link),
                              onDelete: () => _deleteLink(link.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugLogView() {
    return Container(
      color: Colors.black87,
      child: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Text(
                  'Debug Log',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      HomeScreen.debugLogs.clear();
                    });
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: HomeScreen.debugLogs.isEmpty
                ? const Center(
                    child: Text(
                      'No debug logs yet.\nTry sharing a link from another app!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: HomeScreen.debugLogs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          HomeScreen.debugLogs[index],
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}