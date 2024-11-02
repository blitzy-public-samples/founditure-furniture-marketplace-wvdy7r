# Human Tasks:
# 1. Verify that the release signing configuration is properly set up in build.gradle
# 2. Test the release build thoroughly after ProGuard optimization
# 3. Keep backup of mapping.txt file for each release for crash report symbolication
# 4. Update rules if new libraries are added to the project

# Requirement: Security Architecture - Code obfuscation and security measures
# Version references for key dependencies:
# - Retrofit 2.9.0
# - OkHttp 4.11.0
# - Kotlin 1.9.0
# - Hilt 2.48
# - Room (AndroidX) - Based on build.gradle
# - Compose (AndroidX) - Based on build.gradle
# - Coroutines - Based on build.gradle

# General Android rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep the application class and its members
-keep class com.founditure.android.FounditureApplication { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Retrofit rules
-keepattributes Signature
-keepattributes Exceptions
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*

# OkHttp rules
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Gson rules
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Domain model classes (keep data models)
-keep class com.founditure.android.domain.model.** { *; }
-keepclassmembers class com.founditure.android.domain.model.** { *; }

# DTOs (keep API response/request objects)
-keep class com.founditure.android.data.remote.dto.** { *; }
-keepclassmembers class com.founditure.android.data.remote.dto.** { *; }

# Room database entities
-keep class com.founditure.android.data.local.entity.** { *; }
-keepclassmembers class com.founditure.android.data.local.entity.** { *; }

# Hilt dependency injection
-keep class dagger.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.internal.GeneratedComponent
-keepclasseswithmembernames class * {
    @dagger.* <fields>;
}
-keepclasseswithmembernames class * {
    @javax.inject.* <fields>;
}
-keepclasseswithmembernames class * {
    @dagger.* <methods>;
}
-keepclasseswithmembernames class * {
    @javax.inject.* <methods>;
}

# Coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# AndroidX rules
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-keep class androidx.compose.** { *; }
-dontwarn androidx.**

# Jetpack Compose
-keep class androidx.compose.ui.** { *; }
-keep class androidx.compose.material.** { *; }
-keep class androidx.compose.runtime.** { *; }
-keepclassmembers class androidx.compose.runtime.** { *; }

# WebSocket rules
-keep class org.java_websocket.** { *; }
-keepclassmembers class * implements org.java_websocket.WebSocketListener {
    <methods>;
}
-keepclassmembers class * extends org.java_websocket.WebSocketClient {
    <methods>;
}

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Location services
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.maps.**
-dontwarn com.google.android.gms.location.**

# Image loading libraries (Coil & Glide)
-keep class coil.** { *; }
-keep class com.bumptech.glide.** { *; }
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep public class * extends com.bumptech.glide.module.AppGlideModule
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}

# Keep custom application classes
-keep class com.founditure.android.presentation.** { *; }
-keep class com.founditure.android.di.** { *; }
-keep class com.founditure.android.config.** { *; }

# Serialization rules
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Crash reporting - keep source file names and line numbers
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}