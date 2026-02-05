# Quick Start Guide - AgroSense

## Prerequisites
- Flutter SDK 3.2.0 or higher
- Android Studio or VS Code
- Git
- Firebase account
- Google Cloud account (for Gemini API)

## Step-by-Step Setup

### 1. Install Dependencies

```powershell
cd e:\IISF\AgroSenseFarmingAPP
flutter pub get
```

### 2. Generate Code (Drift Database)

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `lib/data/local/database/app_database.g.dart`

### 3. Firebase Configuration

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name: "AgroSense" (or your choice)
4. Enable Google Analytics (optional)

#### Android Setup
1. Add Android app in Firebase Console
2. Package name: `com.agrosense.app` (or your choice)
3. Download `google-services.json`
4. Place in `android/app/google-services.json`

Edit `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Edit `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        applicationId "com.agrosense.app"
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

#### iOS Setup (if targeting iOS)
1. Add iOS app in Firebase Console
2. Bundle ID: `com.agrosense.app`
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/GoogleService-Info.plist`

#### Enable Firebase Services
In Firebase Console, enable:
- **Authentication** → Phone & Google Sign-In
- **Firestore Database** → Start in test mode
- **Storage** → Start in test mode
- **Cloud Messaging** (for notifications)

### 4. Get API Keys

#### Gemini AI API
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create API key
3. Update `lib/core/constants/app_constants.dart`:
   ```dart
   static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
   ```

#### eNAM API (Optional - for Market Prices)
1. Go to [data.gov.in](https://data.gov.in/)
2. Register and get API key
3. Update constants file

### 5. Add Assets

Create these folders and add placeholder files:

```powershell
# Create folders
New-Item -ItemType Directory -Force -Path assets\images
New-Item -ItemType Directory -Force -Path assets\icons
New-Item -ItemType Directory -Force -Path assets\animations
New-Item -ItemType Directory -Force -Path assets\fonts

# Font files (download Poppins from Google Fonts)
# Place in assets/fonts/:
# - Poppins-Regular.ttf
# - Poppins-Medium.ttf
# - Poppins-SemiBold.ttf
# - Poppins-Bold.ttf
```

### 6. Run the App

```powershell
# Check for connected devices
flutter devices

# Run on connected device/emulator
flutter run

# Or run in debug mode with verbose logging
flutter run -v
```

### 7. Test Offline Functionality

1. **Create Data Offline**:
   - Turn off internet
   - Add a task or diary entry
   - Data should save to local DB

2. **Turn On Internet**:
   - Wait 30 seconds (or manually trigger sync)
   - Data should sync to Firebase

3. **Verify in Firebase Console**:
   - Check Firestore → `tasks` collection
   - Your task should appear

### 8. Firebase Security Rules

Update Firestore rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Fields
    match /fields/{fieldId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
    
    // Tasks
    match /tasks/{taskId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
    
    // Diary
    match /diary/{entryId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
    
    // Posts (Community)
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update: if request.auth.uid == resource.data.userId;
      allow delete: if request.auth.uid == resource.data.userId;
    }
    
    // Comments
    match /comments/{commentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
    
    // Schemes (Read-only)
    match /schemes/{schemeId} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
    
    // Market Prices (Read-only for users)
    match /prices/{priceId} {
      allow read: if request.auth != null;
      allow write: if false; // Updated by Cloud Function
    }
  }
}
```

Storage rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId 
                   && request.resource.size < 5 * 1024 * 1024  // 5MB limit
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## Common Issues & Solutions

### Issue: Build Runner Fails
```powershell
# Clear cache and rebuild
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Firebase Not Initialized
```dart
// Make sure main() has:
await Firebase.initializeApp();
```

### Issue: Phone Auth Not Working (Android)
1. Enable Phone Authentication in Firebase Console
2. Add SHA-1 fingerprint:
   ```powershell
   cd android
   ./gradlew signingReport
   # Copy SHA-1 and add to Firebase Console → Project Settings → Your App
   ```

### Issue: Drift Database Error
- Make sure you ran code generator
- Check for syntax errors in `app_database.dart`
- Verify all imports are correct

### Issue: Package Conflicts
```powershell
flutter pub upgrade
flutter pub outdated
```

## Development Workflow

### 1. Feature Development
```dart
// 1. Add table to app_database.dart (if needed)
// 2. Run code generator
flutter pub run build_runner build --delete-conflicting-outputs

// 3. Create repository
// 4. Create provider
// 5. Build UI
// 6. Test offline functionality
```

### 2. Testing Sync
```powershell
# Use Android Studio Device File Explorer
# Navigate to: /data/data/com.agrosense.app/databases/
# View agrosense.db with SQLite viewer
```

### 3. Debugging
```dart
// Use AppLogger everywhere
AppLogger.info('User logged in: $userId');
AppLogger.error('Sync failed', error, stackTrace);

// Check logs
flutter logs
```

## Next Development Tasks

### Priority 1: Complete Authentication
- [ ] Implement OTP verification screen
- [ ] Test phone auth flow end-to-end
- [ ] Add Google Sign-In
- [ ] Handle auth errors gracefully

### Priority 2: Implement GIS
- [ ] Add flutter_map to field screen
- [ ] Implement polygon drawing
- [ ] Calculate area with turf_dart
- [ ] Test field creation offline

### Priority 3: Weather Integration
- [ ] Create weather repository
- [ ] Fetch from Open-Meteo API
- [ ] Cache weather data
- [ ] Generate AI advisory with Gemini

### Priority 4: Market Prices
- [ ] Integrate eNAM API (or mock data)
- [ ] Display price charts
- [ ] Cache prices locally

### Priority 5: AI Assistant
- [ ] Build chat UI
- [ ] Integrate Gemini API
- [ ] Add voice input (optional)
- [ ] Context-aware responses

## Production Checklist

Before releasing:
- [ ] Remove debug API keys
- [ ] Use environment variables for secrets
- [ ] Enable ProGuard/R8 (Android)
- [ ] Test on physical devices
- [ ] Test offline scenarios thoroughly
- [ ] Add crash reporting (Firebase Crashlytics)
- [ ] Add analytics
- [ ] Create privacy policy
- [ ] Create terms of service
- [ ] Prepare app store assets
- [ ] Test background sync on battery saver mode

## Useful Commands

```powershell
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run code generator
flutter pub run build_runner watch

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Check for updates
flutter pub outdated

# Analyze code
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test
```

## Resources

- **Architecture Doc**: `ARCHITECTURE.md`
- **Checklist**: `CHECKLIST.md`
- **Flutter Docs**: https://flutter.dev/docs
- **Drift Docs**: https://drift.simonbinder.eu
- **Firebase Docs**: https://firebase.google.com/docs/flutter
- **Gemini API**: https://ai.google.dev/tutorials/dart_quickstart

## Support

For issues or questions:
1. Check `ARCHITECTURE.md` for detailed implementation guides
2. Review `CHECKLIST.md` for feature status
3. Check Flutter/Firebase documentation
4. Review code comments in source files

---

**Happy Coding! 🌾🚜**
