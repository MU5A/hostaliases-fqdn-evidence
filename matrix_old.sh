#!/bin/bash
cd "$(dirname "$0")"
for img in debian:bullseye-slim alpine:3.12; do
  echo "################ $img: $(docker run --rm $img sh -c '(ldd --version 2>&1 || ldd 2>&1) | head -1')"
  for f in d_plain_baseline a_dotted_only b_two_lines c_one_line_dot_first e_one_line_dot_last; do
    printf "  hosts=%-34s" "$(tr '\t\n' ' |' < hosts/$f)"
    docker run --rm --network none -v "$PWD/hosts/$f:/etc/hosts:ro" "$img" sh -c \
      'for q in api.example.test api.example.test.; do r=$(getent hosts $q | cut -d" " -f1); printf " [%s => %s]" "$q" "${r:-MISS}"; done; echo'
  done
done
