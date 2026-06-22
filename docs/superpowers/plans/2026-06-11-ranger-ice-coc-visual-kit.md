# Ranger Ice CoC Visual Kit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first readable ranger visual kit: generated ranger SpriteSheet, ranger class manifest selection, ice arrow VFX, ice lance VFX, and CoC trigger flash.

**Architecture:** Keep visual assets as replaceable generated files under `assets/generated/`. Keep combat rules in `SkillRules`, visual creation in `Vfx2DFactory`, and class-specific player art selection in `Game2D`. Do not put build logic in visual code.

**Tech Stack:** Godot 4.6 GDScript, generated PNG SpriteSheet via `Image`, existing `visual_asset_manifest` actor pipeline, headless regression scripts.

---

## File Structure

- Create: `scripts/tools/GenerateRangerVisualKit.gd`
  - Runs in headless Godot and generates `player_ranger_sheet_v1.png`.
  - Uses only `Image` drawing primitives, no network or external assets.
- Create: `tests/regression/regression_ranger_visual_kit_assets.gd`
  - Verifies generated ranger asset dimensions, transparency, non-empty frames, and animation segment variance.
- Modify: `scripts/app/Game2D.gd`
  - Adds ranger default SpriteSheet path.
  - Replaces the warrior-only default art hook with `_build_player_visual_manifest()`.
- Modify: `tests/regression/regression_class_basic_skill_presentation.gd`
  - Verifies ranger receives the ranger visual manifest while warrior still receives warrior art.
- Modify: `scripts/combat/Vfx2DFactory.gd`
  - Adds `spawn_ice_arrow_trail()`, `spawn_ice_lance_trail()`, and `spawn_coc_trigger_flash()`.
- Modify: `scripts/combat/Skill2DLibrary.gd`
  - Selects VFX by skill ID: `ranger_ice_shot`, `ice_lance`, generic projectile, melee.
- Create: `tests/regression/regression_ranger_ice_vfx_contract.gd`
  - Verifies ice arrow, ice lance, and CoC flash VFX roles are spawned.
- Create: `docs/progress/2026-06-11-ranger-ice-coc-visual-kit-progress.md`
  - Records assets, integration, tests, and known limitations.

---

### Task 1: Generated Ranger SpriteSheet Asset

**Files:**
- Create: `scripts/tools/GenerateRangerVisualKit.gd`
- Create: `tests/regression/regression_ranger_visual_kit_assets.gd`
- Generated: `assets/generated/actors/player_ranger_sheet_v1.png`

- [ ] **Step 1: Write the failing asset contract test**

Create `tests/regression/regression_ranger_visual_kit_assets.gd`:

```gdscript
extends SceneTree

const RANGER_SHEET := "res://assets/generated/actors/player_ranger_sheet_v1.png"
const FRAME_SIZE := Vector2i(160, 160)
const FRAME_COUNT := 20

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(FileAccess.file_exists(RANGER_SHEET), "ranger spritesheet should exist")
	if FileAccess.file_exists(RANGER_SHEET):
		var image := Image.new()
		_expect(image.load(ProjectSettings.globalize_path(RANGER_SHEET)) == OK, "ranger spritesheet should load")
		_expect(image.get_size() == Vector2i(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y), "ranger spritesheet should be 20 horizontal 160x160 frames")
		_expect(_opaque_pixels(image, 0) > 450, "idle frame should contain visible ranger body")
		_expect(_opaque_pixels(image, 10) > 450, "attack frame should contain visible ranger body")
		_expect(_bounds_width(image, 10) > _bounds_width(image, 0), "attack frame should extend bow/arrow farther than idle")
		_expect(_center_x(image, 10) > _center_x(image, 0), "attack frame should shift bow draw/release pose forward")
		_expect(_blue_pixels(image, 10) > 12, "attack frame should include ice accent pixels")
	_finish()

func _opaque_pixels(image: Image, frame: int) -> int:
	var count := 0
	var origin_x := frame * FRAME_SIZE.x
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			if image.get_pixel(origin_x + x, y).a > 0.08:
				count += 1
	return count

func _bounds_width(image: Image, frame: int) -> int:
	var origin_x := frame * FRAME_SIZE.x
	var min_x := FRAME_SIZE.x
	var max_x := 0
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			if image.get_pixel(origin_x + x, y).a > 0.08:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
	return maxi(0, max_x - min_x)

func _center_x(image: Image, frame: int) -> float:
	var origin_x := frame * FRAME_SIZE.x
	var total := 0.0
	var count := 0
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			if image.get_pixel(origin_x + x, y).a > 0.08:
				total += float(x)
				count += 1
	return total / float(maxi(1, count))

func _blue_pixels(image: Image, frame: int) -> int:
	var count := 0
	var origin_x := frame * FRAME_SIZE.x
	for y in range(FRAME_SIZE.y):
		for x in range(FRAME_SIZE.x):
			var color := image.get_pixel(origin_x + x, y)
			if color.a > 0.08 and color.b > 0.65 and color.g > 0.45 and color.r < 0.45:
				count += 1
	return count

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_VISUAL_KIT_ASSETS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg' --script 'res://tests/regression/regression_ranger_visual_kit_assets.gd'
```

