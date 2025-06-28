import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/metadata_service.dart';
import 'services/obsidian_service.dart';
import 'services/ai_service.dart';
import 'models/link_model.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<List<SharedMediaFile>>? _intentDataStreamSubscription;
  final _storageService = StorageService();
  final _obsidianService = ObsidianService();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    // Delay initialization to ensure the app is fully loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSharingIntent();
    });
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default to dark mode
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }

  void _initSharingIntent() {
    _log('Initializing receive sharing intent...');
    
    // Listen to media sharing coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        _log('Received media from stream: ${value.length} items');
        for (var sharedFile in value) {
          _log('Shared file: ${sharedFile.toMap()}');
          // Check if it's a text share (path contains the shared text/URL)
          if (sharedFile.type == SharedMediaType.text && sharedFile.path.isNotEmpty) {
            _log('Text share detected: ${sharedFile.path}');
            _handleSharedText(sharedFile.path);
          }
        }
      },
      onError: (err) {
        _log("getMediaStream error: $err");
      },
    );

    // Get the media sharing coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _log('Initial media: ${value.length} items');
      if (value.isNotEmpty) {
        for (var sharedFile in value) {
          _log('Initial shared file: ${sharedFile.toMap()}');
          // Check if it's a text share
          if (sharedFile.type == SharedMediaType.text && sharedFile.path.isNotEmpty) {
            _log('Initial text share: ${sharedFile.path}');
            _handleSharedText(sharedFile.path);
          }
        }
        // Tell the library that we are done processing the intent
        ReceiveSharingIntent.instance.reset();
      }
    }).catchError((err) {
      _log('Error getting initial media: $err');
    });
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString();
    final fullMessage = '[$timestamp] $message';
    print(fullMessage);
    
    // Try to update the debug log in HomeScreen if possible
    try {
      HomeScreen.addDebugLog(message);
      // Force a rebuild of the current context if available
      if (mounted && context.mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error updating UI log: $e');
    }
  }

  Future<void> _processSavingLink(String url) async {
    try {
      if (!mounted) {
        _log('Widget not mounted, cannot process link');
        return;
      }
      
      // Extract metadata
      _log('Extracting metadata...');
      final metadata = await MetadataService.extractMetadata(url);
      _log('Metadata extracted: title=${metadata['title']}, has_description=${metadata['description'] != null}');
      
      // Enhance metadata with AI (optional)
      _log('Attempting to enhance metadata with AI...');
      final enhancedMetadata = await AIService.enhanceMetadata(
        url: url,
        title: metadata['title'],
        description: metadata['description'],
      );
      
      // Use enhanced metadata if available
      final finalTitle = enhancedMetadata['title'] ?? metadata['title'] ?? url;
      final finalDescription = enhancedMetadata['description'] ?? metadata['description'];
      
      _log('Final title: $finalTitle');
      
      // Create and save link
      final link = LinkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        title: finalTitle,
        description: finalDescription,
        imageUrl: metadata['imageUrl'],
        savedAt: DateTime.now(),
      );
      
      _log('Saving link to storage...');
      final saved = await _storageService.saveLink(link);
      
      if (!saved) {
        _log('Link already exists in storage');
        
        // Show duplicate message
        try {
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Link already saved!'),
              backgroundColor: Colors.orange,
            ),
          );
        } catch (e) {
          _log('Could not show snackbar: $e');
        }
        return;
      }
      
      _log('Link saved to storage');
      
      // Save to Obsidian if enabled
      _log('Attempting to save to Obsidian...');
      final obsidianSaved = await _obsidianService.saveLinkToObsidian(link);
      _log('Obsidian save result: $obsidianSaved');
      
      // Update the UI log with success
      _log('Link saved successfully!${obsidianSaved ? ' (including Obsidian)' : ''}');
      
      // Refresh the home screen
      HomeScreen.refreshLinks?.call();
      
      // Show success snackbar
      try {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(obsidianSaved 
              ? 'Link saved to app and Obsidian!' 
              : 'Link saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _log('Could not show snackbar: $e');
      }
      
    } catch (e, stackTrace) {
      _log('Error in _processSavingLink: $e');
      _log('Stack trace: $stackTrace');
      
      // Try to show error snackbar
      try {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Error saving link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        _log('Could not show error snackbar: $e');
      }
    }
  }

  void _handleSharedText(String text) async {
    _log('_handleSharedText called with: $text');
    
    try {
      // Extract URL from text
      final urlRegex = RegExp(r'https?://[^\s]+');
      final match = urlRegex.firstMatch(text);
      
      if (match != null) {
      final url = match.group(0)!;
      _log('URL extracted: $url');
      
      // Wait a moment for the app to be ready, then process the link
      await Future.delayed(const Duration(milliseconds: 500));
      _processSavingLink(url);
    } else {
      _log('No URL found in shared text: $text');
    }
    } catch (e, stackTrace) {
      _log('ERROR in _handleSharedText: $e');
      _log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Link Capture',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern indigo
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern indigo
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep slate
        cardColor: const Color(0xFF1E293B), // Slate surface
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: HomeScreen(
        onThemeToggle: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}