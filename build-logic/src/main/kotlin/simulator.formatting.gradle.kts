import com.diffplug.gradle.spotless.SpotlessExtension

plugins {
    id("com.diffplug.spotless")
}

repositories {
    mavenCentral()
}

val formattingExcludes = arrayOf(
    "**/build/**",
    "**/node_modules/**",
    "**/.gradle/**",
    "**/.specify/**",
    "**/specs/**",
    "**/.github/**",
)

configure<SpotlessExtension> {
    java {
        target("src/**/*.java")
        removeUnusedImports()
        trimTrailingWhitespace()
        leadingTabsToSpaces(4)
        endWithNewline()
    }
    kotlin {
        target("src/**/*.kt")
        ktlint()
        trimTrailingWhitespace()
        endWithNewline()
    }
    kotlinGradle {
        target("*.gradle.kts", "src/**/*.gradle.kts")
        ktlint()
        trimTrailingWhitespace()
        endWithNewline()
    }
    format("markdown") {
        target("**/*.md")
        targetExclude(*formattingExcludes)
        prettier(mapOf("prettier" to "3.9.8")).config(mapOf("proseWrap" to "preserve"))
    }
    format("json") {
        target("**/*.json")
        targetExclude(*formattingExcludes, "**/package-lock.json")
        prettier(mapOf("prettier" to "3.9.8"))
    }
    format("yaml") {
        target("**/*.yml", "**/*.yaml")
        targetExclude(*formattingExcludes)
        prettier(mapOf("prettier" to "3.9.8"))
    }
}