Expected: FAIL with `ranger spritesheet should exist`.

- [ ] **Step 3: Create the generator script**

Create `scripts/tools/GenerateRangerVisualKit.gd`:

```gdscript
extends SceneTree

const OUT_PATH := "res://assets/generated/actors/player_ranger_sheet_v1.png"
const FRAME_SIZE := Vector2i(160, 160)
const FRAME_COUNT := 20

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var image := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(FRAME_COUNT):
		_draw_frame(image, frame)
	var absolute_path := ProjectSettings.globalize_path(OUT_PATH)
	var err := image.save_png(absolute_path)
	if err != OK:
		push_error("failed to save ranger visual kit: %s" % err)
		quit(1)
	print("GENERATED_RANGER_VISUAL_KIT %s" % OUT_PATH)
	quit(0)

func _draw_frame(image: Image, frame: int) -> void:
	var local_frame := frame
	var phase := 0.0
	var animation := "idle"
	if frame >= 4 and frame <= 9:
		animation = "run"
		local_frame = frame - 4
		phase = float(local_frame) / 6.0
	elif frame >= 10 and frame <= 15:
		animation = "attack"
		local_frame = frame - 10
		phase = float(local_frame) / 6.0
	elif frame >= 16:
		animation = "death"
		local_frame = frame - 16
		phase = float(local_frame) / 4.0
	else:
		phase = float(frame) / 4.0

	var origin := Vector2i(frame * FRAME_SIZE.x, 0)
	var hip := Vector2(76, 94)
	if animation == "run":
		hip.y += sin(phase * TAU) * 3.0
	elif animation == "attack":
		hip.x += phase * 8.0
	elif animation == "death":
		hip.y += phase * 26.0
		hip.x += phase * 12.0

	_draw_shadow(image, origin, hip)
	_draw_ranger_body(image, origin, hip, animation, phase)
	_draw_bow(image, origin, hip, animation, phase)
	_draw_ice_accents(image, origin, hip, animation, phase)

func _draw_shadow(image: Image, origin: Vector2i, hip: Vector2) -> void:
	_fill_ellipse(image, origin + Vector2i(int(hip.x - 28), 126), Vector2i(58, 12), Color(0.01, 0.015, 0.02, 0.30))

func _draw_ranger_body(image: Image, origin: Vector2i, hip: Vector2, animation: String, phase: float) -> void:
	var cloak := Color(0.06, 0.11, 0.14, 1.0)
	var armor := Color(0.12, 0.18, 0.20, 1.0)
	var trim := Color(0.18, 0.56, 0.68, 1.0)
	var skin := Color(0.62, 0.58, 0.48, 1.0)
	var head := Vector2(hip.x - 1.0, hip.y - 43.0)
	if animation == "death":
		head.y += phase * 18.0
		head.x += phase * 18.0
	var torso := Vector2(hip.x, hip.y - 20.0)
	_fill_ellipse(image, origin + Vector2i(int(torso.x - 15), int(torso.y - 18)), Vector2i(30, 39), armor)
	_fill_ellipse(image, origin + Vector2i(int(torso.x - 19), int(torso.y - 22)), Vector2i(38, 45), Color(0.025, 0.05, 0.07, 0.88))
	_fill_ellipse(image, origin + Vector2i(int(head.x - 12), int(head.y - 13)), Vector2i(24, 24), cloak)
	_fill_ellipse(image, origin + Vector2i(int(head.x - 7), int(head.y - 7)), Vector2i(14, 12), skin)
	_draw_line(image, origin + Vector2i(int(torso.x - 11), int(torso.y - 14)), origin + Vector2i(int(torso.x + 11), int(torso.y + 16)), trim, 3)

	var leg_swing := sin(phase * TAU) * 9.0 if animation == "run" else 0.0
	_draw_line(image, origin + Vector2i(int(hip.x - 7), int(hip.y)), origin + Vector2i(int(hip.x - 18 - leg_swing), 124), Color(0.08, 0.12, 0.13, 1.0), 5)
	_draw_line(image, origin + Vector2i(int(hip.x + 8), int(hip.y)), origin + Vector2i(int(hip.x + 16 + leg_swing), 124), Color(0.08, 0.12, 0.13, 1.0), 5)

func _draw_bow(image: Image, origin: Vector2i, hip: Vector2, animation: String, phase: float) -> void:
	var bow_color := Color(0.36, 0.21, 0.10, 1.0)
	var string_color := Color(0.70, 0.82, 0.82, 0.9)
	var ice := Color(0.48, 0.86, 1.0, 0.95)
	var bow_x := hip.x + 28.0
	var bow_y := hip.y - 30.0
	var draw_back := 0.0
	if animation == "attack":
		draw_back = sin(clampf(phase, 0.0, 1.0) * PI) * 20.0
		bow_x += phase * 14.0
	_draw_line(image, origin + Vector2i(int(bow_x), int(bow_y - 30)), origin + Vector2i(int(bow_x + 11), int(bow_y)), bow_color, 4)
	_draw_line(image, origin + Vector2i(int(bow_x + 11), int(bow_y)), origin + Vector2i(int(bow_x), int(bow_y + 30)), bow_color, 4)
	_draw_line(image, origin + Vector2i(int(bow_x), int(bow_y - 30)), origin + Vector2i(int(bow_x - draw_back), int(bow_y)), string_color, 1)
	_draw_line(image, origin + Vector2i(int(bow_x - draw_back), int(bow_y)), origin + Vector2i(int(bow_x), int(bow_y + 30)), string_color, 1)
	if animation == "attack":
		_draw_line(image, origin + Vector2i(int(bow_x - draw_back - 8), int(bow_y)), origin + Vector2i(int(bow_x + 52), int(bow_y)), ice, 3)
		_fill_triangle(image, origin + Vector2i(int(bow_x + 60), int(bow_y)), origin + Vector2i(int(bow_x + 48), int(bow_y - 6)), origin + Vector2i(int(bow_x + 48), int(bow_y + 6)), ice)

func _draw_ice_accents(image: Image, origin: Vector2i, hip: Vector2, animation: String, phase: float) -> void:
	var ice := Color(0.30, 0.78, 1.0, 0.82)
	_fill_ellipse(image, origin + Vector2i(int(hip.x + 8), int(hip.y - 39)), Vector2i(5, 5), ice)
	if animation == "attack":
		for i in range(4):
			_fill_ellipse(image, origin + Vector2i(int(hip.x + 54 + i * 9), int(hip.y - 31 + sin(phase * TAU + i) * 4.0)), Vector2i(4, 4), Color(0.48, 0.88, 1.0, 0.72))

func _fill_ellipse(image: Image, top_left: Vector2i, size: Vector2i, color: Color) -> void:
	var rx := maxf(1.0, float(size.x) / 2.0)
	var ry := maxf(1.0, float(size.y) / 2.0)
	var center := Vector2(float(top_left.x) + rx, float(top_left.y) + ry)
	for y in range(maxi(0, top_left.y), mini(image.get_height(), top_left.y + size.y)):
		for x in range(maxi(0, top_left.x), mini(image.get_width(), top_left.x + size.x)):
			var p := Vector2(float(x), float(y))
			if pow((p.x - center.x) / rx, 2.0) + pow((p.y - center.y) / ry, 2.0) <= 1.0:
				image.set_pixel(x, y, color)

func _draw_line(image: Image, from_point: Vector2i, to_point: Vector2i, color: Color, width: int) -> void:
	var steps := maxi(1, int(from_point.distance_to(to_point)))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var point := from_point.lerp(to_point, t)
		_fill_ellipse(image, Vector2i(point.x - width, point.y - width), Vector2i(width * 2 + 1, width * 2 + 1), color)

func _fill_triangle(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, color: Color) -> void:
	var min_x := maxi(0, mini(a.x, mini(b.x, c.x)))
	var max_x := mini(image.get_width() - 1, maxi(a.x, maxi(b.x, c.x)))
	var min_y := maxi(0, mini(a.y, mini(b.y, c.y)))
	var max_y := mini(image.get_height() - 1, maxi(a.y, maxi(b.y, c.y)))
	var area := _edge(a, b, c)
	if absf(float(area)) <= 0.001:
		return
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p := Vector2i(x, y)
			var w0 := _edge(b, c, p)
			var w1 := _edge(c, a, p)
			var w2 := _edge(a, b, p)
			if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0):
				image.set_pixel(x, y, color)

func _edge(a: Vector2i, b: Vector2i, c: Vector2i) -> int:
	return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)
```

