# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and

load("@rules_maven//:coursier.bzl", "coursier_fetch")
load("@rules_maven//:specs.bzl", "maven", "parse", "json")

REPOSITORY_NAME = "maven"

def maven_install(
        name = REPOSITORY_NAME,
        repositories = [],
        artifacts = [],
        fetch_sources = False):

    repositories_json_strings = []
    for repository in parse.parse_repository_spec_list(repositories):
        repositories_json_strings.append(json.write_repository_spec(repository))

    artifacts_json_strings = []
    for artifact in parse.parse_artifact_spec_list(artifacts):
        artifacts_json_strings.append(json.write_artifact_spec(artifact))

    coursier_fetch(
        name = name,
        repositories = repositories_json_strings,
        artifacts = artifacts_json_strings,
        fetch_sources = fetch_sources,
    )

def artifact(a, repository_name = REPOSITORY_NAME):
    artifact_obj = _parse_artifact_str(a) if type(a) == "string" else a
    return "@%s//:%s" % (repository_name, _escape(artifact_obj["group"] + ":" + artifact_obj["artifact"]))

def maven_artifact(a):
    return artifact(a, repository_name = REPOSITORY_NAME)

def library(a, repository_name = REPOSITORY_NAME):
    artifact_obj = _parse_artifact_str(a) if type(a) == "string" else a
    return "@%s//:%s" % (repository_name, _escape(artifact_obj["group"] + ":" + artifact_obj["artifact"] + "_lib"))

def maven_library(a):
    return library(a, repository_name = REPOSITORY_NAME)

def _escape(string):
    return string.replace(".", "_").replace("-", "_").replace(":", "_")

def _parse_artifact_str(artifact_str):
    pieces = artifact_str.split(":")
    if len(pieces) == 2:
        return { "group": pieces[0], "artifact": pieces[1] }
    else:
        return parse.parse_maven_coordinate(artifact_str)

