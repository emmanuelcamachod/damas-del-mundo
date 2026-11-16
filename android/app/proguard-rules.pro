# Reglas ProGuard / R8 para Capacitor 6 y WebView Offline-First
-keep class com.getcapacitor.** { *; }
-keep class com.juegodedamas.nemesis.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepclasseswithmembers class * {
    @com.getcapacitor.annotation.CapacitorPlugin <methods>;
}
