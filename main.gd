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

var car: Node3D
var cam: Camera3D
var hud: Hud
var wheel3d: MeshInstance3D
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
	cam.far = 350.0
	add_child(cam)
	cam.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.g = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)


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
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.74, 0.77, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.9
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
	var silver := Color(0.78, 0.8, 0.83)
	var dark := Color(0.08, 0.1, 0.14)
	# Avanza: panjang 4.19 m, lebar 1.66 m, tinggi 1.70 m, wheelbase 2.655 m
	_box(car, Vector3(1.66, 0.6, 4.19), silver, Vector3(0, 0.65, 0))
	_box(car, Vector3(1.56, 0.55, 2.45), dark, Vector3(0, 1.25, 0.3))
	_box(car, Vector3(1.6, 0.07, 2.55), silver, Vector3(0, 1.58, 0.3))
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
			car.add_child(w)
		_box(car, Vector3(0.28, 0.16, 0.04), Color(0.8, 0.05, 0.05), Vector3(sx * 0.65, 0.85, 2.1))
		_box(car, Vector3(0.3, 0.15, 0.04), Color(1.0, 0.95, 0.7), Vector3(sx * 0.6, 0.85, -2.1))
	_box(car, Vector3(0.8, 0.12, 0.04), Color(0.05, 0.05, 0.05), Vector3(0, 0.72, -2.1))
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
	var f := clampf(r / 4200.0, 0.35, 1.0)
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

	if engine_on:
		var target := free
		if engaged:
			target = lerpf(free, maxf(wheel_rpm, 0.0), t * t)
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
			var gate := clampf(1.0 - (wheel_rpm - free) / 400.0, 0.0, 1.0)
			var tq := _torque(rpm) * maxf(gas, 0.12) * gate
			acc += tq * ratio / WHEEL_R * 0.9 * t / MASS
			if gas < 0.05 and wheel_rpm > IDLE + 100.0:
				acc -= signf(speed) * minf((wheel_rpm - IDLE) / 4000.0, 1.0) * 2.5 * t
		elif absf(speed) > 0.1:
			acc -= signf(speed) * 1.5 * t
	speed += acc * dt
	var res := (0.15 + 0.00034 * speed * speed + brake * 9.0) * dt
	if absf(speed) <= res:
		speed = 0.0
	else:
		speed -= signf(speed) * res

	# kemudi
	steer = lerpf(steer, steer_in * 0.5, clampf(dt * 6.0, 0.0, 1.0))
	heading -= speed / 2.655 * tan(steer) * dt
	if absf(steer_in) < 0.05:
		heading = lerpf(heading, 0.0, clampf(dt * 1.2, 0.0, 1.0))  # bantuan lurus
	heading = clampf(heading, -0.6, 0.6)
	pos += Vector3(-sin(heading), 0.0, -cos(heading)) * speed * dt
	pos.x = clampf(pos.x, -6.4, -1.2)  # tetap di jalurnya, tidak naik median


func _process(delta):
	var dt := minf(delta, 0.05)
	if not paused:
		_sim(dt)
	car.position = pos
	car.rotation.y = heading
	wheel3d.rotation.y = -steer_in * 1.6
	for ch: Node3D in chunks:
		if ch.position.z - pos.z > CHUNK * 1.5:
			ch.position.z -= CHUNK * CHUNKS
	_update_camera()
	if msg_t > 0.0:
		msg_t -= dt
	hud.queue_redraw()


func _update_camera():
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


func _touch_down(idx: int, p: Vector2):
	var s := _vp()
	if r_btn(0, s).has_point(p):
		cam_mode = cam_mode % 3 + 1
		_say("Kamera %d" % cam_mode, 1.5)
		return
	if r_btn(1, s).has_point(p):
		paused = not paused
		return
	if r_start(s).has_point(p):
		_start_pressed()
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
		var r := r_clutch(s)
		clutch = clampf(1.0 - (p.y - r.position.y) / r.size.y, 0.0, 1.0)
	elif role == "gas":
		var r := r_gas(s)
		gas = clampf(1.0 - (p.y - r.position.y) / r.size.y, 0.0, 1.0)
	elif role == "brake":
		var r := r_brake(s)
		brake = clampf(1.0 - (p.y - r.position.y) / r.size.y, 0.0, 1.0)
	elif role == "wheel":
		steer_in = clampf((p.x - wheel_c(s).x) / wheel_r(s), -1.0, 1.0)
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
	if role == "gas":
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

