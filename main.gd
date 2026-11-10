extends Node3D
# Simulator Avanza G MT 2018 - putaran 1 (inti game)

const WHEEL_R := 0.30
const MASS := 1350.0
const RATIOS = [0.0, 3.769, 2.045, 1.376, 1.0, 0.838]
const REV_RATIO := 3.67
const FINAL := 4.875
const IDLE := 850.0
const REDLINE := 6200.0
const CHUNK := 60.0
const CHUNKS := 6
const NCH := 14        # 14 potongan x 60 m = rute berputar 840 m
const LOOP := 840.0
const KH := [0.0, 5.0, 6.5, 9.0, 15.0, 17.0, 18.5, 20.0, 24.0]
const KSKY := [Color(0.02, 0.03, 0.08), Color(0.04, 0.05, 0.12), Color(0.95, 0.62, 0.45), Color(0.62, 0.78, 0.95), Color(0.62, 0.78, 0.95), Color(0.95, 0.72, 0.5), Color(0.75, 0.4, 0.3), Color(0.04, 0.05, 0.12), Color(0.02, 0.03, 0.08)]
const KSUN := [0.05, 0.05, 0.6, 1.0, 1.0, 0.8, 0.3, 0.05, 0.05]
const KAMB := [0.3, 0.3, 0.55, 0.75, 0.75, 0.6, 0.4, 0.3, 0.3]
const CARS := [
	{"name": "Toyota Avanza G MT 2018", "file": "res://avanza.glb", "std": false, "eng": "a", "horn": 1.0, "plate": "B 1446 ZMG", "tax": "01.31",
		"eye": Vector3(0.37, 1.22, 0.15), "wheel": Vector3(0.37, 1.0, -0.3), "dash": Vector3(0, 0.99, -0.78), "dashw": 1.5, "rad": 0.3,
		"pf": Vector3(0, 0.62, -2.11), "pr": Vector3(0, 0.62, 2.11), "trf": Color(0.5, 0.25, 0.0), "trr": Color(0.5, 0.25, 0.0)},
	{"name": "Toyota Avanza (baru)", "file": "res://avanza_new.glb", "std": true, "eng": "b", "horn": 1.05, "plate": "B 1446 ZMG", "tax": "01.31",
		"eye": Vector3(0.36, 1.2, -0.3), "wheel": Vector3(0.36, 0.92, -0.84), "dash": Vector3(0, 0.89, -1.27), "dashw": 1.4, "rad": 0.322,
		"pf": Vector3(0, 0.5, -2.522), "pr": Vector3(0, 0.8, 1.895), "trf": Color(0.92, 0.92, 0.95), "trr": Color(0.45, 0.03, 0.03)},
	{"name": "Daihatsu Sigra", "file": "res://sigra.glb", "std": true, "eng": "c", "horn": 0.95, "plate": "B 2155 SOQ", "tax": "03.22",
		"eye": Vector3(0.36, 1.12, 0.0), "wheel": Vector3(0.36, 0.88, -0.55), "dash": Vector3(0, 0.86, -0.97), "dashw": 1.4, "rad": 0.27,
		"pf": Vector3(0, 0.398, -1.975), "pr": Vector3(0, 0.731, 2.045), "trf": Color(0.5, 0.2, 0.0), "trr": Color(0.5, 0.2, 0.0)},
]
const LOCK := 9.42478   # 1,5 putaran setir ke tiap sisi
const ROUTE := [0, 1, 2, 3, 6, 7, 8, 4, 5, 9, 10, 0, 1, 2, 11, 12, 13, 3, 4, 5, 9, 10, 0, 1, 6, 7, 8, 2, 3, 4, 5, 11, 12, 13, 9, 10, 0, 1, 2, 3, 4, 5, 9, 10, 0, 1, 2]
const MODEL_YAW_DEG := 0.0   # ubah ke 180.0 kalau model menghadap terbalik

var car: Node3D
var cam: Camera3D
var hud: Hud
var wheel3d: MeshInstance3D
var car_idx := 0
var interior: Node3D
var hubs := {}
var wheels := {}
var lamp_mats := {}
var turn_rest := {}
var glass_mat: StandardMaterial3D
var inner_mats: Array = []
var plate_nodes: Array = []
var inside_now := true
var wheel_angle := 0.0
var wheel_held := false
var lever := Vector2(0.5, 0.5)
var horn_on := false
var start_timer := 0.0
var last_blink := false
var route_len := 0.0
var barriers: Node3D
var engine_type := "a"
var eng_p: Array = []
var starter_p: AudioStreamPlayer
var horn_p: AudioStreamPlayer
var tick_p: AudioStreamPlayer
var road_p: AudioStreamPlayer
var ext: Node3D
var model: Node3D
var env: Environment
var sun: DirectionalLight3D
var headlight: SpotLight3D
var platform: MeshInstance3D
var clouds: Node3D
var cloud_mat: StandardMaterial3D
var sb_btn: StyleBoxFlat
var sb_dash: StyleBoxFlat
var sb_slot: StyleBoxFlat
var sb_pad: StyleBoxFlat
var sb_on: StyleBoxFlat
var sb_pill: StyleBoxFlat
var amb_p: AudioStreamPlayer
var sfx := {}
var state := "menu"
var menu_ang := 0.6
var time_h := 9.0
var low_on := false
var high_on := false
var pass_on := false
var sig := 0
var hazard := false
var handbrake := false
var blink := 0.0
var shadows_on := true
var chunks: Array = []
var mats := {}
var cam_mode := 1
var orbit_yaw := 0.6
var orbit_pitch := 0.3
var orbit_dist := 9.0

var speed := 0.0
var rpm := 0.0
var engine_on := false
var gear := 0
var clutch := 0.0
var clutch_held := false
var gas := 0.0
var brake := 0.0
var steer_in := 0.0
var steer := 0.0
var heading := 0.0
var pos := Vector3(-5.6, 0.0, 0.0)
var stalls := 0
var msg := "Injak kopling, lalu tekan START"
var msg_t := 6.0
var paused := false
var touches := {}
var tpos := {}


class Hud extends Control:
	var g
	func _draw():
		if g != null:
			g.draw_hud(self)


func _ready():
	_build_env()
	_build_world()
	_build_car()
	cam = Camera3D.new()
	cam.far = 700.0
	add_child(cam)
	cam.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.g = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.1, 0.12, 0.17, 0.92)
	sb_btn.set_border_width_all(2)
	sb_btn.border_color = Color(0.25, 0.28, 0.34)
	sb_btn.set_corner_radius_all(16)
	sb_dash = StyleBoxFlat.new()
	sb_dash.bg_color = Color(0.22, 0.22, 0.23, 0.95)
	sb_dash.corner_radius_top_left = 42
	sb_dash.corner_radius_top_right = 34
	sb_slot = StyleBoxFlat.new()
	sb_slot.bg_color = Color(0.04, 0.04, 0.06, 0.95)
	sb_slot.set_corner_radius_all(12)
	sb_pad = StyleBoxFlat.new()
	sb_pad.bg_color = Color(0.62, 0.64, 0.68)
	sb_pad.set_corner_radius_all(6)
	sb_on = StyleBoxFlat.new()
	sb_on.set_corner_radius_all(14)
	sb_pill = StyleBoxFlat.new()
	sb_pill.bg_color = Color(0.2, 0.04, 0.04, 0.9)
	sb_pill.set_border_width_all(2)
	sb_pill.border_color = Color(0.9, 0.25, 0.2)
	sb_pill.set_corner_radius_all(12)
	headlight = SpotLight3D.new()
	headlight.position = Vector3(0, 0.9, -2.0)
	headlight.rotation_degrees.x = -3.0
	headlight.spot_angle = 32.0
	headlight.spot_range = 40.0
	headlight.visible = false
	car.add_child(headlight)
	var pm := CylinderMesh.new()
	pm.top_radius = 3.4
	pm.bottom_radius = 3.4
	pm.height = 0.2
	pm.radial_segments = 32
	pm.material = _mat(Color(0.42, 0.47, 0.6))
	platform = MeshInstance3D.new()
	platform.mesh = pm
	platform.position.y = -0.1
	add_child(platform)
	_build_clouds()
	_build_audio()
	_enter_menu()


# ---------------------------------------------------------------- dunia

func _mat(c: Color) -> StandardMaterial3D:
	if not mats.has(c):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		mats[c] = m
	return mats[c]


func _box(parent: Node, size: Vector3, c: Color, at: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	b.material = _mat(c)
	m.mesh = b
	m.position = at
	parent.add_child(m)
	return m


func _build_env():
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.74, 0.77, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)


class MB:
	# pembuat mesh gabungan (1 draw call per potongan jalan, warna per-vertex)
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()

	func quad(a: Vector3, b: Vector3, cc: Vector3, d: Vector3, nrm: Vector3, col: Color):
		var p1 := b
		var p3 := d
		if (b - a).cross(cc - a).dot(nrm) > 0.0:
			p1 = d
			p3 = b
		for p in [a, p1, cc, a, cc, p3]:
			v.append(p)
			n.append(nrm)
			c.append(col)

	func box(ct: Vector3, sz: Vector3, col: Color):
		var h := sz * 0.5
		var x0 := ct.x - h.x
		var x1 := ct.x + h.x
		var y0 := ct.y - h.y
		var y1 := ct.y + h.y
		var z0 := ct.z - h.z
		var z1 := ct.z + h.z
		quad(Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x1, y0, z1), Vector3.RIGHT, col)
		quad(Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x0, y1, z1), Vector3(x0, y0, z1), Vector3.LEFT, col)
		quad(Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.UP, col)
		quad(Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK, col)
		quad(Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3.FORWARD, col)

	func mesh() -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return m


