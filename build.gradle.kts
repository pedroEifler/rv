plugins {
    base
    id("simulator.formatting")
}

repositories {
    mavenCentral()
}

tasks.named("check") {
    dependsOn(subprojects.mapNotNull { it.tasks.findByName("check") })
    dependsOn(gradle.includedBuild("build-logic").task(":check"))
}

tasks.named("build") {
    dependsOn(subprojects.mapNotNull { it.tasks.findByName("build") })
}

tasks.register("test") {
    group = "verification"
    description = "Runs the test task of every subproject."
    dependsOn(subprojects.mapNotNull { it.tasks.findByName("test") })
}
