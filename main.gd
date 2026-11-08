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
const KH := [0.0, 5.0, 6.5, 9.0, 15.0, 17.0, 18.5, 20.0, 24.0]
const KSKY := [Color(0.02, 0.03, 0.08), Color(0.04, 0.05, 0.12), Color(0.95, 0.62, 0.45), Color(0.62, 0.78, 0.95), Color(0.62, 0.78, 0.95), Color(0.95, 0.72, 0.5), Color(0.75, 0.4, 0.3), Color(0.04, 0.05, 0.12), Color(0.02, 0.03, 0.08)]
const KSUN := [0.05, 0.05, 0.6, 1.0, 1.0, 0.8, 0.3, 0.05, 0.05]
const KAMB := [0.3, 0.3, 0.55, 0.75, 0.75, 0.6, 0.4, 0.3, 0.3]
const MODEL_YAW_DEG := 0.0   # ubah ke 180.0 kalau model menghadap terbalik

var car: Node3D
var cam: Camera3D
var hud: Hud
var wheel3d: MeshInstance3D
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
	sb_dash.corner_radius_top_right = 42
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


func _tree(parent: Node, at: Vector3, sc: float):
	_box(parent, Vector3(0.4, 3.0 * sc, 0.4), Color(0.35, 0.25, 0.15), at + Vector3(0, 1.5 * sc, 0))
	var m := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 2.0 * sc
	sp.height = 3.4 * sc
	sp.radial_segments = 8
	sp.rings = 4
	sp.material = _mat(Color(0.22, 0.4, 0.2))
	m.mesh = sp
	m.position = at + Vector3(0, 3.8 * sc, 0)
	parent.add_child(m)


func _build_world():
	# Meniru Jl. Raya Parung: dua jalur dipisah median beton, tiap jalur 2 lajur,
	# bahu tanah, ruko/warung rendah, tiang listrik, pohon, dan SPBU.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var palette := [Color(0.2, 0.65, 0.6), Color(0.9, 0.85, 0.7), Color(0.7, 0.35, 0.25), Color(0.85, 0.85, 0.85), Color(0.5, 0.7, 0.4), Color(0.9, 0.75, 0.3)]
	for i in CHUNKS:
		var ch := Node3D.new()
		add_child(ch)
		ch.position.z = CHUNK - CHUNK * i
		chunks.append(ch)
		_box(ch, Vector3(15, 0.1, CHUNK), Color(0.33, 0.33, 0.35), Vector3(0, -0.05, 0))
		_box(ch, Vector3(120, 0.1, CHUNK), Color(0.55, 0.5, 0.4), Vector3(0, -0.15, 0))
		_box(ch, Vector3(0.7, 0.28, CHUNK), Color(0.62, 0.62, 0.6), Vector3(0, 0.09, 0))
		for sx in [-1, 1]:
			_box(ch, Vector3(0.12, 0.02, CHUNK), Color(0.95, 0.8, 0.1), Vector3(sx * 0.55, 0.01, 0))
			_box(ch, Vector3(0.12, 0.02, CHUNK), Color.WHITE, Vector3(sx * 7.2, 0.01, 0))
			_box(ch, Vector3(4.0, 0.06, CHUNK), Color(0.72, 0.66, 0.55), Vector3(sx * 9.5, 0.0, 0))
			for k in 5:
				var dz := -CHUNK * 0.5 + 6.0 + k * 12.0
				_box(ch, Vector3(0.12, 0.02, 4.0), Color.WHITE, Vector3(sx * 3.85, 0.01, dz))
			for k in 4:
				if i == 2 and sx == -1:
					break
				if rng.randf() < 0.2:
					continue
				var h := rng.randf_range(3.5, 8.0)
				var col: Color = palette[rng.randi() % palette.size()]
				_box(ch, Vector3(10, h, 11), col, Vector3(sx * 17.0, h * 0.5, -CHUNK * 0.5 + 7.5 + k * 15.0))
			_box(ch, Vector3(0.25, 8.0, 0.25), Color(0.4, 0.38, 0.35), Vector3(sx * 11.0, 4.0, -15.0))
			_box(ch, Vector3(0.25, 8.0, 0.25), Color(0.4, 0.38, 0.35), Vector3(sx * 11.0, 4.0, 15.0))
			_tree(ch, Vector3(sx * 11.8, 0.0, rng.randf_range(-25.0, 25.0)), rng.randf_range(0.8, 1.2))
		if i == 2:
			# SPBU di sisi kiri
			_box(ch, Vector3(9, 0.4, 10), Color(0.95, 0.75, 0.1), Vector3(-15.0, 4.5, 0))
			_box(ch, Vector3(0.4, 4.5, 0.4), Color(0.8, 0.1, 0.1), Vector3(-12.0, 2.25, -4.0))
			_box(ch, Vector3(0.4, 4.5, 0.4), Color(0.8, 0.1, 0.1), Vector3(-12.0, 2.25, 4.0))
			_box(ch, Vector3(8, 3.5, 8), Color(0.9, 0.9, 0.88), Vector3(-23.0, 1.75, 0))


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
	_box(car, Vector3(1.6, 0.3, 0.5), Color(0.05, 0.05, 0.07), Vector3(0, 0.98, -0.75))
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
	_plate(2.11, false)
	_plate(-2.11, true)
	# setir 3D (setir kanan: pengemudi di sisi kanan, x positif)
	var piv := Node3D.new()
	piv.position = Vector3(0.37, 1.0, -0.3)
	piv.rotation.x = deg_to_rad(70.0)
	car.add_child(piv)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.16
	tm.outer_radius = 0.19
	tm.rings = 16
	tm.ring_segments = 8
	tm.material = _mat(Color(0.04, 0.04, 0.05))
	wheel3d = MeshInstance3D.new()
	wheel3d.mesh = tm
	piv.add_child(wheel3d)
	# model Avanza (opsional): taruh file avanza.glb di root proyek
	if ResourceLoader.exists("res://avanza.glb"):
		var res = load("res://avanza.glb")
		if res is PackedScene:
			model = res.instantiate()
			car.add_child(model)
			_fit_model(model)


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
	for i in CHUNKS:
		var ch: Node3D = chunks[i]
		ch.position.z = CHUNK - CHUNK * i
		ch.visible = true
	_say("Injak kopling, lalu tekan START", 6.0)