# Profil rute (840 m): 0-5 kota, 6-8 flyover, 9-10 kota, 11-13 underpass
func _road_y(k: int, u: float) -> float:
	var e := u * u * (3.0 - 2.0 * u)
	if k == 6:
		return 5.5 * e
	if k == 7:
		return 5.5
	if k == 8:
		return 5.5 * (1.0 - e)
	if k == 11:
		return -5.0 * e
	if k == 12:
		return -5.0
	if k == 13:
		return -5.0 * (1.0 - e)
	return 0.0


func _elev(sd: float) -> float:
	var i := int(floorf(sd / CHUNK))
	if i < 0 or i >= ROUTE.size():
		return 0.0
	return _road_y(ROUTE[i], (sd - i * CHUNK) / CHUNK)


func _strip(b: MB, k: int, u0: float, u1: float, xa: float, xb: float, yo: float, col: Color):
	var z0 := 30.0 - 60.0 * u0
	var z1 := 30.0 - 60.0 * u1
	var y0 := _road_y(k, u0) + yo
	var y1 := _road_y(k, u1) + yo
	b.quad(Vector3(xa, y0, z0), Vector3(xb, y0, z0), Vector3(xb, y1, z1), Vector3(xa, y1, z1), Vector3.UP, col)


func _build_chunk(k: int, rng: RandomNumberGenerator, vm: Material) -> MeshInstance3D:
	var b := MB.new()
	var fly := k >= 6 and k <= 8
	var under := k >= 11
	var city := not fly and not under
	var asphalt := Color(0.30, 0.30, 0.32)
	var conc := Color(0.62, 0.62, 0.6)
	var yellow := Color(0.95, 0.8, 0.1)
	var steps := 12
	for i in steps:
		var u0 := float(i) / steps
		var u1 := float(i + 1) / steps
		var z0 := 30.0 - 60.0 * u0
		var z1 := 30.0 - 60.0 * u1
		var y0 := _road_y(k, u0)
		var y1 := _road_y(k, u1)
		_strip(b, k, u0, u1, -7.5, 7.5, 0.0, asphalt)
		_strip(b, k, u0, u1, -0.35, 0.35, 0.25, conc)
		_strip(b, k, u0, u1, -0.62, -0.45, 0.02, yellow)
		_strip(b, k, u0, u1, 0.45, 0.62, 0.02, yellow)
		_strip(b, k, u0, u1, -7.25, -7.1, 0.02, Color.WHITE)
		_strip(b, k, u0, u1, 7.1, 7.25, 0.02, Color.WHITE)
		if i % 3 == 0:
			_strip(b, k, u0, u1, -3.92, -3.78, 0.02, Color.WHITE)
			_strip(b, k, u0, u1, 3.78, 3.92, 0.02, Color.WHITE)
		for sm in [-1.0, 1.0]:
			b.quad(Vector3(sm * 0.35, y0, z0), Vector3(sm * 0.35, y0 + 0.25, z0), Vector3(sm * 0.35, y1 + 0.25, z1), Vector3(sm * 0.35, y1, z1), Vector3(sm, 0, 0), conc)
		for sx in [-1.0, 1.0]:
			var nx := Vector3(sx, 0, 0)
			var xw: float = 7.5 * sx
			var xi: float = xw - sx * 0.3
			if fly:
				var yb0 := y0 - 0.9 if k == 7 else 0.0
				var yb1 := y1 - 0.9 if k == 7 else 0.0
				b.quad(Vector3(xw, yb0, z0), Vector3(xw, y0 + 0.9, z0), Vector3(xw, y1 + 0.9, z1), Vector3(xw, yb1, z1), nx, conc)
				b.quad(Vector3(xi, y0, z0), Vector3(xi, y0 + 0.9, z0), Vector3(xi, y1 + 0.9, z1), Vector3(xi, y1, z1), -nx, conc)
				b.quad(Vector3(xi, y0 + 0.9, z0), Vector3(xw, y0 + 0.9, z0), Vector3(xw, y1 + 0.9, z1), Vector3(xi, y1 + 0.9, z1), Vector3.UP, conc)
			if under:
				b.quad(Vector3(xw, y0, z0), Vector3(xw, 0.0, z0), Vector3(xw, 0.0, z1), Vector3(xw, y1, z1), -nx, conc)
		if k == 7:
			b.quad(Vector3(-7.5, y0 - 0.9, z0), Vector3(7.5, y0 - 0.9, z0), Vector3(7.5, y1 - 0.9, z1), Vector3(-7.5, y1 - 0.9, z1), Vector3.DOWN, conc)

	# ground kiri-kanan (jalan dibiarkan terbuka supaya underpass bisa turun)
	b.box(Vector3(-37.5, -0.1, 0), Vector3(60, 0.2, 60), Color(0.5, 0.5, 0.45))
	b.box(Vector3(37.5, -0.1, 0), Vector3(60, 0.2, 60), Color(0.5, 0.5, 0.45))
	b.box(Vector3(-8.5, 0.075, 0), Vector3(2.0, 0.15, 60), Color(0.62, 0.62, 0.62))
	b.box(Vector3(8.5, 0.075, 0), Vector3(2.0, 0.15, 60), Color(0.62, 0.62, 0.62))

	if k == 7:
		# jalan di bawah flyover, simpang, dan pilar
		b.quad(Vector3(-7.5, 0.01, 30), Vector3(7.5, 0.01, 30), Vector3(7.5, 0.01, -30), Vector3(-7.5, 0.01, -30), Vector3.UP, asphalt)
		b.quad(Vector3(-60, 0.02, 8), Vector3(60, 0.02, 8), Vector3(60, 0.02, -8), Vector3(-60, 0.02, -8), Vector3.UP, Color(0.27, 0.27, 0.29))
		for px in [-5.0, 0.0, 5.0]:
			b.box(Vector3(px, 2.3, 0), Vector3(1.2, 4.6, 1.2), conc)
	if k == 6:
		b.quad(Vector3(-7.5, 0.0, -30), Vector3(7.5, 0.0, -30), Vector3(7.5, 5.5, -30), Vector3(-7.5, 5.5, -30), Vector3.FORWARD, conc)
	if k == 8:
		b.quad(Vector3(-7.5, 0.0, 30), Vector3(7.5, 0.0, 30), Vector3(7.5, 5.5, 30), Vector3(-7.5, 5.5, 30), Vector3.BACK, conc)
	if k == 12:
		# atap terowongan (jalan lintas di atasnya)
		b.quad(Vector3(-7.5, 0.0, 30), Vector3(7.5, 0.0, 30), Vector3(7.5, 0.0, -30), Vector3(-7.5, 0.0, -30), Vector3.UP, asphalt)
		b.quad(Vector3(-7.5, -0.5, 30), Vector3(7.5, -0.5, 30), Vector3(7.5, -0.5, -30), Vector3(-7.5, -0.5, -30), Vector3.DOWN, conc)
		b.quad(Vector3(-7.5, -0.5, 30), Vector3(7.5, -0.5, 30), Vector3(7.5, 0.0, 30), Vector3(-7.5, 0.0, 30), Vector3.BACK, conc)
		b.quad(Vector3(-7.5, -0.5, -30), Vector3(7.5, -0.5, -30), Vector3(7.5, 0.0, -30), Vector3(-7.5, 0.0, -30), Vector3.FORWARD, conc)

	# gedung-gedung: menara kaca dan gedung menengah ala Sudirman-Thamrin
	var pal := [Color(0.38, 0.52, 0.65), Color(0.3, 0.55, 0.55), Color(0.65, 0.65, 0.68), Color(0.8, 0.74, 0.62), Color(0.85, 0.86, 0.88), Color(0.2, 0.27, 0.35)]
	for sx in [-1.0, 1.0]:
		for j in 3:
			if rng.randf() < 0.1:
				continue
			var w := rng.randf_range(14.0, 18.0)
			var d := rng.randf_range(14.0, 22.0)
			var h := rng.randf_range(12.0, 28.0)
			if rng.randf() < 0.55:
				h = rng.randf_range(30.0, 90.0)
			var col: Color = pal[rng.randi() % pal.size()]
			var zc := 20.0 - 20.0 * j
			b.box(Vector3(sx * (10.5 + d * 0.5), h * 0.5, zc), Vector3(d, h, w), col)
			var band := col.darkened(0.4)
			var yy := 3.0
			while yy < h - 1.0:
				b.quad(Vector3(sx * 10.48, yy, zc - w * 0.5), Vector3(sx * 10.48, yy + 1.4, zc - w * 0.5), Vector3(sx * 10.48, yy + 1.4, zc + w * 0.5), Vector3(sx * 10.48, yy, zc + w * 0.5), Vector3(-sx, 0, 0), band)
				yy += 4.0
			if h > 25.0:
				b.box(Vector3(sx * (10.5 + d * 0.5), h + 1.5, zc), Vector3(d * 0.4, 3.0, w * 0.4), col.darkened(0.25))

	if city:
		for sz in [-15.0, 15.0]:
			for sx in [-1.0, 1.0]:
				b.box(Vector3(sx * 7.9, 4.5, sz), Vector3(0.25, 9.0, 0.25), Color(0.25, 0.25, 0.28))
				b.box(Vector3(sx * 6.9, 9.0, sz), Vector3(2.2, 0.2, 0.3), Color(0.25, 0.25, 0.28))
		for sx in [-1.0, 1.0]:
			var tz := rng.randf_range(-25.0, 25.0)
			b.box(Vector3(sx * 9.0, 1.4, tz), Vector3(0.4, 2.8, 0.4), Color(0.35, 0.25, 0.15))
			b.box(Vector3(sx * 9.0, 3.8, tz), Vector3(2.8, 2.4, 2.8), Color(0.2, 0.42, 0.2))

	var mi := MeshInstance3D.new()
	mi.mesh = b.mesh()
	mi.material_override = vm
	mi.visibility_range_end = 450.0
	return mi


