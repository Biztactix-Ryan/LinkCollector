# Link Capture - Flutter App

A Flutter app that captures links from any Android app and saves them locally and to your Obsidian vault.

## Installation

1. Install the APK: `build/app/outputs/flutter-apk/app-debug.apk`
2. Grant necessary permissions when prompted

## Features

- **Share to Save**: Share any link from any app to Link Capture
- **Manual Add**: Tap the + button to manually add a link
- **Obsidian Integration**: Automatically save links as markdown files in your vault
- **Search**: Search through saved links
- **Metadata Extraction**: Automatically fetches title, description, and preview images

## Testing the App

### Method 1: Manual Add (Recommended for Testing)
1. Open Link Capture
2. Tap the **+** button in the top bar
3. Enter a URL (e.g., https://example.com)
4. Tap "Add"
5. The link will be saved with metadata

### Method 2: Share from Browser
1. Open any web browser
2. Navigate to a webpage
3. Tap the share button
4. Select "Link Capture" from the share menu
5. The app should open and save the link

### Method 3: Share Text with URL
1. Select any text containing a URL
2. Share the text
3. Choose "Link Capture"

## Obsidian Setup

1. Tap the settings icon (⚙️)
2. Enable "Obsidian Integration"
3. Either:
   - Select a detected vault from the list
   - Or tap "Enter Vault Path" and type the full path (e.g., `/storage/emulated/0/MyVault`)
4. Choose target folder for links
5. Grant storage permissions when prompted

## Troubleshooting

### Share Intent Not Working?

1. **Check App Installation**: 
   - Uninstall and reinstall the app
   - Make sure the app appears in your app drawer

2. **Test Manual Add First**:
   - Use the + button to verify the app works
   - This confirms the saving functionality is working

3. **Share Menu Issues**:
   - Some apps may not show all share targets immediately
   - Try sharing from Chrome or Firefox first
   - Restart your device after installation

4. **Debug Mode**:
   - Check Android logs: `adb logcat | grep -i "link\|share"`
   - Look for print statements from the app

### Obsidian Not Saving?

1. **Permissions**:
   - Go to Settings > Apps > Link Capture > Permissions
   - Enable "Files and media" permission
   - On Android 11+, you may need "All files access"

2. **Vault Path**:
   - Make sure the path exists
   - Try `/storage/emulated/0/YourVaultName`
   - The vault must contain a `.obsidian` folder

3. **Test Path**:
   - Create a test vault at `/storage/emulated/0/TestVault`
   - Create `.obsidian` folder inside it
   - Use this path in settings

## File Location

Links are saved in Obsidian as:
```
YourVault/
└── LinkCapture/
    └── 2024-06-27-143025-example-article.md
```

## APK Details

- **Location**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Package**: `com.linkcapture.link_capture`
- **Min Android**: API 21 (Android 5.0)

## Development

To rebuild:
```bash
flutter pub get
flutter build apk --debug
```

To run with debugging:
```bash
flutter run
```

To see logs:
```bash
adb logcat | grep flutter
```