- [ ] **Step 4: Run generator**

Run:

```powershell
& 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg' --script 'res://scripts/tools/GenerateRangerVisualKit.gd'
```

Expected: `GENERATED_RANGER_VISUAL_KIT res://assets/generated/actors/player_ranger_sheet_v1.png`

- [ ] **Step 5: Run asset test to verify it passes**

Run the test from Step 2 again.

Expected: `NEW_PROJECT_RANGER_VISUAL_KIT_ASSETS_OK`

- [ ] **Step 6: Commit**

```powershell
git add scripts/tools/GenerateRangerVisualKit.gd tests/regression/regression_ranger_visual_kit_assets.gd assets/generated/actors/player_ranger_sheet_v1.png
git commit -m "Generate ranger visual kit spritesheet"
```

---

### Task 2: Ranger Player Manifest Selection

**Files:**
- Modify: `scripts/app/Game2D.gd`
- Modify: `tests/regression/regression_class_basic_skill_presentation.gd`

- [ ] **Step 1: Extend the failing/coverage test**

In `tests/regression/regression_class_basic_skill_presentation.gd`, update `_expect_game2d_default_art_scope()` to assert the ranger manifest path:

```gdscript
	var ranger_manifest: Dictionary = ranger.call("get_visual_asset_manifest_for_test")
	_expect(str(ranger_manifest.get("sprite_sheet_path", "")).ends_with("player_ranger_sheet_v1.png"), "ranger should load ranger spritesheet manifest")
	_expect(str(ranger_manifest.get("pose_variation_version", "")) == "ranger_ice_coc_v1", "ranger should expose ranger visual kit manifest")
	_expect(bool(game.call("_is_default_player_art_loaded")), "ranger should load default ranger art")
```

