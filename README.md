# AgroSense - Smart Farming Assistant

## Overview
AgroSense is an offline-first mobile application designed for Indian farmers, providing land management, weather intelligence, market data, and AI-powered farming assistance.

## Architecture
- **Pattern:** Clean Architecture (Data, Domain, Presentation)
- **State Management:** Riverpod
- **Database:** Drift (SQLite) for offline-first capability
- **Backend:** Firebase (Auth, Firestore, Storage, Functions)

## Key Features
1. **Offline-First Architecture** - All data operations work offline with background sync
2. **GIS Land Management** - Draw and manage field boundaries
3. **Weather Intelligence** - Real-time weather with AI-generated advisories
4. **Market Intelligence** - Mandi prices and trends
5. **AI Assistant** - Gemini-powered farming advisor
6. **Crop Management** - Task scheduling and crop lifecycle tracking
7. **Community Forum** - Connect with other farmers
8. **Government Schemes** - Eligibility checker

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.2.0)
- Firebase Project configured
- Android Studio / VS Code

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase:
   - Add `google-services.json` (Android) to `android/app/`
   - Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`
4. Generate code: `flutter pub run build_runner build --delete-conflicting-outputs`
5. Run: `flutter run`

## Project Structure
```
lib/
├── core/                   # Core utilities, constants, themes
├── data/                   # Data layer (APIs, local DB, repositories)
├── domain/                 # Business logic (entities, use cases)
├── presentation/           # UI layer (screens, widgets, state)
└── main.dart              # Entry point
```

## Technologies Used
- Flutter & Dart
- Riverpod (State Management)
- Drift (Local Database)
- Firebase (Backend)
- flutter_map + turf_dart (GIS)
- Gemini API (AI)
- workmanager (Background Sync)

## License
MIT License
