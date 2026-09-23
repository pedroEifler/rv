package simulator

import java.io.File
import org.gradle.testkit.runner.GradleRunner
import org.gradle.testkit.runner.TaskOutcome
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.security.MessageDigest

/**
 * Functional tests proving the formatting convention: check and apply are
 * separate, spotlessCheck never mutates fixtures, and Java, Kotlin, Kotlin
 * Gradle, Markdown, JSON and YAML are all covered.
 */
class FormattingConventionsFunctionalTest {

    @TempDir
    lateinit var projectDir: File

    private fun writeFile(path: String, content: String): File {
        val file = File(projectDir, path)
        file.parentFile.mkdirs()
        file.writeText(content)
        return file
    }

    private fun sha256(file: File): String =
        MessageDigest.getInstance("SHA-256").digest(file.readBytes()).joinToString("") { "%02x".format(it) }

    private fun runner(vararg arguments: String) =
        GradleRunner.create()
            .withProjectDir(projectDir)
            .withPluginClasspath()
            .withTestKitDir(File(System.getProperty("user.home"), ".gradle"))
            .withArguments(*arguments, "--console=plain")

    @BeforeEach
    fun setUp() {
        writeFile("settings.gradle.kts", "rootProject.name = \"fixture\"\n")
        writeFile(
            "build.gradle.kts",
            """
            plugins {
                id("simulator.formatting")
            }
            """.trimIndent(),
        )
    }

    @Test
    fun `spotlessCheck fails without mutating and spotlessApply fixes every covered format`() {
        val java = writeFile(
            "src/main/java/fixture/App.java",
            "package fixture;\n\nimport java.util.List;\n\npublic class App {\n    public String greet(){return \"hi\";}\n}\n",
        )
        val kotlin = writeFile(
            "src/main/kotlin/fixture/App.kt",
            "package fixture\nclass App{fun greet():String{return \"hi\"}}\n",
        )
        val gradleKts = writeFile(
            "module.gradle.kts",
            "val   x   =   1\n",
        )
        val markdown = writeFile(
            "NOTES.md",
            "# Title\nSome   text   with   irregular    spacing.\n",
        )
        val json = writeFile(
            "data.json",
            "{\"a\":1,\"b\":2}",
        )
        val yaml = writeFile(
            "data.yaml",
            "a:    1\nb:  2\n",
        )

        val fixtures = listOf(java, kotlin, gradleKts, markdown, json, yaml)
        val before = fixtures.associateWith { sha256(it) }

        // The spotlessCheck aggregate is a lifecycle task with no actions: when every
        // per-format check task it depends on fails, Gradle (even with --continue) never
        // executes the lifecycle task itself, so its TaskOutcome stays unreported (null).
        // We therefore assert on the individual per-format check tasks instead.
        val checkResult = runner("spotlessCheck", "--continue").buildAndFail()

        listOf("spotlessJavaCheck", "spotlessKotlinCheck", "spotlessKotlinGradleCheck",
            "spotlessMarkdownCheck", "spotlessJsonCheck", "spotlessYamlCheck").forEach { taskName ->
            assertEquals(
                TaskOutcome.FAILED,
                checkResult.task(":$taskName")?.outcome,
                "expected ':$taskName' to fail as part of spotlessCheck",
            )
        }

        fixtures.forEach { file ->
            assertEquals(before[file], sha256(file), "spotlessCheck must not mutate ${file.name}")
        }

        val applyResult = runner("spotlessApply").build()
        assertEquals(TaskOutcome.SUCCESS, applyResult.task(":spotlessApply")?.outcome)

        fixtures.forEach { file ->
            assertNotEquals(before[file], sha256(file), "spotlessApply should have changed ${file.name}")
        }

        val recheckResult = runner("spotlessCheck").build()
        assertEquals(TaskOutcome.SUCCESS, recheckResult.task(":spotlessCheck")?.outcome)
    }
}