Remove the older assertion that ranger should not load default art.

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg' --script 'res://tests/regression/regression_class_basic_skill_presentation.gd'
```

Expected: FAIL because `Game2D` still returns early for ranger.

- [ ] **Step 3: Implement manifest selection**

Modify `scripts/app/Game2D.gd`:

```gdscript
const DEFAULT_PLAYER_IMAGE2_SPRITE_PATH := "res://assets/generated/actors/player_warrior_sheet_v3.png"
const RANGER_PLAYER_SPRITE_PATH := "res://assets/generated/actors/player_ranger_sheet_v1.png"
```

Replace `_apply_default_player_art()` with:

```gdscript
func _apply_default_player_art() -> void:
	if not is_instance_valid(player) or not player.has_method("apply_visual_asset_manifest"):
		return
	var manifest := _build_player_visual_manifest()
	if manifest.is_empty():
		return
	player.apply_visual_asset_manifest(manifest)

func _build_player_visual_manifest() -> Dictionary:
	var base_class := str(player_data.get("base_class", "warrior"))
	if base_class == "ranger":
		if not FileAccess.file_exists(RANGER_PLAYER_SPRITE_PATH):
			return {}
		return {
			"asset_pipeline": "generated",
			"pose_variation_version": "ranger_ice_coc_v1",
			"direction_mode": "runtime_flip_2dir",
			"enabled": true,
			"sprite_sheet_path": RANGER_PLAYER_SPRITE_PATH,
			"frame_size": Vector2i(160, 160),
			"hide_procedural_body": true,
			"animations": {
				"idle": {"from": 0, "to": 3, "fps": 6},
				"run": {"from": 4, "to": 9, "fps": 9},
				"attack": {"from": 10, "to": 15, "fps": 12},
				"death": {"from": 16, "to": 19, "fps": 6},
			},
		}
	if base_class != "warrior":
		return {}
	if not FileAccess.file_exists(DEFAULT_PLAYER_IMAGE2_SPRITE_PATH):
		return {}
	return {
		"asset_pipeline": "IMAGE2",
		"pose_variation_version": "production_dark_armor_v3",
		"direction_mode": "runtime_flip_2dir",
		"enabled": true,
		"sprite_sheet_path": DEFAULT_PLAYER_IMAGE2_SPRITE_PATH,
		"frame_size": Vector2i(160, 160),
		"hide_procedural_body": true,
		"animations": {
			"idle": {"from": 0, "to": 3, "fps": 6},
			"run": {"from": 4, "to": 9, "fps": 9},
			"attack": {"from": 10, "to": 15, "fps": 10},
			"death": {"from": 16, "to": 19, "fps": 6},
		},
	}
