import socket, subprocess, sys
for name in sys.argv[1:]:
    try:
        r = sorted({a[4][0] for a in socket.getaddrinfo(name, None, socket.AF_INET)})
        ga = str(r)
    except socket.gaierror as e:
        ga = "MISS"
    p = subprocess.run(["getent", "hosts", name], capture_output=True, text=True)
    ge = p.stdout.split()[0] if p.stdout.strip() else "MISS"
    print(f"    query {name!r:22} getaddrinfo={ga:18} getent={ge}")
