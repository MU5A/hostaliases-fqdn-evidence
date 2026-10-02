import socket, struct, sys
TARGET = "api.example.test"
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(("0.0.0.0", 53))
print("ready", flush=True)
while True:
    data, addr = s.recvfrom(512)
    i, labels = 12, []
    while data[i]:
        n = data[i]; labels.append(data[i+1:i+1+n].decode()); i += n + 1
    qtype = struct.unpack("!H", data[i+1:i+3])[0]
    qend = i + 5
    name = ".".join(labels).lower()
    print(f"Q {name} {'A' if qtype==1 else 'AAAA' if qtype==28 else qtype}", flush=True)
    hit = name == TARGET
    if hit and qtype == 1:
        hdr = data[:2] + struct.pack("!HHHHH", 0x8180, 1, 1, 0, 0)
        ans = b"\xc0\x0c" + struct.pack("!HHIH", 1, 1, 30, 4) + bytes([1,2,3,4])
        s.sendto(hdr + data[12:qend] + ans, addr)
    else:
        rcode = 0 if hit else 3  # NOERROR/NODATA for AAAA of target, NXDOMAIN otherwise
        hdr = data[:2] + struct.pack("!HHHHH", 0x8180 | rcode, 1, 0, 0, 0)
        s.sendto(hdr + data[12:qend], addr)
