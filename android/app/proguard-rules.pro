-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.odyssey.moodtracker.** { *; }
-keep class com.dexterous.** { *; }
-keep class com.soloud.** { *; }
-keep class me.carda.awesome_notifications.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes *Annotation*
-dontwarn io.flutter.embedding.engine.plugins.*
-dontwarn io.flutter.plugin.common.*
-dontwarn com.google.protobuf.**
-dontwarn kotlin.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.internal.firebase-auth.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.j2objc.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn com.google.errorprone.annotations.**

# Firebase Auth
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Guava
-dontwarn com.google.common.**
-keep class com.google.common.** { *; }

# Gson (used by Firebase)
-keepattributes Signature
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp / Retrofit (if used)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
