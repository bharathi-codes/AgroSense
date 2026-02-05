# Supabase Migration Guide

## Overview
Firebase has been replaced with Supabase as the backend service for AgroSense.

## Changes Made

### 1. Dependencies Updated
- ✅ **Removed**: All Firebase packages (firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging)
- ✅ **Added**: `supabase_flutter: ^2.0.0`

### 2. Configuration Updates
- ✅ **README.md**: Updated architecture and setup instructions for Supabase
- ✅ **Gemini API Key**: Updated to `AIzaSyA14cixMyJbGXYn5mAcOoBySlq-BIRXtGI`
- ✅ **app_constants.dart**: Added Supabase URL and anon key placeholders
- ✅ **main.dart**: Replaced Firebase.initializeApp() with Supabase.initialize()
- ✅ **repository_providers.dart**: Replaced Firebase providers with Supabase client

### 3. Authentication Updates
- ✅ **AuthRepository**: Updated constructor to use SupabaseClient instead of FirebaseAuth
- ✅ **getCurrentUserId()**: Modified to check Supabase auth first, then fallback to demo login

## Required Setup Steps

### 1. Create Supabase Project
1. Go to https://supabase.com
2. Create a new project
3. Wait for project to be provisioned (takes ~2 minutes)

### 2. Get Your Credentials
From your Supabase project dashboard:
1. Go to **Settings** → **API**
2. Copy **Project URL** (looks like: `https://xxxxx.supabase.co`)
3. Copy **anon/public** key (starts with `eyJ...`)

### 3. Update Configuration
In `lib/core/constants/app_constants.dart`:
```dart
static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
```

### 4. Setup Database Schema
In Supabase SQL Editor, run:
```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone_number TEXT UNIQUE,
  email TEXT UNIQUE,
  name TEXT NOT NULL,
  photo_url TEXT,
  language TEXT DEFAULT 'en',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Fields table
CREATE TABLE fields (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  area REAL,
  coordinates JSONB,
  soil_type TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tasks table
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  field_id UUID REFERENCES fields(id),
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  is_completed BOOLEAN DEFAULT FALSE,
  priority TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Posts table (Community)
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  user_name TEXT NOT NULL,
  user_photo_url TEXT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  images JSONB,
  likes INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Policies (adjust as needed)
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view own fields" ON fields FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own fields" ON fields FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view all posts" ON posts FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can create posts" ON posts FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
```

### 5. Setup Storage
1. In Supabase Dashboard: **Storage** → **Create Bucket**
2. Create buckets:
   - `avatars` (for user profile photos)
   - `field-images` (for field photos)
   - `crop-images` (for crop photos)
   - `diary-images` (for diary entries)

## Remaining Implementation Tasks

### High Priority
1. **Phone OTP Authentication** - Implement Supabase phone auth in auth_repository.dart
   - Replace Firebase verifyPhoneNumber with Supabase.auth.signInWithOtp()
   - Update verifyOTP to use Supabase.auth.verifyOTP()

2. **Google Sign-In** - Update Google OAuth flow
   - Use Supabase.auth.signInWithIdToken() instead of Firebase

3. **Cloud Sync** - Replace Firestore calls with Supabase PostgreSQL
   - Update FieldRepository to sync with Supabase
   - Update TaskRepository to sync with Supabase
   - Update CommunityRepository to sync with Supabase
   - Update DiaryRepository to sync with Supabase

4. **Storage** - Replace Firebase Storage with Supabase Storage
   - Update image upload/download methods
   - Use Supabase.storage.from('bucket-name').upload()

5. **Real-time** - Implement Supabase Realtime
   - Subscribe to table changes for community posts
   - Real-time task updates

### Medium Priority
6. **Push Notifications** - Replace Firebase Messaging
   - Use Supabase Edge Functions or third-party service (OneSignal, FCM direct)

7. **Edge Functions** - Create Supabase Edge Functions
   - Weather advisory generator
   - Market price analyzer
   - Crop recommendation engine

### Low Priority
8. **Analytics** - Replace Firebase Analytics
   - Use Supabase + PostHog or Mixpanel

9. **Crash Reporting** - Replace Firebase Crashlytics
   - Use Sentry or similar service

## Current Status

### Working Features ✅
- Simple login with demo credentials (9786820364 / 54123)
- Offline-first local database (Drift/SQLite)
- All UI screens (Dashboard, Fields, Tasks, Weather, Market, etc.)
- Adaptive planning algorithm
- AI assistant with Gemini
- GIS field management (local)
- All offline features

### Needs Implementation ⚠️
- Phone OTP with Supabase
- Google Sign-In with Supabase
- Cloud data sync
- Image upload to Supabase Storage
- Real-time features
- Push notifications

## Testing the App

The app currently works in **offline mode** with the simple login:
1. Run: `flutter run -d YOUR_DEVICE`
2. Login with: **9786820364** / OTP: **54123**
3. All features work locally without cloud sync

## Migration Benefits

### Why Supabase > Firebase
1. **Open Source** - No vendor lock-in
2. **PostgreSQL** - Real SQL database with relations, views, functions
3. **Cost** - More generous free tier (500MB database vs 1GB Firestore)
4. **Developer Experience** - Better API, SQL editor, real-time dashboard
5. **Real-time** - Built-in with PostgreSQL logical replication
6. **Storage** - Integrated with buckets and RLS policies
7. **Edge Functions** - Deno-based, faster cold starts
8. **Self-hosting Option** - Can deploy on your own infrastructure

## Next Steps
1. Set up your Supabase project
2. Update the configuration constants
3. Implement phone authentication
4. Implement cloud sync for fields and tasks
5. Test end-to-end with real device

## Resources
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Supabase Auth with Flutter](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase Database](https://supabase.com/docs/guides/database)
- [Supabase Storage](https://supabase.com/docs/guides/storage)
