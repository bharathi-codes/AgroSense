# AgroSense - Implementation Checklist

## Phase 1: Core Setup ✓

- [x] Project structure created
- [x] pubspec.yaml with all dependencies
- [x] Core constants and theme
- [x] Error handling (failures & exceptions)
- [x] Logger utility
- [x] **Firebase configured with FlutterFire CLI** ✨
- [x] **Android build files created** ✨
- [x] **Drift code generated** ✨

## Phase 2: Offline-First Database ✓

- [x] Drift database schema with 11 tables:
  - [x] Users
  - [x] Fields
  - [x] Tasks
  - [x] DiaryEntries
  - [x] WeatherCache
  - [x] MarketPrices
  - [x] Posts
  - [x] Comments
  - [x] Schemes
  - [x] ChatMessages
  - [x] SyncQueue
- [x] Database CRUD operations
- [x] Sync tracking (isSynced flags)

## Phase 3: Sync Engine ✓

- [x] SyncService implementation
- [x] Bidirectional sync logic
- [x] Conflict resolution (last-write-wins)
- [x] Background sync manager with WorkManager
- [x] Sync queue for retry mechanism

## Phase 4: UI Screens

### Completed ✓
- [x] Splash screen
- [x] Language selection screen
- [x] Phone auth screen (with Google Sign-In and Developer Login)
- [x] Dashboard screen (main UI)
- [x] Today Tasks screen (Full CRUD with weather prioritization)

### To Implement
- [ ] OTP verification screen
- [ ] Map setup screen (GIS)
- [ ] Weather screen
- [ ] Market prices screen
- [ ] Tasks calendar screen
- [ ] Diary list & entry screens
- [ ] Community feed screen
- [ ] AI chat screen
- [ ] Government schemes screen
- [ ] Profile screen
- [ ] Settings screen

## Phase 5: Repositories (Data Layer)

- [ ] AuthRepository (Firebase Auth)
- [ ] FieldRepository (GIS data)
- [ ] TaskRepository (CRUD + auto-generation)
- [ ] WeatherRepository (Open-Meteo API)
- [ ] MarketRepository (eNAM API)
- [ ] DiaryRepository (Entries + photos)
- [ ] CommunityRepository (Posts + comments)
- [ ] AIRepository (Gemini API)
- [ ] SchemesRepository (Eligibility logic)

## Phase 6: State Management (Riverpod) ✓

**Decision: Using existing StreamProviders from `repository_providers.dart`**

- [x] Auth providers (currentUserIdProvider, isLoggedInProvider)
- [x] User profile provider (via authRepositoryProvider)
- [x] Fields state provider (userFieldsProvider - StreamProvider)
- [x] Tasks state provider (userTasksProvider - StreamProvider)
- [x] Weather state provider (weatherRepositoryProvider)
- [x] Market prices provider (marketPricesProvider - StreamProvider)
- [x] Community posts provider (communityPostsProvider - StreamProvider)
- [x] AI chat provider (aiRepositoryProvider)

**Note:** All providers are StreamProvider or FutureProvider based, working with existing repository layer. Full StateNotifier implementation deferred to future phase when CRUD operations are needed in UI.

## Phase 7: Features Implementation

### 1. Authentication ✓ (Partially)
- [x] Phone auth UI
- [ ] OTP verification
- [ ] Google Sign-In flow
- [ ] User profile creation
- [ ] Secure token storage

### 2. GIS & Land Management
- [ ] flutter_map integration
- [ ] Polygon drawing tool
- [ ] Area calculation with turf_dart
- [ ] Save field coordinates
- [ ] Multiple field support
- [ ] Field editing/deletion

### 3. Weather System
- [ ] Open-Meteo API integration
- [ ] Weather data caching
- [ ] Gemini AI advisory generation
- [ ] Weather widgets on dashboard
- [ ] 7-day forecast
- [ ] Weather-based task suggestions

### 4. Market Intelligence
- [ ] eNAM API integration
- [ ] Commodity price fetching
- [ ] Price trend charts (fl_chart)
- [ ] Price alerts
- [ ] Nearby market finder

