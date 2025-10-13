// In android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("com.google.gms:google-services:4.4.2")
        // The Kotlin plugin is now declared in the `plugins` block below.
    }
}

// NEW: This block is required to configure the toolchain.
// `apply false` makes the plugin available to subprojects without applying it here.
plugins {
    id("org.jetbrains.kotlin.android") version "1.9.23" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")

subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
    // We no longer need the complex afterEvaluate blocks here,
    // as the toolchain will handle Java version consistency.
}

// NEW: This is the toolchain configuration. It tells all Kotlin
// modules in the entire project to target JVM 17.
kotlin {
    jvmToolchain(17)
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}