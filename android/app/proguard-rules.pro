# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core / Deferred Components (suppress missing class warnings for non-deferred apps)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Video Player
-keep class io.flutter.plugins.videoplayer.** { *; }

# Google Mobile Ads & WebView
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.startup.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**

# Stack traces / Line numbers for debugging production crashes
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