func _process(delta):
	var dt := minf(delta, 0.05)
	blink += dt
	if state == "menu":
		menu_ang += dt * 0.4
	else:
		if not clutch_held and clutch > 0.0:
			clutch = move_toward(clutch, 0.0, dt * 3.0)  # pedal kopling kembali sendiri
		if not paused:
			_sim(dt)
			time_h += dt / 60.0   # 1 detik nyata = 1 menit di game
		car.position = pos
		car.rotation.y = heading
		wheel3d.rotation.y = -steer_in * 1.6
		for ch: Node3D in chunks:
			if ch.position.z - pos.z > CHUNK * 1.5:
				ch.position.z -= CHUNK * CHUNKS
		clouds.position = Vector3(pos.x, 0.0, pos.z)
	_apply_time()
	_update_camera()
	if msg_t > 0.0:
		msg_t -= dt
	hud.queue_redraw()


func _update_camera():
	var inside := state == "play" and cam_mode == 1
	if model != null:
		model.visible = not inside
		ext.visible = inside
	else:
		ext.visible = true
	if state == "menu":
		var tgt := Vector3(0, 0.8, 0)
		cam.fov = 45.0
		cam.position = tgt + Vector3(sin(menu_ang) * 7.5, 1.7, cos(menu_ang) * 7.5)
		cam.look_at(tgt)
		return
	if cam_mode == 1:
		cam.fov = 70.0
		cam.global_transform = car.global_transform * Transform3D(Basis(), Vector3(0.37, 1.22, 0.15))
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

