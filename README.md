# rules_maven

Transitive Maven artifact repository rule implementation that just depends on
the `coursier` CLI tool.

This is a experimental proof of concept; support is on a best-effort basis.

Tested on Windows, macOS, Linux. 

Requires `java` to be on your `$PATH`, or set `$JAVA_HOME`.

## Usage

List the top-level Maven artifacts and servers in the WORKSPACE:

```python
RULES_MAVEN_COMMIT = <commit>

http_archive(
    name = "rules_maven",
    strip_prefix = "rules_maven-%s" % RULES_MAVEN_COMMIT,
    url = "https://github.com/jin/rules_maven/archive/%s.zip" % RULES_MAVEN_COMMIT,
)

load("@rules_maven//:defs.bzl", "maven_install")

maven_install(
    artifacts = {
        # Artifact FQN : sha256 (not implemented yet)
        "junit:junit:4.12": "",
        "com.google.inject:guice:4.0": "",
        "org.hamcrest:java-hamcrest:2.0.0.0": "",
        "androidx.test.espresso:espresso-core:3.1.1": "",
        "androidx.test:runner:1.1.1": "",
        "androidx.test.ext:junit:1.1.0": "",
    },
    repositories = [
        "https://maven.google.com",
        "https://repo1.maven.org", # this is the default server
    ],
)
```

and use them directly in the BUILD file:

```python
load("@rules_maven//:defs.bzl", "artifact")

android_library(
    name = "test_deps",
    exports = [
        artifact("androidx.test.espresso:espresso-core:3.1.1"),
        artifact("androidx.test:runner:1.1.1"),
        artifact("androidx.test.ext:junit:1.1.0"),
        artifact("junit:junit:4.12"),
        artifact("com.google.inject:guice:4.0"),
        artifact("org.hamcrest:java-hamcrest:2.0.0.0"),
    ],
)

android_library(
    name = "greeter_test_lib",
    srcs = ["GreeterTest.java"],
    custom_package = "com.example.bazel.test",
    visibility = ["//src/test:__subpackages__"],
    deps = [
        ":test_deps",
        "//src/main/java/com/example/bazel:greeter_activity",
    ],
)
```

Note the lack of explicit packaging type (a la gmaven_rules). `coursier`
resolves that automatically, fetches the transitive jars using the transitive
pom files, and saves them into a central cache `~/.cache/coursier`.

The repository rule then..

1. creates one repository for each top level artifact
1. creates a BUILD file for each repository
1. symlinks the transitive artifacts from the central cache to the repository's
   directory in the output_base
1. creates java_import/aar_import for each transitive artifact (including the
   top level one)
1. creates a top level android_binary or android_library that exports all the
   transitive java_import and aar_import targets (for strict deps)

The `artifact` macro used in the BUILD file translates the artifact fully
qualified name to the label of the top level target in the repository.

## Demo

```shell
$ cd examples/simple && bazel build :my_app
INFO: Invocation ID: a32f5c70-2165-4c6c-bee1-47bc1ab91a89
INFO: Analysed target //:my_app (38 packages loaded, 730 targets configured).
INFO: Found 1 target...
Target //:my_app up-to-date:
  bazel-bin/my_app_deploy.jar
  bazel-bin/my_app_unsigned.apk
  bazel-bin/my_app.apk
INFO: Elapsed time: 9.330s, Critical Path: 8.51s
INFO: 50 processes: 37 linux-sandbox, 13 worker.
INFO: Build completed successfully, 92 total actions

$ jar tf bazel-out/k8-fastbuild/bin/my_app_deploy.jar | grep -v ".class"
META-INF/
META-INF/MANIFEST.MF
android/
android/arch/
android/arch/lifecycle/
android/support/
android/support/annotation/
META-INF/android.arch.lifecycle_viewmodel.version
javax/
javax/annotation/
javax/annotation/concurrent/
javax/annotation/meta/

... <all transitive classes>
```

## TODO

- [x] don't symlink to the basename; symlink to the fqn-derived path
- [x] maven server configuration
- [x] windows support
- [ ] load test with different artifacts
- [ ] authentication
- [ ] sha checks of transitive artifacts
- [ ] support more packaging types than just aar and jar

## Known issues

### Windows

- The repository rule generates very long paths, and this is an issue on Windows.
