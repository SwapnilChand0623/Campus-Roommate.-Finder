# 📱 APK Distribution Guide - Campus Roommate Finder

## 🔨 How to Build & Distribute the APK

### **1. Build Release APK**

#### **Option A: Standard Release Build**
```bash
# Navigate to project directory
cd /Users/swapnilchand/campus_roommate_finder

# Build release APK
flutter build apk --release
```

**Output Location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

#### **Option B: Split APKs by Architecture (Smaller File Size)**
```bash
# Build separate APKs for different CPU architectures
flutter build apk --split-per-abi
```

**Output Files:**
```
build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk   (~25 MB) - 32-bit ARM devices
├── app-arm64-v8a-release.apk     (~28 MB) - 64-bit ARM devices (most modern)
└── app-x86_64-release.apk        (~30 MB) - x86 devices (rare)
```

**Recommendation:** Use `app-arm64-v8a-release.apk` for most modern Android devices.

---

## 📲 How Users Install the APK

### **Step 1: Transfer APK to Device**

**Methods:**
1. **USB Transfer** - Copy APK to phone via USB cable
2. **Cloud Storage** - Upload to Google Drive/Dropbox, download on phone
3. **Messaging App** - Send via WhatsApp/Telegram to themselves
4. **Direct Link** - Host on web server, share download link
5. **ADB Install** - `adb install app-release.apk` (for developers)

### **Step 2: Enable "Install from Unknown Sources"**

Since this isn't from Google Play Store, users must enable installation:

**Android 8.0+ (Oreo and newer):**
1. User taps the APK file
2. Android shows: **"For your security, your phone is not allowed to install unknown apps from this source"**
3. User taps **"Settings"**
4. Toggle on **"Allow from this source"**
5. Go back and tap APK again

**Android 7.1 and older:**
1. Go to **Settings** → **Security**
2. Enable **"Unknown sources"**
3. Confirm the warning dialog

### **Step 3: Installation Process**

1. **APK opens installer screen**
2. Shows app name: **"campus_roommate_finder"**
3. Shows app icon (your logo)
4. Lists **ALL PERMISSIONS** the app will use
5. User taps **"Install"**
6. Installation progress bar
7. **"App installed"** confirmation
8. Options: **Open** or **Done**

---

## 🔐 Permissions Your App Requests

Based on your packages and features, here are the permissions:

### **Automatically Added by Your Packages:**

#### 1. **INTERNET** (Required - Auto-approved)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
- **Why:** Supabase API calls, image loading, maps
- **User Sees:** ✅ "Full network access"
- **Runtime Permission:** ❌ No (auto-granted)

