buildscript {
    repositories {
        google()
        mavenCentral() // Add this line
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("com.google.gms:google-services:4.4.2") // Added Firebase plugin
    }
}

allprojects {
    repositories {
        google()
        mavenCentral() // Add this line
    }
}

rootProject.buildDir = file("../build") // Use file() for path resolution
subprojects {
    project.buildDir = File(rootProject.buildDir, project.name) // Use File constructor
}
subprojects {
    afterEvaluate {
        project.tasks.findByName("lint")?.let { lintTask ->
            lintTask.dependsOn("clean")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}