pluginManagement {
    includeBuild("build-logic")
}

rootProject.name = "breaking-bad-production-simulator"

val servicesDir = file("services")
val serviceProjectDirs =
    servicesDir
        .listFiles { candidate -> candidate.isDirectory && File(candidate, "build.gradle.kts").exists() }
        ?.sortedBy { it.name }
        .orEmpty()

serviceProjectDirs.forEach { dir ->
    val projectPath = ":services:${dir.name}"
    include(projectPath)
    project(projectPath).projectDir = dir
}