```

Keep `_is_default_player_art_loaded()` unchanged.

- [ ] **Step 4: Run tests**

Run:

```powershell
& 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg' --script 'res://tests/regression/regression_class_basic_skill_presentation.gd'
& 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg' --script 'res://tests/regression/regression_default_image2_player_art_contract.gd'
```

Expected:

```text
NEW_PROJECT_CLASS_BASIC_SKILL_PRESENTATION_OK
NEW_PROJECT_DEFAULT_IMAGE2_PLAYER_ART_CONTRACT_OK
```

- [ ] **Step 5: Commit**

```powershell
git add scripts/app/Game2D.gd tests/regression/regression_class_basic_skill_presentation.gd
git commit -m "Apply ranger visual kit manifest"
```

---

### Task 3: Ice Arrow, Ice Lance, and CoC Flash VFX

**Files:**
- Create: `tests/regression/regression_ranger_ice_vfx_contract.gd`
- Modify: `scripts/combat/Vfx2DFactory.gd`
- Modify: `scripts/combat/Skill2DLibrary.gd`

- [ ] **Step 1: Write the failing VFX contract test**

Create `tests/regression/regression_ranger_ice_vfx_contract.gd`:

```gdscript
extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const Player2DScript := preload("res://scripts/combat/Player2D.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var player := Player2DScript.new()
	arena.add_child(player)
	player.global_position = Vector2.ZERO
	var data := PlayerDataServiceScript.build_starter_player("slot_1", "Visual Ranger", "ranger")
	data["critical_chance"] = 100
	player.apply_player_data(data)

	var enemy := Enemy2DScript.new()
	arena.add_child(enemy)
	enemy.global_position = Vector2(120, 0)
	enemy.apply_enemy_data({"max_health": 300, "attack_damage": 0, "move_speed": 0.0})
	await process_frame

	var result: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(str(result.get("skill_id", "")) == "ranger_ice_shot", "ranger should cast ice shot")
	_expect(bool(result.get("triggered", false)), "100 crit ranger should trigger ice lance")
	_expect(_has_vfx_role(arena, "ice_arrow_trail"), "ice shot should spawn ice arrow trail")
	_expect(_has_vfx_role(arena, "ice_lance_trail"), "triggered ice lance should spawn ice lance trail")
	_expect(_has_vfx_role(arena, "coc_trigger_flash"), "CoC trigger should spawn trigger flash")
	_expect(_role_line_width(arena, "ice_lance_trail") < _role_line_width(arena, "ice_arrow_trail"), "ice lance should be visually thinner than ice arrow")

	arena.queue_free()
	await process_frame
	_finish()

func _has_vfx_role(root_node: Node, role: String) -> bool:
	for child in root_node.get_children():
		if child.has_meta("vfx_role") and str(child.get_meta("vfx_role")) == role:
			return true
	return false

func _role_line_width(root_node: Node, role: String) -> float:
	for child in root_node.get_children():
		if child.has_meta("vfx_role") and str(child.get_meta("vfx_role")) == role:
			var line := child.find_child("*Line", true, false) as Line2D
			if line != null:
				return line.width
	return 999.0

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_ICE_VFX_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg' --script 'res://tests/regression/regression_ranger_ice_vfx_contract.gd'
```

Expected: FAIL because ice-specific VFX roles do not exist yet.

- [ ] **Step 3: Add VFX factory methods**

Modify `scripts/combat/Vfx2DFactory.gd` by adding:

```gdscript
static func spawn_ice_arrow_trail(parent: Node, origin: Vector2, direction: Vector2, distance: float) -> void:
	_spawn_named_projectile(parent, "IceArrowTrailVFX", "ice_arrow_trail", origin, direction, distance, 7.0, Color(0.36, 0.84, 1.0, 0.90), 0.16)

static func spawn_ice_lance_trail(parent: Node, origin: Vector2, direction: Vector2, distance: float) -> void:
	_spawn_named_projectile(parent, "IceLanceTrailVFX", "ice_lance_trail", origin, direction, distance + 28.0, 3.0, Color(0.78, 0.96, 1.0, 0.96), 0.12)

static func spawn_coc_trigger_flash(parent: Node, position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "CocTriggerFlashVFX"
	root.set_meta("vfx_role", "coc_trigger_flash")
	parent.add_child(root)
	root.global_position = position
	for i in range(8):
		var ray := Line2D.new()
		ray.name = "CocTriggerRay"
		ray.width = 2.0
		ray.default_color = Color(0.58, 0.90, 1.0, 0.86)
		var angle := TAU * float(i) / 8.0
		ray.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(angle), sin(angle)) * 24.0])
		root.add_child(ray)
	_fade(parent, root, 0.12)

