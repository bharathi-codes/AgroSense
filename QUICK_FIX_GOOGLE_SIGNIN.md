# Quick Fix: Google Sign-In Error Code 10

## Problem
Error: `ApiException: 10` when signing in with Google

## Root Cause
Missing Android OAuth Client ID in Firebase - SHA-1 fingerprint not added

## Quick Fix (3 Steps)

### 1️⃣ Get SHA-1 Fingerprint
```powershell
cd E:\IISF\AgroSenseFarmingAPP\android
.\gradlew.bat signingReport
```

Copy the **SHA1** from the **debug** section (looks like: `AB:CD:EF:12:34:...`)

### 2️⃣ Add to Firebase Console
1. Go to: https://console.firebase.google.com/project/agrosense-228d8/settings/general
2. Scroll to "Your apps" → Find Android app `com.agrosense.app`
3. Click "Add fingerprint"
4. Paste your SHA-1
5. Click "Save"
6. **Download new google-services.json**
7. Replace file: `android/app/google-services.json`

### 3️⃣ Rebuild App
```powershell
cd E:\IISF\AgroSenseFarmingAPP
flutter clean
flutter pub get
flutter run -d RZCY80DXBTJ
```

## Temporary Workaround
Use **Developer Login** button (visible on login screen) to bypass Google Sign-In and test the app.

## Verify Fix
The new `google-services.json` should have **TWO** oauth_client entries:
- client_type: 1 (Android) ← **This is what's missing**
- client_type: 3 (Web) ← Already exists

## Help
See `GOOGLE_SIGNIN_FIX.md` for detailed instructions.
