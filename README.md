# Godot YOLO Highlighting Prototype

A Godot 4 project that uses YOLOv8n via OpenVINO to detect objects in 
rendered frames and highlight them in 3D space using raycasting.

## Setup

1. Install Godot 4 (standard, not .NET)
2. Set up Python environment:
python -m venv yolo_env
yolo_env\Scripts\activate    # Windows
pip install ultralytics opencv-python numpy openvino
yolo export model=yolov8n.pt format=openvino imgsz=640
3. Run `server.py` first, then open `project.godot` in Godot 4 and run the main scene

## Controls
- WASD - move
- Space/Shift - up/down
- Mouse - look
- Escape - release mouse
