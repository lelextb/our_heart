<p align="center">
  <img src="assets/icon/icon.png" width="120" alt="Our Heart Logo">
</p>

<h1 align="center">💕 Our Heart</h1>

<p align="center">
  <strong>Your private, offline‑first relationship companion — where love lives offline.</strong>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-screenshots">Screenshots</a> •
  <a href="#-architecture">Architecture</a> •
  <a href="#-tech-stack">Tech Stack</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-building-apk">Building APK</a> •
  <a href="#-license">License</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-green" alt="Platform">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen" alt="PRs Welcome">
  <img src="https://img.shields.io/badge/offline--first-✓-brightgreen" alt="Offline-first">
  <img src="https://img.shields.io/badge/glassmorphism-✨-pink" alt="Glassmorphism">
</p>

---

## 📖 About

**"Our Heart"** is a production‑ready Flutter application that serves as a private, offline‑first relationship companion — a digital space where two partners can track their relationship journey, store shared memories, write love letters, manage events and reminders, and create custom lyric videos.

Built with an obsessive focus on **glassmorphism aesthetics**, **local data privacy** (no cloud — everything stays on your device), and **fluid animations**.

✨ **Live demo?** No — your love story deserves privacy. All data stays offline.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔐 **PIN Authentication** | SHA‑256 hashed PIN with salt, stored in Android Keystore — never in plain text |
| 💖 **Interactive Heart** | Beautiful heart filling animation that grows as your relationship progresses |
| 📸 **Shared Gallery** | Organize memories into custom albums with thumbnail generation |
| ✍️ **Love Letters** | Write, save, and cherish heartfelt letters with word/character counts |
| 📅 **Planner & Reminders** | Auto‑generated anniversaries, birthdays, and custom reminders with local notifications |
| 📝 **Notes (Info)** | Quick journal entries and shared notes with rich text |
| 🎬 **Lyric Video Creator** | Search/download audio from YouTube Music, fetch synced lyrics (LRCLIB/RentAnAdviser), 14 animation styles, custom glass colors, render directly to video using FFmpeg |
| 🎨 **Glassmorphism UI** | Consistent frosted‑glass design with 24 preset glass colors and light/dark theme support |
| 📤 **Data Export** | Export all memories, letters, and photos as a ZIP file with JSON metadata |

---

## 📸 Screenshots

<p align="center">
  <img src="screenshots/home.jpg" width="180" alt="Home Screen with heart animation">
  <img src="screenshots/gallery.jpg" width="180" alt="Gallery albums">
  <img src="screenshots/lyric_video.jpg" width="180" alt="Lyric video creator">
  <img src="screenshots/letters.jpg" width="180" alt="Love letters editor">
</p>
<p align="center">
  <img src="screenshots/planner.jpg" width="180" alt="Calendar and events">
  <img src="screenshots/reminders.jpg" width="180" alt="Reminders list">
  <img src="screenshots/settings.jpg" width="180" alt="Settings with glassmorphism">
  <img src="screenshots/pin.jpg" width="180" alt="PIN authentication screen">
</p>

---

## 🏗️ Architecture

```
lib/
├── core/                 # Core utilities, constants, theme, extensions
├── data/                 # Database (Drift), repositories, local storage
├── features/             # Feature-based modules (9 features)
│   ├── auth/            # PIN authentication
│   ├── home/            # Dashboard with heart animation
│   ├── gallery/         # Photo albums
│   ├── letters/         # Love letters
│   ├── plans/           # Calendar & events
│   ├── reminders/       # Reminder management
│   ├── info/            # Notes
│   ├── settings/        # App configuration
│   └── lyric_video/     # Lyric video creator (off-screen capture + FFmpeg)
└── shared_widgets/      # Reusable glassmorphic UI components
```

The app follows **Clean Architecture** principles with **BLoC/Cubit** for state management, **Repository Pattern** for data abstraction, and **feature-based modularity** for scalability and maintainability.

### State Management & DI

- **BLoC/Cubit** (`flutter_bloc`) for predictable state management
- **MultiRepositoryProvider** & **MultiBlocProvider** for dependency injection
- **Singleton database instances** with background isolates for performance

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | Flutter 3.x (Dart) |
| State Management | BLoC/Cubit (`flutter_bloc`) |
| Local Database | Drift (SQLite ORM) |
| Secure Storage | `flutter_secure_storage` (Android Keystore) |
| Notifications | `flutter_local_notifications` |
| Media Processing | `ffmpeg_kit_flutter_new` (full-gpl) |
| Audio Playback | `just_audio` |
| YouTube Integration | `ytmusicapi_dart` + `youtube_explode_dart` |
| Image Handling | `image_picker` + `image_cropper` |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.x stable)
- Android Studio / VS Code with Flutter extensions
- Android SDK (API 21+)

### Clone & Install

```bash
# Clone the repository
git clone https://github.com/lelextb/our_heart.git
cd our_heart

# Fetch dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration

The app uses `flutter_secure_storage` which relies on Android Keystore. No external API keys are required for core functionality. Lyric video features work out of the box.

**Note:** The lyric video creator requires FFmpeg binaries (bundled via `ffmpeg_kit_flutter_new/full-gpl`). First run may take a few seconds to extract binaries.

---

## 📦 Building APK

### Debug Build

```bash
flutter build apk --debug
```

### Release Build (Signed)

1. Create a keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

3. Build release APK:
```bash
flutter build apk --release --split-per-abi
```

Output APKs will be in `build/app/outputs/flutter-apk/`.

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a PR.

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with ❤️ using Flutter
- FFmpeg for media processing capabilities
- All contributors and open-source libraries that made this possible

---

<p align="center">
  Made with love for couples who cherish their privacy. 💕
</p>