func _build_world():
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var vm := StandardMaterial3D.new()
	vm.vertex_color_use_as_albedo = true
	vm.roughness = 1.0
	var meshes: Array = []
	for k in NCH:
		var tmp := _build_chunk(k, rng, vm)
		meshes.append(tmp.mesh)
		tmp.free()
	for i in ROUTE.size():
		var inst := MeshInstance3D.new()
		inst.mesh = meshes[ROUTE[i]]
		inst.material_override = vm
		inst.visibility_range_end = 450.0
		inst.position.z = -(i + 0.5) * CHUNK
		add_child(inst)
		chunks.append(inst)
	route_len = ROUTE.size() * CHUNK
	barriers = Node3D.new()
	add_child(barriers)
	for zz in [9.5, -route_len + 1.0]:
		_box(barriers, Vector3(15, 1.2, 0.8), Color(0.9, 0.2, 0.15), Vector3(0, 0.6, zz))
		_box(barriers, Vector3(15, 0.3, 0.85), Color.WHITE, Vector3(0, 0.75, zz))
		_box(barriers, Vector3(90, 22, 2), Color(0.55, 0.58, 0.64), Vector3(0, 11, zz + (3.0 if zz > 0 else -3.0)))


func _place_chunks():
	# potongan jalan digeser berulang sehingga rute 840 m terasa tak berujung
	for k in chunks.size():
		var ch: Node3D = chunks[k]
		var base := -(k + 0.5) * CHUNK
		var n := floorf((pos.z + 90.0 - base) / LOOP)
		ch.position.z = base + n * LOOP


func _build_car():
	car = Node3D.new()
	add_child(car)
	ext = Node3D.new()
	car.add_child(ext)
	var silver := Color(0.78, 0.8, 0.83)
	var dark := Color(0.08, 0.1, 0.14)
	# Avanza: panjang 4.19 m, lebar 1.66 m, tinggi 1.70 m, wheelbase 2.655 m
	_box(ext, Vector3(1.66, 0.6, 4.19), silver, Vector3(0, 0.65, 0))
	_box(ext, Vector3(1.56, 0.55, 2.45), dark, Vector3(0, 1.25, 0.3))
	_box(ext, Vector3(1.6, 0.07, 2.55), silver, Vector3(0, 1.58, 0.3))
	for sx in [-1, 1]:
		for sz in [-1.33, 1.33]:
			var w := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.3
			cyl.bottom_radius = 0.3
			cyl.height = 0.2
			cyl.radial_segments = 12
			cyl.material = _mat(Color(0.05, 0.05, 0.05))
			w.mesh = cyl
			w.rotation.z = PI / 2.0
			w.position = Vector3(sx * 0.8, 0.3, sz)
			ext.add_child(w)
		_box(ext, Vector3(0.28, 0.16, 0.04), Color(0.8, 0.05, 0.05), Vector3(sx * 0.65, 0.85, 2.1))
		_box(ext, Vector3(0.3, 0.15, 0.04), Color(1.0, 0.95, 0.7), Vector3(sx * 0.6, 0.85, -2.1))
	_box(ext, Vector3(0.8, 0.12, 0.04), Color(0.05, 0.05, 0.05), Vector3(0, 0.72, -2.1))
	_load_car(car_idx)


func _wav(path: String, loop: bool) -> AudioStreamWAV:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var b := f.get_buffer(f.get_length())
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = 22050
	st.stereo = false
	st.data = b.slice(44)
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.data.size() / 2)
	return st


