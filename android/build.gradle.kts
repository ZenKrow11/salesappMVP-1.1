// In android/app/build.gradle.kts

import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { stream ->
        localProperties.load(stream)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.sales_app_mvp"
    // This is the fix for the plugin warnings.
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    // The toolchain now controls this, so we remove the explicit blocks.
    // REMOVED compileOptions and kotlinOptions

    defaultConfig {
        applicationId = "com.example.sales_app_mvp"
        minSdk = 24
        // The targetSdk should match the compileSdk
        targetSdk = 36
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("androidx.multidex:multidex:2.0.1")
    implementation(kotlin("stdlib-jdk8"))
}