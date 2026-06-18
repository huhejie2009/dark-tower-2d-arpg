extends Node3D

const BillboardActor3D := preload("res://scripts/prototype/BillboardActor3D.gd")
const BillboardActorManifestLibrary := preload("res://scripts/prototype/BillboardActorManifestLibrary.gd")
const CombatPlane3DService := preload("res://scripts/prototype/CombatPlane3DService.gd")
const Prototype2_5DVisualQaService := preload("res://scripts/prototype/Prototype2_5DVisualQaService.gd")
const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const SceneRouterScript := preload("res://scripts/app/SceneRouter.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")
const HudControllerScript := preload("res://scripts/ui/HudController.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")
const LootNotificationServiceScript := preload("res://scripts/data/LootNotificationService.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const TowerProgressServiceScript := preload("res://scripts/data/TowerProgressService.gd")
const LootRulesScript := preload("res://scripts/rules/LootRules.gd")
const DeathSettlementServiceScript := preload("res://scripts/data/DeathSettlementService.gd")

const ENEMY_CHASE_RANGE := 20.0
const ENEMY_ATTACK_RANGE := 1.05
const ENEMY_ATTACK_COOLDOWN := 0.8
const ENEMY_ATTACK_DAMAGE := 12
const ENEMY_MAX_HEALTH := 1
const PLAYER_ATTACK_RANGE := 1.35
const PLAYER_ATTACK_HALF_ANGLE := 80.0
const PLAYER_ATTACK_DAMAGE := 1
const PLAYER_ATTACK_COOLDOWN := 0.42
const PLAYER_ATTACK_ACTIVE_TIME := 0.14
const PLAYER_ATTACK_ARC_SEGMENTS := 12
const PLAYER_HIT_VFX_LIFETIME := 0.22
const DEATH_SETTLEMENT_PANEL_SIZE := Vector2(560, 500)
const DEATH_SETTLEMENT_SECTION_MIN_HEIGHT := 62

var player: Node3D
var player_data: Dictionary = {}
var death_return_player_data: Dictionary = {}
var current_floor := 1
var legacy_fallback_scene := GameConstantsScript.GAME_2D_SCENE
var kill_index := 0
var floor_kill_count := 0
var floor_pickup_names: Array[String] = []
var last_floor_rewards: Dictionary = {}
var last_loot_notification: Dictionary = {}
var last_xp_result: Dictionary = {}
var enemies: Array[Node3D] = []
var enemy_states: Dictionary = {}
var living_enemy_count := 0
var room_cleared := false
var exit_unlocked := false
var wall_nodes: Array[Node3D] = []
var column_nodes: Array[Node3D] = []
var actor_visible_markers: Array[MeshInstance3D] = []
var floor_mesh: MeshInstance3D
var exit_marker: Node3D
var player_attack_arc_marker: MeshInstance3D
var hit_vfx_root: Node3D
var hit_impact_marker: MeshInstance3D
var camera: Camera3D
var world_environment: WorldEnvironment
var key_light: DirectionalLight3D
var hud: CanvasLayer
var ui_layer: CanvasLayer
var inventory_window: Control
var pause_overlay: CanvasLayer
var pause_resume_button: Button
var death_overlay: CanvasLayer
var death_floor_section: Label
var death_kills_section: Label
var death_loot_section: Label
var death_boss_reward_section: Label
var death_summary_label: Label
var death_return_town_button: Button
var debug_hud: CanvasLayer
var camera_follow_offset := Vector3(0.0, 10.0, 10.0)
var player_move_input_override_enabled := false
var player_move_input_override := Vector2.ZERO
var active_move_input := Vector2.ZERO
var player_attack_direction_override_enabled := false
var player_attack_direction_override := Vector2.RIGHT
var last_player_attack_direction := Vector2.RIGHT
var player_attack_cooldown_remaining := 0.0
var player_attack_phase := "ready"
var total_player_attack_count := 0
var last_player_attack_hit_count := 0
var last_player_attack_aim_source := "none"
var last_player_attack_world_target := Vector3.ZERO
var hit_vfx_lifetime_remaining := 0.0
var last_hit_vfx_position := Vector3.ZERO
var debug_readability_markers_enabled := false
var death_settlement_active := false
var death_trigger_count := 0

func _ready() -> void:
	_initialize_main_flow_context()
	_build_visibility_baseline()
	_build_room()
	_build_camera()
	_build_actors()
	_build_exit_marker()
	_build_player_attack_arc_marker()
	_build_hit_vfx()
	_build_debug_hud()
	_create_hud()
	_create_inventory_window()
	_create_pause_overlay()
	_create_death_overlay()
	_update_hud("Entered floor %d. Left click attacks, I/C opens inventory, Esc pauses." % current_floor)

func _physics_process(_delta: float) -> void:
	if _is_menu_blocking_combat():
		active_move_input = Vector2.ZERO
		if player != null and player.has_method("set_move_input"):
			player.call("set_move_input", Vector2.ZERO)
		_sync_player_action_state()
		return
	active_move_input = _read_player_move_input()
	if player != null and player.has_method("set_move_input"):
		player.call("set_move_input", active_move_input)
	_update_camera_follow()
	_update_enemy_loop(_delta)
	_tick_player_attack(_delta)
	_tick_hit_vfx(_delta)

func _input(event: InputEvent) -> void:
	if death_settlement_active:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _is_menu_blocking_combat():
			_perform_player_attack(_read_player_attack_direction_from_mouse_event(event))
			_update_hud("Basic attack hit %d target(s)." % last_player_attack_hit_count)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if exit_unlocked and not _is_menu_blocking_combat():
			_enter_next_floor()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_handle_cancel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I or event.keycode == KEY_C:
			_toggle_inventory_window()
			get_viewport().set_input_as_handled()

func _initialize_main_flow_context() -> void:
	player_data = SaveManagerScript.get_active_player_data()
	current_floor = TowerRunStartServiceScript.consume_start_floor(player_data)

func _build_visibility_baseline() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "PrototypeWorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.043, 0.055)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.28, 0.32, 0.38)
	environment.ambient_light_energy = 1.1
	world_environment.environment = environment
	add_child(world_environment)

	key_light = DirectionalLight3D.new()
	key_light.name = "PrototypeKeyLight"
	key_light.light_energy = 2.2
	key_light.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	add_child(key_light)

func _build_room() -> void:
	floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "GreyboxFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 12.0)
	floor_mesh.mesh = plane
	floor_mesh.material_override = _make_material(Color(0.16, 0.18, 0.20), Color(0.02, 0.025, 0.03))
	add_child(floor_mesh)

	_create_wall("NorthWall", Vector3(0.0, 0.75, -6.0), Vector3(18.0, 1.5, 0.35))
	_create_wall("SouthWall", Vector3(0.0, 0.75, 6.0), Vector3(18.0, 1.5, 0.35))
	_create_wall("WestWall", Vector3(-9.0, 0.75, 0.0), Vector3(0.35, 1.5, 12.0))
	_create_wall("EastWall", Vector3(9.0, 0.75, 0.0), Vector3(0.35, 1.5, 12.0))
	_create_column("ColumnA", Vector3(-3.5, 0.75, -1.5))
	_create_column("ColumnB", Vector3(3.5, 0.75, 1.5))

func _create_wall(node_name: String, node_position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = node_position
	add_child(body)

	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape_node.shape = box
	body.add_child(shape_node)

	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.material_override = _make_material(Color(0.23, 0.24, 0.25), Color(0.015, 0.018, 0.022))
	body.add_child(mesh_node)
	wall_nodes.append(body)

func _create_column(node_name: String, node_position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = node_position
	add_child(body)

	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.5, 0.8)
	shape_node.shape = box
	body.add_child(shape_node)

	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 1.5, 0.8)
	mesh_node.mesh = mesh
	mesh_node.material_override = _make_material(Color(0.31, 0.32, 0.34), Color(0.025, 0.028, 0.032))
	body.add_child(mesh_node)
	column_nodes.append(body)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "PrototypeCamera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.position = Vector3(0.0, 10.0, 10.0)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _build_actors() -> void:
	player = BillboardActor3D.new()
	player.name = "PlayerBillboard"
	player.position = Vector3(0.0, 0.0, 2.0)
	player.set_movement_speed(4.5)
	add_child(player)
	_apply_actor_animation_manifest(player, BillboardActorManifestLibrary.make_player_warrior_v3())
	_add_actor_visible_marker(player, Color(0.22, 0.65, 1.0), "PlayerReadableMarker")
	_update_camera_follow()

	for index in range(2):
		_create_enemy_actor(index)
	living_enemy_count = enemies.size()

func _create_enemy_actor(index: int) -> Node3D:
	var enemy := BillboardActor3D.new()
	enemy.name = "EnemyBillboard%d" % (index + 1)
	enemy.position = Vector3(-2.0 + float(index) * 4.0, 0.0, -2.0)
	enemy.set_movement_speed(3.2)
	add_child(enemy)
	_apply_actor_animation_manifest(enemy, _make_enemy_actor_manifest(index))
	_add_actor_visible_marker(enemy, Color(0.95, 0.20, 0.16), "EnemyReadableMarker")
	enemies.append(enemy)
	enemy_states[enemy] = _make_enemy_state(_get_enemy_type_for_index(index))
	return enemy

func _get_enemy_type_for_index(index: int) -> String:
	if index == 0:
		return "rot_melee"
	return "shadow_archer"

func _apply_actor_animation_manifest(actor: Node3D, manifest: Dictionary) -> void:
	if actor == null or not actor.has_method("apply_visual_asset_manifest"):
		return
	var resolved_manifest := manifest if not manifest.is_empty() else _make_default_billboard_animation_manifest()
	actor.call("apply_visual_asset_manifest", resolved_manifest)

func _apply_default_actor_animation_manifest(actor: Node3D) -> void:
	if actor == null or not actor.has_method("apply_visual_asset_manifest"):
		return
	actor.call("apply_visual_asset_manifest", _make_default_billboard_animation_manifest())

func _make_enemy_actor_manifest(enemy_index: int) -> Dictionary:
	if enemy_index == 0:
		return BillboardActorManifestLibrary.make_rot_melee_v3()
	return BillboardActorManifestLibrary.make_shadow_archer_v3()

func _make_default_billboard_animation_manifest() -> Dictionary:
	return {
		"asset_pipeline": "runtime_placeholder",
		"enabled": false,
		"sprite_sheet_path": "",
		"frame_size": Vector2i(32, 48),
		"direction_mode": "4dir",
		"direction_frame_offsets": {
			"down": 0,
			"left": 12,
			"right": 24,
			"up": 36,
		},
		"animations": {
			"idle": {"from": 0, "to": 1, "fps": 8, "loop": true},
			"run": {"from": 4, "to": 5, "fps": 10, "loop": true},
			"attack": {"from": 8, "to": 9, "fps": 10, "loop": false},
			"death": {"from": 10, "to": 11, "fps": 6, "loop": false},
		},
	}

func _build_exit_marker() -> void:
	exit_marker = MeshInstance3D.new()
	exit_marker.name = "ExitMarker"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.55
	mesh.bottom_radius = 0.55
	mesh.height = 0.08
	exit_marker.mesh = mesh
	exit_marker.position = Vector3(0.0, 0.05, -4.8)
	add_child(exit_marker)
	_set_exit_locked_visual()

func _build_player_attack_arc_marker() -> void:
	player_attack_arc_marker = MeshInstance3D.new()
	player_attack_arc_marker.name = "PlayerAttackArcMarker"
	player_attack_arc_marker.mesh = _make_attack_arc_mesh(PLAYER_ATTACK_RANGE, PLAYER_ATTACK_HALF_ANGLE)
	player_attack_arc_marker.material_override = _make_translucent_material(Color(0.42, 0.74, 1.0, 0.34), Color(0.04, 0.18, 0.36))
	player_attack_arc_marker.visible = false
	add_child(player_attack_arc_marker)

func _build_hit_vfx() -> void:
	hit_vfx_root = Node3D.new()
	hit_vfx_root.name = "PrototypeHitVfxRoot"
	add_child(hit_vfx_root)

	hit_impact_marker = MeshInstance3D.new()
	hit_impact_marker.name = "HitImpactMarker"
	hit_impact_marker.set_meta("vfx_role", "hit_impact")
	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.32
	hit_impact_marker.mesh = mesh
	hit_impact_marker.material_override = _make_translucent_material(Color(1.0, 0.76, 0.32, 0.62), Color(0.65, 0.32, 0.08))
	hit_impact_marker.visible = false
	hit_vfx_root.add_child(hit_impact_marker)

func _build_debug_hud() -> void:
	debug_hud = CanvasLayer.new()
	debug_hud.name = "PrototypeDebugHUD"
	add_child(debug_hud)

	var label := Label.new()
	label.name = "PrototypeModeLabel"
	label.text = "2.5D PROTOTYPE - greybox visibility pass"
	label.position = Vector2(24.0, 20.0)
	label.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0))
	label.add_theme_font_size_override("font_size", 20)
	debug_hud.add_child(label)