static func _spawn_named_projectile(parent: Node, node_name: String, role: String, origin: Vector2, direction: Vector2, distance: float, width: float, color: Color, duration: float) -> void:
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var root := Node2D.new()
	root.name = node_name
	root.set_meta("vfx_role", role)
	parent.add_child(root)
	root.global_position = origin
	root.rotation = direction.angle()
	var line := Line2D.new()
	line.name = "%sLine" % node_name
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([Vector2(16, 0), Vector2(maxf(48.0, distance), 0)])
	root.add_child(line)
	var head := Polygon2D.new()
	head.name = "%sHead" % node_name
	var head_x := maxf(48.0, distance)
	head.polygon = PackedVector2Array([Vector2(head_x + 16, 0), Vector2(head_x - 10, -width * 1.5), Vector2(head_x - 5, 0), Vector2(head_x - 10, width * 1.5)])
	head.color = color
	root.add_child(head)
	_fade(parent, root, duration)
```

Keep existing `spawn_projectile_trail()` as generic fallback.

- [ ] **Step 4: Route skill IDs to VFX**

Modify `scripts/combat/Skill2DLibrary.gd`:

```gdscript
	if is_instance_valid(parent) and cast_style == "projectile":
		var origin := caster.global_position + direction * 24.0
		if skill_id == "ranger_ice_shot":
			Vfx2DFactoryScript.spawn_ice_arrow_trail(parent, origin, direction, first_hit_distance)
		elif skill_id == "ice_lance":
			Vfx2DFactoryScript.spawn_ice_lance_trail(parent, origin, direction, first_hit_distance)
		else:
			Vfx2DFactoryScript.spawn_projectile_trail(parent, origin, direction, first_hit_distance)
```

Modify `scripts/combat/Player2D.gd` inside the triggered block:

```gdscript
	if bool(result.get("triggered", false)):
		var trigger_result := Skill2DLibraryScript.cast_triggered_skill(self, str(result["trigger_skill_id"]), direction, attack_damage)
		result["trigger_hit_count"] = int(trigger_result.get("hit_count", 0))
		var parent := get_parent()
		if is_instance_valid(parent):
			Vfx2DFactoryScript.spawn_coc_trigger_flash(parent, global_position + direction.normalized() * 18.0)
