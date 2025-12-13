# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase (Essential for Auth/Firestore/Crashlytics)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Flutter Secure Storage (prevent key loss)
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep Models/JSON (if you use reflection based serialization, though manual is common in Flutter)
# It is safer directly in Dart, but for native interaction:
-keepmonitoramenities
-keepattributes *Annotation*

# Google ML Kit
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }

# Google Play Core (Deferred Components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Standard Flutter/R8 recommendations
-dontwarn io.flutter.**
