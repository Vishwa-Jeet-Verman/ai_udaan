# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (missing classes fix for R8)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# OkHttp (used by http/dio)
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep model classes from being stripped
-keepattributes *Annotation*
-keepattributes Signature

# Razorpay
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
