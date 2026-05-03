import socket, json, struct

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(("127.0.0.1", 9999))
server.listen(1)
print("Waiting for Godot...")

conn, addr = server.accept()
print(f"Connected: {addr}")

while True:
    # Read and discard the incoming frame
    raw_size = conn.recv(4)
    if not raw_size:
        break
    size = struct.unpack("<I", raw_size)[0]
    
    # Drain image bytes without doing anything with them
    received = 0
    while received < size:
        chunk = conn.recv(min(4096, size - received))
        if not chunk:
            break
        received += len(chunk)

    # Send back a hardcoded fake box
    # Set cx, cy to the center of viewport (e.g. 960x600 scene = 480, 300)
    fake_boxes = [{"label": "fake_object", "cx": 491, "cy": 324, "conf": 0.99}]
    response = json.dumps(fake_boxes) + "\n"
    conn.sendall(response.encode())
    print("Sent fake box")
