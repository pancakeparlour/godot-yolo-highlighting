import socket, json, struct
import numpy as np
import cv2
from ultralytics import YOLO

model = YOLO("yolov8n_openvino_model", task="detect")  # or "yolov8n.pt" if we skipped openvino

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(("127.0.0.1", 9999))
server.listen(1)
print("Waiting for Godot...")

conn, addr = server.accept()
print(f"Connected: {addr}")

def recv_exactly(conn, n):
    data = b""
    while len(data) < n:
        chunk = conn.recv(n - len(data))
        if not chunk:
            raise ConnectionError("Disconnected")
        data += chunk
    return data

while True:
    # Read the 4-byte size header
    raw_size = recv_exactly(conn, 4)
    size = struct.unpack("<I", raw_size)[0]  # little-endian unsigned int

    # Read exactly that many bytes
    img_bytes = recv_exactly(conn, size)

    # Decode and run YOLO
    np_arr = np.frombuffer(img_bytes, np.uint8)
    frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    results = model(frame, imgsz=320, verbose=False)
    boxes = []
    for r in results[0].boxes:
        cls = int(r.cls[0])
        label = model.names[cls]
        cx, cy = r.xywh[0][0].item(), r.xywh[0][1].item()
        conf = r.conf[0].item()
        boxes.append({"label": label, "cx": int(cx), "cy": int(cy), "conf": round(conf, 2)})

    response = json.dumps(boxes) + "\n"
    conn.sendall(response.encode())
    print("Sent:", response.strip())
