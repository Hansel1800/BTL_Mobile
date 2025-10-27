plugins {
    // Plugin Android (phiên bản có thể khác)
    id("com.android.application") version "8.9.1" apply false
    
    // Plugin Kotlin (phiên bản có thể khác)
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false

    // Dòng bạn cần thêm từ hướng dẫn Firebase:
    id("com.google.gms.google-services") version "4.3.15" apply false
}



allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
