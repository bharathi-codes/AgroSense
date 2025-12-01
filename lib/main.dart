import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/language/language_selection_screen.dart';
import 'presentation/screens/auth/phone_auth_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/dashboard/farm_overview_screen.dart';
import 'presentation/screens/weather/weather_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/fields/fields_screen.dart';
import 'presentation/screens/community/community_screen.dart';
import 'presentation/screens/ai/ai_assistant_screen.dart';
import 'presentation/screens/market/market_screen.dart';
import 'presentation/screens/diary/diary_screen.dart';
import 'presentation/screens/schemes/schemes_screen.dart';
import 'presentation/screens/tasks/today_tasks_screen.dart';
import 'data/local/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Easy Localization
  await EasyLocalization.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Database
  final database = AppDatabase();
  
  runApp(
    ProviderScope(
      overrides: [
        // Provide database instance
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('ta'),
          Locale('hi'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const AgroSenseApp(),
      ),
    ),
  );
}

// Provider for database instance
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError();
});

class AgroSenseApp extends ConsumerWidget {
  const AgroSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          initialRoute: Routes.splash,
          routes: {
            Routes.splash: (context) => const SplashScreen(),
            Routes.languageSelection: (context) => const LanguageSelectionScreen(),
            Routes.phoneAuth: (context) => const PhoneAuthScreen(),
            Routes.dashboard: (context) => const DashboardScreen(),
            Routes.weather: (context) => const WeatherScreen(),
            Routes.settings: (context) => const SettingsScreen(),
            Routes.profile: (context) => const ProfileScreen(),
            Routes.fields: (context) => const FieldsScreen(),
            Routes.community: (context) => const CommunityScreen(),
            Routes.aiAssistant: (context) => const AiAssistantScreen(),
            Routes.market: (context) => const MarketScreen(),
            Routes.diary: (context) => const DiaryScreen(),
            Routes.schemes: (context) => const SchemesScreen(),
            Routes.todayTasks: (context) => const TodayTasksScreen(),
            Routes.upcomingTasks: (context) => const UpcomingTasksScreen(),
            Routes.farmOverview: (context) => const FarmOverviewScreen(),
          },
        );
      },
    );
  }
}
