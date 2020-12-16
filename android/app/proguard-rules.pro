-dontwarn kotlin.**
-keep class kotlin.** { *;}

#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

#Umeng
-keep class com.umeng.** {*;}
-keep class com.uc.** {*;}
-keepclassmembers class * {
   public <init> (org.json.JSONObject);
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}


#7ZIP-JBinding
-keep class net.sf.sevenzipjbinding.** { *;}
-keep class com.musketeer.compressor.** { *;}

-keep public class com.musketeer.compressor.R$*{
    public static final int *;
}