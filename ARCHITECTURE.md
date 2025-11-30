# AgroSense - Complete Architecture Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Offline-First Architecture](#offline-first-architecture)
3. [Folder Structure](#folder-structure)
4. [Database Schema](#database-schema)
5. [Sync Service Logic](#sync-service-logic)
6. [Feature Implementation Guide](#feature-implementation-guide)
7. [API Integration](#api-integration)
8. [Setup & Configuration](#setup--configuration)

---

## Project Overview

**AgroSense** is a comprehensive smart farming assistant mobile application designed for Indian farmers. It implements a robust **offline-first architecture** ensuring farmers can use the app even in areas with poor internet connectivity.

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Riverpod**: State management
- **Drift (SQLite)**: Local database for offline storage
- **Firebase**: Cloud backend (Auth, Firestore, Storage, Functions)
- **WorkManager**: Background sync jobs
- **Gemini API**: AI-powered farming advice
- **flutter_map**: OpenStreetMap integration
- **turf_dart**: Geospatial calculations

---

## Offline-First Architecture

### Core Principle
**"Write Local, Sync Later"**

All user operations (create, read, update, delete) are performed on the local SQLite database first. The app then syncs with Firebase in the background when internet connectivity is available.

### Data Flow

```
User Action → Local DB (Drift) → UI Update
                    ↓
            [Background Sync Service]
                    ↓
          Cloud DB (Firestore) ← → Local DB
```

### Sync Strategy

1. **Immediate Local Write**
   - All CRUD operations write to Drift database immediately
   - UI updates instantly from local data
   - No waiting for network operations

2. **Background Sync**
   - WorkManager runs sync every 30 minutes
   - Only syncs when internet is available
   - Respects battery and charging constraints

3. **Conflict Resolution**
   - **Last-Write-Wins**: Timestamps determine which version is kept
   - Remote timestamp > Local timestamp → Pull remote data
   - Local unsync data → Push to cloud

4. **Sync Queue**
   - Failed sync operations are queued
   - Retried up to 3 times
   - Prevents data loss

---

## Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # App-wide constants
│   ├── error/
│   │   ├── failures.dart               # Failure types
│   │   └── exceptions.dart             # Exception classes
│   ├── theme/
│   │   └── app_theme.dart              # Colors, text styles, theme
│   └── utils/
│       └── logger.dart                 # Logging utility
│
├── data/
│   ├── local/
│   │   └── database/
│   │       └── app_database.dart       # Drift database schema
│   ├── services/
│   │   ├── sync_service.dart           # Core sync logic
│   │   └── background_sync_manager.dart # WorkManager setup
│   ├── repositories/
│   │   ├── auth_repository.dart        # Firebase Auth operations
│   │   ├── field_repository.dart       # Field data operations
│   │   ├── task_repository.dart        # Task CRUD operations
│   │   ├── weather_repository.dart     # Weather API integration
│   │   ├── market_repository.dart      # Market price data
│   │   └── ai_repository.dart          # Gemini API integration
│   └── models/
│       ├── user_model.dart
│       ├── field_model.dart
│       ├── task_model.dart
│       └── ...
│
├── domain/
│   ├── entities/                       # Business entities
│   └── usecases/                       # Business logic use cases
│
├── presentation/
│   ├── screens/
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── language/
│   │   │   └── language_selection_screen.dart
│   │   ├── auth/
│   │   │   ├── phone_auth_screen.dart
│   │   │   └── otp_verification_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart   # Main landing screen
│   │   ├── fields/
│   │   │   ├── fields_map_screen.dart  # GIS map view
│   │   │   └── add_field_screen.dart
│   │   ├── weather/
│   │   │   └── weather_screen.dart
│   │   ├── market/
│   │   │   └── market_prices_screen.dart
│   │   ├── tasks/
│   │   │   └── tasks_screen.dart
│   │   ├── diary/
│   │   │   ├── diary_list_screen.dart
│   │   │   └── diary_entry_screen.dart
│   │   ├── community/
│   │   │   ├── community_feed_screen.dart
│   │   │   └── post_details_screen.dart
│   │   ├── ai_assistant/
│   │   │   └── ai_chat_screen.dart
│   │   └── schemes/
│   │       └── schemes_screen.dart
│   ├── widgets/                        # Reusable widgets
│   └── providers/                      # Riverpod providers
│
└── main.dart                           # App entry point
```

---

## Database Schema

### Key Tables

#### 1. Users
- `id` (PK)
- `phoneNumber`
- `email`
- `name`
- `photoUrl`
- `language`
- `createdAt`
- `updatedAt`
- `isSynced` (Boolean flag)

#### 2. Fields (Land Parcels)
- `id` (PK)
- `userId` (FK)
- `name`
- `coordinates` (JSON polygon)
- `area` (in acres)
- `cropType`
- `soilType`
- `createdAt`
- `updatedAt`
- `isSynced`
- `isDeleted` (Soft delete)

#### 3. Tasks
- `id` (PK)
- `userId` (FK)
- `fieldId` (FK, nullable)
- `title`
- `description`
- `taskType` (watering, fertilizing, etc.)
- `dueDate`
- `isCompleted`
- `completedAt`
- `priority` (0=low, 1=medium, 2=high)
- `createdAt`
- `updatedAt`
- `isSynced`
- `isDeleted`

#### 4. DiaryEntries
- `id` (PK)
- `userId` (FK)
- `fieldId` (FK, nullable)
- `title`
- `content`
- `imagePaths` (JSON array)
- `category` (observation, expense, income, note)
- `amount` (for expense/income)
- `entryDate`
- `createdAt`
- `updatedAt`
- `isSynced`
- `isDeleted`

#### 5. WeatherCache
- `id` (PK)
- `latitude`
- `longitude`
- `weatherData` (JSON)
- `forecastDate`
- `aiSummary` (Gemini-generated)
- `cachedAt`
- `expiresAt`

#### 6. MarketPrices
- `id` (PK)
- `commodity`
- `market`
- `state`
- `minPrice`
- `maxPrice`
- `modalPrice`
- `priceDate`
- `cachedAt`
- `isSynced`

#### 7. Posts (Community)
- `id` (PK)
- `userId` (FK)
- `userName`
- `userPhotoUrl`
- `title`
- `content`
- `imageUrls` (JSON array)
- `upvotes`
- `commentsCount`
- `tags` (JSON array)
- `createdAt`
- `updatedAt`
- `isSynced`
- `isDeleted`

#### 8. SyncQueue
- `id` (PK, autoincrement)
- `tableName`
- `recordId`
- `operation` (insert, update, delete)
- `data` (JSON string)
- `createdAt`
- `retryCount`
- `status` (pending, processing, completed, failed)

---

## Sync Service Logic

### Implementation Details

Located in: `lib/data/services/sync_service.dart`

#### Main Sync Flow

```dart
Future<bool> performSync(String userId) async {
  // 1. Check internet connectivity
  final connectivity = await _connectivity.checkConnectivity();
  if (connectivity == ConnectivityResult.none) return false;
  
  // 2. Sync user profile
  await _syncUserProfile(userId);
  
  // 3. Sync fields (bidirectional)
  await _syncFields(userId);
  
  // 4. Sync tasks
  await _syncTasks(userId);
  
  // 5. Sync diary entries
  await _syncDiaryEntries(userId);
  
  // 6. Sync community posts
  await _syncPosts(userId);
  
  // 7. Process sync queue (retries)
  await _processSyncQueue();
  
  return true;
}
```

#### Bidirectional Sync Example (Fields)

```dart
Future<void> _syncFields(String userId) async {
  // PUSH: Upload unsynced local fields
  final unsyncedFields = await _localDb.getUnsyncedFields();
  for (final field in unsyncedFields) {
    if (field.isDeleted) {
      await _firestore.collection('fields').doc(field.id).delete();
    } else {
      await _firestore.collection('fields').doc(field.id).set({
        'userId': field.userId,
        'name': field.name,
        'coordinates': field.coordinates,
        'area': field.area,
        // ... other fields
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await _localDb.markAsSynced('fields', field.id);
  }
  
  // PULL: Download remote fields
  final remoteFields = await _firestore
      .collection('fields')
      .where('userId', isEqualTo: userId)
      .get();
  
  for (final doc in remoteFields.docs) {
    final data = doc.data();
    final remoteUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
    
    // Check local field
    final localField = await _localDb.getFieldById(doc.id);
    
    // Last-write-wins conflict resolution
    if (localField == null || remoteUpdatedAt.isAfter(localField.updatedAt)) {
      await _localDb.insertField(/* ... */);
    }
  }
}
```

#### Background Sync with WorkManager

```dart
// Initialize in main.dart
await BackgroundSyncManager.initialize();

// WorkManager callback (runs in separate isolate)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();
    final database = AppDatabase();
    final syncService = SyncService(/* ... */);
    return await syncService.performSync(userId);
  });
}
```

---

## Feature Implementation Guide

### 1. Authentication & Profile

**Files to Implement:**
- `lib/presentation/screens/auth/phone_auth_screen.dart` ✓ (Created)
- `lib/presentation/screens/auth/otp_verification_screen.dart` (TODO)
- `lib/data/repositories/auth_repository.dart` (TODO)

**Flow:**
1. User enters phone number
2. Firebase sends OTP
3. User verifies OTP
4. Create/Update user profile in Firestore
5. Store user session locally (flutter_secure_storage)

### 2. GIS & Land Management

**Files to Implement:**
- `lib/presentation/screens/fields/fields_map_screen.dart` (TODO)
- `lib/presentation/screens/fields/add_field_screen.dart` (TODO)
- `lib/data/repositories/field_repository.dart` (TODO)

**Dependencies:**
```yaml
flutter_map: ^6.1.0
latlong2: ^0.9.0
turf: ^0.0.9  # For area calculation
geolocator: ^10.1.0
```

**Implementation Steps:**
1. Display OpenStreetMap using `flutter_map`
2. Allow polygon drawing for field boundaries
3. Calculate area using `turf_dart` (turf.area())
4. Convert area to acres
5. Save coordinates as JSON string in local DB
6. Sync to Firestore collection `fields/{fieldId}`

### 3. Weather System

**Files to Implement:**
- `lib/presentation/screens/weather/weather_screen.dart` (TODO)
- `lib/data/repositories/weather_repository.dart` (TODO)

**API:** Open-Meteo (Free, no API key required)
- Endpoint: `https://api.open-meteo.com/v1/forecast`
- Parameters: `latitude`, `longitude`, `hourly`, `daily`

**Flow:**
1. Get user's field location (lat/lon)
2. Fetch weather data from Open-Meteo
3. Cache in `WeatherCache` table with 6-hour expiry
4. Send weather data to Gemini API for advisory:
   ```
   Prompt: "Based on this weather data: [JSON], 
            provide farming advice for [crop_type] in 2-3 sentences."
   ```
5. Display weather + AI advisory in UI

### 4. Market Intelligence

**Files to Implement:**
- `lib/presentation/screens/market/market_prices_screen.dart` (TODO)
- `lib/data/repositories/market_repository.dart` (TODO)

**API:** eNAM (Government of India)
- Endpoint: `https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070`
- Requires API key (free registration)

**Implementation:**
1. Fetch mandi prices by commodity
2. Cache in `MarketPrices` table
3. Display price trends using `fl_chart`
4. Allow users to set price alerts

### 5. Crop Management & Tasks

**Files to Implement:**
- `lib/presentation/screens/tasks/tasks_screen.dart` (TODO)
- `lib/presentation/screens/tasks/add_task_screen.dart` (TODO)
- `lib/data/repositories/task_repository.dart` (TODO)

**Features:**
- Calendar view (`table_calendar` package)
- Auto-generate tasks based on crop lifecycle
- Local notifications (`flutter_local_notifications`)
- Task categories: Watering, Fertilizing, Pest Control, Harvesting

**Example Task Generation:**
```dart
void generateCropTasks(String cropType, DateTime plantingDate) {
  if (cropType == 'Rice') {
    // Day 10: First watering
    // Day 15: Fertilizer application
    // Day 30: Pest control inspection
    // Day 120: Harvest
  }
}
```

### 6. Recommendation Engine

**Files to Implement:**
- `lib/data/repositories/ai_repository.dart` (TODO)
- `lib/presentation/screens/recommendations/recommendations_screen.dart` (TODO)

**Gemini API Integration:**
```dart
final model = GenerativeModel(
  model: 'gemini-pro',
  apiKey: AppConstants.geminiApiKey,
);

final prompt = '''
Soil Type: ${soilData.type}
pH: ${soilData.ph}
Crop: ${cropType}
Weather: ${weatherData.summary}

Provide recommendations for:
1. Fertilizer type and quantity
2. Watering schedule
3. Expected yield
''';

final response = await model.generateContent([Content.text(prompt)]);
```

### 7. Farm Diary & Finance

**Files to Implement:**
- `lib/presentation/screens/diary/diary_list_screen.dart` (TODO)
- `lib/presentation/screens/diary/diary_entry_screen.dart` (TODO)
- `lib/presentation/screens/finance/finance_dashboard_screen.dart` (TODO)

**Features:**
- CRUD operations for diary entries
- Categories: Observation, Expense, Income, Note
- Image upload to Firebase Storage (when online)
- Local image path storage (when offline)
- Dashboard with income vs. expense charts

### 8. Community Forum

**Files to Implement:**
- `lib/presentation/screens/community/community_feed_screen.dart` (TODO)
- `lib/presentation/screens/community/post_details_screen.dart` (TODO)
- `lib/data/repositories/community_repository.dart` (TODO)

**Features:**
- Create posts with text + images
- Upvote/Downvote system
- Comment threads
- Offline: Cache last 20 posts
- Tags for categorization

### 9. AI Assistant (AgroBot)

**Files to Implement:**
- `lib/presentation/screens/ai_assistant/ai_chat_screen.dart` (TODO)
- `lib/data/repositories/ai_repository.dart` (TODO)

**Features:**
- Chat interface
- Voice input (Offline STT using `speech_to_text`)
- Text-to-Speech output (`flutter_tts`)
- Context-aware responses (user's location, crops, current tasks)

**Gemini Prompt Template:**
```dart
final context = '''
User Location: ${userLocation}
Current Crops: ${userCrops.join(', ')}
Recent Tasks: ${recentTasks.join(', ')}
Weather: ${currentWeather}

User Question: ${userInput}

Provide a helpful farming-related answer in simple language.
If the question is not farming-related, politely redirect to farming topics.
''';
```

### 10. Government Schemes

**Files to Implement:**
- `lib/presentation/screens/schemes/schemes_screen.dart` (TODO)
- `lib/data/repositories/schemes_repository.dart` (TODO)

**Implementation:**
1. Store schemes in Firestore collection `schemes`
2. Each scheme has eligibility criteria (JSON):
   ```json
   {
     "minLandSize": 2,
     "cropTypes": ["Rice", "Wheat"],
     "stateRestrictions": ["Tamil Nadu", "Kerala"]
   }
   ```
3. Local eligibility check against user profile
4. "Apply Now" redirects to scheme website

---

## API Integration

### Gemini AI API

```dart
import 'package:google_generative_ai/google_generative_ai.dart';

final model = GenerativeModel(
  model: 'gemini-pro',
  apiKey: 'YOUR_GEMINI_API_KEY',
);

final response = await model.generateContent([
  Content.text('Your prompt here')
]);

print(response.text);
```

### Open-Meteo Weather API

```dart
final url = Uri.parse(
  'https://api.open-meteo.com/v1/forecast?'
  'latitude=$lat&longitude=$lon&'
  'daily=temperature_2m_max,temperature_2m_min,precipitation_sum&'
  'timezone=Asia/Kolkata'
);

final response = await http.get(url);
final data = jsonDecode(response.body);
```

---

## Setup & Configuration

### 1. Firebase Setup

**Android:**
1. Create Firebase project
2. Download `google-services.json`
3. Place in `android/app/`
4. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
5. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

**iOS:**
1. Download `GoogleService-Info.plist`
2. Place in `ios/Runner/`

**Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    match /fields/{fieldId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.userId;
    }
    
    match /tasks/{taskId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.userId;
    }
    
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### 2. Run Code Generation

```powershell
# Generate Drift database code
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch mode for development
flutter pub run build_runner watch
```

### 3. Initialize App

```powershell
# Get dependencies
flutter pub get

# Run app
flutter run
```

### 4. Environment Variables

Create `.env` file (add to .gitignore):
```
GEMINI_API_KEY=your_key_here
ENAM_API_KEY=your_key_here
```

Load in code:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load();
final geminiKey = dotenv.env['GEMINI_API_KEY'];
```

---

## Testing

### Unit Tests
```dart
test('Sync service pushes unsynced fields', () async {
  // Arrange
  final mockDb = MockAppDatabase();
  final syncService = SyncService(localDb: mockDb, /* ... */);
  
  // Act
  await syncService.performSync('user_123');
  
  // Assert
  verify(mockDb.getUnsyncedFields()).called(1);
});
```

### Widget Tests
```dart
testWidgets('Dashboard displays today tasks', (tester) async {
  await tester.pumpWidget(DashboardScreen());
  expect(find.text('Today\'s Tasks'), findsOneWidget);
});
```

---

## Deployment

### Android Release Build
```powershell
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS Release Build
```powershell
flutter build ios --release
```

---

## Next Steps

1. **Run Code Generator**: `flutter pub run build_runner build --delete-conflicting-outputs`
2. **Configure Firebase**: Add `google-services.json` and `GoogleService-Info.plist`
3. **Add API Keys**: Get Gemini API key and update `app_constants.dart`
4. **Implement Remaining Screens**: Weather, Market, AI Assistant, etc.
5. **Test Offline Functionality**: Turn off internet and verify CRUD operations
6. **Test Background Sync**: Use Android WorkManager debug tools

---

## Key Files to Review

1. **Database Schema**: `lib/data/local/database/app_database.dart` ✓
2. **Sync Service**: `lib/data/services/sync_service.dart` ✓
3. **Dashboard UI**: `lib/presentation/screens/dashboard/dashboard_screen.dart` ✓
4. **Main Entry**: `lib/main.dart` ✓
5. **Theme**: `lib/core/theme/app_theme.dart` ✓

---

## Support & Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Drift Documentation](https://drift.simonbinder.eu)
- [Firebase Flutter](https://firebase.google.com/docs/flutter/setup)
- [Gemini API](https://ai.google.dev/docs)
- [Open-Meteo API](https://open-meteo.com/en/docs)

---

**Note**: The compile errors shown during generation are expected since packages haven't been installed yet. Run `flutter pub get` to resolve dependencies.
