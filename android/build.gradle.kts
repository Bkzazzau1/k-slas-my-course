allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

fun Project.ensureAndroidNamespaceFallback() {
    val androidExt = extensions.findByName("android") ?: return

    val getNamespace = androidExt::class.java.methods.firstOrNull {
        it.name == "getNamespace" && it.parameterCount == 0
    } ?: return

    val setNamespace = androidExt::class.java.methods.firstOrNull {
        it.name == "setNamespace" && it.parameterCount == 1
    } ?: return

    val current = getNamespace.invoke(androidExt) as? String
    if (!current.isNullOrBlank()) return

    val manifestPackage = runCatching {
        val manifest = file("src/main/AndroidManifest.xml")
        if (!manifest.exists()) return@runCatching null
        val text = manifest.readText()
        Regex("""package\s*=\s*"([^"]+)"""")
            .find(text)
            ?.groupValues
            ?.getOrNull(1)
    }.getOrNull()

    val fallback = manifestPackage ?: "dev.flutter.plugins.${name.replace("-", "_")}"
    setNamespace.invoke(androidExt, fallback)
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

subprojects {
    pluginManager.withPlugin("com.android.application") {
        ensureAndroidNamespaceFallback()
    }
    pluginManager.withPlugin("com.android.library") {
        ensureAndroidNamespaceFallback()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