### 5. Crop Management & Tasks
- [ ] Calendar UI (table_calendar)
- [ ] Task CRUD operations
- [ ] Auto-task generation by crop type
- [ ] Task categories (watering, fertilizing, etc.)
- [ ] Local notifications
- [ ] Task completion tracking

### 6. Recommendation Engine
- [ ] Soil data input
- [ ] Gemini API prompt engineering
- [ ] Fertilizer recommendations
- [ ] Watering schedule
- [ ] Pest control advice
- [ ] Yield predictions

### 7. Farm Diary & Finance
- [ ] Diary entry CRUD
- [ ] Image upload (Firebase Storage)
- [ ] Offline image caching
- [ ] Category filtering
- [ ] Income/Expense tracking
- [ ] Financial dashboard with charts

### 8. Community Forum
- [ ] Post creation UI
- [ ] Image uploads in posts
- [ ] Upvote/Downvote system
- [ ] Comment threads
- [ ] Post caching (last 20)
- [ ] Search and filtering

### 9. AI Assistant (AgroBot)
- [ ] Chat interface
- [ ] Voice input (STT)
- [ ] Text-to-Speech (TTS)
- [ ] Context-aware prompts
- [ ] Chat history
- [ ] Multilingual support

### 10. Government Schemes
- [ ] Schemes list from Firestore
- [ ] Eligibility checker
- [ ] Apply now (external link)
- [ ] Multilingual scheme data
- [ ] Offline scheme caching

## Phase 8: Integration & Polish

- [ ] Background sync testing
- [ ] Offline mode testing
- [ ] Network transition handling
- [ ] Loading states
- [ ] Error states
- [ ] Empty states
- [ ] Pull-to-refresh
- [ ] Pagination
- [ ] Search functionality
- [ ] Image compression
- [ ] Performance optimization

## Phase 9: Localization

- [x] English translations
- [x] Hindi translations
- [x] Tamil translations
- [ ] Telugu translations (complete)
- [ ] Malayalam translations (complete)
- [ ] Dynamic language switching
- [ ] RTL support (if needed)

## Phase 10: Testing

- [ ] Unit tests for repositories
- [ ] Unit tests for sync service
- [ ] Widget tests for screens
- [ ] Integration tests
- [ ] Offline functionality tests
- [ ] Background sync tests

## Phase 11: Firebase Configuration

- [ ] Firebase project setup
- [ ] Android google-services.json
- [ ] iOS GoogleService-Info.plist
- [ ] Firestore security rules
- [ ] Storage security rules
- [ ] Cloud Functions (if needed)
- [ ] Firebase Messaging setup

## Phase 12: Deployment

- [ ] Android release build config
- [ ] iOS release build config
- [ ] App icons
- [ ] Splash screen assets
- [ ] Play Store listing
- [ ] App Store listing
- [ ] Privacy policy
- [ ] Terms of service

## Next Immediate Steps

1. **Run Code Generator**:
   ```powershell
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Configure Firebase**:
   - Create Firebase project
   - Add Android/iOS apps
   - Download config files

3. **Get API Keys**:
   - Gemini API key
   - eNAM API key (if using)

4. **Implement Priority Screens**:
   - OTP verification
   - Map setup (GIS)
   - Weather screen

5. **Test Offline-First**:
   - Create field offline
   - Turn on internet
   - Verify sync

## Known Issues / Notes

- Crop disease detection (Scan Crop) is UI-only placeholder (ML not implemented)
- Need to add actual logo image (currently using icon)
- Font files (Poppins) need to be added to assets/fonts/
- Some translation files incomplete (Telugu, Malayalam need more phrases)
- Background sync requires proper user session management
- Image upload to Firebase Storage needs compression

## Resources Needed

- [ ] App logo (AI-generated as mentioned)
- [ ] Font files (Poppins)
- [ ] Lottie animation files
- [ ] Icon assets
- [ ] Sample crop images
- [ ] Firebase config files
- [ ] API keys
