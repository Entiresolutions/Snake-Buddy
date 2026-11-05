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

fun configureAndroidSdk(p: Project) {
    val android = p.extensions.findByName("android") ?: return
    for (m in android.javaClass.methods) {
        if (m.name in listOf("compileSdkVersion", "setCompileSdkVersion", "setCompileSdk")) {
            if (m.parameterTypes.size == 1 &&
                (m.parameterTypes[0] == Int::class.javaPrimitiveType || m.parameterTypes[0] == java.lang.Integer::class.java)) {
                try {
                    m.invoke(android, 36)
                } catch (_: Throwable) {}
            }
        }
    }
}

subprojects {
    if (state.executed) {
        configureAndroidSdk(this)
    } else {
        afterEvaluate {
            configureAndroidSdk(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