#### 2. **CAMERA** (Runtime Permission)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```
- **Why:** `image_picker` for taking photos (profile, listings)
- **User Sees:** 📸 "Take pictures and videos"
- **Runtime Permission:** ✅ Yes (asks when user taps camera)
- **Can Deny:** Yes (app works without it, can't take photos)

#### 3. **READ_EXTERNAL_STORAGE** (Runtime Permission)
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```
- **Why:** `image_picker` for selecting photos from gallery
- **User Sees:** 📁 "Photos and media" or "Files and media"
- **Runtime Permission:** ✅ Yes (asks when user taps gallery)
- **Can Deny:** Yes (can't upload photos from gallery)

#### 4. **WRITE_EXTERNAL_STORAGE** (May be added)
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```
- **Why:** Saving cached images (Android 9 and below)
- **User Sees:** 💾 "Modify or delete contents of storage"
- **Runtime Permission:** ✅ Yes (Android 6+)
- **Note:** Not needed on Android 10+ with scoped storage

#### 5. **ACCESS_NETWORK_STATE** (Auto-approved)
```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```
- **Why:** Check if device has internet connection
- **User Sees:** 🌐 "View network connections"
- **Runtime Permission:** ❌ No (auto-granted)

#### 6. **POST_NOTIFICATIONS** (Android 13+)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
- **Why:** `flutter_local_notifications` for match/message alerts
- **User Sees:** 🔔 "Send notifications"
- **Runtime Permission:** ✅ Yes (Android 13+)
- **Can Deny:** Yes (won't see notifications)

---

## 📋 Installation Screen - What Users See

### **Before Installation (Permission List):**

```
┌─────────────────────────────────────┐
│  Campus Roommate Finder             │
│  [App Icon]                         │
│                                     │
│  This app will have access to:     │
│                                     │
│  📸 Camera                          │
│     Take pictures and videos        │
│                                     │
│  📁 Photos and media                │
│     Read photos on your device      │
│                                     │
│  🌐 Network                         │
│     Full network access             │
│     View network connections        │
│                                     │
│  🔔 Notifications                   │
│     Send notifications              │
│                                     │
│  [ Cancel ]         [ Install ]     │
└─────────────────────────────────────┘
```

**Users cannot selectively approve/deny at install time.**  
They see ALL permissions and choose:
- **Install** - Grant all permissions
- **Cancel** - Don't install

### **After Installation (Runtime Permissions):**

When user tries to:

1. **Take a photo:**
   ```
   Allow Campus Roommate Finder to take pictures and record video?
   [While using the app] [Only this time] [Don't allow]
   ```

2. **Select from gallery:**
   ```
   Allow Campus Roommate Finder to access photos and media?
   [Allow] [Don't allow]
   ```

3. **Receive notifications (Android 13+):**
   ```
   Allow Campus Roommate Finder to send notifications?
   [Allow] [Don't allow]
   ```

---

## 🔒 Security Considerations

### **For You (Developer):**

1. **Signing the APK**
   - Debug APK: Signed with debug key (for testing only)
   - Release APK: Should be signed with your keystore
   - Generate keystore: `keytool -genkey -v -keystore my-release-key.jks`

2. **Code Obfuscation (Optional)**
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=build/debug-info
   ```
   Makes reverse engineering harder.

### **For Users:**

1. **"Unknown Sources" Warning**
   - Users will see security warnings
   - This is normal for non-Play Store apps
   - Explain this is expected in your distribution

2. **Google Play Protect**
   - May scan the APK
   - Usually passes if app is legitimate
   - Can submit APK for verification beforehand

---

## 📤 Distribution Methods

### **1. Direct Sharing (Best for Testing)**
- Send APK file via messaging apps
- Share via cloud storage links
- Good for: Friends, beta testers, small groups

### **2. Self-Hosted Download**
- Upload to your own web server
- Create download page: `yoursite.com/download/app.apk`
- Good for: Public distribution without Play Store

### **3. Third-Party App Stores**
- APKPure
- F-Droid (if open source)
- Amazon AppStore
- Good for: Wider distribution

### **4. Google Play Store (Recommended for Production)**
- Create Google Play Developer account ($25 one-time fee)
- Upload App Bundle (AAB), not APK
- Build with: `flutter build appbundle --release`
- Benefits: Automatic updates, Play Protect trust, larger audience

---

## 🚀 Best Practices

### **Before Distribution:**

1. **Test on Multiple Devices**
   ```bash
   flutter build apk --release
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Check App Size**
   - Target: < 50 MB for release APK
   - Use `--split-per-abi` to reduce size

3. **Update App Name**
   Edit `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <application
       android:label="Campus Roommate Finder"
   ```

4. **Verify Permissions**
   ```bash
   # After build, check what permissions are included
   aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
   ```

### **User Instructions (Include with APK):**

```
📱 How to Install Campus Roommate Finder

1. Download app-release.apk to your phone
2. Open the downloaded file
3. If prompted, tap "Settings" and enable "Install from unknown sources"
4. Tap "Install"
5. Grant permissions when prompted (Camera, Photos, Notifications)
6. Open the app and sign up!

Need help? Contact: [your email]
```

---

## 🐛 Common Issues

### **"App not installed" Error**
- **Cause:** Existing debug version conflicts
- **Fix:** Uninstall old version first: `adb uninstall com.example.campus_roommate_finder`

### **"App keeps crashing"**
- **Cause:** Missing Supabase credentials or network issues
- **Fix:** Ensure Supabase URL/keys are correct in `lib/config/supabase_config.dart`

### **"Parse error"**
- **Cause:** Corrupted APK download or incompatible device
- **Fix:** Re-download APK, check minimum Android version (API 21 / Android 5.0)

---

## 📊 APK Information

**Your Current App:**
- **Package Name:** `com.example.campus_roommate_finder`
- **Min Android Version:** API 21 (Android 5.0 Lollipop)
- **Target Android Version:** Latest (from Flutter SDK)
- **Expected APK Size:** ~40-50 MB (release build)
- **Architecture Support:** ARM 32-bit, ARM 64-bit, x86_64

---

## 🔄 App Updates

**Method 1: Manual Updates**
1. Build new APK with higher version code
2. Users download and install over existing app
3. User data is preserved

**Method 2: In-App Update Notification**
- Add version checking in app
- Show "Update Available" dialog
- Direct user to download new APK

**Method 3: Google Play Store**
- Automatic updates
- Users get notified automatically
- Recommended for production

---

## ✅ Pre-Release Checklist

Before sharing your APK:

- [ ] Change app name in `AndroidManifest.xml`
- [ ] Update `pubspec.yaml` version number
- [ ] Test on physical device (not just emulator)
- [ ] Verify all features work (camera, gallery, notifications)
- [ ] Check Supabase connection works
- [ ] Test with fresh install (no cached data)
- [ ] Build release APK: `flutter build apk --release`
- [ ] Test release APK installation
- [ ] Create user installation instructions
- [ ] Prepare privacy policy (required if personal data collected)

---

## 📞 Support

If users have issues:
1. Check Android version (must be 5.0+)
2. Verify internet connection
3. Clear app data: Settings → Apps → Campus Roommate Finder → Clear Data
4. Reinstall APK

---

**Last Updated:** November 24, 2025  
**App Version:** 1.0.0+1  
**Target Platform:** Android 5.0+ (API 21+)
