# flutter_vless: Kotlin plugin + VPN service + Xray runtime
-keep class com.github.tfox.flutter_vless.** { *; }
-keep class dev.tfox.fluttervless.** { *; }

# Gson reads the plugin's config classes by reflection
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**