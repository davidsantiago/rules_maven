workspace(name = "rules_maven")

# For tests
load("//:defs.bzl", "maven_install")

maven_install(
    artifacts = {
        "junit:junit:4.12": "",
        "com.google.inject:guice:4.0": "",
        "org.hamcrest:java-hamcrest:2.0.0.0": "",
    },
    repositories = [
        "https://maven.google.com",
    ],
)
