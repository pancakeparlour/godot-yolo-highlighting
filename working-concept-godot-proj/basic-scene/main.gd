extends Node3D

@onready var camera = $DroneCam/Camera3D
@onready var fps_label = $Label
var client := StreamPeerTCP.new()
var connected := false

# Maps StaticBody3D -> array of MeshInstance3D nodes belonging to it
var object_meshes := {}

func _ready():
	client.connect_to_host("127.0.0.1", 9999)
	
	# Register every top-level child of Main as a potential highlightable object
	for child in get_children():
		if child.name in ["DroneCam", "DirectionalLight3D", "WorldEnvironment", "OmniLight3D", "Room"]:
			continue  # skip non-object nodes
		register_object(child)
	
	print("Registered objects: ", object_meshes.size())
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.2
	timer.connect("timeout", capture_and_send)
	timer.start()

func register_object(root: Node):
	# Find the StaticBody3D and all MeshInstance3D nodes inside this object
	var body = find_static_body(root)
	if body == null:
		return
	var meshes = []
	collect_meshes(root, meshes)
	if meshes.size() > 0:
		object_meshes[body] = meshes
		print("Registered ", root.name, " with ", meshes.size(), " meshes")

func find_static_body(node: Node) -> StaticBody3D:
	if node is StaticBody3D:
		return node
	for child in node.get_children():
		var result = find_static_body(child)
		if result:
			return result
	return null

func collect_meshes(node: Node, arr: Array):
	if node is MeshInstance3D:
		arr.append(node)
	for child in node.get_children():
		collect_meshes(child, arr)

func _process(_delta):
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	client.poll()
	if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		connected = true
		if client.get_available_bytes() > 0:
			var raw = client.get_utf8_string(client.get_available_bytes())
			var json = JSON.new()
			if json.parse(raw) == OK:
				var boxes = json.get_data()
				for box in boxes:
					highlight_object_at(box["cx"], box["cy"])
					print("YOLO saw: ", box["label"], " conf: ", box["conf"])

func capture_and_send():
	if not connected:
		return
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var jpeg_bytes = img.save_jpg_to_buffer(0.7)
	var size = jpeg_bytes.size()
	client.put_32(size)
	client.put_data(jpeg_bytes)

func highlight_object_at(cx: float, cy: float):
	var origin = camera.project_ray_origin(Vector2(cx, cy))
	var direction = camera.project_ray_normal(Vector2(cx, cy))
	var end = origin + direction * 1000.0
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	var result = space.intersect_ray(query)
	
	if result:
		var hit_body = result["collider"]
		var node = hit_body
		while node != null:
			if node in object_meshes:
				flash_meshes(object_meshes[node])
				return
			node = node.get_parent()

func flash_meshes(meshes: Array):
	for mesh in meshes:
		# Create a fresh material for each mesh so flashes don't interfere
		var mat = StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color(1, 1, 1)  # white glow
		mat.emission_energy_multiplier = 3.0  # bright initial flash
		mesh.material_override = mat
		
		# Tween the emission energy back down to 0, then clear the override
		var tween = create_tween()
		tween.tween_property(mat, "emission_energy_multiplier", 0.0, 0.4)
		tween.tween_callback(func(): mesh.material_override = null)