func _btn(c: Control, r: Rect2, text: String, on := false):
	var font := ThemeDB.fallback_font
	c.draw_rect(r, Color(0.15, 0.17, 0.2, 0.85) if not on else Color(0.2, 0.5, 0.3, 0.9))
	c.draw_string(font, r.position + Vector2(0, r.size.y * 0.68), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, Color.WHITE)


func _pedal(c: Control, r: Rect2, text: String, v: float, col: Color):
	var font := ThemeDB.fallback_font
	c.draw_rect(r, Color(0, 0, 0, 0.45))
	var fh := r.size.y * v
	c.draw_rect(Rect2(r.position.x + r.size.x * 0.2, r.end.y - fh, r.size.x * 0.6, fh), Color(col.r, col.g, col.b, 0.6))
	c.draw_rect(Rect2(r.position.x, r.end.y - fh - 3.0, r.size.x, 6.0), col)
	c.draw_string(font, r.position + Vector2(0, -6), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, col)


func _gauge(c: Control, ctr: Vector2, r: float, val: float, vmax: float, red_from: float, ticks: int, label: String):
	var font := ThemeDB.fallback_font
	var a0 := deg_to_rad(135.0)
	var a1 := deg_to_rad(405.0)
	c.draw_circle(ctr, r, Color(0.03, 0.03, 0.05, 0.92))
	c.draw_arc(ctr, r * 0.9, a0, a1, 48, Color(0.8, 0.8, 0.85), 2.0)
	if red_from > 0.0:
		c.draw_arc(ctr, r * 0.9, lerpf(a0, a1, red_from / vmax), a1, 12, Color(0.9, 0.15, 0.1), 5.0)
	for i in range(ticks + 1):
		var ang := lerpf(a0, a1, float(i) / ticks)
		c.draw_line(ctr + Vector2.from_angle(ang) * r * 0.78, ctr + Vector2.from_angle(ang) * r * 0.9, Color.WHITE, 2.0)
	var an := lerpf(a0, a1, clampf(val / vmax, 0.0, 1.0))
	c.draw_line(ctr, ctr + Vector2.from_angle(an) * r * 0.8, Color(1, 0.5, 0.1), 3.0)
	c.draw_string(font, ctr + Vector2(-r, r * 0.75), label, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 13, Color(0.8, 0.8, 0.85))


func draw_hud(c: Control):
	var s := c.size
	var font := ThemeDB.fallback_font
	var gtxt := "N"
	if gear == -1:
		gtxt = "R"
	elif gear > 0:
		gtxt = str(gear)

	# pedal
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

	# tombol
	_btn(c, r_btn(0, s), "CAM %d" % cam_mode)
	_btn(c, r_btn(1, s), "PLAY" if paused else "PAUSE")
	_btn(c, r_start(s), "STOP" if engine_on else "START", engine_on)

	# gigi + kecepatan
	var kmh := absf(speed) * 3.6
	c.draw_rect(Rect2(s.x * 0.38, s.y * 0.02, s.x * 0.24, s.y * 0.12), Color(0, 0, 0, 0.6))
	c.draw_string(font, Vector2(s.x * 0.40, s.y * 0.115), gtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.3, 0.8, 1.0))
	c.draw_string(font, Vector2(s.x * 0.47, s.y * 0.115), "%d km/h" % int(kmh), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)

	# instrumen (kamera interior)
	if cam_mode == 1:
		var gr := s.y * 0.13
		_gauge(c, Vector2(s.x * 0.44, s.y * 0.84), gr, rpm, 8000.0, 6000.0, 8, "x1000 rpm")
		_gauge(c, Vector2(s.x * 0.56, s.y * 0.84), gr, kmh, 200.0, 0.0, 10, "km/h")

	# pesan
	if msg_t > 0.0:
		c.draw_rect(Rect2(s.x * 0.27, s.y * 0.17, s.x * 0.46, s.y * 0.08), Color(0, 0, 0, 0.65))
		c.draw_string(font, Vector2(s.x * 0.27, s.y * 0.225), msg, HORIZONTAL_ALIGNMENT_CENTER, s.x * 0.46, 20, Color(1, 0.95, 0.8))
	if paused:
		c.draw_string(font, Vector2(0, s.y * 0.5), "PAUSE", HORIZONTAL_ALIGNMENT_CENTER, s.x, 48, Color.WHITE)