func _create_hud() -> void:
	hud = HudControllerScript.new()
	hud.name = "HudController"
	add_child(hud)

func _create_inventory_window() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "PrototypeUiLayer"
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	inventory_window = InventoryEquipmentWindowScript.new()
	inventory_window.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(inventory_window)
	inventory_window.set_player_data(player_data)
	inventory_window.player_data_changed.connect(_on_player_data_changed)
	inventory_window.close_requested.connect(func(): _set_inventory_window_visible(false))

func _create_pause_overlay() -> void:
	pause_overlay = CanvasLayer.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	add_child(pause_overlay)

	var veil := ColorRect.new()
	veil.name = "PauseDarkVeil"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.0, 0.0, 0.0, 0.48)
	pause_overlay.add_child(veil)

	var panel := PanelContainer.new()
	panel.position = Vector2(490, 205)
	panel.size = Vector2(300, 230)
	DarkArpgUiThemeScript.style_panel(panel, true)
	pause_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_title(title, 24)
	box.add_child(title)

	pause_resume_button = Button.new()
	pause_resume_button.name = "ResumeButton"
	pause_resume_button.text = "Resume"
	pause_resume_button.custom_minimum_size = Vector2(260, 42)
	DarkArpgUiThemeScript.style_button(pause_resume_button, true)
	pause_resume_button.pressed.connect(_toggle_pause)
	box.add_child(pause_resume_button)

	var inventory := Button.new()
	inventory.name = "PauseInventoryButton"
	inventory.text = "Inventory / Equipment"
	inventory.custom_minimum_size = Vector2(260, 42)
	DarkArpgUiThemeScript.style_button(inventory)
	inventory.pressed.connect(_toggle_inventory_window)
	box.add_child(inventory)

	var town := Button.new()
	town.name = "ReturnTownButton"
	town.text = "Return To Town"
	town.custom_minimum_size = Vector2(260, 42)
	DarkArpgUiThemeScript.style_button(town)
	town.pressed.connect(_return_to_town)
	box.add_child(town)

