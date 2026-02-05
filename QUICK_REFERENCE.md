# AgroSense - Quick Reference Guide

## 🚀 Quick Start (5 Minutes)

```powershell
# 1. Navigate to project
cd e:\IISF\AgroSenseFarmingAPP

# 2. Install dependencies
flutter pub get

# 3. Generate database code
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run app (will show error without Firebase config - normal!)
flutter run
```

---

## 📋 Essential Commands

### Development
```powershell
# Watch mode (auto-rebuild on changes)
flutter pub run build_runner watch

# Format code
dart format lib/

# Analyze code
flutter analyze

# Clean build
flutter clean ; flutter pub get
```

### Build
```powershell
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# Check size
flutter build apk --analyze-size
```

---

## 🗄️ Database Quick Reference

### Create Record
```dart
final task = TasksCompanion(
  id: Value('unique_id'),
  userId: Value('user_123'),
  title: Value('Water crops'),
  dueDate: Value(DateTime.now()),
  createdAt: Value(DateTime.now()),
  updatedAt: Value(DateTime.now()),
  isSynced: Value(false), // ← Mark for sync!
  isDeleted: Value(false),
);

await database.insertTask(task);
```

### Read Records
```dart
// Get all tasks for user
final tasks = await database.getTasksByUserId('user_123');

// Watch tasks (stream for real-time updates)
database.watchTasksByUserId('user_123').listen((tasks) {
  // UI updates automatically
});
```

### Update Record
```dart
await database.updateTask(
  TasksCompanion(
    id: Value(taskId),
    title: Value('New title'),
    updatedAt: Value(DateTime.now()),
    isSynced: Value(false), // ← Important!
  ),
);
```

### Delete Record (Soft)
```dart
await database.deleteTask(taskId);
// Sets isDeleted = true, isSynced = false
```

---

## 🔄 Sync Service Usage

### Manual Sync
```dart
final syncService = SyncService(
  localDb: database,
  firestore: FirebaseFirestore.instance,
  connectivity: Connectivity(),
);

await syncService.performSync('user_123');
```

### Check Sync Status
```dart
final isCurrentlySyncing = syncService.isSyncing;
final lastSync = syncService.lastSyncTime;
```

### Add to Sync Queue (Fallback)
```dart
await syncService.addToSyncQueue(
  tableName: 'tasks',
  recordId: 'task_123',
  operation: 'update',
  data: jsonEncode(taskData),
);
```

---

## 🎨 Theme Usage

### Colors
```dart
// Use predefined colors
Container(color: AppColors.primary)
Container(color: AppColors.secondary)
Container(color: AppColors.success)
Container(color: AppColors.error)
```

### Text Styles
```dart
Text('Hello', style: AppTextStyles.h1)
Text('Title', style: AppTextStyles.h2)
Text('Body', style: AppTextStyles.bodyLarge)
Text('Caption', style: AppTextStyles.caption)
```

### Buttons
```dart
// Elevated button (already styled)
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
)

// Outlined button
OutlinedButton(
  onPressed: () {},
  child: Text('Cancel'),
)
```

---

## 🔐 Authentication Quick Reference

### Phone Auth
```dart
// 1. Send OTP
final result = await authRepository.sendOTP('+919876543210');
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (verificationId) => print('OTP sent'),
);

// 2. Verify OTP
final result = await authRepository.verifyOTP(
  verificationId: verificationId,
  otp: '123456',
);
```

### Google Sign-In
```dart
final result = await authRepository.signInWithGoogle();
result.fold(
  (failure) => print('Error'),
  (user) => print('Signed in: ${user.displayName}'),
);
```

### Check Login Status
```dart
final isLoggedIn = await authRepository.isLoggedIn();
final userId = await authRepository.getCurrentUserId();
```

---

## 📝 Task Repository Usage

### Create Task
```dart
await taskRepository.createTask(
  userId: 'user_123',
  title: 'Water crops',
  description: 'Water field A',
  taskType: 'watering',
  dueDate: DateTime.now(),
  priority: 2, // 0=low, 1=medium, 2=high
);
```

### Auto-Generate Tasks
```dart
await taskRepository.generateCropTasks(
  userId: 'user_123',
  fieldId: 'field_456',
  cropType: 'Rice',
  plantingDate: DateTime.now(),
);
// Creates 7 tasks automatically!
```

### Complete Task
```dart
await taskRepository.completeTask('task_123');
```

### Watch Tasks (Real-time)
```dart
taskRepository.watchTasksByUserId('user_123').listen((result) {
  result.fold(
    (failure) => print('Error'),
    (tasks) => print('Tasks: ${tasks.length}'),
  );
});
```

---

## 🌐 Translations Usage

### In Dart Code
```dart
import 'package:easy_localization/easy_localization.dart';

Text('dashboard.home'.tr()) // Translated text
Text('common.save'.tr())
Text('tasks.add_task'.tr())
```

### Change Language
```dart
await context.setLocale(Locale('hi', 'IN')); // Hindi
await context.setLocale(Locale('ta', 'IN')); // Tamil
```

---

## 🐛 Error Handling Pattern

### Repository Methods
```dart
Future<Either<Failure, List<Task>>> getTasks() async {
  try {
    final tasks = await database.getTasks();
    return Right(tasks);
  } on DatabaseException catch (e) {
    return Left(DatabaseFailure(message: e.message));
  } catch (e) {
    return Left(GenericFailure(message: e.toString()));
  }
}
```

### UI Usage
```dart
final result = await repository.getTasks();
result.fold(
  (failure) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure.message)),
    );
  },
  (tasks) {
    // Use data
    setState(() => _tasks = tasks);
  },
);
```

---

## 📱 Screen Navigation