func r_clutch(s: Vector2) -> Rect2: return Rect2(s.x * 0.03, s.y * 0.40, s.x * 0.09, s.y * 0.56)
func r_brake(s: Vector2) -> Rect2: return Rect2(s.x * 0.80, s.y * 0.60, s.x * 0.08, s.y * 0.36)
func r_gas(s: Vector2) -> Rect2: return Rect2(s.x * 0.90, s.y * 0.46, s.x * 0.08, s.y * 0.50)
func r_shift(s: Vector2) -> Rect2: return Rect2(s.x * 0.80, s.y * 0.12, s.x * 0.18, s.y * 0.33)
func r_start(s: Vector2) -> Rect2: return Rect2(s.x * 0.80, s.y * 0.02, s.x * 0.18, s.y * 0.085)
func r_btn(i: int, s: Vector2) -> Rect2: return Rect2(s.x * 0.03 + i * s.x * 0.115, s.y * 0.03, s.x * 0.105, s.y * 0.085)
func r_top(i: int, s: Vector2) -> Rect2: return Rect2(s.x * (0.28 + i * 0.07), s.y * 0.03, s.x * 0.065, s.y * 0.085)
func r_hb(s: Vector2) -> Rect2: return Rect2(s.x * 0.155, s.y * 0.40, s.x * 0.12, s.y * 0.09)
func r_menu(s: Vector2) -> Rect2: return Rect2(s.x * 0.4, s.y * 0.62, s.x * 0.2, s.y * 0.1)
func r_menu_btn(i: int, s: Vector2) -> Rect2: return Rect2(s.x * (0.26 + i * 0.17), s.y * 0.76, s.x * 0.15, s.y * 0.2)
func r_gear(s: Vector2) -> Rect2: return Rect2(s.x * 0.93, s.y * 0.03, s.x * 0.05, s.y * 0.09)
func wheel_c(s: Vector2) -> Vector2: return Vector2(s.x * 0.24, s.y * 0.74)
func wheel_r(s: Vector2) -> float: return s.y * 0.19


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


func _menu_touch(p: Vector2, s: Vector2):
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
		low_on = not low_on
	elif i == 4:
		high_on = not high_on
	elif i == 6:
		var presets := [6.5, 12.0, 17.0, 20.5]
		var nxt: float = presets[0]
		for pz in presets:
			if pz > fposmod(time_h, 24.0) + 0.05:
				nxt = pz
				break
		time_h = nxt
		_say("Jam %s - %s" % [_clock(), _period()], 2.0)


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
		_say("Rem tangan " + ("terpasang" if handbrake else "dilepas"), 1.5)
		return
	for i in 7:
		if r_top(i, s).has_point(p):
			if i == 5:
				touches[idx] = "pass"
				pass_on = true
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
		var raw := clampf((p.x - wheel_c(s).x) / (wheel_r(s) * 1.8), -1.0, 1.0)
		steer_in = signf(raw) * pow(absf(raw), 1.6)
	elif role == "shift":
		var r := r_shift(s)
		var best := 0
		var bd := 1e9
		for g in [1, 2, 3, 4, 5, -1, 0]:
			var d := p.distance_to(shift_pt(g, r))
			if d < bd:
				bd = d
				best = g
		_try_gear(best)
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
		steer_in = 0.0
	touches.erase(idx)
	tpos.erase(idx)


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
	if gear != 0 and clutch < 0.7:
		_say("Injak kopling dulu atau masuk netral", 3.0)
		return
	engine_on = true
	rpm = IDLE
	_say("Mesin hidup. Injak kopling, masuk gigi 1", 3.0)


# ---------------------------------------------------------------- gambar HUD

func _btn(c: Control, r: Rect2, text: String, on := false, oncol := Color(0.2, 0.5, 0.3, 0.9), fs := 16):
	var font := ThemeDB.fallback_font
	c.draw_rect(r, oncol if on else Color(0.15, 0.17, 0.2, 0.85))
	c.draw_string(font, r.position + Vector2(0, r.size.y * 0.66), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, Color.WHITE)


func _pedal(c: Control, r: Rect2, text: String, v: float, col: Color):
	var font := ThemeDB.fallback_font
	c.draw_rect(r, Color(0, 0, 0, 0.45))
	var fh := r.size.y * v
	c.draw_rect(Rect2(r.position.x + r.size.x * 0.2, r.end.y - fh, r.size.x * 0.6, fh), Color(col.r, col.g, col.b, 0.6))
	c.draw_rect(Rect2(r.position.x, r.end.y - fh - 3.0, r.size.x, 6.0), col)
	c.draw_string(font, r.position + Vector2(0, -6), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, col)


func _draw_msg(c: Control, s: Vector2, font: Font):
	if msg_t > 0.0:
		c.draw_rect(Rect2(s.x * 0.27, s.y * 0.17, s.x * 0.46, s.y * 0.08), Color(0, 0, 0, 0.65))
		c.draw_string(font, Vector2(s.x * 0.27, s.y * 0.225), msg, HORIZONTAL_ALIGNMENT_CENTER, s.x * 0.46, 20, Color(1, 0.95, 0.8))


