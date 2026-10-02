#!/bin/bash
cd "$(dirname "$0")"
for img in python:3-slim python:3-alpine; do
  libc=$([ "$img" = python:3-slim ] && echo "glibc 2.41" || echo "musl")
  echo "################ $libc ($img)"
  for f in d_plain_baseline a_dotted_only b_two_lines c_one_line_dot_first e_one_line_dot_last; do
    echo "  /etc/hosts = $(tr '\t\n' ' |' < hosts/$f)"
    docker run --rm --network none \
      -v "$PWD/hosts/$f:/etc/hosts:ro" -v "$PWD/probe.py:/probe.py:ro" -v "$PWD/gotest-linux:/gotest:ro" \
      "$img" sh -c 'python3 /probe.py api.example.test api.example.test. ; /gotest api.example.test api.example.test.'
  done
done
