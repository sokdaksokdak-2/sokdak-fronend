// android/build.gradle.kts  (Project-level)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ↓ AGP 7.4.2 로 다운그레이드
        classpath("com.android.tools.build:gradle:7.4.2")
        // Kotlin 플러그인은 1.8.22 그대로 사용 가능
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/* ──────────────[ 빌드 출력 경로 통합 : 기존과 동일 ]────────────── */
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubDir)

    // app 모듈 평가가 먼저 끝나야 하는 플러그인들이 있어 선행-의존 걸어둠
    evaluationDependsOn(":app")
}

/* clean task */
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