func _mk_player(sname: String, loop: bool, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = _wav("res://%s.snd" % sname, loop)
	p.volume_db = db
	add_child(p)
	return p


func _build_audio():
	for i in 3:
		var p := AudioStreamPlayer.new()
		add_child(p)
		eng_p.append(p)
	starter_p = _mk_player("sfx_starter", false, -4.0)
	horn_p = _mk_player("sfx_horn", true, -2.0)
	tick_p = _mk_player("sfx_tick", false, -8.0)
	road_p = _mk_player("sfx_road", true, -6.0)
	amb_p = _mk_player("sfx_ambient", true, -17.0)
	for k in ["stall", "clunk", "hb"]:
		sfx[k] = _mk_player("sfx_" + k, false, -3.0)
	_apply_sounds()


func _play_sfx(k: String):
	var p: AudioStreamPlayer = sfx[k]
	if p.stream != null:
		p.play()


func _apply_sounds():
	var names := ["low", "mid", "high"]
	for i in eng_p.size():
		var p: AudioStreamPlayer = eng_p[i]
		p.stop()
		p.stream = _wav("res://sfx_eng_%s_%s.snd" % [engine_type, names[i]], true)
	horn_p.pitch_scale = CARS[car_idx]["horn"]


func _update_audio(dt: float):
	var live := state == "play" and not paused
	var running := live and engine_on
	var bases := [1000.0, 3000.0, 5500.0]
	var w0 := clampf((3000.0 - rpm) / 1800.0, 0.0, 1.0)
	var w2 := clampf((rpm - 3600.0) / 1600.0, 0.0, 1.0)
	var ws := [w0, clampf(1.0 - w0 - w2, 0.0, 1.0), w2]
	var vol := (0.5 + 0.5 * gas) * 0.9
	if rpm > REDLINE * 0.97 and fmod(blink * 12.0, 1.0) < 0.5:
		vol *= 0.5
	for i in eng_p.size():
		var p: AudioStreamPlayer = eng_p[i]
		if p.stream == null:
			continue
		if running:
			p.pitch_scale = clampf(rpm / bases[i], 0.4, 2.6)
			p.volume_db = linear_to_db(maxf(ws[i] * vol, 0.0001))
			if not p.playing:
				p.play()
		elif p.playing:
			p.stop()
	var sp := absf(speed)
	if road_p.stream != null:
		if live and sp > 0.5:
			road_p.pitch_scale = 0.7 + minf(sp / 30.0, 1.0) * 0.8
			road_p.volume_db = linear_to_db(clampf(sp / 25.0, 0.0, 1.0) * 0.5 + 0.0001)
			if not road_p.playing:
				road_p.play()
		elif road_p.playing:
			road_p.stop()
	if horn_p.stream != null:
		if live and horn_on:
			if not horn_p.playing:
				horn_p.play()
		elif horn_p.playing:
			horn_p.stop()
	if amb_p.stream != null:
		if live:
			if not amb_p.playing:
				amb_p.play()
		elif amb_p.playing:
			amb_p.stop()
	var bl := fmod(blink, 0.8) < 0.4
	if bl != last_blink:
		last_blink = bl
		if live and (sig != 0 or hazard) and tick_p.stream != null:
			tick_p.pitch_scale = 1.0 if bl else 0.8
			tick_p.play()


func _clear_car():
	if model != null:
		model.queue_free()
		model = null
	if interior != null:
		interior.queue_free()
		interior = null
	for n in plate_nodes:
		n.queue_free()
	plate_nodes.clear()
	hubs.clear()
	wheels.clear()
	lamp_mats.clear()
	turn_rest.clear()
	inner_mats.clear()
	glass_mat = null
	inside_now = true


func _load_car(idx: int):
	_clear_car()
	car_idx = idx
	var cfg: Dictionary = CARS[idx]
	engine_type = cfg["eng"]
	if ResourceLoader.exists(cfg["file"]):
		var res = load(cfg["file"])
		if res is PackedScene:
			model = res.instantiate()
			car.add_child(model)
			if cfg["std"]:
				_setup_std_model(cfg)
			else:
				_fit_model(model)
	_build_interior(cfg)
	_plate_at(cfg["pf"], true, cfg)
	_plate_at(cfg["pr"], false, cfg)
	if eng_p.size() > 0:
		_apply_sounds()
	_set_inside(false)


func _lamp_mat(base: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.emission_enabled = true
	m.emission = base
	m.emission_energy_multiplier = 0.0
	return m


func _setup_std_model(cfg: Dictionary):
	for k in ["FL", "FR", "RL", "RR"]:
		var h = model.find_child("hub_" + k, true, false)
		var w = model.find_child("wheel_" + k, true, false)
		if h != null and w != null:
			hubs[k] = h
			wheels[k] = w
		var tm = model.find_child("turn_" + k, true, false)
		if tm is MeshInstance3D:
			var rest: Color = cfg["trf"] if k.begins_with("F") else cfg["trr"]
			var lm := _lamp_mat(rest)
			tm.material_override = lm
			lamp_mats["turn_" + k] = lm
			turn_rest[k] = rest
	var heads := {"head": Color(0.95, 0.97, 1.0), "tail": Color(0.75, 0.03, 0.03), "rev": Color(0.95, 0.95, 0.95)}
	for k in heads:
		var mi = model.find_child("lamp_" + k, true, false)
		if mi is MeshInstance3D:
			var lm2 := _lamp_mat(heads[k])
			mi.material_override = lm2
			lamp_mats[k] = lm2
	var gl = model.find_child("glass", true, false)
	if gl is MeshInstance3D:
		glass_mat = StandardMaterial3D.new()
		glass_mat.albedo_color = Color(0.05, 0.08, 0.12, 0.45)
		glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass_mat.roughness = 0.1
		glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		gl.material_override = glass_mat
	var bd = model.find_child("body", true, false)
	if bd is MeshInstance3D:
		for i in bd.mesh.get_surface_count():
			var m0 = bd.mesh.surface_get_material(i)
			if m0 is StandardMaterial3D:
				var m2: StandardMaterial3D = m0.duplicate()
				m2.cull_mode = BaseMaterial3D.CULL_DISABLED
				inner_mats.append([bd, i, m2])


func _set_inside(v: bool):
	if v == inside_now:
		return
	inside_now = v
	for e in inner_mats:
		var mi: MeshInstance3D = e[0]
		mi.set_surface_override_material(e[1], e[2] if v else null)
	if glass_mat != null:
		glass_mat.albedo_color.a = 0.12 if v else 0.45


func _build_interior(cfg: Dictionary):
	interior = Node3D.new()
	car.add_child(interior)
	var dz: Vector3 = cfg["dash"]
	var wp: Vector3 = cfg["wheel"]
	var eye: Vector3 = cfg["eye"]
	var dark := Color(0.1, 0.1, 0.11)
	_box(interior, Vector3(cfg["dashw"], 0.22, 0.55), dark, dz)
	_box(interior, Vector3(0.55, 0.14, 0.3), Color(0.06, 0.06, 0.07), Vector3(wp.x, dz.y + 0.17, dz.z + 0.05))
	_box(interior, Vector3(0.4, 0.07, 0.02), Color(0.2, 0.3, 0.4), Vector3(wp.x, dz.y + 0.17, dz.z + 0.2))
	_box(interior, Vector3(0.3, 0.4, 0.9), dark, Vector3(0, 0.5, dz.z + 0.95))
	_box(interior, Vector3(0.07, 0.07, 0.07), Color(0.03, 0.03, 0.03), Vector3(0, 0.75, dz.z + 0.65))
	var seat := Color(0.33, 0.31, 0.29)
	for sx in [-0.36, 0.36]:
		_box(interior, Vector3(0.5, 0.14, 0.5), seat, Vector3(sx, 0.45, eye.z + 0.28))
		_box(interior, Vector3(0.5, 0.62, 0.12), seat, Vector3(sx, 0.8, eye.z + 0.55))
	_box(interior, Vector3(1.3, 0.14, 0.5), seat, Vector3(0, 0.45, eye.z + 1.3))
	_box(interior, Vector3(1.3, 0.6, 0.14), seat, Vector3(0, 0.82, eye.z + 1.6))
	var piv := Node3D.new()
	piv.position = wp
	piv.rotation.x = deg_to_rad(68.0)
	interior.add_child(piv)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.16
	tm.outer_radius = 0.19
	tm.rings = 16
	tm.ring_segments = 8
	tm.material = _mat(Color(0.04, 0.04, 0.05))
	wheel3d = MeshInstance3D.new()
	wheel3d.mesh = tm
	piv.add_child(wheel3d)
	_box(wheel3d, Vector3(0.34, 0.02, 0.03), Color(0.04, 0.04, 0.05), Vector3.ZERO)
	_box(wheel3d, Vector3(0.03, 0.02, 0.17), Color(0.04, 0.04, 0.05), Vector3(0, 0, 0.085))
	_box(wheel3d, Vector3(0.1, 0.04, 0.1), Color(0.25, 0.25, 0.27), Vector3.ZERO)


func _plate_at(at: Vector3, flip: bool, cfg: Dictionary):
	var root := Node3D.new()
	root.position = at
	if flip:
		root.rotation.y = PI
	car.add_child(root)
	plate_nodes.append(root)
	_box(root, Vector3(0.44, 0.14, 0.02), Color(0.02, 0.02, 0.02), Vector3.ZERO)
	var l := Label3D.new()
	l.text = cfg["plate"]
	l.font_size = 32
	l.pixel_size = 0.0018
	l.outline_size = 0
	l.modulate = Color.WHITE
	l.position = Vector3(0, 0.02, 0.012)
	root.add_child(l)
	var l2 := Label3D.new()
	l2.text = cfg["tax"]
	l2.font_size = 20
	l2.pixel_size = 0.0018
	l2.outline_size = 0
	l2.modulate = Color.WHITE
	l2.position = Vector3(0, -0.04, 0.012)
	root.add_child(l2)


func _update_car_parts(dt: float):
	var cfg: Dictionary = CARS[car_idx]
	if not paused:
		var rad: float = cfg["rad"]
		for k in wheels:
			var w: Node3D = wheels[k]
			w.rotation.x = fposmod(w.rotation.x - speed * dt / rad, TAU)
	for k in ["FL", "FR"]:
		if hubs.has(k):
			var h: Node3D = hubs[k]
			h.rotation.y = -steer
	if lamp_mats.is_empty():
		return
	var bl := fmod(blink, 0.8) < 0.4
	var hi := high_on or pass_on
	if lamp_mats.has("head"):
		var lh: StandardMaterial3D = lamp_mats["head"]
		lh.emission_energy_multiplier = (3.0 if hi else 1.6) if (low_on or hi) else 0.0
	if lamp_mats.has("tail"):
		var lt: StandardMaterial3D = lamp_mats["tail"]
		lt.emission_energy_multiplier = 3.0 if brake > 0.05 else (0.8 if low_on else 0.15)
	if lamp_mats.has("rev"):
		var lr: StandardMaterial3D = lamp_mats["rev"]
		lr.emission_energy_multiplier = 2.5 if gear == -1 else 0.0
	for k in ["FL", "FR", "RL", "RR"]:
		var key: String = "turn_" + k
		if lamp_mats.has(key):
			var lm: StandardMaterial3D = lamp_mats[key]
			var active: bool = (sig == -1 and k.ends_with("L")) or (sig == 1 and k.ends_with("R")) or hazard
			var on: bool = active and bl
			var col: Color = Color(1.0, 0.55, 0.05) if on else turn_rest[k]
			lm.albedo_color = col
			lm.emission = col
			lm.emission_energy_multiplier = 3.0 if on else 0.0


func _collect(n: Node, out: Array):
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)


func _aabb(m: Node3D) -> AABB:
	var meshes: Array = []
	_collect(m, meshes)
	var box := AABB()
	var has := false
	for mi: MeshInstance3D in meshes:
		var bb: AABB = mi.global_transform * mi.get_aabb()
		if has:
			box = box.merge(bb)
		else:
			box = bb
			has = true
	return box


func _fit_model(m: Node3D):
	# putar, skala ke panjang Avanza 4.19 m, taruh di tengah dan menapak tanah
	var bx := _aabb(m)
	var yaw := MODEL_YAW_DEG
	if bx.size.x > bx.size.z:
		yaw += 90.0
	m.rotation.y = deg_to_rad(yaw)
	bx = _aabb(m)
	var sc := 4.19 / maxf(bx.size.z, 0.01)
	m.scale = Vector3.ONE * sc
	bx = _aabb(m)
	var ctr := bx.position + bx.size * 0.5
	m.position = Vector3(-ctr.x, -bx.position.y, -ctr.z)


func _plate(z: float, flip: bool):
	var root := Node3D.new()
	root.position = Vector3(0, 0.62, z)
	if flip:
		root.rotation.y = PI
	car.add_child(root)
	_box(root, Vector3(0.44, 0.14, 0.02), Color(0.02, 0.02, 0.02), Vector3.ZERO)
	var l := Label3D.new()
	l.text = "B 1446 ZMG"
	l.font_size = 32
	l.pixel_size = 0.0018
	l.outline_size = 0
	l.modulate = Color.WHITE
	l.position = Vector3(0, 0.02, 0.012)
	root.add_child(l)
	var l2 := Label3D.new()
	l2.text = "01.31"
	l2.font_size = 20
	l2.pixel_size = 0.0018
	l2.outline_size = 0
	l2.modulate = Color.WHITE
	l2.position = Vector3(0, -0.04, 0.012)
	root.add_child(l2)


# ---------------------------------------------------------------- simulasi

func _say(t: String, secs: float):
	msg = t
	msg_t = secs


func _torque(r: float) -> float:
	var f := clampf(r / 4200.0, 0.5, 1.0)
	if r > 4200.0:
		f = lerpf(1.0, 0.8, (r - 4200.0) / 2000.0)
	return 121.0 * f


func _sim(dt: float):
	var ratio := 0.0
	if gear == -1:
		ratio = -REV_RATIO * FINAL
	elif gear > 0:
		var gr: float = RATIOS[gear]
		ratio = gr * FINAL
	# kopling: clutch 1 = diinjak penuh. Mulai menggigit di 0.65, penuh di 0.25
	var t := clampf((0.65 - clutch) / 0.4, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	var wheel_rpm := speed / WHEEL_R * ratio * 9.5493
	var engaged := ratio != 0.0 and t > 0.0
	var free := IDLE + gas * (REDLINE - IDLE)
	var idle_comp := 0.0
	if engaged and gas < 0.05:
		idle_comp = 450.0 * t   # ECU injeksi menaikkan idle saat kopling menggigit

	if engine_on:
		var target := free
		if engaged:
			target = lerpf(free + idle_comp, maxf(wheel_rpm, 0.0), t * t)
		rpm = lerpf(rpm, target, clampf(dt * 8.0, 0.0, 1.0))
		rpm = minf(rpm, REDLINE)
		if rpm < 500.0:
			engine_on = false
			rpm = 0.0
			stalls += 1
			_say("Mesin mati! Injak kopling, netral, tekan START", 4.0)
			_play_sfx("stall")
	else:
		rpm = lerpf(rpm, 0.0, clampf(dt * 6.0, 0.0, 1.0))

	var acc := 0.0
	if engaged:
		if engine_on:
			var gate := clampf(1.0 - (wheel_rpm - free - idle_comp) / 400.0, 0.0, 1.0)
			var tq := _torque(rpm) * maxf(gas, 0.35) * gate
			acc += tq * ratio / WHEEL_R * 0.9 * t / MASS
			if gas < 0.05 and wheel_rpm > IDLE + 100.0:
				acc -= signf(speed) * minf((wheel_rpm - IDLE) / 4000.0, 1.0) * 2.5 * t
		elif absf(speed) > 0.1:
			acc -= signf(speed) * 1.5 * t
	speed += acc * dt
	var res := (0.15 + 0.00034 * speed * speed + brake * 9.0 + (7.0 if handbrake else 0.0)) * dt
	if absf(speed) <= res:
		speed = 0.0
	else:
		speed -= signf(speed) * res

	# kemudi
	steer = lerpf(steer, steer_in * 0.5 / (1.0 + absf(speed) * 0.06), clampf(dt * 6.0, 0.0, 1.0))
	heading -= speed / 2.655 * tan(steer) * dt
	if absf(steer_in) < 0.05:
		heading = lerpf(heading, 0.0, clampf(dt * 1.2, 0.0, 1.0))  # bantuan lurus
	heading = clampf(heading, -0.6, 0.6)
	pos += Vector3(-sin(heading), 0.0, -cos(heading)) * speed * dt
	pos.x = clampf(pos.x, -6.4, -1.2)  # tetap di jalurnya, tidak naik median
	var zmin := -route_len + 6.0
	if pos.z < zmin or pos.z > 6.0:
		if (pos.z < zmin and speed > 0.0) or (pos.z > 6.0 and speed < 0.0):
			speed = 0.0
			_say("Ujung jalan", 2.0)
		pos.z = clampf(pos.z, zmin, 6.0)
	pos.y = _elev(-pos.z)


func _kf(vals: Array, h: float):
	for i in range(KH.size() - 1):
		if h <= KH[i + 1]:
			var f: float = (h - KH[i]) / (KH[i + 1] - KH[i])
			if vals[i] is Color:
				return vals[i].lerp(vals[i + 1], f)
			return lerpf(vals[i], vals[i + 1], f)
	return vals[vals.size() - 1]


func _clock() -> String:
	var h := fposmod(time_h, 24.0)
	return "%02d:%02d" % [int(h), int((h - floorf(h)) * 60.0)]


func _period() -> String:
	var h := fposmod(time_h, 24.0)
	if h < 5.0 or h >= 19.0:
		return "Malam"
	if h < 10.0:
		return "Pagi"
	if h < 15.0:
		return "Siang"
	return "Sore"


func _apply_time():
	if state == "menu":
		env.background_color = Color(0.05, 0.07, 0.12)
		env.ambient_light_color = Color(0.6, 0.65, 0.8)
		env.ambient_light_energy = 0.8
		sun.rotation_degrees = Vector3(-40, 35, 0)
		sun.light_energy = 1.0
		sun.light_color = Color.WHITE
		sun.shadow_enabled = shadows_on
		headlight.visible = false
		return
	var h := fposmod(time_h, 24.0)
	var sky: Color = _kf(KSKY, h)
	var se: float = _kf(KSUN, h)
	var am: float = _kf(KAMB, h)
	var t := clampf((h - 6.0) / 12.0, 0.0, 1.0)
	var elev := maxf(sin(t * PI) * 65.0, 8.0)
	sun.rotation_degrees = Vector3(-elev, lerpf(-80.0, 80.0, t), 0.0)
	sun.light_energy = se
	sun.light_color = Color(1.0, 0.62, 0.38).lerp(Color(1.0, 0.96, 0.88), clampf(elev / 35.0, 0.0, 1.0))
	sun.shadow_enabled = se > 0.2 and shadows_on
	env.background_color = sky
	env.ambient_light_color = sky.lerp(Color.WHITE, 0.55)
	env.ambient_light_energy = am
	cloud_mat.albedo_color = Color.WHITE.lerp(sky, 0.3) * clampf(0.25 + se, 0.25, 1.0)
	var hi := high_on or pass_on
	headlight.visible = low_on or hi
	headlight.spot_range = 75.0 if hi else 40.0
	headlight.light_energy = 3.5 if hi else 2.0


func _build_clouds():
	clouds = Node3D.new()
	add_child(clouds)
	cloud_mat = StandardMaterial3D.new()
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 9:
		var cl := Node3D.new()
		cl.position = Vector3(rng.randf_range(-260.0, 260.0), rng.randf_range(110.0, 170.0), rng.randf_range(-260.0, 260.0))
		clouds.add_child(cl)
		for k in 4:
			var m := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = rng.randf_range(14.0, 24.0)
			sp.height = sp.radius * 1.1
			sp.radial_segments = 6
			sp.rings = 3
			sp.material = cloud_mat
			m.mesh = sp
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.position = Vector3(k * 18.0 - 27.0 + rng.randf_range(-5.0, 5.0), rng.randf_range(-3.0, 3.0), rng.randf_range(-8.0, 8.0))
			cl.add_child(m)


func _enter_menu():
	state = "menu"
	paused = false
	touches.clear()
	tpos.clear()
	platform.visible = true
	clouds.visible = false
	for ch: Node3D in chunks:
		ch.visible = false
	barriers.visible = false
	horn_on = false
	car.position = Vector3.ZERO
	car.rotation = Vector3.ZERO
	wheel3d.rotation.y = 0.0


func _enter_play():
	state = "play"
	paused = false
	platform.visible = false
	clouds.visible = true
	speed = 0.0
	rpm = 0.0
	engine_on = false
	gear = 0
	clutch = 0.0
	gas = 0.0
	brake = 0.0
	steer_in = 0.0
	steer = 0.0
	heading = 0.0
	handbrake = false
	pos = Vector3(-5.6, 0.0, 0.0)
	cam_mode = 1
	for ch: Node3D in chunks:
		ch.visible = true
	barriers.visible = true
	wheel_angle = 0.0
	wheel_held = false
	lever = Vector2(0.5, 0.5)
	horn_on = false
	start_timer = 0.0
	_say("Injak kopling, lalu tekan START", 6.0)


func _process(delta):
	var dt := minf(delta, 0.05)
	blink += dt
	if state == "menu":
		menu_ang += dt * 0.4
	else:
		if not clutch_held and clutch > 0.0:
			clutch = move_toward(clutch, 0.0, dt * 3.0)  # pedal kopling kembali sendiri
		if not wheel_held and wheel_angle != 0.0:
			wheel_angle = move_toward(wheel_angle, 0.0, (3.0 + absf(speed) * 0.8) * dt)
			steer_in = wheel_angle / LOCK
		if not paused:
			if start_timer > 0.0:
				start_timer -= dt
				if start_timer <= 0.0:
					engine_on = true
					rpm = IDLE
					_say("Mesin hidup", 2.0)
			_sim(dt)
			time_h += dt / 60.0   # 1 detik nyata = 1 menit di game
		car.position = pos
		var s0 := -pos.z
		var pitch := atan2(_elev(s0 + 3.0) - _elev(s0 - 3.0), 6.0)
		car.rotation = Vector3(pitch, heading, 0.0)
		wheel3d.rotation.y = -wheel_angle
		_update_car_parts(dt)
		clouds.position = Vector3(pos.x, 0.0, pos.z)
	_apply_time()
	_update_audio(dt)
	_update_camera()
	if msg_t > 0.0:
		msg_t -= dt
	hud.queue_redraw()


func _update_camera():
	var inside := state == "play" and cam_mode == 1
	var std: bool = model != null and CARS[car_idx]["std"]
	if model != null:
		model.visible = std or not inside
		ext.visible = (not std) and inside
	else:
		ext.visible = true
	_set_inside(inside and std)
	if state == "menu":
		var tgt := Vector3(0, 0.8, 0)
		cam.fov = 45.0
		cam.position = tgt + Vector3(sin(menu_ang) * 7.5, 1.7, cos(menu_ang) * 7.5)
		cam.look_at(tgt)
		return
	if cam_mode == 1:
		cam.fov = 70.0
		cam.global_transform = car.global_transform * Transform3D(Basis(), CARS[car_idx]["eye"])
	elif cam_mode == 2:
		cam.fov = 60.0
		var target := car.position + Vector3(0, 1.0, 0)
		var off := Vector3(sin(orbit_yaw) * cos(orbit_pitch), sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch)) * orbit_dist
		cam.position = target + off
		cam.look_at(target)
	else:
		cam.fov = 65.0
		cam.global_transform = car.global_transform * Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3(0, 2.4, 7.0))