### Push Route
```dart
Navigator.of(context).pushNamed(Routes.dashboard);

Navigator.of(context).pushNamed(
  Routes.taskDetails,
  arguments: {'taskId': 'task_123'},
);
```

### Pop Route
```dart
Navigator.of(context).pop();
Navigator.of(context).pop(result); // With result
```

### Replace Route
```dart
Navigator.of(context).pushReplacementNamed(Routes.dashboard);
```

---

## 🔍 Logging

```dart
import '../../core/utils/logger.dart';

AppLogger.debug('Debug message');
AppLogger.info('User logged in: $userId');
AppLogger.warning('Network slow');
AppLogger.error('Sync failed', error, stackTrace);
```

---

## 🎯 Common Patterns

### Loading State
```dart
bool _isLoading = false;

void _loadData() async {
  setState(() => _isLoading = true);
  try {
    // Load data
  } finally {
    setState(() => _isLoading = false);
  }
}

// In UI
if (_isLoading)
  CircularProgressIndicator()
else
  DataWidget()
```

### Empty State
```dart
if (tasks.isEmpty)
  Center(
    child: Column(
      children: [
        Icon(Icons.inbox, size: 64),
        Text('No tasks yet'),
      ],
    ),
  )
else
  ListView(...)
```

### Error State
```dart
if (error != null)
  ErrorWidget(
    message: error.message,
    onRetry: () => _loadData(),
  )
else
  DataWidget()
```

---

## 🔔 Notifications Setup

### Schedule Local Notification
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final notifications = FlutterLocalNotificationsPlugin();

await notifications.show(
  0,
  'Task Reminder',
  'Time to water crops',
  NotificationDetails(
    android: AndroidNotificationDetails(
      'tasks',
      'Task Reminders',
      importance: Importance.high,
    ),
  ),
);
```

---

## 📊 Charts (fl_chart)

### Line Chart
```dart
import 'package:fl_chart/fl_chart.dart';

LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: [
          FlSpot(0, 1),
          FlSpot(1, 3),
          FlSpot(2, 2),
        ],
        color: AppColors.primary,
      ),
    ],
  ),
)
```

---

## 🗺️ Map (flutter_map)

### Basic Map
```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

FlutterMap(
  options: MapOptions(
    center: LatLng(11.0168, 76.9558), // Coimbatore
    zoom: 15.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
  ],
)
```

---

## 🤖 Gemini AI

### Basic Request
```dart
import 'package:google_generative_ai/google_generative_ai.dart';

final model = GenerativeModel(
  model: 'gemini-pro',
  apiKey: AppConstants.geminiApiKey,
);

final response = await model.generateContent([
  Content.text('What fertilizer is best for rice?'),
]);

print(response.text);
```

### With Context
```dart
final prompt = '''
User Location: Tamil Nadu, India
Soil Type: Clay
Crop: Rice
Season: Monsoon

Question: ${userQuestion}

Provide farming advice in simple language.
''';

final response = await model.generateContent([
  Content.text(prompt),
]);
```

---

## 🔧 Troubleshooting

### Build Errors
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Database Errors
```powershell
# Regenerate database
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Firebase Errors
1. Check `google-services.json` is in `android/app/`
2. Verify package name matches Firebase Console
3. Run: `flutter clean && flutter run`

### Sync Not Working
1. Check internet connectivity
2. Verify Firebase rules
3. Check logs: `flutter logs | grep Sync`
4. Look for unsynced records: `isSynced = false`

---

## 📚 Documentation Files

Quick access to docs:
- **ARCHITECTURE.md** - Detailed architecture
- **CHECKLIST.md** - Feature status
- **SETUP_GUIDE.md** - Setup instructions
- **PROJECT_SUMMARY.md** - High-level overview
- **PROJECT_STRUCTURE.md** - File structure
- **This file** - Quick reference

---

## 🎓 Best Practices

### Always Mark for Sync
```dart
// After any local change:
updatedAt: Value(DateTime.now()),
isSynced: Value(false), // ← Never forget this!
```

### Use Streams for Real-time UI
```dart
// Instead of:
final tasks = await database.getTasks();

// Use:
database.watchTasks().listen((tasks) {
  // UI updates automatically
});
```

### Handle Offline Gracefully
```dart
final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.none) {
  // Show offline banner
  // Still allow local operations!
}
```

### Log Everything Important
```dart
AppLogger.info('User action: Created task');
AppLogger.error('Failed to sync', error, stackTrace);
```

---

## 🚦 Workflow

### Feature Development Flow
1. Design database table (if needed)
2. Run build_runner
3. Create repository
4. Create provider (Riverpod)
5. Build UI screen
6. Test offline
7. Test sync

### Testing Sync Flow
1. Turn off internet
2. Create/update data
3. Verify in local DB (Device File Explorer)
4. Turn on internet
5. Wait or trigger manual sync
6. Verify in Firestore Console

---

## 💡 Pro Tips

1. **Use `isSynced` flag**: Critical for offline-first
2. **Soft delete**: Use `isDeleted` instead of hard delete
3. **Timestamps**: Always update `updatedAt` on changes
4. **Streams over Futures**: For real-time UI
5. **Either monad**: Consistent error handling
6. **Logger everywhere**: Makes debugging easy
7. **Test offline first**: Then online
8. **WorkManager**: Respects battery/network constraints

---

## 🔗 Quick Links

- **Firebase Console**: https://console.firebase.google.com/
- **Gemini API**: https://makersuite.google.com/app/apikey
- **Open-Meteo**: https://open-meteo.com/en/docs
- **Flutter Packages**: https://pub.dev/
- **Drift Docs**: https://drift.simonbinder.eu/

---

**Need more details? Check the comprehensive documentation files!** 📚