func _draw_menu(c: Control, s: Vector2, font: Font):
	var gold := Color(0.97, 0.73, 0.2)
	c.draw_rect(Rect2(0, 0, s.x, s.y * 0.14), Color(0.03, 0.04, 0.08, 0.9))
	c.draw_string(font, Vector2(s.x * 0.05, s.y * 0.105), "MANUAL DRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, gold)
	c.draw_style_box(sb_btn, r_gear(s))
	c.draw_string(font, r_gear(s).position + Vector2(0, r_gear(s).size.y * 0.62), "SET", HORIZONTAL_ALIGNMENT_CENTER, r_gear(s).size.x, 18, Color.WHITE)
	c.draw_string(font, Vector2(0, s.y * 0.71), "Avanza G MT 2018 - B 1446 ZMG", HORIZONTAL_ALIGNMENT_CENTER, s.x, 24, Color(0.75, 0.78, 0.85))
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
	var pr := Rect2(s.x * 0.43, s.y * 0.72, s.x * 0.36, s.y * 0.27)
	c.draw_style_box(sb_dash, pr)
	var rad := pr.size.y * 0.40
	var cl := Vector2(pr.position.x + pr.size.x * 0.17, pr.position.y + pr.size.y * 0.55)
	var cr := Vector2(pr.end.x - pr.size.x * 0.17, cl.y)
	for ct in [cl, cr]:
		c.draw_circle(ct, rad + 3.0, Color.WHITE)
		c.draw_circle(ct, rad, Color.BLACK)
	c.draw_string(font, cl + Vector2(-rad, -rad * 0.3), "RPM", HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, 18, Color.WHITE)
	c.draw_string(font, cl + Vector2(-rad, rad * 0.5), "%d" % int(rpm), HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, 26, Color.WHITE)
	c.draw_string(font, cr + Vector2(-rad, -rad * 0.3), "KM/H", HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, 18, Color.WHITE)
	c.draw_string(font, cr + Vector2(-rad, rad * 0.5), "%d" % int(absf(speed) * 3.6), HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, 26, Color.WHITE)
	var gb := Rect2(pr.position.x + pr.size.x * 0.39, pr.position.y + pr.size.y * 0.14, pr.size.x * 0.22, pr.size.y * 0.74)
	c.draw_rect(gb, Color(0.09, 0.13, 0.2))
	c.draw_string(font, gb.position + Vector2(0, 20), "GEAR", HORIZONTAL_ALIGNMENT_CENTER, gb.size.x, 15, Color.WHITE)
	c.draw_string(font, gb.position + Vector2(0, gb.size.y * 0.62), gtxt, HORIZONTAL_ALIGNMENT_CENTER, gb.size.x, 46, Color.WHITE)
	var ltxt := "Off"
	if high_on or pass_on:
		ltxt = "High"
	elif low_on:
		ltxt = "Low"
	c.draw_string(font, gb.position + Vector2(4, gb.size.y - 24), "Light: " + ltxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	c.draw_string(font, gb.position + Vector2(4, gb.size.y - 8), "Hazard: " + ("On" if hazard else "Off"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var ay := gb.position.y + 22.0
	var axl := (cl.x + rad + gb.position.x) * 0.5
	var axr := (cr.x - rad + gb.end.x) * 0.5
	var lon := (sig == -1 or hazard) and bl
	var ron := (sig == 1 or hazard) and bl
	c.draw_colored_polygon(PackedVector2Array([Vector2(axl - 14, ay), Vector2(axl + 10, ay - 11), Vector2(axl + 10, ay + 11)]), Color(0.2, 1.0, 0.3) if lon else Color(0.4, 0.4, 0.4))
	c.draw_colored_polygon(PackedVector2Array([Vector2(axr + 14, ay), Vector2(axr - 10, ay - 11), Vector2(axr - 10, ay + 11)]), Color(0.2, 1.0, 0.3) if ron else Color(0.4, 0.4, 0.4))


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

	# setir di samping kopling
	var wc := wheel_c(s)
	var wr := wheel_r(s)
	var a := steer_in * 1.6
	c.draw_circle(wc, wr, Color(0, 0, 0, 0.25))
	c.draw_arc(wc, wr, 0.0, TAU, 48, Color(0.12, 0.12, 0.14), 10.0)
	for k in [0.0, PI, PI * 0.5]:
		c.draw_line(wc, wc + Vector2.from_angle(a + k) * wr, Color(0.12, 0.12, 0.14), 8.0)
	c.draw_circle(wc, wr * 0.18, Color(0.2, 0.2, 0.23))
	c.draw_circle(wc + Vector2.from_angle(a - PI * 0.5) * wr, 6.0, Color(0.9, 0.2, 0.2))

	# tuas gigi
	var sr := r_shift(s)
	c.draw_rect(sr, Color(0.2, 0.2, 0.22, 0.85))
	var top := shift_pt(1, sr)
	var bot := shift_pt(2, sr)
	for gx in [1, 3, 5]:
		var x0 := shift_pt(gx, sr)
		c.draw_line(x0, Vector2(x0.x, bot.y), Color(0.05, 0.05, 0.06), 10.0)
	c.draw_line(Vector2(top.x, sr.position.y + sr.size.y * 0.5), Vector2(shift_pt(5, sr).x, sr.position.y + sr.size.y * 0.5), Color(0.05, 0.05, 0.06), 10.0)
	for g in [1, 2, 3, 4, 5, -1]:
		var pt := shift_pt(g, sr)
		c.draw_circle(pt, 9.0, Color(0.35, 0.35, 0.4))
		c.draw_string(font, pt + Vector2(-8, -14), "R" if g == -1 else str(g), HORIZONTAL_ALIGNMENT_CENTER, 16, 16, Color.WHITE)
	c.draw_circle(shift_pt(gear, sr), 15.0, Color(0.3, 0.7, 1.0))
	c.draw_string(font, shift_pt(gear, sr) + Vector2(-8, 7), gtxt, HORIZONTAL_ALIGNMENT_CENTER, 16, 18, Color.BLACK)

	# tombol utama
	_btn(c, r_btn(0, s), "CAM %d" % cam_mode, false, Color(), 20)
	_btn(c, r_btn(1, s), "PLAY" if paused else "PAUSE", false, Color(), 20)
	_btn(c, r_start(s), "STOP" if engine_on else "START", engine_on, Color(0.2, 0.5, 0.3, 0.9), 20)
	_btn(c, r_hb(s), "REM TANGAN", handbrake, Color(0.8, 0.2, 0.15, 0.9), 18)

	# sein, hazard, lampu, jam
	var labels := ["", "HAZ", "", "LAMPU", "JAUH", "PASS", _clock()]
	var actives := [sig == -1, hazard, sig == 1, low_on, high_on, pass_on, false]
	for i in 7:
		var r := r_top(i, s)
		_btn(c, r, labels[i], actives[i], Color(0.85, 0.6, 0.1, 0.9) if i < 3 else Color(0.2, 0.5, 0.8, 0.9), 14)
		if i == 0 or i == 2:
			var dir := -1.0 if i == 0 else 1.0
			var cx := r.position.x + r.size.x * 0.5
			var cy := r.position.y + r.size.y * 0.5
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx + dir * 14.0, cy), Vector2(cx - dir * 10.0, cy - 13.0), Vector2(cx - dir * 10.0, cy + 13.0)]), Color(1, 0.8, 0.2))

	_draw_dash(c, s, font, gtxt, bl)
	_draw_msg(c, s, font)
	if paused:
		c.draw_rect(Rect2(0, 0, s.x, s.y), Color(0, 0, 0, 0.5))
		c.draw_string(font, Vector2(0, s.y * 0.45), "PAUSE", HORIZONTAL_ALIGNMENT_CENTER, s.x, 48, Color.WHITE)
		_btn(c, r_menu(s), "KE MENU", true, Color(0.2, 0.5, 0.8, 0.95), 22)
		c.draw_string(font, Vector2(0, s.y * 0.88), "Model: 2015 Toyota Avanza G 1.3 oleh Raysh (sketchfab.com/Ray2007ben), CC BY 4.0", HORIZONTAL_ALIGNMENT_CENTER, s.x, 16, Color(0.85, 0.85, 0.9))
