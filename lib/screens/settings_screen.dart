import 'package:flutter/material.dart';
import '../services/obsidian_service.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _obsidianService = ObsidianService();
  bool _obsidianEnabled = false;
  String? _vaultPath;
  String _targetFolder = 'LinkCapture';
  List<String> _availableVaults = [];
  List<String> _vaultFolders = [];
  bool _isLoadingVaults = false;
  
  // AI Settings
  String? _aiApiKey;
  String _aiProvider = 'cohere';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _obsidianService.isEnabled;
    final vaultPath = await _obsidianService.vaultPath;
    final targetFolder = await _obsidianService.targetFolder;
    
    // Load AI settings
    final aiApiKey = await AIService.getApiKey();
    final aiProvider = await AIService.getProvider();

    setState(() {
      _obsidianEnabled = enabled;
      _vaultPath = vaultPath;
      _targetFolder = targetFolder;
      _aiApiKey = aiApiKey;
      _aiProvider = aiProvider;
    });

    if (vaultPath != null) {
      _loadVaultFolders();
    }
    _findObsidianVaults();
  }

  Future<void> _findObsidianVaults() async {
    setState(() => _isLoadingVaults = true);
    
    final hasPermission = await _obsidianService.requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required for Obsidian integration')),
        );
      }
      setState(() => _isLoadingVaults = false);
      return;
    }

    final vaults = await _obsidianService.findObsidianVaults();
    setState(() {
      _availableVaults = vaults;
      _isLoadingVaults = false;
    });
  }

  Future<void> _loadVaultFolders() async {
    if (_vaultPath == null) return;
    
    final folders = await _obsidianService.getVaultFolders(_vaultPath!);
    setState(() {
      _vaultFolders = folders;
    });
  }

  Future<void> _selectVault(String vault) async {
    await _obsidianService.setVaultPath(vault);
    setState(() {
      _vaultPath = vault;
    });
    _loadVaultFolders();
  }

  Future<void> _showManualPathDialog() async {
    final controller = TextEditingController(text: _vaultPath ?? '/storage/emulated/0/');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Vault Path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '/storage/emulated/0/MyVault',
            labelText: 'Vault Path',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await _obsidianService.setVaultPath(result);
      setState(() {
        _vaultPath = result;
      });
      _loadVaultFolders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Obsidian Integration',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _obsidianEnabled,
                        onChanged: (value) async {
                          await _obsidianService.setEnabled(value);
                          setState(() {
                            _obsidianEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save links to your Obsidian vault',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          
          if (_obsidianEnabled) ...[
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vault Location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_vaultPath != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _vaultPath!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'No vault selected',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 12),
                    
                    if (_isLoadingVaults)
                      const Center(child: CircularProgressIndicator())
                    else if (_availableVaults.isNotEmpty) ...[
                      const Text(
                        'Available Vaults:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ..._availableVaults.map((vault) => ListTile(
                        title: Text(vault),
                        leading: Icon(
                          _vaultPath == vault ? Icons.check_circle : Icons.folder,
                          color: _vaultPath == vault ? Colors.green : null,
                        ),
                        onTap: () => _selectVault(vault),
                        contentPadding: EdgeInsets.zero,
                      )),
                    ],
                    
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showManualPathDialog,
                      icon: const Icon(Icons.edit),
                      label: const Text('Enter Vault Path'),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_vaultPath != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Folder',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _vaultFolders.contains(_targetFolder) ? _targetFolder : '/',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _vaultFolders.map((folder) {
                          return DropdownMenuItem(
                            value: folder,
                            child: Text(
                              folder == '/' ? 'Root' : folder,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            await _obsidianService.setTargetFolder(value);
                            setState(() {
                              _targetFolder = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Links will be saved to this folder in your vault',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          
          // AI Enhancement Section
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Enhancement',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use AI to generate better titles and descriptions',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  
                  // API Provider Selection
                  const Text(
                    'AI Provider',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _aiProvider,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cohere', child: Text('Cohere (Free tier available)')),
                      DropdownMenuItem(value: 'openai', child: Text('OpenAI (GPT-3.5)')),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await AIService.setProvider(value);
                        setState(() {
                          _aiProvider = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // API Key Input
                  const Text(
                    'API Key',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: _aiApiKey),
                    obscureText: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: _aiProvider == 'cohere' 
                        ? 'Enter your Cohere API key' 
                        : 'Enter your OpenAI API key',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () async {
                          final controller = TextEditingController(text: _aiApiKey ?? '');
                          final key = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Set API Key'),
                              content: TextField(
                                controller: controller,
                                obscureText: false,
                                decoration: const InputDecoration(
                                  hintText: 'Paste your API key here',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(controller.text),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          
                          if (key != null) {
                            await AIService.setApiKey(key);
                            setState(() {
                              _aiApiKey = key;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API key saved')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    onChanged: (value) async {
                      await AIService.setApiKey(value);
                      setState(() {
                        _aiApiKey = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiProvider == 'cohere' 
                      ? 'Get a free API key at cohere.com' 
                      : 'Get an API key at platform.openai.com',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}