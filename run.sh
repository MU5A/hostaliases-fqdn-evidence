#!/bin/bash
# Runs every experiment and writes the raw output to results/. Requires Docker and Go.
set -e
cd "$(dirname "$0")"
ARCH=$(docker version -f '{{.Server.Arch}}')
(cd gotest && CGO_ENABLED=0 GOOS=linux GOARCH="$ARCH" go build -o ../gotest-linux .)
mkdir -p results
./matrix.sh     2>&1 | tee results/hosts_matrix_current.txt
./matrix_old.sh 2>&1 | grep -v -E 'Pulling|Pull complete|Digest|Status:|Download|Unable to find' | tee results/hosts_matrix_old.txt
./reverse.sh    2>&1 | tee results/reverse_lookup.txt
./runtimes.sh   2>&1 | tee results/runtimes_node_java.txt
./ndots.sh      2>&1 | tee results/ndots_amplification.txt
