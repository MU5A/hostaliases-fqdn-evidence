# hostaliases-fqdn-evidence

Reproducible measurements backing the discussion on
[kubernetes/enhancements#6075](https://github.com/kubernetes/enhancements/pull/6075)
(allow a trailing dot in `hostAliases[].hostnames`). The KEP makes claims about
libc `/etc/hosts` parsing and `ndots:5` query amplification. These scripts test
those claims in real containers instead of arguing from documentation.

Everything runs in Docker with `--network none` where hosts-file behavior is
tested, so a hosts miss cannot be masked by real DNS.

## Findings

### 1. `ndots:5` amplification

A counting DNS server logs every query a libc resolver sends. The client calls
`getaddrinfo` (A and AAAA) for an external name, using Docker's `--dns-search`
and `--dns-opt ndots:5`.

| libc | search domains | app looks up | queries sent |
|---|---|---|---|
| glibc 2.41 | 3 (stock Kubernetes list) | `api.example.test` | 8 (6 wasted) |
| glibc 2.41 | 3 | `api.example.test.` | 2 |
| glibc 2.41 | 5 (with cloud suffixes) | `api.example.test` | 12 (10 wasted) |
| glibc 2.41 | 5 | `api.example.test.` | 2 |
| musl 1.2.6 | 3 / 5 | bare / dotted | 8 / 2 and 12 / 2 |

Identical on glibc and musl. "Up to 10 wasted queries" is accurate only with 5
search domains. With the stock 3-domain list it is 6 wasted, a 4x amplification.

### 2. A plain hostAlias does not satisfy a trailing-dot query

Resolvers match `/etc/hosts` names literally, in both directions. With
`10.10.10.10 api.example.test` in the file, `getaddrinfo("api.example.test.")`
and `getent hosts api.example.test.` both miss. With only the dotted entry, the
undotted query misses. Observed on glibc 2.31, glibc 2.41, musl 1.1.24 (Alpine
3.12) and musl 1.2.6 (current Alpine). The pure-Go resolver normalizes the dot and resolves
both forms from either entry.

So an application that uses the absolute form to avoid the amplification above
cannot be overridden through `hostAliases` today.

### 3. Dotted tokens do not break parsers

A dotted token anywhere on a hosts line is parsed without rejecting the line,
and aliases after it still resolve, on every libc tested. A single line
(`IP name. name` or `IP name name.`) resolves both query forms, so the
two-line layout is not required for compatibility.

### 4. Line ordering changes reverse lookups

`gethostbyaddr` and `getnameinfo` return the first name on the matching line.
A line with only the dotted name, or with the dotted name first, returns a
trailing-dot canonical name
(`api.example.test.`), which differs from today's output. Listing the undotted
name first (`IP name name.`) resolves both forms and keeps the canonical name
unchanged. Tested on glibc 2.41 and musl 1.2.6.

## Layout

| File | Purpose |
|---|---|
| `run.sh` | Builds the Go probe, runs everything, writes `results/` |
| `matrix.sh` | Hosts-file matching on glibc 2.41 and musl 1.2.6 (`getaddrinfo`, `getent`, pure Go) |
| `matrix_old.sh` | Same matrix on glibc 2.31 and musl 1.1.24 on Alpine 3.12 (`getent`) |
| `reverse.sh` | Canonical name returned by reverse lookups for each line ordering |
| `ndots.sh`, `dnsserver.py` | Query-count measurement against a counting DNS server |
| `hosts/` | The `/etc/hosts` variants under test |
| `results/` | Raw output from the last run |

## Running it

Requires Docker and Go.

```bash
./run.sh
```

## What this does not cover

- Java, Node.js and other runtimes. Only libc resolvers and Go's pure resolver
  were tested.
- libc versions beyond those listed.
- Real-world resolver behavior under retries, timeouts or packet loss. The
  amplification test uses a server that answers promptly (NXDOMAIN for search
  suffixes), so it counts queries, not latency.
- The Kubernetes side. These tests use plain `/etc/hosts` files and do not
  exercise kubelet or API server validation.