func _create_death_overlay() -> void:
	death_overlay = CanvasLayer.new()
	death_overlay.name = "DeathSettlementOverlay"
	death_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	death_overlay.visible = false
	add_child(death_overlay)

	var veil := ColorRect.new()
	veil.name = "DeathDarkVeil"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.0, 0.0, 0.0, 0.62)
	death_overlay.add_child(veil)

	var panel := PanelContainer.new()
	panel.position = Vector2(360, 110)
	panel.size = DEATH_SETTLEMENT_PANEL_SIZE
	DarkArpgUiThemeScript.style_panel(panel, true)
	death_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Death Settlement"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_title(title, 26)
	box.add_child(title)

	death_floor_section = _make_death_section_label("DeathFloorSection")
	box.add_child(death_floor_section)
	death_kills_section = _make_death_section_label("DeathKillsSection")
	box.add_child(death_kills_section)
	death_loot_section = _make_death_section_label("DeathLootSection")
	box.add_child(death_loot_section)
	death_boss_reward_section = _make_death_section_label("DeathBossRewardSection")
	box.add_child(death_boss_reward_section)

	death_summary_label = Label.new()
	death_summary_label.name = "DeathSummary"
	death_summary_label.visible = false
	death_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	death_summary_label.custom_minimum_size = Vector2(500, 1)
	DarkArpgUiThemeScript.style_body_label(death_summary_label, 15, true)
	box.add_child(death_summary_label)

	death_return_town_button = Button.new()
	death_return_town_button.name = "DeathReturnTownButton"
	death_return_town_button.text = "Return To Town"
	death_return_town_button.custom_minimum_size = Vector2(380, 46)
	DarkArpgUiThemeScript.style_button(death_return_town_button, true)
	death_return_town_button.pressed.connect(_return_to_town_after_death)
	box.add_child(death_return_town_button)

func _make_death_section_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(520, DEATH_SETTLEMENT_SECTION_MIN_HEIGHT)
	DarkArpgUiThemeScript.style_body_label(label, 15)
	return label

func _add_actor_visible_marker(actor: Node3D, color: Color, node_name: String) -> void:
	var marker := MeshInstance3D.new()
	marker.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.36
	mesh.height = 0.18
	marker.mesh = mesh
	marker.position = Vector3(0.0, 0.11, 0.0)
	marker.material_override = _make_material(color, color * 0.25)
	marker.visible = debug_readability_markers_enabled
	marker.set_meta("debug_readability_marker", true)
	actor.add_child(marker)
	actor_visible_markers.append(marker)

