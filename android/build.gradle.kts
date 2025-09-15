// Top-level build file where you can add configuration options common to all sub-projects/modules.

plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false // ✅ Firebase plugin
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
