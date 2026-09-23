package simulator

import java.io.File
import org.gradle.testkit.runner.GradleRunner
import org.gradle.testkit.runner.TaskOutcome
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir

/**
 * Functional tests proving the java-service and kotlin-service conventions
 * pin Java 25 / Kotlin 2.4.20 and provide the mandatory build/test/check
 * tasks, using real Gradle TestKit builds against the plugin classpath.
 */
class BuildConventionsFunctionalTest {

    @TempDir
    lateinit var projectDir: File

    private fun writeFile(path: String, content: String) {
        val file = File(projectDir, path)
        file.parentFile.mkdirs()
        file.writeText(if (content.endsWith("\n")) content else content + "\n")
    }

    private fun runner(vararg arguments: String) =
        GradleRunner.create()
            .withProjectDir(projectDir)
            .withPluginClasspath()
            .withTestKitDir(File(System.getProperty("user.home"), ".gradle"))
            .withArguments(*arguments, "--console=plain")

    private fun repoRoot(): File =
        generateSequence(File(".").absoluteFile) { it.parentFile }
            .first { File(it, "gradle/libs.versions.toml").exists() }

    @BeforeEach
    fun setUp() {
        val catalogPath = File(repoRoot(), "gradle/libs.versions.toml").absolutePath.replace("\\", "/")
        writeFile(
            "settings.gradle.kts",
            """
            rootProject.name = "fixture"

            dependencyResolutionManagement {
                versionCatalogs {
                    create("libs") {
                        from(files("${catalogPath}"))
                    }
                }
            }
            """.trimIndent(),
        )
    }

    @Test
    fun `java service convention pins Java 25 and runs build test check`() {
        writeFile(
            "build.gradle.kts",
            """
            plugins {
                id("simulator.java-service")
            }

            tasks.register("printJavaVersion") {
                val version = java.toolchain.languageVersion
                doLast {
                    println("JAVA_TOOLCHAIN_VERSION=" + version.get())
                }
            }
            """.trimIndent(),
        )
        writeFile(
            "src/main/java/fixture/App.java",
            """
            package fixture;

            public class App {
                public String greet() {
                    return "hello";
                }
            }
            """.trimIndent(),
        )
        writeFile(
            "src/test/java/fixture/AppTest.java",
            """
            package fixture;

            import org.junit.jupiter.api.Test;
            import static org.junit.jupiter.api.Assertions.assertEquals;

            class AppTest {
                @Test
                void greetsHello() {
                    assertEquals("hello", new App().greet());
                }
            }
            """.trimIndent(),
        )

        val result = runner("build", "printJavaVersion").build()

        assertEquals(TaskOutcome.SUCCESS, result.task(":build")?.outcome)
        assertEquals(TaskOutcome.SUCCESS, result.task(":test")?.outcome)
        assertTrue(result.output.contains("JAVA_TOOLCHAIN_VERSION=25"))
    }

    @Test
    fun `kotlin service convention compiles Kotlin sources on Java 25`() {
        writeFile(
            "build.gradle.kts",
            """
            plugins {
                id("simulator.kotlin-service")
            }

            tasks.register("printJavaVersion") {
                val version = java.toolchain.languageVersion
                doLast {
                    println("JAVA_TOOLCHAIN_VERSION=" + version.get())
                }
            }
            """.trimIndent(),
        )
        writeFile(
            "src/main/kotlin/fixture/App.kt",
            """
            package fixture

            class App {
                fun greet(): String = "hello"
            }
            """.trimIndent(),
        )
        writeFile(
            "src/test/kotlin/fixture/AppTest.kt",
            """
            package fixture

            import org.junit.jupiter.api.Assertions.assertEquals
            import org.junit.jupiter.api.Test

            class AppTest {
                @Test
                fun greetsHello() {
                    assertEquals("hello", App().greet())
                }
            }
            """.trimIndent(),
        )

        val result = runner("build", "printJavaVersion").build()

        assertEquals(TaskOutcome.SUCCESS, result.task(":build")?.outcome)
        assertEquals(TaskOutcome.SUCCESS, result.task(":test")?.outcome)
        assertTrue(result.output.contains("JAVA_TOOLCHAIN_VERSION=25"))
    }

    @Test
    fun `jvm-base convention exposes the mandatory build test and quality tasks`() {
        writeFile(
            "build.gradle.kts",
            """
            plugins {
                id("simulator.jvm-base")
            }
            """.trimIndent(),
        )

        val result = runner("tasks", "--all").build()

        listOf("build", "test", "check", "spotlessCheck", "spotlessApply", "clean").forEach { taskName ->
            assertTrue(result.output.contains(taskName), "expected task listing to contain '$taskName'")
        }
    }

    @Test
    fun `version catalog pins the exact required Java and Kotlin versions`() {
        val repoRoot = generateSequence(File(".").absoluteFile) { it.parentFile }
            .first { File(it, "gradle/libs.versions.toml").exists() }
        val versionsFile = File(repoRoot, "gradle/libs.versions.toml").readText()
        assertTrue(versionsFile.contains("java = \"25\""), "libs.versions.toml must pin java = \"25\"")
        assertTrue(versionsFile.contains("kotlin = \"2.4.20\""), "libs.versions.toml must pin kotlin = \"2.4.20\"")
    }
}
