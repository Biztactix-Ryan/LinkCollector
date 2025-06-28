# LinkCollector 🔗

**A modern Flutter app for capturing and organizing links from any Android app with seamless Obsidian integration.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

## ✨ Features

- **🚀 Quick Link Saving**: Share any link from any app to LinkCollector using Android's share menu
- **🌙 Beautiful Dark Mode**: Modern UI with dark mode enabled by default and theme toggle
- **🤖 AI-Enhanced Metadata**: Automatically extracts and enhances link titles and descriptions
- **📝 Obsidian Integration**: Save links directly to your Obsidian vault as markdown files
- **💾 Offline Support**: Links are saved locally first, ensuring nothing is lost
- **🔍 Smart Search**: Quickly find saved links with powerful search functionality
- **📖 Read Tracking**: Keep track of which links you've visited
- **🎨 Material 3 Design**: Clean, modern interface with smooth animations

## 🎯 How It Works

1. **Share**: Find an interesting link in any app (browser, social media, etc.)
2. **Save**: Share it to LinkCollector using Android's share menu
3. **Organize**: The app automatically fetches metadata and saves the link
4. **Sync**: If Obsidian integration is enabled, a markdown file is created in your vault
5. **Access**: View your saved links anytime from the app or Obsidian

## 📱 Screenshots

*Screenshots coming soon...*

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.8.1+
- Android Studio (for Android development)
- Android device/emulator running Android 5.0 (API 21) or higher

### Build from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Biztactix-Ryan/LinkCollector.git
   cd LinkCollector
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Build APK**:
   ```bash
   flutter build apk --release
   ```

## ⚙️ Configuration

### Obsidian Integration Setup

1. Open LinkCollector and tap the settings icon (⚙️)
2. Enable "Obsidian Integration"
3. Select your Obsidian vault:
   - The app will auto-detect vaults in common locations
   - Or manually browse for your vault folder
4. Choose the target folder (default: `LinkCollector/`)

### Link Format in Obsidian

Links are saved as markdown files with the following structure:

```markdown
---
title: "Example Article"
url: "https://example.com/article"
description: "An interesting article about..."
savedAt: 2024-03-15T10:30:00Z
tags: [link-collector, unread]
---

# Example Article

> An interesting article about...

**URL**: https://example.com/article
**Saved**: 2024-03-15 10:30 AM
```

## 🛠️ Development

### Project Structure
```
lib/
├── main.dart                 # App entry point with theme management
├── models/
│   └── link_model.dart      # Link data model
├── screens/
│   ├── home_screen.dart     # Main app interface
│   └── settings_screen.dart # Configuration screen
├── services/
│   ├── storage_service.dart    # Local storage management
│   ├── metadata_service.dart   # Web scraping for metadata
│   ├── obsidian_service.dart   # Obsidian vault integration
│   └── ai_service.dart        # AI metadata enhancement
└── widgets/
    └── link_card.dart       # Reusable link display component
```

### Key Technologies
- **Flutter 3.8.1+**: Cross-platform mobile framework
- **Material 3**: Modern design system with theming
- **SharedPreferences**: Local data persistence
- **HTTP & HTML parsing**: Metadata extraction
- **File system access**: Obsidian integration

### Development Commands
```bash
# Install dependencies
flutter pub get

# Run on device
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

## 🎨 Theming

LinkCollector features a modern dark-first design:

- **Primary Color**: Indigo (#6366F1)
- **Dark Mode**: Deep slate backgrounds with excellent contrast
- **Light Mode**: Clean whites and subtle grays
- **Theme Toggle**: Persistent across app restarts
- **Material 3**: Latest design principles and components

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Inspired by the Obsidian community and knowledge management workflows
- Material Design 3 for the beautiful UI components

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/Biztactix-Ryan/LinkCollector/issues) page
2. Create a new issue with detailed information
3. Include your device model, Android version, and steps to reproduce

---

**Made with ❤️ by [Biztactix-Ryan](https://github.com/Biztactix-Ryan)**