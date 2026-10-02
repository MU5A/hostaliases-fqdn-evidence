#!/bin/bash
# Forward-lookup matrix for Node.js and Java on glibc and musl images.
cd "$(dirname "$0")"
run() { # label image kind
  local label=$1 img=$2 kind=$3
  echo "################ $label ($img)"
  for f in d_plain_baseline a_dotted_only b_two_lines c_one_line_dot_first e_one_line_dot_last; do
    echo "  /etc/hosts = $(tr '\t\n' ' |' < hosts/$f)"
    if [ "$kind" = node ]; then
      docker run --rm --network none -v "$PWD/hosts/$f:/etc/hosts:ro" -v "$PWD/probe.js:/probe.js:ro" "$img" \
        node /probe.js api.example.test api.example.test. 2>&1
    else
      docker run --rm --network none -v "$PWD/hosts/$f:/etc/hosts:ro" -v "$PWD/Probe.java:/Probe.java:ro" "$img" \
        java /Probe.java api.example.test api.example.test. 2>&1
    fi
  done
}
run "Node 22 on glibc" node:22-slim node
run "Node 22 on musl"  node:22-alpine node
run "Java 21 on glibc" eclipse-temurin:21-jdk java
run "Java 21 on musl"  eclipse-temurin:21-jdk-alpine java
