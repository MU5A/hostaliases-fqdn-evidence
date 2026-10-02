#!/bin/bash
cd "$(dirname "$0")"
for img in python:3-slim python:3-alpine; do
  echo "## $img: what does a REVERSE lookup of 10.10.10.10 return? (canonical name)"
  for f in b_two_lines c_one_line_dot_first e_one_line_dot_last d_plain_baseline; do
    printf "  %-34s" "$(tr '\t\n' ' |' < hosts/$f)"
    docker run --rm --network none -v "$PWD/hosts/$f:/etc/hosts:ro" "$img" python3 -c \
      "import socket; print('gethostbyaddr ->', socket.gethostbyaddr('10.10.10.10')[0]); print('   getnameinfo   ->', socket.getnameinfo(('10.10.10.10',0), 0)[0])" | tr '\n' ' '; echo
  done
done