func _make_material(albedo: Color, emission: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.roughness = 0.85
	return material

func _make_translucent_material(albedo: Color, emission: Color) -> StandardMaterial3D:
	var material := _make_material(albedo, emission)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _make_attack_arc_mesh(radius: float, half_angle_degrees: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var half_angle := deg_to_rad(half_angle_degrees)
	for index in range(PLAYER_ATTACK_ARC_SEGMENTS):
		var angle_a := lerpf(-half_angle, half_angle, float(index) / float(PLAYER_ATTACK_ARC_SEGMENTS))
		var angle_b := lerpf(-half_angle, half_angle, float(index + 1) / float(PLAYER_ATTACK_ARC_SEGMENTS))
		vertices.append(Vector3.ZERO)
		vertices.append(Vector3(cos(angle_a) * radius, 0.0, sin(angle_a) * radius))
		vertices.append(Vector3(cos(angle_b) * radius, 0.0, sin(angle_b) * radius))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _read_player_move_input() -> Vector2:
	if player_move_input_override_enabled:
		return player_move_input_override
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

func _update_camera_follow() -> void:
	if camera == null or player == null:
		return
	var target_position := player.global_position
	camera.global_position = target_position + camera_follow_offset
	camera.look_at(target_position, Vector3.UP)

func set_player_move_input_for_test(value: Vector2) -> void:
	player_move_input_override_enabled = true
	player_move_input_override = value

func clear_player_move_input_override_for_test() -> void:
	player_move_input_override_enabled = false
	player_move_input_override = Vector2.ZERO

func _tick_player_attack(delta: float) -> void:
	if player_attack_cooldown_remaining <= 0.0:
		player_attack_phase = "ready"
		_hide_player_attack_arc()
		_sync_player_action_state()
		return
	player_attack_cooldown_remaining = maxf(0.0, player_attack_cooldown_remaining - delta)
	if player_attack_cooldown_remaining <= 0.0:
		player_attack_phase = "ready"
		_hide_player_attack_arc()
	elif player_attack_cooldown_remaining >= PLAYER_ATTACK_COOLDOWN - PLAYER_ATTACK_ACTIVE_TIME:
		player_attack_phase = "active"
	else:
		player_attack_phase = "recovery"
	_sync_player_action_state()

func _tick_hit_vfx(delta: float) -> void:
	if hit_impact_marker == null or hit_vfx_lifetime_remaining <= 0.0:
		return
	hit_vfx_lifetime_remaining = maxf(0.0, hit_vfx_lifetime_remaining - delta)
	if hit_vfx_lifetime_remaining <= 0.0:
		hit_impact_marker.visible = false
		return
	var progress := hit_vfx_lifetime_remaining / PLAYER_HIT_VFX_LIFETIME
	hit_impact_marker.scale = Vector3.ONE * lerpf(0.7, 1.35, progress)

func _read_player_attack_direction_from_mouse_event(event: InputEventMouseButton) -> Vector2:
	if player_attack_direction_override_enabled:
		last_player_attack_aim_source = "override"
		return _read_player_attack_direction()
	var direction := _attack_direction_from_screen_position(event.position)
	if direction.length_squared() > 0.0001:
		last_player_attack_aim_source = "mouse"
		return direction
	last_player_attack_aim_source = "fallback"
	return _read_player_attack_direction()

func _read_player_attack_direction() -> Vector2:
	if player_attack_direction_override_enabled:
		return _normalize_attack_direction(player_attack_direction_override)
	if active_move_input.length_squared() > 0.0001:
		return _normalize_attack_direction(active_move_input)
	return _normalize_attack_direction(last_player_attack_direction)

func _attack_direction_from_screen_position(screen_position: Vector2) -> Vector2:
	if camera == null or player == null:
		return Vector2.ZERO
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	if absf(ray_direction.y) <= 0.0001:
		return Vector2.ZERO
	var plane_y := player.global_position.y
	var distance_to_plane := (plane_y - ray_origin.y) / ray_direction.y
	if distance_to_plane < 0.0:
		return Vector2.ZERO
	last_player_attack_world_target = ray_origin + ray_direction * distance_to_plane
	var direction := Vector2(
		last_player_attack_world_target.x - player.global_position.x,
		last_player_attack_world_target.z - player.global_position.z
	)
	return _normalize_attack_direction(direction)

func _normalize_attack_direction(direction: Vector2) -> Vector2:
	if direction.length_squared() <= 0.0001:
		return Vector2.RIGHT
	return direction.normalized()

func _perform_player_attack(direction: Vector2) -> Dictionary:
	if death_settlement_active:
		return {
			"accepted": false,
			"hit_count": 0,
			"cooldown_remaining": player_attack_cooldown_remaining,
			"attack_phase": "dead",
		}
	var attack_direction := _normalize_attack_direction(direction)
	if player_attack_cooldown_remaining > 0.0:
		return {
			"accepted": false,
			"hit_count": 0,
			"cooldown_remaining": player_attack_cooldown_remaining,
			"attack_phase": player_attack_phase,
		}
	last_player_attack_direction = attack_direction
	player_attack_cooldown_remaining = PLAYER_ATTACK_COOLDOWN
	player_attack_phase = "active"
	_sync_player_action_state()
	total_player_attack_count += 1
	last_player_attack_hit_count = 0
	_show_player_attack_arc(attack_direction)
	var target := _find_player_attack_target(attack_direction)
	if target != null:
		_show_hit_vfx(target.global_position)
		_damage_enemy(target, PLAYER_ATTACK_DAMAGE)
		last_player_attack_hit_count = 1
	return {
		"accepted": true,
		"hit_count": last_player_attack_hit_count,
		"cooldown_remaining": player_attack_cooldown_remaining,
		"attack_phase": player_attack_phase,
	}

func _find_player_attack_target(direction: Vector2) -> Node3D:
	if player == null:
		return null
	var forward := Vector3(direction.x, 0.0, direction.y)
	var best_enemy: Node3D = null
	var best_distance := INF
	for enemy in enemies:
		if enemy == null or not enemy_states.has(enemy):
			continue
		var state: Dictionary = enemy_states[enemy]
		if not bool(state.get("alive", false)):
			continue
		if not CombatPlane3DService.is_inside_attack_arc_xz(player.global_position, enemy.global_position, forward, PLAYER_ATTACK_RANGE, PLAYER_ATTACK_HALF_ANGLE):
			continue
		var distance := CombatPlane3DService.distance_xz(player.global_position, enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best_enemy = enemy
	return best_enemy

func _damage_enemy(enemy: Node3D, amount: int) -> void:
	if enemy == null or not enemy_states.has(enemy):
		return
	var state: Dictionary = enemy_states[enemy]
	if not bool(state.get("alive", false)):
		return
	state["health"] = maxi(0, int(state.get("health", 0)) - amount)
	enemy_states[enemy] = state
	if int(state.get("health", 0)) <= 0:
		_defeat_enemy(enemy)

func set_player_attack_direction_for_test(value: Vector2) -> void:
	player_attack_direction_override_enabled = true
	player_attack_direction_override = value
	last_player_attack_direction = _normalize_attack_direction(value)
	last_player_attack_aim_source = "override"

func clear_player_attack_direction_override_for_test() -> void:
	player_attack_direction_override_enabled = false

func perform_player_attack_for_test(direction: Vector2) -> Dictionary:
	last_player_attack_aim_source = "test"
	return _perform_player_attack(direction)

func _show_player_attack_arc(direction: Vector2) -> void:
	if player_attack_arc_marker == null or player == null:
		return
	var normalized := _normalize_attack_direction(direction)
	player_attack_arc_marker.visible = true
	player_attack_arc_marker.global_position = player.global_position + Vector3(0.0, 0.045, 0.0)
	player_attack_arc_marker.rotation = Vector3(0.0, -atan2(normalized.y, normalized.x), 0.0)

func _hide_player_attack_arc() -> void:
	if player_attack_arc_marker != null:
		player_attack_arc_marker.visible = false

func _show_hit_vfx(world_position: Vector3) -> void:
	if hit_impact_marker == null:
		return
	last_hit_vfx_position = world_position + Vector3(0.0, 0.35, 0.0)
	hit_impact_marker.global_position = last_hit_vfx_position
	hit_impact_marker.scale = Vector3.ONE
	hit_impact_marker.visible = true
	hit_vfx_lifetime_remaining = PLAYER_HIT_VFX_LIFETIME

func _sync_player_action_state() -> void:
	if player == null or not player.has_method("set_action_state"):
		return
	if death_settlement_active or _is_player_dead_runtime():
		player.call("set_action_state", "death")
	elif player_attack_phase == "active" or player_attack_phase == "recovery":
		player.call("set_action_state", "attack")
	elif active_move_input.length_squared() > 0.0001:
		player.call("set_action_state", "run")
	else:
		player.call("set_action_state", "idle")
	_update_actor_animation(player, active_move_input, player_attack_phase == "active" or player_attack_phase == "recovery", death_settlement_active or _is_player_dead_runtime())

func _is_player_dead_runtime() -> bool:
	return int(player_data.get("health", player_data.get("max_health", 1))) <= 0

func _update_actor_animation(actor: Node3D, movement: Vector2, attacking: bool, dead: bool) -> void:
	if actor != null and actor.has_method("update_actor_animation_state"):
		actor.call("update_actor_animation_state", movement, attacking, dead)

func _make_enemy_state(enemy_type: String = "rot_melee") -> Dictionary:
	return {
		"health": ENEMY_MAX_HEALTH,
		"alive": true,
		"mode": "idle",
		"distance_to_player": 0.0,
		"attack_timer": 0.0,
		"attack_count": 0,
		"enemy_type": enemy_type,
		"display_rank": "normal",
		"is_elite": false,
		"is_boss": false,
	}

func _update_enemy_loop(delta: float) -> void:
	if player == null or death_settlement_active:
		return
	for enemy in enemies:
		if enemy == null or not enemy_states.has(enemy):
			continue
		var state: Dictionary = enemy_states[enemy]
		if not bool(state.get("alive", false)):
			if enemy.has_method("set_move_input"):
				enemy.call("set_move_input", Vector2.ZERO)
			_update_actor_animation(enemy, Vector2.ZERO, false, true)
			continue
		var offset := player.global_position - enemy.global_position
		offset.y = 0.0
		var distance := offset.length()
		state["distance_to_player"] = distance
		var enemy_movement := Vector2.ZERO
		var enemy_attacking := false
		if distance <= ENEMY_ATTACK_RANGE:
			state["mode"] = "attack"
			enemy_attacking = true
			state["attack_timer"] = float(state.get("attack_timer", 0.0)) + delta
			if float(state.get("attack_timer", 0.0)) >= ENEMY_ATTACK_COOLDOWN:
				state["attack_timer"] = 0.0
				state["attack_count"] = int(state.get("attack_count", 0)) + 1
				_apply_damage_to_player(ENEMY_ATTACK_DAMAGE)
			if enemy.has_method("set_move_input"):
				enemy.call("set_move_input", Vector2.ZERO)
		elif distance <= ENEMY_CHASE_RANGE:
			state["mode"] = "chase"
			state["attack_timer"] = 0.0
			enemy_movement = Vector2(offset.x, offset.z)
			if enemy.has_method("set_move_input"):
				enemy.call("set_move_input", enemy_movement)
		else:
			state["mode"] = "idle"
			state["attack_timer"] = 0.0
			if enemy.has_method("set_move_input"):
				enemy.call("set_move_input", Vector2.ZERO)
		_update_actor_animation(enemy, enemy_movement, enemy_attacking, false)
		enemy_states[enemy] = state

func _apply_damage_to_player(amount: int) -> void:
	if death_settlement_active:
		return
	var max_health := maxi(1, int(player_data.get("max_health", 120)))
	var health := clampi(int(player_data.get("health", max_health)), 0, max_health)
	health = maxi(0, health - maxi(0, amount))
	player_data["health"] = health
	player_data["max_health"] = max_health
	_update_hud("You took %d damage." % maxi(0, amount))
	if health <= 0:
		_on_player_died()

func force_enemy_attack_player_for_test(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy := enemies[index]
	if enemy == null or not enemy_states.has(enemy):
		return
	var state: Dictionary = enemy_states[enemy]
	state["mode"] = "attack"
	state["attack_count"] = int(state.get("attack_count", 0)) + 1
	enemy_states[enemy] = state
	_apply_damage_to_player(ENEMY_ATTACK_DAMAGE)

func _defeat_enemy(enemy: Node3D) -> void:
	if enemy == null or not enemy_states.has(enemy):
		return
	var state: Dictionary = enemy_states[enemy]
	if not bool(state.get("alive", false)):
		return
	state["health"] = 0
	state["alive"] = false
	state["mode"] = "dead"
	state["attack_timer"] = 0.0
	enemy_states[enemy] = state
	living_enemy_count = maxi(0, living_enemy_count - 1)
	if enemy.has_method("set_move_input"):
		enemy.call("set_move_input", Vector2.ZERO)
	_update_actor_animation(enemy, Vector2.ZERO, false, true)
	var collision := enemy.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = true
	enemy.visible = false
	var xp_result := _record_enemy_defeat_rewards(state)
	var level_note := " Level up!" if bool(xp_result.get("leveled_up", false)) else ""
	_update_hud("Enemy defeated. %d enemy/enemies remain. +%d XP%s" % [living_enemy_count, int(xp_result.get("experience_gained", 0)), level_note])
	if living_enemy_count <= 0:
		_on_floor_cleared()

func _record_enemy_defeat_rewards(enemy_state: Dictionary) -> Dictionary:
	kill_index += 1
	floor_kill_count += 1
	var enemy_data := _build_enemy_experience_source(enemy_state)
	var xp_result := _award_enemy_experience(enemy_data)
	_add_direct_enemy_drop(enemy_data)
	SaveManagerScript.save_active_player_data(_build_current_player_snapshot(), current_floor)
	return xp_result

func _build_enemy_experience_source(enemy_state: Dictionary) -> Dictionary:
	return {
		"enemy_type": str(enemy_state.get("enemy_type", "rot_melee")),
		"display_rank": str(enemy_state.get("display_rank", "normal")),
		"is_elite": bool(enemy_state.get("is_elite", false)),
		"is_boss": bool(enemy_state.get("is_boss", false)),
	}

func _award_enemy_experience(enemy_data: Dictionary) -> Dictionary:
	var before_level := int(player_data.get("player_level", 1))
	var experience := _get_enemy_experience_reward(enemy_data)
	player_data = PlayerDataServiceScript.add_experience(player_data, experience)
	last_xp_result = {
		"experience_gained": experience,
		"leveled_up": int(player_data.get("player_level", 1)) > before_level,
		"player_level": int(player_data.get("player_level", 1)),
	}
	return last_xp_result.duplicate(true)

func _get_enemy_experience_reward(enemy_data: Dictionary) -> int:
	var base := 18 + current_floor * 3
	match str(enemy_data.get("enemy_type", "rot_melee")):
		"shadow_archer":
			base += 4
		"tower_guardian":
			base += 10
		"tower_gatekeeper":
			base += 35
	if bool(enemy_data.get("is_boss", false)) or str(enemy_data.get("display_rank", "")) == "boss":
		base *= 4
	elif bool(enemy_data.get("is_elite", false)) or str(enemy_data.get("display_rank", "")) == "elite":
		base *= 2
	return maxi(1, base)

func _add_direct_enemy_drop(enemy_data: Dictionary) -> void:
	var source := "elite" if bool(enemy_data.get("is_elite", false)) else "normal"
	var payload := LootRulesScript.generate_enemy_drop_with_source(current_floor, str(player_data.get("base_class", "warrior")), kill_index, source)
	_add_payload_to_player_inventory(payload, "drop")

func _add_payload_to_player_inventory(payload: Dictionary, source: String) -> void:
	var notification := _build_loot_notification(payload, source)
	player_data["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player_data.get("inventory", {})), payload)
	floor_pickup_names.append(str(payload.get("name", "Item")))
	_show_loot_notification(notification)

func _build_loot_notification(payload: Dictionary, source: String = "drop") -> Dictionary:
	return LootNotificationServiceScript.build_pickup_notification(player_data, payload, source)

func _show_loot_notification(notification: Dictionary) -> void:
	last_loot_notification = notification.duplicate(true)
	if is_instance_valid(hud) and hud.has_method("show_loot_notification"):
		hud.call("show_loot_notification", notification)

func _on_floor_cleared() -> void:
	if exit_unlocked:
		return
	var rewards := _build_floor_clear_rewards(current_floor, str(player_data.get("base_class", "warrior")))
	player_data = _apply_floor_clear_rewards_to_player(player_data, rewards)
	var next_floor := TowerProgressServiceScript.next_floor_after_clear(current_floor)
	player_data["highest_floor"] = maxi(next_floor, int(player_data.get("highest_floor", 1)))
	last_floor_rewards = rewards.duplicate(true)
	SaveManagerScript.apply_floor_clear(current_floor, rewards, _build_current_player_snapshot())
	_unlock_exit()

func _build_floor_clear_rewards(floor: int, base_class: String) -> Dictionary:
	var rewards := TowerProgressServiceScript.build_floor_reward(floor)
	if bool(rewards.get("guaranteed_magic_equipment", false)):
		rewards["guaranteed_items"] = [LootRulesScript.generate_boss_clear_reward(floor, base_class)]
	else:
		rewards["guaranteed_items"] = []
	return rewards

func _apply_floor_clear_rewards_to_player(data: Dictionary, rewards: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	var inventory: Dictionary = Dictionary(result.get("inventory", {}))
	for item in Array(rewards.get("guaranteed_items", [])):
		var payload: Dictionary = Dictionary(item)
		var notification := _build_loot_notification(payload, "boss_reward")
		inventory = InventoryDataServiceScript.add_item(inventory, payload)
		floor_pickup_names.append(str(payload.get("name", "Item")))
		_show_loot_notification(notification)
	result["inventory"] = inventory
	return result

func _unlock_exit() -> void:
	if exit_unlocked:
		return
	exit_unlocked = true
	room_cleared = true
	if exit_marker != null:
		exit_marker.material_override = _make_material(Color(0.18, 0.65, 1.0), Color(0.08, 0.35, 0.8))
		exit_marker.scale = Vector3(1.18, 1.0, 1.18)
	_update_hud("Floor clear. Press E at the exit marker to climb.")

func _set_exit_locked_visual() -> void:
	exit_unlocked = false
	room_cleared = false
	if exit_marker != null:
		exit_marker.material_override = _make_material(Color(0.08, 0.12, 0.16), Color(0.01, 0.025, 0.04))
		exit_marker.scale = Vector3.ONE

func _enter_next_floor() -> void:
	if not exit_unlocked or death_settlement_active:
		return
	current_floor += 1
	player_data = _build_current_player_snapshot()
	player_data["highest_floor"] = current_floor
	SaveManagerScript.save_active_player_data(player_data, current_floor)
	_set_exit_locked_visual()
	_reset_enemy_wave()
	_update_camera_follow()
	_update_hud("Entered floor %d." % current_floor)

func _return_to_town() -> void:
	if death_settlement_active:
		_return_to_town_after_death()
		return
	player_data = _build_current_player_snapshot()
	SaveManagerScript.save_active_player_data(player_data, current_floor)
	get_tree().paused = false
	SceneRouterScript.go_to_town(get_tree())

func _return_to_town_for_test() -> void:
	player_data = _build_current_player_snapshot()
	SaveManagerScript.save_active_player_data(player_data, current_floor)

func _on_player_died() -> void:
	if death_settlement_active:
		return
	death_settlement_active = true
	death_trigger_count += 1
	active_move_input = Vector2.ZERO
	player_attack_phase = "dead"
	player_attack_cooldown_remaining = 0.0
	_hide_player_attack_arc()
	if player != null and player.has_method("set_move_input"):
		player.call("set_move_input", Vector2.ZERO)
	_sync_player_action_state()
	death_return_player_data = _build_current_player_snapshot()
	death_return_player_data["health"] = maxi(1, int(death_return_player_data.get("max_health", 120)) / 2)
	SaveManagerScript.save_active_player_data(death_return_player_data, current_floor)
	_update_hud("You fell. Return to town to recover.")
	_show_death_settlement()

func _show_death_settlement() -> void:
	if not is_instance_valid(death_overlay):
		return
	if is_instance_valid(pause_overlay):
		pause_overlay.visible = false
	if is_instance_valid(inventory_window):
		inventory_window.visible = false
	_refresh_death_settlement_sections()
	death_overlay.visible = true
	get_tree().paused = true
	_grab_focus_when_ready(death_return_town_button)

func _return_to_town_after_death() -> void:
	if death_return_player_data.is_empty():
		death_return_player_data = _build_current_player_snapshot()
		death_return_player_data["health"] = maxi(1, int(death_return_player_data.get("max_health", 120)) / 2)
	SaveManagerScript.save_active_player_data(death_return_player_data, current_floor)
	get_tree().paused = false
	SceneRouterScript.go_to_town(get_tree())

func _return_to_town_after_death_for_test() -> void:
	if death_return_player_data.is_empty():
		death_return_player_data = _build_current_player_snapshot()
		death_return_player_data["health"] = maxi(1, int(death_return_player_data.get("max_health", 120)) / 2)
	SaveManagerScript.save_active_player_data(death_return_player_data, current_floor)
	get_tree().paused = false

func _refresh_death_settlement_sections() -> void:
	var settlement := _build_death_settlement()
	if is_instance_valid(death_floor_section):
		death_floor_section.text = str(settlement.get("floor_text", ""))
	if is_instance_valid(death_kills_section):
		death_kills_section.text = str(settlement.get("combat_text", ""))
	if is_instance_valid(death_loot_section):
		death_loot_section.text = str(settlement.get("loot_text", ""))
	if is_instance_valid(death_boss_reward_section):
		death_boss_reward_section.text = str(settlement.get("boss_reward_text", ""))
	if is_instance_valid(death_summary_label):
		death_summary_label.text = str(settlement.get("summary_text", ""))

func _build_death_settlement() -> Dictionary:
	return DeathSettlementServiceScript.build_death_settlement({
		"floor": current_floor,
		"template_id": "prototype_2_5d_combat_room",
		"kill_count": floor_kill_count,
		"pickup_names": floor_pickup_names,
		"last_floor_rewards": last_floor_rewards,
		"return_health_mode": "half",
	})

func _build_death_settlement_for_test() -> Dictionary:
	return _build_death_settlement()

func _toggle_pause() -> void:
	if death_settlement_active or not is_instance_valid(pause_overlay):
		return
	pause_overlay.visible = not pause_overlay.visible
	_sync_menu_pause_state()
	if pause_overlay.visible:
		_grab_focus_when_ready(pause_resume_button)

func _toggle_pause_for_test() -> void:
	_toggle_pause()

func _handle_cancel() -> void:
	if death_settlement_active:
		return
	if is_instance_valid(inventory_window) and inventory_window.visible:
		_set_inventory_window_visible(false)
		if is_instance_valid(pause_overlay) and pause_overlay.visible:
			_grab_focus_when_ready(pause_resume_button)
		return
	_toggle_pause()

func _handle_cancel_for_test() -> void:
	_handle_cancel()

func _grab_focus_when_ready(control: Control) -> void:
	if not is_instance_valid(control):
		return
	control.call_deferred("grab_focus")

func _toggle_inventory_window() -> void:
	if death_settlement_active or not is_instance_valid(inventory_window):
		return
	_set_inventory_window_visible(not inventory_window.visible)

func _toggle_inventory_window_for_test() -> void:
	_toggle_inventory_window()

func _set_inventory_window_visible(visible: bool) -> void:
	if not is_instance_valid(inventory_window):
		return
	inventory_window.visible = visible
	if visible:
		inventory_window.set_player_data(player_data)
	_sync_menu_pause_state()

func _sync_menu_pause_state() -> void:
	var pause_visible := is_instance_valid(pause_overlay) and pause_overlay.visible
	var inventory_visible := is_instance_valid(inventory_window) and inventory_window.visible
	var death_visible := is_instance_valid(death_overlay) and death_overlay.visible
	get_tree().paused = pause_visible or inventory_visible or death_visible

func _is_menu_blocking_combat() -> bool:
	return death_settlement_active or (is_instance_valid(pause_overlay) and pause_overlay.visible) or (is_instance_valid(inventory_window) and inventory_window.visible)

func _on_player_data_changed(updated: Dictionary) -> void:
	player_data = updated.duplicate(true)
	SaveManagerScript.save_active_player_data(player_data, current_floor)
	_update_hud("Equipment updated.")

func _update_hud(message: String) -> void:
	if not is_instance_valid(hud):
		return
	hud.call("set_status", "Floor %d | Enemies %d" % [current_floor, living_enemy_count])
	hud.call("set_log", message)
	if hud.has_method("set_objective"):
		var objective := "Objective: defeat all enemies."
		if exit_unlocked:
			objective = "Objective: enter the blue exit marker."
		hud.call("set_objective", objective)
	var capacity: Dictionary = InventoryDataServiceScript.build_capacity_summary(Dictionary(player_data.get("inventory", {})))
	hud.call("set_inventory", str(capacity.get("summary_text", "Bag 0/40")))
	if hud.has_method("set_player_vitals"):
		hud.call(
			"set_player_vitals",
			int(player_data.get("health", player_data.get("max_health", 1))),
			int(player_data.get("max_health", 1)),
			int(player_data.get("mana", 0)),
			int(player_data.get("max_mana", 1))
		)
	if hud.has_method("set_player_progress"):
		hud.call(
			"set_player_progress",
			int(player_data.get("player_level", 1)),
			int(player_data.get("current_exp", 0)),
			int(player_data.get("exp_to_next_level", 100)),
			int(player_data.get("skill_points", 0))
		)

func _build_current_player_snapshot() -> Dictionary:
	var snapshot := player_data.duplicate(true)
	snapshot["highest_floor"] = maxi(current_floor, int(snapshot.get("highest_floor", 1)))
	return snapshot

func _reset_enemy_wave() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	enemy_states.clear()
	floor_kill_count = 0
	floor_pickup_names = []
	last_floor_rewards = {}
	last_loot_notification = {}
	last_xp_result = {}
	actor_visible_markers = _get_surviving_actor_visible_markers()
	for index in range(2):
		_create_enemy_actor(index)
	living_enemy_count = enemies.size()

func _get_surviving_actor_visible_markers() -> Array[MeshInstance3D]:
	var surviving: Array[MeshInstance3D] = []
	for marker in actor_visible_markers:
		if is_instance_valid(marker) and marker.get_parent() == player:
			surviving.append(marker)
	return surviving

func set_player_position_for_test(value: Vector3) -> void:
	if player != null:
		player.global_position = value
	_update_camera_follow()

func defeat_enemy_for_test(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	_defeat_enemy(enemies[index])

func build_prototype_snapshot_for_test() -> Dictionary:
	return {
		"prototype_id": "2_5d_billboard_combat_room",
		"isolated_from_main_flow": true,
		"has_camera_3d": camera != null,
		"camera_orthographic": camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
		"wall_count": wall_nodes.size(),
		"column_count": column_nodes.size(),
		"player_count": 1 if player != null else 0,
		"enemy_count": enemies.size(),
		"has_exit_marker": exit_marker != null,
	}

func build_main_flow_migration_snapshot_for_test() -> Dictionary:
	return {
		"runtime_id": "prototype_2_5d_main_tower_flow",
		"active_game_scene": GameConstantsScript.ACTIVE_GAME_SCENE,
		"legacy_fallback_scene": legacy_fallback_scene,
		"current_floor": current_floor,
		"active_player_name": str(player_data.get("character_name", "")),
		"player_highest_floor": int(player_data.get("highest_floor", 1)),
		"uses_save_manager": true,
		"uses_tower_run_start_service": true,
		"exit_unlocked": exit_unlocked,
		"enemy_count": enemies.size(),
		"living_enemy_count": living_enemy_count,
		"can_return_to_town": has_method("_return_to_town"),
	}

func build_hud_inventory_pause_snapshot_for_test() -> Dictionary:
	var focus_owner := get_viewport().gui_get_focus_owner()
	var status_text := ""
	var inventory_text := ""
	var objective_text := ""
	var hud_level := 0
	if is_instance_valid(hud):
		var status_label := hud.get("status_label") as Label
		var inventory_label := hud.get("inventory_label") as Label
		var objective_label := hud.get("objective_label") as Label
		if is_instance_valid(status_label):
			status_text = status_label.text
		if is_instance_valid(inventory_label):
			inventory_text = inventory_label.text
		if is_instance_valid(objective_label):
			objective_text = objective_label.text
		hud_level = int(player_data.get("player_level", 1))
	return {
		"has_hud": is_instance_valid(hud),
		"has_inventory_window": is_instance_valid(inventory_window),
		"has_pause_overlay": is_instance_valid(pause_overlay),
		"pause_visible": is_instance_valid(pause_overlay) and pause_overlay.visible,
		"inventory_visible": is_instance_valid(inventory_window) and inventory_window.visible,
		"tree_paused": get_tree().paused,
		"menu_blocks_combat": _is_menu_blocking_combat(),
		"hud_status_text": status_text,
		"hud_inventory_text": inventory_text,
		"hud_objective_text": objective_text,
		"hud_level": hud_level,
		"pause_focus_name": focus_owner.name if focus_owner != null else "",
		"inventory_process_always": is_instance_valid(inventory_window) and inventory_window.process_mode == Node.PROCESS_MODE_ALWAYS,
		"pause_process_always": is_instance_valid(pause_overlay) and pause_overlay.process_mode == Node.PROCESS_MODE_ALWAYS,
	}

func build_loot_xp_reward_snapshot_for_test() -> Dictionary:
	var capacity: Dictionary = InventoryDataServiceScript.build_capacity_summary(Dictionary(player_data.get("inventory", {})))
	var status_text := ""
	var inventory_text := ""
	if is_instance_valid(hud):
		var status_label := hud.get("status_label") as Label
		var inventory_label := hud.get("inventory_label") as Label
		if is_instance_valid(status_label):
			status_text = status_label.text
		if is_instance_valid(inventory_label):
			inventory_text = inventory_label.text
	return {
		"current_floor": current_floor,
		"kill_index": kill_index,
		"floor_kill_count": floor_kill_count,
		"floor_pickup_names": floor_pickup_names.duplicate(),
		"last_floor_rewards": last_floor_rewards.duplicate(true),
		"last_loot_notification": last_loot_notification.duplicate(true),
		"last_xp_gained": int(last_xp_result.get("experience_gained", 0)),
		"last_xp_leveled_up": bool(last_xp_result.get("leveled_up", false)),
		"player_level": int(player_data.get("player_level", 1)),
		"current_exp": int(player_data.get("current_exp", 0)),
		"exp_to_next_level": int(player_data.get("exp_to_next_level", 100)),
		"inventory_used_slots": int(capacity.get("used_slots", 0)),
		"inventory_capacity": int(capacity.get("capacity", 0)),
		"has_boss_reward_item": _inventory_has_boss_reward_item(),
		"exit_unlocked": exit_unlocked,
		"living_enemy_count": living_enemy_count,
		"hud_status_text": status_text,
		"hud_inventory_text": inventory_text,
	}

func build_death_settlement_snapshot_for_test() -> Dictionary:
	var settlement := _build_death_settlement()
	var saved_player := SaveManagerScript.get_active_player_data()
	return {
		"death_settlement_active": death_settlement_active,
		"death_trigger_count": death_trigger_count,
		"death_overlay_visible": is_instance_valid(death_overlay) and death_overlay.visible,
		"tree_paused": get_tree().paused,
		"menu_blocks_combat": _is_menu_blocking_combat(),
		"player_health": int(player_data.get("health", player_data.get("max_health", 1))),
		"player_max_health": int(player_data.get("max_health", 1)),
		"saved_player_health": int(saved_player.get("health", 0)),
		"saved_player_max_health": int(saved_player.get("max_health", 0)),
		"current_floor": current_floor,
		"floor_kill_count": floor_kill_count,
		"settlement_summary": str(settlement.get("summary_text", "")),
		"settlement_floor_text": str(settlement.get("floor_text", "")),
		"settlement_loot_text": str(settlement.get("loot_text", "")),
		"death_return_button_exists": is_instance_valid(death_return_town_button),
	}

func _inventory_has_boss_reward_item() -> bool:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	for entry_value in inventory.values():
		var entry: Dictionary = Dictionary(entry_value)
		var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
		if str(equipment.get("template_id", "")) == "boss_clear_reward":
			return true
	return false

func build_visual_qa_snapshot_for_test() -> Dictionary:
	var actor_snapshots: Array[Dictionary] = []
	if player != null and player.has_method("build_contract_snapshot"):
		actor_snapshots.append(player.call("build_contract_snapshot"))
	for enemy in enemies:
		if enemy != null and enemy.has_method("build_contract_snapshot"):
			actor_snapshots.append(enemy.call("build_contract_snapshot"))
	return Prototype2_5DVisualQaService.build_snapshot(build_prototype_snapshot_for_test(), actor_snapshots)

func build_visibility_snapshot_for_test() -> Dictionary:
	return {
		"has_world_environment": world_environment != null and world_environment.environment != null,
		"has_key_light": key_light != null,
		"floor_has_material": floor_mesh != null and floor_mesh.material_override != null,
		"wall_visible_material_count": _count_visible_materials(wall_nodes),
		"column_visible_material_count": _count_visible_materials(column_nodes),
		"actor_visible_marker_count": actor_visible_markers.size(),
		"actor_visible_marker_visible_count": _count_visible_actor_markers(),
		"exit_marker_has_material": exit_marker != null and exit_marker.get("material_override") != null,
		"has_debug_hud": debug_hud != null and debug_hud.has_node("PrototypeModeLabel"),
		"camera_has_visible_background": world_environment != null and world_environment.environment != null,
	}

func set_debug_readability_markers_enabled_for_test(enabled: bool) -> void:
	debug_readability_markers_enabled = enabled
	_set_actor_visible_markers_enabled(enabled)

func build_visual_grounding_snapshot_for_test() -> Dictionary:
	var actor_count := 0
	var contact_shadow_count := 0
	var visible_contact_shadow_count := 0
	var total_shadow_alpha := 0.0
	var all_actor_sprites_grounded := true
	for actor in _get_all_billboard_actors():
		actor_count += 1
		var state := _get_actor_animation_snapshot(actor)
		var has_shadow := bool(state.get("has_contact_shadow", false))
		var shadow_visible := bool(state.get("contact_shadow_visible", false))
		var sprite_visible := bool(state.get("actor_sprite_visible", false))
		var texture_loaded := bool(state.get("actor_sprite_texture_loaded", false))
		if has_shadow:
			contact_shadow_count += 1
		if shadow_visible:
			visible_contact_shadow_count += 1
			total_shadow_alpha += float(state.get("contact_shadow_alpha", 0.0))
		all_actor_sprites_grounded = all_actor_sprites_grounded and has_shadow and shadow_visible and sprite_visible and texture_loaded
	var average_alpha := 0.0
	if visible_contact_shadow_count > 0:
		average_alpha = total_shadow_alpha / float(visible_contact_shadow_count)
	return {
		"actor_count": actor_count,
		"contact_shadow_count": contact_shadow_count,
		"visible_contact_shadow_count": visible_contact_shadow_count,
		"average_shadow_alpha": average_alpha,
		"all_actor_sprites_grounded": all_actor_sprites_grounded,
		"actor_visible_marker_count": actor_visible_markers.size(),
		"actor_visible_marker_visible_count": _count_visible_actor_markers(),
		"debug_readability_markers_enabled": debug_readability_markers_enabled,
	}

func build_player_control_snapshot_for_test() -> Dictionary:
	var player_snapshot: Dictionary = {}
	if player != null and player.has_method("build_contract_snapshot"):
		player_snapshot = player.call("build_contract_snapshot")
	return {
		"can_control_player": player != null and player.has_method("set_move_input"),
		"movement_plane": str(player_snapshot.get("plane", "")),
		"player_position": player.global_position if player != null else Vector3.ZERO,
		"player_movement_speed": float(player_snapshot.get("movement_speed", 0.0)),
		"player_facing_direction": str(player_snapshot.get("facing_direction", "")),
		"active_move_input": active_move_input,
		"input_override_enabled": player_move_input_override_enabled,
		"camera_current": camera != null and camera.current,
		"camera_orthographic": camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
		"camera_tracks_player": camera != null and player != null,
		"camera_position": camera.global_position if camera != null else Vector3.ZERO,
		"camera_follow_offset": camera_follow_offset,
		"camera_size": camera.size if camera != null else 0.0,
	}

func build_player_attack_snapshot_for_test() -> Dictionary:
	return {
		"attack_ready": player_attack_cooldown_remaining <= 0.0,
		"attack_phase": player_attack_phase,
		"attack_range": PLAYER_ATTACK_RANGE,
		"attack_half_angle": PLAYER_ATTACK_HALF_ANGLE,
		"attack_damage": PLAYER_ATTACK_DAMAGE,
		"cooldown_remaining": player_attack_cooldown_remaining,
		"total_attack_count": total_player_attack_count,
		"last_hit_count": last_player_attack_hit_count,
		"last_attack_direction": last_player_attack_direction,
		"direction_override_enabled": player_attack_direction_override_enabled,
		"aim_source": last_player_attack_aim_source,
	}

func build_player_attack_visual_snapshot_for_test() -> Dictionary:
	return {
		"has_attack_arc_marker": player_attack_arc_marker != null,
		"attack_arc_visible": player_attack_arc_marker != null and player_attack_arc_marker.visible,
		"arc_position": player_attack_arc_marker.global_position if player_attack_arc_marker != null else Vector3.ZERO,
		"arc_direction": last_player_attack_direction,
		"arc_range": PLAYER_ATTACK_RANGE,
		"arc_half_angle": PLAYER_ATTACK_HALF_ANGLE,
		"last_world_target": last_player_attack_world_target,
	}

func build_player_attack_feedback_snapshot_for_test() -> Dictionary:
	var player_snapshot: Dictionary = {}
	if player != null and player.has_method("build_contract_snapshot"):
		player_snapshot = player.call("build_contract_snapshot")
	var parent_path := ""
	if hit_impact_marker != null and hit_impact_marker.get_parent() != null:
		parent_path = str(hit_impact_marker.get_parent().get_path())
	return {
		"player_action_state": str(player_snapshot.get("action_state", "")),
		"attack_phase": player_attack_phase,
		"hit_vfx_root_exists": hit_vfx_root != null,
		"hit_vfx_marker_exists": hit_impact_marker != null,
		"hit_vfx_visible": hit_impact_marker != null and hit_impact_marker.visible,
		"hit_vfx_role": str(hit_impact_marker.get_meta("vfx_role", "")) if hit_impact_marker != null else "",
		"hit_vfx_parent_path": parent_path,
		"hit_vfx_independent_from_actor": hit_impact_marker != null and not parent_path.contains("PlayerBillboard") and not parent_path.contains("WeaponSprite"),
		"last_hit_vfx_position": last_hit_vfx_position,
		"hit_vfx_lifetime_remaining": hit_vfx_lifetime_remaining,
	}

func build_animation_state_snapshot_for_test() -> Dictionary:
	var player_animation := _get_actor_animation_snapshot(player)
	var enemy_animations: Array[Dictionary] = []
	for enemy in enemies:
		var enemy_animation := _get_actor_animation_snapshot(enemy)
		var state: Dictionary = enemy_states.get(enemy, {})
		enemy_animation["name"] = enemy.name if enemy != null else ""
		enemy_animation["alive"] = bool(state.get("alive", false))
		enemy_animation["mode"] = str(state.get("mode", ""))
		enemy_animations.append(enemy_animation)
	return {
		"player_animation": str(player_animation.get("animation", "")),
		"player_frame_index": int(player_animation.get("frame_index", -1)),
		"player_resolved_frame_index": int(player_animation.get("resolved_frame_index", -1)),
		"player_asset_pipeline": str(player_animation.get("asset_pipeline", "")),
		"player_sprite_sheet_path": str(player_animation.get("sprite_sheet_path", "")),
		"player_frame_size": player_animation.get("frame_size", Vector2i.ZERO),
		"player_direction_mode": str(player_animation.get("direction_mode", "")),
		"player_actor_sprite_visible": bool(player_animation.get("actor_sprite_visible", false)),
		"player_actor_sprite_texture_loaded": bool(player_animation.get("actor_sprite_texture_loaded", false)),
		"player_facing_direction": str(player_animation.get("facing_direction", "")),
		"player_body_weapon_separated": bool(player_animation.get("body_weapon_separated", false)),
		"player_animation_locked_until_end": bool(player_animation.get("animation_locked_until_end", false)),
		"enemy_animations": enemy_animations,
	}

func _get_actor_animation_snapshot(actor: Node3D) -> Dictionary:
	if actor != null and actor.has_method("get_actor_animation_state"):
		return actor.call("get_actor_animation_state")
	return {}

func get_player_screen_position_for_test() -> Vector2:
	return camera.unproject_position(player.global_position) if camera != null and player != null else Vector2.ZERO

func get_enemy_screen_position_for_test(index: int) -> Vector2:
	if camera == null or index < 0 or index >= enemies.size() or enemies[index] == null:
		return Vector2.ZERO
	return camera.unproject_position(enemies[index].global_position)

func build_enemy_loop_snapshot_for_test() -> Dictionary:
	var snapshots: Array[Dictionary] = []
	for enemy in enemies:
		var state: Dictionary = enemy_states.get(enemy, {})
		var move_input := Vector2.ZERO
		if enemy != null:
			move_input = enemy.get("move_input")
		snapshots.append({
			"name": enemy.name if enemy != null else "",
			"alive": bool(state.get("alive", false)),
			"health": int(state.get("health", 0)),
			"mode": str(state.get("mode", "")),
			"distance_to_player": float(state.get("distance_to_player", 0.0)),
			"attack_count": int(state.get("attack_count", 0)),
			"position": enemy.global_position if enemy != null else Vector3.ZERO,
			"move_input": move_input,
		})
	return {
		"total_enemy_count": enemies.size(),
		"living_enemy_count": living_enemy_count,
		"room_cleared": room_cleared,
		"exit_unlocked": exit_unlocked,
		"enemy_attack_range": ENEMY_ATTACK_RANGE,
		"enemy_chase_range": ENEMY_CHASE_RANGE,
		"enemy_states": snapshots,
	}

func _count_visible_materials(nodes: Array[Node3D]) -> int:
	var count := 0
	for node in nodes:
		for child in node.get_children():
			if child is MeshInstance3D and child.material_override != null:
				count += 1
	return count

func _set_actor_visible_markers_enabled(enabled: bool) -> void:
	for marker in actor_visible_markers:
		if marker != null:
			marker.visible = enabled

func _count_visible_actor_markers() -> int:
	var count := 0
	for marker in actor_visible_markers:
		if marker != null and marker.visible:
			count += 1
	return count

func _get_all_billboard_actors() -> Array[Node3D]:
	var actors: Array[Node3D] = []
	if player != null:
		actors.append(player)
	for enemy in enemies:
		if enemy != null:
			actors.append(enemy)
	return actors
