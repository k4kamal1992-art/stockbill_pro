# StockBill Pro - Production Build Guide

## 1. Android Build Setup

### 1.1 Create Keystore (Run once)
```bash
cd android/app
keytool -genkey -v -keystore stockbill_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias stockbill
```
When prompted:
- Keystore password: `stockbill123` (change in production!)
- Key password: `stockbill123` (change in production!)
- Name: Your name
- Organization: Your company

### 1.2 Update android/app/build.gradle

Replace the contents with:

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0.0'
}

android {
    namespace "com.stockbillpro.app"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.stockbillpro.app"
        minSdkVersion 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    signingConfigs {
        release {
            keyAlias 'stockbill'
            keyPassword 'stockbill123'
            storeFile file('stockbill_keystore.jks')
            storePassword 'stockbill123'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

flutter {
    source '../..'
}
```

### 1.3 Create android/app/proguard-rules.pro

```proguard
# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# JSON Serialization
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# SQLite
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.* { *; }

# Share Plus
-dontwarn com.google.android.gms.common.**
-dontwarn android.support.v4.**

# URL Launcher
-keep class androidx.core.app.** { *; }

# Mobile Scanner / Camera
-keep class io.github.edufolly.fluttermobilevision.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Bluetooth Print
-keep class com.gprinter.** { *; }
-keep class com.ctk.** { *; }

# Prevent obfuscation of model classes
-keep class com.stockbillpro.data.models.** { *; }
-keepclassmembers class com.stockbillpro.data.models.** { *; }

# General
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
```

### 1.4 Update AndroidManifest.xml

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
    <!-- Bluetooth permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

    <!-- Camera for barcode scanning -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Storage for backup -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

    <!-- Internet for WhatsApp sharing -->
    <uses-permission android:name="android.permission.INTERNET" />
```

## 2. App Icons & Splash Screen

### 2.1 Add Icon Assets

Place these files in `assets/icon/`:
- `app_icon.png` (1024x1024)
- `app_icon_foreground.png` (1024x1024, transparent bg)
- `brand.png` (600x200, for splash)

### 2.2 Generate Icons

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create
```

## 3. Build Release APK / AppBundle

### 3.1 Build APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### 3.2 Build AppBundle (Recommended for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

## 4. Play Store Submission Checklist

- [ ] Create Google Play Developer account ($25 one-time)
- [ ] Generate signed AppBundle
- [ ] App icon (512x512 PNG) for Play Console
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (phone + tablet)
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars)
- [ ] Privacy policy URL
- [ ] Content rating questionnaire
- [ ] Set countries to distribute
- [ ] Set pricing (free)

## 5. Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
# format: versionName+versionCode
# 1.0.0+2 for next release
```

## 6. Pre-Release Testing

```bash
# Run all tests
flutter test

# Install on device
flutter install

# Run in profile mode
flutter run --profile
```