```

Add `const Vfx2DFactoryScript := preload("res://scripts/combat/Vfx2DFactory.gd")` to `Player2D.gd`.

- [ ] **Step 5: Run VFX test**

Run the test from Step 2 again.

Expected: `NEW_PROJECT_RANGER_ICE_VFX_CONTRACT_OK`

- [ ] **Step 6: Run ranger CoC regression**

Run:

```powershell
& 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg' --script 'res://tests/regression/regression_ranger_coc_player_cast.gd'
```

Expected: `NEW_PROJECT_RANGER_COC_PLAYER_CAST_OK`

- [ ] **Step 7: Commit**

```powershell
git add scripts/combat/Vfx2DFactory.gd scripts/combat/Skill2DLibrary.gd scripts/combat/Player2D.gd tests/regression/regression_ranger_ice_vfx_contract.gd
git commit -m "Add ranger ice skill VFX"
```

---

### Task 4: Progress Doc and Final Verification

**Files:**
- Create: `docs/progress/2026-06-11-ranger-ice-coc-visual-kit-progress.md`

- [ ] **Step 1: Write progress document**

Create `docs/progress/2026-06-11-ranger-ice-coc-visual-kit-progress.md`:

```markdown
# 游侠寒冰 CoC 视觉套装进度

日期：2026-06-11

## 已完成

- 新增程序化游侠 20 帧 SpriteSheet。
- 游侠进入战斗时使用 `player_ranger_sheet_v1.png` manifest。
- 战士继续使用现有 `player_warrior_sheet_v3.png`。
- 寒冰射击使用冰箭轨迹。
- 冰矛使用更细、更亮的冰矛轨迹。
- CoC 触发时生成蓝白触发闪光。

## 验证

- `regression_ranger_visual_kit_assets.gd`
- `regression_class_basic_skill_presentation.gd`
- `regression_ranger_ice_vfx_contract.gd`
- `regression_default_image2_player_art_contract.gd`
- `regression_ranger_coc_player_cast.gd`
- `regression_scene_boot.gd`

## 已知限制

- 游侠 SpriteSheet 是程序化生成资产，不是最终商用品质。
- 仍使用 `runtime_flip_2dir`，尚未制作四方向角色。
- 弓包含在角色帧内，尚未支持装备换装。
- 法师和侍僧仍使用程序化占位外观。
```

- [ ] **Step 2: Run focused verification**

Run:

```powershell
$godot = 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe'
$project = 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg'
$tests = @(
  'res://tests/regression/regression_ranger_visual_kit_assets.gd',
  'res://tests/regression/regression_class_basic_skill_presentation.gd',
  'res://tests/regression/regression_ranger_ice_vfx_contract.gd',
  'res://tests/regression/regression_default_image2_player_art_contract.gd',
  'res://tests/regression/regression_ranger_coc_player_cast.gd',
  'res://tests/regression/regression_scene_boot.gd'
)
foreach ($test in $tests) {
  Write-Host "RUN $test"
  & $godot --headless --path $project --script $test
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED $test EXIT $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}
Write-Host 'RANGER_ICE_VISUAL_KIT_REGRESSION_OK'
```

Expected: all tests print their OK marker and final output is `RANGER_ICE_VISUAL_KIT_REGRESSION_OK`.

- [ ] **Step 3: Run diff checks**

```powershell
git diff --check -- scripts/tools/GenerateRangerVisualKit.gd scripts/app/Game2D.gd scripts/combat/Vfx2DFactory.gd scripts/combat/Skill2DLibrary.gd scripts/combat/Player2D.gd tests/regression/regression_ranger_visual_kit_assets.gd tests/regression/regression_class_basic_skill_presentation.gd tests/regression/regression_ranger_ice_vfx_contract.gd docs/progress/2026-06-11-ranger-ice-coc-visual-kit-progress.md
```

Expected: no output and exit code 0.

- [ ] **Step 4: Commit final doc**

```powershell
git add docs/progress/2026-06-11-ranger-ice-coc-visual-kit-progress.md
git commit -m "Document ranger ice visual kit progress"
```

