# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Pigeon generated code (critical for 7.x)
-keep class dev.flutter.pigeon.** { *; }
-keep interface dev.flutter.pigeon.** { *; }

# Google Sign-In Android 7.x - Credential Manager
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keep class androidx.credentials.** { *; }
-keep class androidx.credentials.provider.** { *; }
-keep class androidx.credentials.playservices.** { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.internal.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Attributes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Suppress warnings
-dontwarn com.google.android.gms.**
-dontwarn androidx.credentials.**
-dontwarn com.google.android.libraries.identity.**
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.**