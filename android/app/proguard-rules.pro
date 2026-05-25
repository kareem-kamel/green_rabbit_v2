# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Prevent Pigeon classes from being obfuscated (Solves "Unable to establish connection on channel")
-keep class dev.flutter.pigeon.** { *; }

# Google Sign-In Plugin
-keep class io.flutter.plugins.googlesignin.** { *; }

# Google Play Services Auth
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }

# Ignore missing classes from Flutter's Play Core integrations during R8
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**