# ---------------------------------------------------------------- layout UI

func _vp() -> Vector2:
	return get_viewport().get_visible_rect().size

func r_clutch(s: Vector2) -> Rect2: return Rect2(s.x * 0.02, s.y * 0.48, s.x * 0.07, s.y * 0.49)
func r_brake(s: Vector2) -> Rect2: return Rect2(s.x * 0.83, s.y * 0.60, s.x * 0.07, s.y * 0.37)
func r_gas(s: Vector2) -> Rect2: return Rect2(s.x * 0.91, s.y * 0.48, s.x * 0.07, s.y * 0.49)
func r_shift(s: Vector2) -> Rect2: return Rect2(s.x * 0.82, s.y * 0.13, s.x * 0.16, s.y * 0.31)
func r_start(s: Vector2) -> Rect2: return Rect2(s.x * 0.79, s.y * 0.03, s.x * 0.09, s.y * 0.075)
func r_btn(i: int, s: Vector2) -> Rect2: return Rect2(s.x * (0.02 + i * 0.085), s.y * 0.03, s.x * (0.075 if i == 0 else 0.04), s.y * 0.075)
func r_top(i: int, s: Vector2) -> Rect2: return Rect2(s.x * (0.02 + i * 0.056), s.y * 0.135, s.x * 0.052, s.y * 0.062)
func r_hb(s: Vector2) -> Rect2: return Rect2(s.x * 0.89, s.y * 0.03, s.x * 0.09, s.y * 0.075)
func r_menu(s: Vector2) -> Rect2: return Rect2(s.x * 0.4, s.y * 0.62, s.x * 0.2, s.y * 0.1)
func r_menu_btn(i: int, s: Vector2) -> Rect2: return Rect2(s.x * (0.26 + i * 0.17), s.y * 0.76, s.x * 0.15, s.y * 0.2)
func r_gear(s: Vector2) -> Rect2: return Rect2(s.x * 0.93, s.y * 0.03, s.x * 0.05, s.y * 0.09)
func wheel_c(s: Vector2) -> Vector2: return Vector2(s.x * 0.098 + wheel_r(s), s.y * 0.71)
func wheel_r(s: Vector2) -> float: return s.y * 0.17


