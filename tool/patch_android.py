#!/usr/bin/env python3
"""
Patch Android build files after `flutter create` generates them.
Adds required permissions and build configurations.
"""

import os
import sys

def patch_android_manifest():
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if not os.path.exists(manifest_path):
        print(f"Warning: {manifest_path} not found, skipping manifest patch")
        return

    with open(manifest_path, "r") as f:
        content = f.read()

    # Check if already patched
    if "android.permission.CAMERA" in content:
        print("AndroidManifest.xml already patched")
        return

    # Add permissions before the <application> tag
    permissions = """    <!-- Camera for barcode scanning -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />

    <!-- Bluetooth for thermal printer -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

    <!-- Storage for backup export/import -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <!-- Internet for WhatsApp sharing -->
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Query for WhatsApp -->
    <queries>
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />
        <intent>
            <action android:name="android.intent.action.SEND" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>

"""

    content = content.replace(
        "    <application",
        permissions + "    <application"
    )

    with open(manifest_path, "w") as f:
        f.write(content)

    print("AndroidManifest.xml patched successfully")

def patch_build_gradle():
    build_gradle = "android/app/build.gradle"
    if not os.path.exists(build_gradle):
        # Try .gradle.kts
        build_gradle = "android/app/build.gradle.kts"
        if not os.path.exists(build_gradle):
            print(f"Warning: app build.gradle not found, skipping build patch")
            return

    with open(build_gradle, "r") as f:
        content = f.read()

    # Check if already patched
    if "multiDexEnabled" in content:
        print("build.gradle already patched")
        return

    # Add multiDex and minSdk config
    content = content.replace(
        "minSdkVersion flutter.minSdkVersion",
        "minSdkVersion 21"
    )
    content = content.replace(
        "minSdk = flutter.minSdkVersion",
        "minSdk = 21"
    )

    # Add multiDexEnabled in defaultConfig
    if "multiDexEnabled" not in content:
        content = content.replace(
            "targetSdk = flutter.targetSdkVersion",
            "targetSdk = flutter.targetSdkVersion
        multiDexEnabled = true"
        )
        content = content.replace(
            "targetSdkVersion flutter.targetSdkVersion",
            "targetSdkVersion flutter.targetSdkVersion
        multiDexEnabled true"
        )

    with open(build_gradle, "w") as f:
        f.write(content)

    print("build.gradle patched successfully")

def patch_proguard():
    proguard_path = "android/app/proguard-rules.pro"
    if os.path.exists(proguard_path):
        print("proguard-rules.pro already exists")
        return

    proguard_rules = """# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# JSON
-keepclassmembers class ** { @com.google.gson.annotations.SerializedName <fields>; }

# SQLite
-keep class net.sqlcipher.** { *; }

# Share Plus
-dontwarn com.google.android.gms.common.**
-dontwarn android.support.v4.**

# URL Launcher
-keep class androidx.core.app.** { *; }

# Models
-keep class com.stockbillpro.data.models.** { *; }
-keepclassmembers class com.stockbillpro.data.models.** { *; }

# General
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
"""

    with open(proguard_path, "w") as f:
        f.write(proguard_rules)

    print("proguard-rules.pro created")

if __name__ == "__main__":
    patch_android_manifest()
    patch_build_gradle()
    patch_proguard()
    print("Android patching complete!")
