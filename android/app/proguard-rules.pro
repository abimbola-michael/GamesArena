# Firebase
-keep class com.google.firebase.** { *; }
-keepnames class com.google.firebase.**
-keepattributes Signature
-keepattributes *Annotation*

# Firestore model annotations
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <methods>;
}

# Keep models for Firebase Firestore, Realtime Database, etc.
-keepclassmembers class * {
    @com.google.firebase.database.PropertyName <methods>;
}
-keepnames class com.google.firebase.database.DataSnapshot { *; }

# Prevent issues with Play Services and Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }

-keep public class * extends java.lang.Exception

# Prevent warnings
-dontwarn com.google.**
