#!/bin/bash
# Measures how many DNS queries a libc resolver sends for an external name under ndots:5,
# with and without the trailing dot, using a counting DNS server on the default bridge.
cd "$(dirname "$0")"
docker rm -f dnscount >/dev/null 2>&1
docker run -d --name dnscount -v "$PWD/dnsserver.py:/s.py:ro" python:3-alpine python -u /s.py >/dev/null
sleep 2
IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dnscount)
echo "counting DNS server at $IP"

run() { # image search-list name -> number of queries the server saw
  local img=$1 search=$2 name=$3; local args=()
  for d in $search; do args+=(--dns-search "$d"); done
  local before after
  before=$(docker logs dnscount 2>&1 | grep -c '^Q ')
  docker run --rm --dns "$IP" "${args[@]}" --dns-opt ndots:5 "$img" python3 -c \
    "import socket; socket.getaddrinfo('$name', 80)" >/dev/null 2>&1
  after=$(docker logs dnscount 2>&1 | grep -c '^Q ')
  echo $((after-before))
}

S3="default.svc.cluster.local svc.cluster.local cluster.local"
S5="$S3 us-west-2.compute.internal ec2.internal"
printf "%-8s %-20s %-20s %s\n" libc "search domains" "app looks up" "DNS queries sent"
for img in python:3-slim python:3-alpine; do
  libc=$([ "$img" = python:3-slim ] && echo glibc || echo musl)
  for list in "$S3" "$S5"; do
    n=$(echo $list | wc -w)
    for name in api.example.test api.example.test.; do
      printf "%-8s %-20s %-20s %s\n" "$libc" "$n" "$name" "$(run "$img" "$list" "$name")"
    done
  done
done
docker rm -f dnscount >/dev/null