func shift_pt(g: int, r: Rect2) -> Vector2:
	var fx := 0.5
	var fy := 0.5
	match g:
		1: fx = 0.2; fy = 0.2
		2: fx = 0.2; fy = 0.8
		3: fx = 0.5; fy = 0.2
		4: fx = 0.5; fy = 0.8
		5: fx = 0.8; fy = 0.2
		-1: fx = 0.8; fy = 0.8
	return r.position + Vector2(fx * r.size.x, fy * r.size.y)


# ---------------------------------------------------------------- input

func _input(e):
	if e is InputEventScreenTouch:
		if e.pressed:
			_touch_down(e.index, e.position)
		else:
			_touch_up(e.index)
	elif e is InputEventScreenDrag:
		_touch_move(e.index, e.position, e.relative)


func r_arrow(i: int, s: Vector2) -> Rect2: return Rect2(s.x * (0.10 if i == 0 else 0.84), s.y * 0.34, s.x * 0.06, s.y * 0.16)


func _menu_touch(p: Vector2, s: Vector2):
	for i in 2:
		if r_arrow(i, s).has_point(p):
			var d := -1 if i == 0 else 1
			_load_car((car_idx + d + CARS.size()) % CARS.size())
			return
	for i in 3:
		if r_menu_btn(i, s).has_point(p):
			if i == 1:
				_enter_play()
			else:
				_say("Segera hadir", 2.0)
	if r_gear(s).has_point(p):
		_say("Pengaturan grafik: segera hadir", 2.0)


func _top_action(i: int):
	if i == 0:
		sig = 0 if sig == -1 else -1
	elif i == 1:
		hazard = not hazard
	elif i == 2:
		sig = 0 if sig == 1 else 1
	elif i == 3:
		var presets := [6.5, 12.0, 17.0, 20.5]
		var nxt: float = presets[0]
		for pz in presets:
			if pz > fposmod(time_h, 24.0) + 0.05:
				nxt = pz
				break
		time_h = nxt
		_say("Jam %s - %s" % [_clock(), _period()], 2.0)
	elif i == 4:
		low_on = not low_on
	elif i == 5:
		high_on = not high_on


func _touch_down(idx: int, p: Vector2):
	var s := _vp()
	if state == "menu":
		_menu_touch(p, s)
		return
	if paused:
		if r_btn(1, s).has_point(p):
			paused = false
		elif r_menu(s).has_point(p):
			_enter_menu()
		return
	if r_btn(0, s).has_point(p):
		cam_mode = cam_mode % 3 + 1
		_say("Kamera %d" % cam_mode, 1.5)
		return
	if r_btn(1, s).has_point(p):
		paused = true
		return
	if r_start(s).has_point(p):
		_start_pressed()
		return
	if r_hb(s).has_point(p):
		handbrake = not handbrake
		_say("(P) HANDBRAKE " + ("ON" if handbrake else "OFF"), 1.5)
		_play_sfx("hb")
		return
	for i in 8:
		if r_top(i, s).has_point(p):
			if i == 6:
				touches[idx] = "pass"
				pass_on = true
			elif i == 7:
				touches[idx] = "horn"
				horn_on = true
			else:
				_top_action(i)
			return
	var role := ""
	if r_clutch(s).grow(20.0).has_point(p):
		role = "clutch"
	elif r_gas(s).has_point(p):
		role = "gas"
	elif r_brake(s).has_point(p):
		role = "brake"
	elif (p - wheel_c(s)).length() < wheel_r(s) * 1.3:
		role = "wheel"
	elif r_shift(s).has_point(p):
		role = "shift"
	elif cam_mode == 2:
		role = "orbit"
	if role == "":
		return
	touches[idx] = role
	tpos[idx] = p
	_touch_move(idx, p, Vector2.ZERO)


func _touch_move(idx: int, p: Vector2, rel: Vector2):
	if not touches.has(idx):
		return
	var s := _vp()
	var role: String = touches[idx]
	if role == "clutch":
		clutch_held = true
		var r := r_clutch(s)
		clutch = clampf(1.0 - (p.y - r.position.y) / r.size.y, 0.0, 1.0)
	elif role == "gas":
		var r := r_gas(s)
		gas = clampf(1.0 - (p.y - r.position.y) / r.size.y, 0.0, 1.0)
	elif role == "brake":
		var r := r_brake(s)
		brake = clampf(1.0 - (p.y - r.position.y) / r.size.y, 0.0, 1.0)
	elif role == "wheel":
		wheel_held = true
		var rr := (p - rel) - wheel_c(s)
		var dn := maxf(rr.length_squared(), pow(wheel_r(s) * 0.45, 2.0))
		wheel_angle = clampf(wheel_angle + (rr.x * rel.y - rr.y * rel.x) / dn, -LOCK, LOCK)
		steer_in = wheel_angle / LOCK
	elif role == "shift":
		_shift_drag(p, s)
	elif role == "orbit":
		var other := Vector2.ZERO
		var has_other := false
		for k in touches:
			if k != idx and touches[k] == "orbit":
				other = tpos[k]
				has_other = true
		if has_other:
			var nd := p.distance_to(other)
			var od := (p - rel).distance_to(other)
			if nd > 1.0:
				orbit_dist = clampf(orbit_dist * od / nd, 4.0, 20.0)
		else:
			orbit_yaw -= rel.x * 0.008
			orbit_pitch = clampf(orbit_pitch + rel.y * 0.006, 0.05, 1.2)
	tpos[idx] = p


func _touch_up(idx: int):
	if not touches.has(idx):
		return
	var role: String = touches[idx]
	if role == "pass":
		pass_on = false
	elif role == "clutch":
		clutch_held = false
	elif role == "gas":
		gas = 0.0
	elif role == "brake":
		brake = 0.0
	elif role == "wheel":
		wheel_held = false
	elif role == "shift":
		_shift_release()
	elif role == "horn":
		horn_on = false
	touches.erase(idx)
	tpos.erase(idx)


func _shift_drag(p: Vector2, s: Vector2):
	var r := r_shift(s)
	var fx := clampf((p.x - r.position.x) / r.size.x, 0.2, 0.8)
	var fy := clampf((p.y - r.position.y) / r.size.y, 0.2, 0.8)
	var cols := [0.2, 0.5, 0.8]
	var ci := 0
	for i in 3:
		if absf(lever.x - cols[i]) < absf(lever.x - cols[ci]):
			ci = i
	var at_col: bool = absf(lever.x - cols[ci]) < 0.04
	if absf(lever.y - 0.5) < 0.08:
		lever.x = move_toward(lever.x, fx, 0.05)      # baris netral: geser kiri-kanan, ada batas kecepatan
		if at_col:
			lever.y = move_toward(lever.y, fy, 0.05)  # hanya bisa masuk gigi dari tengah jalur
			if absf(lever.y - 0.5) >= 0.08:
				lever.x = cols[ci]
	else:
		lever.y = move_toward(lever.y, fy, 0.05)      # di dalam jalur: hanya maju-mundur
	_apply_lever()


