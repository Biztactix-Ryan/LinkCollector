# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

LinkCapture is a Flutter mobile application for capturing and saving links from other Android apps. It provides share extension functionality, metadata extraction, local storage, and Obsidian vault integration.

## Development Commands

```bash
# Install dependencies
flutter pub get

# Development
flutter run           # Run on connected device

# Build APKs
flutter build apk --debug
flutter build apk --release

# Testing
flutter test

# Analyze code
flutter analyze
```

## Architecture

### Project Structure
- **Entry Point**: `lib/main.dart`
- **Screens**: `lib/screens/` - UI screens (home, settings)
- **Services**: `lib/services/` - Business logic
  - `storage_service.dart` - SharedPreferences for local link persistence
  - `metadata_service.dart` - Web scraping for link metadata
  - `obsidian_service.dart` - Obsidian vault file operations
  - `ai_service.dart` - AI-related functionality
- **Models**: `lib/models/` - Data models
- **Widgets**: `lib/widgets/` - Reusable UI components
- **Share Intent**: Handled via `receive_sharing_intent` package

### Key Patterns
- Widget-based architecture following Flutter patterns
- Service layer separation for business logic
- Local-first storage with optional Obsidian sync
- Material Design UI

## Important Technical Details

### Android Configuration
- Minimum API 21 (Android 5.0)
- Share intent filters in `android/app/src/main/AndroidManifest.xml`
- Storage permissions required for Obsidian integration

### Obsidian Integration
- Links saved as markdown files in `{vault}/LinkCapture/`
- Files include frontmatter with metadata
- Vault detection looks in `/storage/emulated/0/`
- Manual vault selection available via file browser

### Dependencies (pubspec.yaml)
- `shared_preferences`: Local storage
- `receive_sharing_intent`: Handle shared links
- `http` & `html`: Web scraping for metadata
- `path_provider` & `permission_handler`: File operations
- `url_launcher`: Open links in browser
- `intl`: Date formatting

## Common Tasks

### Adding New Features
1. Implement service logic in appropriate service file
2. Update screens/widgets to use the service
3. Test share functionality with external apps
4. Verify Obsidian file creation if applicable

### Debugging Share Intent
- Check `AndroidManifest.xml` intent filters
- Verify app appears in Android share menu
- Test with various content types (URLs, text)

### Testing Obsidian Integration
1. Grant storage permissions
2. Ensure vault exists in accessible location
3. Check LinkCapture folder creation
4. Verify markdown file format

### Running on Device
```bash
# Check connected devices
flutter devices

# Run on specific device
flutter run -d device_id
```