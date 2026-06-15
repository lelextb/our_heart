# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepclassmembers class kotlin.Metadata { *; }

# Our Heart Kotlin classes
-keep class com.example.ourheart.services.** { *; }
-keep class com.example.ourheart.utils.** { *; }

# Room / SQLite (drift is SQLite-based, no Room, but safe to keep general)
-keep class * extends androidx.room.** { *; } # not used but harmless
-keep class android.database.** { *; }

# Image cropper / picker
-keep class com.yalantis.ucrop** { *; }
-keep class com.yalantis.ucrop.** { *; }