func _shift_release():
	var cols := [0.2, 0.5, 0.8]
	var ci := 0
	for i in 3:
		if absf(lever.x - cols[i]) < absf(lever.x - cols[ci]):
			ci = i
	lever.x = cols[ci]
	if lever.y <= 0.28:
		lever.y = 0.2
	elif lever.y >= 0.72:
		lever.y = 0.8
	else:
		lever.y = 0.5
	_apply_lever()


func _apply_lever():
	var cols := [0.2, 0.5, 0.8]
	var ci := 0
	for i in 3:
		if absf(lever.x - cols[i]) < absf(lever.x - cols[ci]):
			ci = i
	var g := 0
	if lever.y <= 0.28:
		g = [1, 3, 5][ci]
	elif lever.y >= 0.72:
		g = [2, 4, -1][ci]
	if g != gear:
		if g != 0 and clutch < 0.7:
			_say("Injak kopling dulu sebelum pindah gigi", 2.0)
			lever.y = 0.3 if lever.y < 0.5 else 0.7
			return
		gear = g
		if g != 0:
			_play_sfx("clunk")


func _try_gear(g: int):
	if g == gear:
		return
	if g != 0 and clutch < 0.7:
		_say("Injak kopling dulu sebelum pindah gigi", 2.0)
		return
	gear = g


func _start_pressed():
	if engine_on:
		engine_on = false
		return
	if start_timer > 0.0:
		return
	if gear != 0 and clutch < 0.7:
		_say("Injak kopling dulu atau masuk netral", 3.0)
		return
	start_timer = 0.9
	if starter_p != null and starter_p.stream != null:
		starter_p.play()


# ---------------------------------------------------------------- gambar HUD

func _btn(c: Control, r: Rect2, text: String, on := false, oncol := Color(0.2, 0.5, 0.3, 0.9), fs := 16):
	var font := ThemeDB.fallback_font
	if on:
		sb_on.bg_color = oncol
		c.draw_style_box(sb_on, r)
	else:
		c.draw_style_box(sb_btn, r)
	c.draw_string(font, r.position + Vector2(0, r.size.y * 0.64), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, Color.WHITE)


func _pedal(c: Control, r: Rect2, text: String, v: float, col: Color):
	var font := ThemeDB.fallback_font
	c.draw_style_box(sb_btn, r)
	var top_y := r.position.y + r.size.y * 0.17
	var slot := Rect2(r.position.x + r.size.x * 0.36, top_y, r.size.x * 0.28, r.size.y * 0.66)
	c.draw_style_box(sb_slot, slot)
	var fh := slot.size.y * v
	if fh > 3.0:
		c.draw_rect(Rect2(slot.position.x + 2.0, slot.end.y - fh, slot.size.x - 4.0, fh), Color(col.r, col.g, col.b, 0.9))
	var ph := r.size.y * 0.13
	var py := lerpf(r.end.y - ph - r.size.y * 0.05, top_y, v)
	var pad := Rect2(r.position.x + r.size.x * 0.12, py, r.size.x * 0.76, ph)
	c.draw_style_box(sb_pad, pad)
	for i in 3:
		var ly := pad.position.y + pad.size.y * (0.25 + 0.25 * i)
		c.draw_line(Vector2(pad.position.x + 6.0, ly), Vector2(pad.end.x - 6.0, ly), Color(0.3, 0.3, 0.33), 2.0)
	c.draw_string(font, r.position + Vector2(0, r.size.y * 0.12), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, col)


func _draw_msg(c: Control, s: Vector2, font: Font):
	if msg_t > 0.0:
		c.draw_style_box(sb_btn, Rect2(s.x * 0.30, s.y * 0.22, s.x * 0.40, s.y * 0.07))
		c.draw_string(font, Vector2(s.x * 0.30, s.y * 0.268), msg, HORIZONTAL_ALIGNMENT_CENTER, s.x * 0.40, 18, Color(1, 0.95, 0.8))


func _draw_menu(c: Control, s: Vector2, font: Font):
	var gold := Color(0.97, 0.73, 0.2)
	c.draw_rect(Rect2(0, 0, s.x, s.y * 0.14), Color(0.03, 0.04, 0.08, 0.9))
	c.draw_string(font, Vector2(s.x * 0.05, s.y * 0.105), "MANUAL DRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, gold)
	c.draw_style_box(sb_btn, r_gear(s))
	c.draw_string(font, r_gear(s).position + Vector2(0, r_gear(s).size.y * 0.62), "SET", HORIZONTAL_ALIGNMENT_CENTER, r_gear(s).size.x, 18, Color.WHITE)
	c.draw_string(font, Vector2(0, s.y * 0.71), CARS[car_idx]["name"] + " - " + CARS[car_idx]["plate"], HORIZONTAL_ALIGNMENT_CENTER, s.x, 24, Color(0.75, 0.78, 0.85))
	for i in 2:
		var ar := r_arrow(i, s)
		c.draw_style_box(sb_btn, ar)
		var ax := ar.position.x + ar.size.x * 0.5
		var ay := ar.position.y + ar.size.y * 0.5
		var dr := -1.0 if i == 0 else 1.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(ax + dr * 12.0, ay), Vector2(ax - dr * 8.0, ay - 14.0), Vector2(ax - dr * 8.0, ay + 14.0)]), gold)
	var names := ["Garasi", "Free Mode", "Karir"]
	for i in 3:
		var r := r_menu_btn(i, s)
		c.draw_style_box(sb_btn, r)
		var cx := r.position.x + r.size.x * 0.5
		var cy := r.position.y + r.size.y * 0.34
		if i == 0:
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx - 26, cy - 4), Vector2(cx, cy - 24), Vector2(cx + 26, cy - 4)]), gold)
			c.draw_rect(Rect2(cx - 22, cy - 4, 44, 26), gold)
		elif i == 1:
			c.draw_arc(Vector2(cx, cy), 24.0, 0.0, TAU, 32, gold, 5.0)
			c.draw_line(Vector2(cx - 24, cy), Vector2(cx + 24, cy), gold, 5.0)
			c.draw_line(Vector2(cx, cy), Vector2(cx, cy + 24), gold, 5.0)
		else:
			c.draw_line(Vector2(cx - 14, cy + 24), Vector2(cx - 14, cy - 24), gold, 4.0)
			c.draw_rect(Rect2(cx - 12, cy - 24, 34, 22), gold)
			c.draw_rect(Rect2(cx - 12, cy - 24, 17, 11), Color(0.1, 0.1, 0.1))
			c.draw_rect(Rect2(cx + 5, cy - 13, 17, 11), Color(0.1, 0.1, 0.1))
		if i != 1:
			c.draw_string(font, Vector2(r.position.x, r.position.y + r.size.y * 0.66), "SEGERA HADIR", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color(1.0, 0.7, 0.2))
		c.draw_string(font, Vector2(r.position.x, r.position.y + r.size.y * 0.9), names[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, Color.WHITE)
	_draw_msg(c, s, font)


func _draw_dash(c: Control, s: Vector2, font: Font, gtxt: String, bl: bool):
	var pr := Rect2(s.x * 0.40, s.y * 0.76, s.x * 0.30, s.y * 0.23)
	c.draw_style_box(sb_dash, pr)
	var k := pr.size.y / 150.0
	var rad := pr.size.y * 0.40
	var cl := Vector2(pr.position.x + pr.size.x * 0.17, pr.position.y + pr.size.y * 0.55)
	var cr := Vector2(pr.end.x - pr.size.x * 0.17, cl.y)
	for ct in [cl, cr]:
		c.draw_circle(ct, rad + 2.0, Color.WHITE)
		c.draw_circle(ct, rad, Color.BLACK)
	c.draw_string(font, cl + Vector2(-rad, -rad * 0.3), "RPM", HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, int(16 * k), Color.WHITE)
	c.draw_string(font, cl + Vector2(-rad, rad * 0.5), "%d" % int(rpm), HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, int(24 * k), Color.WHITE)
	c.draw_string(font, cr + Vector2(-rad, -rad * 0.3), "KM/H", HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, int(16 * k), Color.WHITE)
	c.draw_string(font, cr + Vector2(-rad, rad * 0.5), "%d" % int(absf(speed) * 3.6), HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, int(24 * k), Color.WHITE)
	var gb := Rect2(pr.position.x + pr.size.x * 0.39, pr.position.y + pr.size.y * 0.14, pr.size.x * 0.22, pr.size.y * 0.74)
	c.draw_rect(gb, Color(0.09, 0.13, 0.2))
	c.draw_string(font, gb.position + Vector2(0, 18.0 * k), "GEAR", HORIZONTAL_ALIGNMENT_CENTER, gb.size.x, int(14 * k), Color.WHITE)
	c.draw_string(font, gb.position + Vector2(0, gb.size.y * 0.62), gtxt, HORIZONTAL_ALIGNMENT_CENTER, gb.size.x, int(42 * k), Color.WHITE)
	var ltxt := "Off"
	if high_on or pass_on:
		ltxt = "High"
	elif low_on:
		ltxt = "Low"
	c.draw_string(font, gb.position + Vector2(4, gb.size.y - 22.0 * k), "Light: " + ltxt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * k), Color.WHITE)
	c.draw_string(font, gb.position + Vector2(4, gb.size.y - 8.0 * k), "Hazard: " + ("On" if hazard else "Off"), HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * k), Color.WHITE)
	var ay := gb.position.y + 20.0 * k
	var axl := (cl.x + rad + gb.position.x) * 0.5
	var axr := (cr.x - rad + gb.end.x) * 0.5
	var lon := (sig == -1 or hazard) and bl
	var ron := (sig == 1 or hazard) and bl
	var ah := 11.0 * k
	c.draw_colored_polygon(PackedVector2Array([Vector2(axl - 13.0 * k, ay), Vector2(axl + 9.0 * k, ay - ah), Vector2(axl + 9.0 * k, ay + ah)]), Color(0.2, 1.0, 0.3) if lon else Color(0.4, 0.4, 0.4))
	c.draw_colored_polygon(PackedVector2Array([Vector2(axr + 13.0 * k, ay), Vector2(axr - 9.0 * k, ay - ah), Vector2(axr - 9.0 * k, ay + ah)]), Color(0.2, 1.0, 0.3) if ron else Color(0.4, 0.4, 0.4))


