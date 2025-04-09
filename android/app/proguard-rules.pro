# Flutter ProGuard rules to keep essential Flutter and plugin classes
# Required for Flutter and some plugins to avoid stripping out necessary classes

# Flutter core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.view.FlutterMain { *; }

# Flutter plugin registrant (for older plugins)
-keep class GeneratedPluginRegistrant { *; }

# Play Core (used for deferred components / dynamic feature delivery)
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# For Gson or JSON parsing (if used)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Optional: keep model classes used in JSON serialization (adjust the package)
# -keep class com.wali.sales_app.models.** { *; }

# Prevent removal of annotations
-keepattributes RuntimeVisibleAnnotations

# Keep Kotlin metadata (avoid breaking Kotlin-related classes)
-keep class kotlin.Metadata { *; }
-keepclassmembers class ** {
    @kotlin.Metadata *;
}

# Keep other third-party libraries (add more as needed based on usage)
# Example:
# -keep class androidx.lifecycle.** { *; }
# -keep class retrofit2.** { *; }

# Needed for reflection / native calls
-keepclassmembers class * {
    native <methods>;
}

# Keep Application class
-keep class com.wali.sales_app.MainApplication { *; }

# Keep activity classes
-keep class com.wali.sales_app.MainActivity { *; }

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task