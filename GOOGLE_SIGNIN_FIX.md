# Google Sign-In Error Fix (Code 10)

## Problem
Google Sign-In fails with error:
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10:, null, null)
```

This error (code 10) means **API_NOT_CONNECTED** - the OAuth client ID for Android is not configured in Firebase.

## Root Cause
Your `google-services.json` only has a Web client ID (client_type: 3) but is missing the Android OAuth client ID (client_type: 1).

## Solution Steps

### Step 1: Get Your SHA-1 Fingerprint

#### Option A: Using Flutter (Recommended)
```powershell
flutter pub get
cd android
gradlew signingReport
```

Look for the **debug** variant SHA1 fingerprint. It will look like:
```
SHA1: 1A:2B:3C:4D:5E:6F:7A:8B:9C:0D:1E:2F:3A:4B:5C:6D:7E:8F:9A:0B
```

#### Option B: Using keytool (if Flutter method doesn't work)
```powershell
# For Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### Option C: Get SHA-1 from another source
If you already have the debug.keystore, the SHA-1 is typically located at:
- Windows: `C:\Users\YourUsername\.android\debug.keystore`
- Mac/Linux: `~/.android/debug.keystore`

**Default debug keystore password**: `android`

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **agrosense-228d8**
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Find your Android app: `com.agrosense.app`
6. Click **Add fingerprint**
7. Paste your SHA-1 fingerprint
8. Click **Save**

### Step 3: Download Updated google-services.json

1. In Firebase Console, after adding SHA-1
2. Click **Download google-services.json**
3. Replace the file at: `android/app/google-services.json`

The new file should have **TWO** oauth_client entries:
```json
"oauth_client": [
  {
    "client_id": "YOUR-PROJECT-ID.apps.googleusercontent.com",
    "client_type": 1  // <-- Android client (REQUIRED for sign-in)
  },
  {
    "client_id": "YOUR-PROJECT-ID.apps.googleusercontent.com",
    "client_type": 3  // <-- Web client
  }
]
```

### Step 4: Clean and Rebuild

```powershell
# Clean build
flutter clean
flutter pub get

# Rebuild
flutter build apk --debug

# Or run directly
flutter run -d RZCY80DXBTJ
```

## Alternative Fix: Add OAuth Client Manually in Google Cloud Console

If Firebase Console doesn't automatically create the Android OAuth client:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **agrosense-228d8**
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. Select **Android** as application type
6. Enter:
   - **Name**: `AgroSense Android Client`
   - **Package name**: `com.agrosense.app`
   - **SHA-1 certificate fingerprint**: [Your SHA-1 from Step 1]
7. Click **Create**
8. Download updated `google-services.json` from Firebase

## Verification

After completing the steps above, test Google Sign-In:

1. Run the app: `flutter run -d RZCY80DXBTJ`
2. Click "Continue with Google"
3. Select your Google account
4. Should successfully navigate to Dashboard

## Common Issues

### Issue: Still getting error after adding SHA-1
**Solution**: Wait 5-10 minutes for Firebase/Google Cloud changes to propagate, then:
```powershell
flutter clean
flutter pub get
flutter run
```

### Issue: Multiple Google accounts but can't sign in with any
**Solution**: 
1. Clear app data on device
2. Uninstall app
3. Reinstall: `flutter run -d RZCY80DXBTJ`

### Issue: Works in debug but not in release
**Solution**: You need to add SHA-1 for **release keystore** too:
```powershell
keytool -list -v -keystore path/to/your/release.keystore -alias your-alias
```

## Quick Command Reference

```powershell
# Get SHA-1 (Windows)
cd E:\IISF\AgroSenseFarmingAPP\android
.\gradlew.bat signingReport

# Clean rebuild
cd E:\IISF\AgroSenseFarmingAPP
flutter clean
flutter pub get
flutter run -d RZCY80DXBTJ

# Check device
flutter devices
```

## Current Configuration

**Package Name**: `com.agrosense.app`
**Firebase Project**: `agrosense-228d8`
**Current Web Client ID**: `180177908800-sho980dj6t7b4lf3fh4741janr6rv82r.apps.googleusercontent.com`

**Missing**: Android OAuth Client ID (client_type: 1)

---

**Status**: ⚠️ Requires manual Firebase Console configuration to add SHA-1 fingerprint and download updated google-services.json