func _draw_shifter(c: Control, s: Vector2, font: Font, gtxt: String):
	var sr := r_shift(s)
	c.draw_style_box(sb_btn, sr)
	var rail := Color(0.03, 0.03, 0.05)
	var th := maxf(6.0, s.y * 0.016)
	var xs := [0.2, 0.5, 0.8]
	var ym := sr.position.y + sr.size.y * 0.5
	c.draw_line(Vector2(sr.position.x + sr.size.x * 0.2, ym), Vector2(sr.position.x + sr.size.x * 0.8, ym), rail, th)
	for i in 3:
		var x: float = sr.position.x + sr.size.x * xs[i]
		var y0 := sr.position.y + sr.size.y * 0.2
		var y1 := sr.position.y + sr.size.y * 0.8
		c.draw_line(Vector2(x, y0), Vector2(x, y1), rail, th)
		c.draw_circle(Vector2(x, y0), th * 0.85, Color(0.18, 0.18, 0.22))
		c.draw_circle(Vector2(x, y1), th * 0.85, Color(0.18, 0.18, 0.22))
		var tl: String = ["1", "3", "5"][i]
		var bt: String = ["2", "4", "R"][i]
		c.draw_string(font, Vector2(x - 20.0, sr.position.y + sr.size.y * 0.12), tl, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color(0.85, 0.85, 0.9))
		c.draw_string(font, Vector2(x - 20.0, sr.position.y + sr.size.y * 0.96), bt, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color(0.85, 0.85, 0.9))
	var kp := sr.position + Vector2(lever.x * sr.size.x, lever.y * sr.size.y)
	c.draw_circle(kp, s.y * 0.034, Color(0.3, 0.7, 1.0))
	c.draw_string(font, kp + Vector2(-20.0, s.y * 0.012), gtxt, HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color(0.02, 0.05, 0.1))


func draw_hud(c: Control):
	var s := c.size
	var font := ThemeDB.fallback_font
	if state == "menu":
		_draw_menu(c, s, font)
		return
	var gtxt := "N"
	if gear == -1:
		gtxt = "R"
	elif gear > 0:
		gtxt = str(gear)
	var bl := fmod(blink, 0.8) < 0.4

	_pedal(c, r_clutch(s), "CLUTCH", clutch, Color(1.0, 0.75, 0.2))
	_pedal(c, r_brake(s), "BRAKE", brake, Color(0.9, 0.25, 0.2))
	_pedal(c, r_gas(s), "GAS", gas, Color(0.3, 0.9, 0.4))

	# setir menempel di samping kopling
	var wc := wheel_c(s)
	var wr := wheel_r(s)
	var a := wheel_angle
	var ring := Color(0.13, 0.13, 0.16)
	c.draw_circle(wc, wr, Color(0, 0, 0, 0.3))
	c.draw_arc(wc, wr * 0.93, 0.0, TAU, 48, ring, wr * 0.13)
	for k in [0.0, PI, PI * 0.5]:
		c.draw_line(wc, wc + Vector2.from_angle(a + k) * wr * 0.9, ring, wr * 0.09)
	c.draw_circle(wc, wr * 0.2, Color(0.22, 0.22, 0.26))
	c.draw_circle(wc + Vector2.from_angle(a - PI * 0.5) * wr * 0.93, wr * 0.06, Color(0.9, 0.2, 0.2))

	_draw_shifter(c, s, font, gtxt)

	_btn(c, r_btn(0, s), "CAMERA", false, Color(), 14)
	_btn(c, r_btn(1, s), "PLAY" if paused else "||", false, Color(), 16)
	_btn(c, r_start(s), "STOP" if engine_on else "START", engine_on, Color(0.2, 0.5, 0.3, 0.95), 17)
	_btn(c, r_hb(s), "(P)", handbrake, Color(0.8, 0.25, 0.2, 0.95), 18)

	# sein, hazard, jam, lampu, klakson
	var labels := ["", "HAZ", "", _clock(), "LAMPU", "JAUH", "PASS", "KLAKSON"]
	var actives := [sig == -1, hazard, sig == 1, false, low_on, high_on, pass_on, horn_on]
	for i in 8:
		var r := r_top(i, s)
		_btn(c, r, labels[i], actives[i], Color(0.85, 0.6, 0.1, 0.95) if i < 3 else Color(0.2, 0.5, 0.8, 0.95), 11)
		if i == 0 or i == 2:
			var dir := -1.0 if i == 0 else 1.0
			var cx := r.position.x + r.size.x * 0.5
			var cy := r.position.y + r.size.y * 0.5
			var ah := r.size.y * 0.25
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx + dir * ah, cy), Vector2(cx - dir * ah * 0.7, cy - ah), Vector2(cx - dir * ah * 0.7, cy + ah)]), Color(1, 0.8, 0.2))

	if handbrake:
		var pl := Rect2(s.x * 0.02, s.y * 0.21, s.x * 0.12, s.y * 0.05)
		c.draw_style_box(sb_pill, pl)
		c.draw_string(font, pl.position + Vector2(0, pl.size.y * 0.7), "(P) HANDBRAKE", HORIZONTAL_ALIGNMENT_CENTER, pl.size.x, 13, Color(0.95, 0.35, 0.3))

	# gigi + kecepatan + bar rpm (tengah atas)
	var ib := Rect2(s.x * 0.41, s.y * 0.02, s.x * 0.18, s.y * 0.105)
	c.draw_style_box(sb_btn, ib)
	c.draw_string(font, ib.position + Vector2(0, ib.size.y * 0.66), gtxt, HORIZONTAL_ALIGNMENT_CENTER, ib.size.x * 0.28, int(ib.size.y * 0.62), Color(0.35, 0.8, 1.0))
	c.draw_line(Vector2(ib.position.x + ib.size.x * 0.30, ib.position.y + 8.0), Vector2(ib.position.x + ib.size.x * 0.30, ib.end.y - 12.0), Color(0.3, 0.3, 0.35), 1.5)
	c.draw_string(font, ib.position + Vector2(ib.size.x * 0.33, ib.size.y * 0.66), "%d" % int(absf(speed) * 3.6), HORIZONTAL_ALIGNMENT_LEFT, -1, int(ib.size.y * 0.55), Color.WHITE)
	c.draw_string(font, ib.position + Vector2(ib.size.x * 0.76, ib.size.y * 0.66), "km/h", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.85))
	var bar := Rect2(ib.position.x + 10.0, ib.end.y - 9.0, ib.size.x - 20.0, 4.0)
	c.draw_rect(bar, Color(0.2, 0.22, 0.27))
	c.draw_rect(Rect2(bar.position.x, bar.position.y, bar.size.x * clampf(rpm / 7000.0, 0.0, 1.0), bar.size.y), Color(0.35, 0.8, 1.0) if rpm < 6000.0 else Color(0.95, 0.2, 0.15))
	c.draw_rect(Rect2(bar.end.x - bar.size.x * 0.14, bar.position.y, bar.size.x * 0.14, bar.size.y), Color(0.8, 0.15, 0.1, 0.5))

	if cam_mode == 1:
		_draw_dash(c, s, font, gtxt, bl)
	_draw_msg(c, s, font)
	if paused:
		c.draw_rect(Rect2(0, 0, s.x, s.y), Color(0, 0, 0, 0.5))
		c.draw_string(font, Vector2(0, s.y * 0.45), "PAUSE", HORIZONTAL_ALIGNMENT_CENTER, s.x, 48, Color.WHITE)
		_btn(c, r_menu(s), "KE MENU", true, Color(0.2, 0.5, 0.8, 0.95), 22)
		c.draw_string(font, Vector2(0, s.y * 0.88), "Model: Avanza 2015 oleh Raysh; Indonesian LMPV (Avanza baru, Sigra) oleh Han66st - semua CC BY 4.0, Sketchfab", HORIZONTAL_ALIGNMENT_CENTER, s.x, 16, Color(0.85, 0.85, 0.9))
