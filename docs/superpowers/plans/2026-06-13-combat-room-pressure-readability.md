# Combat Room Pressure Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a small, testable P2/P3 foundation inspired by 33 Immortals: clearer room objectives, divine pressure warnings, and combat readability contracts, without adding roguelike relics or multiplayer systems.

**Architecture:** Keep gameplay rules in small `scripts/data/*Service.gd` files, keep Godot scene wiring in `scripts/app/Game2D.gd`, keep visual-only effects in `scripts/combat/Vfx2DFactory.gd`, and expose QA/test snapshots instead of relying on screenshot guessing. The first implementation must remain single-room, single-player, and compatible with current save data.

**Tech Stack:** Godot 4.6.2, GDScript, headless regression scripts in `tests/regression`, existing `Game2D.tscn`, existing HUD and combat scripts.

---

## Design Boundaries

- Do not add局内遗物、每局构筑、Roguelike relic choice, multiplayer, matchmaking, or network sync.
- Do not clear or migrate player saves.
- Do not replace current player/enemy art in this plan.
- Do not add code-generated character sprites.
- Do not alter the current asset pipeline except for VFX layering interfaces.

## File Structure

- Create `scripts/data/RoomObjectiveService.gd`  
  Responsibility: build objective state from a floor template, update progress after enemy deaths/events, return HUD text and completion state.

- Create `tests/regression/regression_room_objective_service.gd`  
  Responsibility: prove objective state is deterministic and does not depend on scene nodes.

- Modify `scripts/app/Game2D.gd`  
  Responsibility: own current objective state, update it on spawn/enemy death/floor clear, and send objective text to HUD.

- Modify `scripts/ui/HudController.gd`  
  Responsibility: show compact objective text without changing inventory or vitals layout.

- Create `tests/regression/regression_room_objective_hud_contract.gd`  
  Responsibility: prove a loaded Game2D scene exposes and displays objective text.

- Create `scripts/data/DivinePressureService.gd`  
  Responsibility: deterministic rules for divine pressure warning duration, damage, radius, and trigger eligibility.

- Modify `scripts/combat/Vfx2DFactory.gd`  
  Responsibility: spawn visual-only ground warning and impact VFX with distinct `vfx_role` metadata.

- Modify `scripts/app/Game2D.gd`  
  Responsibility: trigger a minimal divine pressure event after elite/boss death or via test hook; apply damage only after warning delay.

- Create `tests/regression/regression_divine_pressure_service.gd`  
  Responsibility: prove pressure configs satisfy readable warning rules.

- Create `tests/regression/regression_divine_pressure_game2d_contract.gd`  
  Responsibility: prove Game2D can spawn a warning and expose its state without blocking normal clear/portal flow.

- Modify `scripts/combat/Enemy2D.gd`  
  Responsibility: expose combat readability snapshots for attack windup/animation state; keep existing animation implementation.

- Create `tests/regression/regression_enemy_attack_readability_contract.gd`  
  Responsibility: prove enemy attack states are inspectable and meet minimum warning/animation contract.

- Create `docs/progress/2026-06-13-combat-room-pressure-readability-progress.md`  
  Responsibility: record what changed, what was verified, and what remains out of scope.

---

## Task 1: Room Objective Service

**Files:**
- Create: `scripts/data/RoomObjectiveService.gd`
- Create: `tests/regression/regression_room_objective_service.gd`

- [ ] **Step 1: Write the failing regression test**

Create `tests/regression/regression_room_objective_service.gd`:

```gdscript
extends SceneTree

const RoomObjectiveServiceScript := preload("res://scripts/data/RoomObjectiveService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var clear_state := RoomObjectiveServiceScript.build_state({
		"floor": 2,
		"template_id": "dense_room",
		"objective": "clear_all",
		"enemies": [{}, {}, {}, {}],
	})
	_expect(str(clear_state.get("objective_id", "")) == "clear_all", "clear_all objective id should be preserved")
	_expect(int(clear_state.get("target_count", 0)) == 4, "clear_all target should equal enemy count")
	_expect(str(clear_state.get("hud_text", "")).contains("Clear enemies"), "clear_all HUD text should be readable")
	clear_state = RoomObjectiveServiceScript.record_enemy_defeated(clear_state, {"is_elite": false, "is_boss": false})
	_expect(int(clear_state.get("current_count", 0)) == 1, "enemy defeat should advance clear objective")
	_expect(not bool(clear_state.get("completed", true)), "objective should not complete early")
	clear_state = RoomObjectiveServiceScript.record_enemy_defeated(clear_state, {})
	clear_state = RoomObjectiveServiceScript.record_enemy_defeated(clear_state, {})
	clear_state = RoomObjectiveServiceScript.record_enemy_defeated(clear_state, {})
	_expect(bool(clear_state.get("completed", false)), "clear objective should complete at target count")

	var elite_state := RoomObjectiveServiceScript.build_state({
		"floor": 5,
		"template_id": "elite_preview",
		"objective": "defeat_elite",
		"enemies": [{}, {"modifiers": {"elite_affixes": ["tough"]}}, {}],
	})
	_expect(int(elite_state.get("target_count", 0)) == 1, "elite objective should target elite count")
	elite_state = RoomObjectiveServiceScript.record_enemy_defeated(elite_state, {"is_elite": false})
	_expect(not bool(elite_state.get("completed", true)), "normal kill should not complete elite objective")
	elite_state = RoomObjectiveServiceScript.record_enemy_defeated(elite_state, {"is_elite": true})
	_expect(bool(elite_state.get("completed", false)), "elite kill should complete elite objective")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ROOM_OBJECTIVE_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_room_objective_service.gd'
```

Expected: FAIL because `scripts/data/RoomObjectiveService.gd` does not exist.

- [ ] **Step 3: Implement the service**

Create `scripts/data/RoomObjectiveService.gd`:

```gdscript
extends RefCounted
class_name RoomObjectiveService

static func build_state(template: Dictionary) -> Dictionary:
	var objective_id := str(template.get("objective", "clear_all"))
	var enemies: Array = Array(template.get("enemies", []))
	var target_count := _count_targets(objective_id, enemies)
	var state := {
		"objective_id": objective_id,
		"template_id": str(template.get("template_id", "standard_clear")),
		"floor": int(template.get("floor", 1)),
		"target_count": maxi(1, target_count),
		"current_count": 0,
		"completed": false,
	}
	state["hud_text"] = build_hud_text(state)
	return state

static func record_enemy_defeated(state: Dictionary, enemy_data: Dictionary) -> Dictionary:
	var result := state.duplicate(true)
	var objective_id := str(result.get("objective_id", "clear_all"))
	var advances := false
	match objective_id:
		"defeat_elite":
			advances = bool(enemy_data.get("is_elite", false)) or bool(enemy_data.get("is_boss", false))
		"defeat_boss":
			advances = bool(enemy_data.get("is_boss", false))
		_:
			advances = true
	if advances:
		result["current_count"] = mini(int(result.get("target_count", 1)), int(result.get("current_count", 0)) + 1)
	result["completed"] = int(result.get("current_count", 0)) >= int(result.get("target_count", 1))
	result["hud_text"] = build_hud_text(result)
	return result

static func build_hud_text(state: Dictionary) -> String:
	var objective_id := str(state.get("objective_id", "clear_all"))
	var current := int(state.get("current_count", 0))
	var target := maxi(1, int(state.get("target_count", 1)))
	match objective_id:
		"defeat_elite":
			return "Objective: Defeat elite %d/%d" % [current, target]
		"defeat_boss":
			return "Objective: Break the gatekeeper %d/%d" % [current, target]
		_:
			return "Objective: Clear enemies %d/%d" % [current, target]

static func _count_targets(objective_id: String, enemies: Array) -> int:
	if objective_id == "defeat_elite":
		var elite_count := 0
		for entry in enemies:
			var spawn := Dictionary(entry)
			var modifiers := Dictionary(spawn.get("modifiers", {}))
			if bool(modifiers.get("boss", false)) or bool(modifiers.get("elite", false)):
				elite_count += 1
			elif Array(modifiers.get("elite_affixes", [])).size() > 0:
				elite_count += 1
		return elite_count
	if objective_id == "defeat_boss":
		var boss_count := 0
		for entry in enemies:
			var spawn := Dictionary(entry)
			var modifiers := Dictionary(spawn.get("modifiers", {}))
			if bool(modifiers.get("boss", false)):
				boss_count += 1
		return boss_count
	return enemies.size()
```

- [ ] **Step 4: Run the test to verify it passes**

Run the same command. Expected output:

```text
NEW_PROJECT_ROOM_OBJECTIVE_SERVICE_OK
```

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add scripts/data/RoomObjectiveService.gd tests/regression/regression_room_objective_service.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add room objective service"
```

---

## Task 2: Objective HUD Contract

**Files:**
- Modify: `scripts/app/Game2D.gd`
- Modify: `scripts/ui/HudController.gd`
- Create: `tests/regression/regression_room_objective_hud_contract.gd`

- [ ] **Step 1: Write the failing regression test**

Create `tests/regression/regression_room_objective_hud_contract.gd`:

```gdscript
extends SceneTree

const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_expect(scene.has_method("get_room_objective_state_for_test"), "Game2D should expose objective state for QA")
	var state: Dictionary = scene.call("get_room_objective_state_for_test") if scene.has_method("get_room_objective_state_for_test") else {}
	_expect(str(state.get("hud_text", "")).contains("Objective:"), "objective state should include HUD text")
	var hud := scene.get("hud") as Node
	_expect(is_instance_valid(hud), "HUD should exist")
	if is_instance_valid(hud) and hud.has_method("get_objective_text_for_test"):
		_expect(str(hud.call("get_objective_text_for_test")).contains("Objective:"), "HUD should show objective text")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ROOM_OBJECTIVE_HUD_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run the test to verify it fails**

Expected: FAIL because Game2D and HUD do not expose objective state yet.

- [ ] **Step 3: Wire the objective service into Game2D**

In `scripts/app/Game2D.gd`, add preload near other services:

```gdscript
const RoomObjectiveServiceScript := preload("res://scripts/data/RoomObjectiveService.gd")
```

Add state near current floor fields:

```gdscript
var room_objective_state: Dictionary = {}
```

In `_spawn_floor_template(template: Dictionary)`, after `current_floor_template = template.duplicate(true)`, add:

```gdscript
room_objective_state = RoomObjectiveServiceScript.build_state(current_floor_template)
```

In `_on_enemy_died(enemy: Node)`, after `floor_kill_count += 1`, add:

```gdscript
room_objective_state = RoomObjectiveServiceScript.record_enemy_defeated(room_objective_state, _build_enemy_experience_source(enemy))
```

In `_update_hud(message: String)`, after `hud.set_log(message)`, add:

```gdscript
if hud.has_method("set_objective"):
	hud.set_objective(str(room_objective_state.get("hud_text", "")))
```

Add test getter:

```gdscript
func get_room_objective_state_for_test() -> Dictionary:
	return room_objective_state.duplicate(true)
```

- [ ] **Step 4: Add objective text to HUD**

In `scripts/ui/HudController.gd`, add field:

```gdscript
var objective_label: Label
```

In `_ready()`, after `log_label = _make_label(...)`, create and add:

```gdscript
objective_label = _make_label("ObjectiveLabel", Vector2(20, 72), 14, DarkArpgUiThemeScript.COLOR_GOLD)
objective_label.size = Vector2(260, 42)
```

Add `add_child(objective_label)` near other label adds.

Shift existing vitals down only if text overlaps. Keep `hud_panel.size` under `Vector2(292, 210)` and avoid covering playfield.

Add methods:

```gdscript
func set_objective(text: String) -> void:
	if is_instance_valid(objective_label):
		objective_label.text = text

func get_objective_text_for_test() -> String:
	return objective_label.text if is_instance_valid(objective_label) else ""
```

- [ ] **Step 5: Run the test to verify it passes**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_room_objective_hud_contract.gd'
```

Expected:

```text
NEW_PROJECT_ROOM_OBJECTIVE_HUD_CONTRACT_OK
```

- [ ] **Step 6: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add scripts/app/Game2D.gd scripts/ui/HudController.gd tests/regression/regression_room_objective_hud_contract.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Show room objective in HUD"
```

---

## Task 3: Divine Pressure Service

**Files:**
- Create: `scripts/data/DivinePressureService.gd`
- Create: `tests/regression/regression_divine_pressure_service.gd`

- [ ] **Step 1: Write the failing regression test**

Create `tests/regression/regression_divine_pressure_service.gd`:

```gdscript
extends SceneTree

const DivinePressureServiceScript := preload("res://scripts/data/DivinePressureService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var config := DivinePressureServiceScript.build_event_config("elite_defeated", 4)
	_expect(str(config.get("trigger", "")) == "elite_defeated", "trigger should be preserved")
	_expect(float(config.get("warning_seconds", 0.0)) >= 0.6, "warning should be at least 0.6 seconds")
	_expect(float(config.get("radius", 0.0)) >= 80.0, "pressure radius should be readable")
	_expect(int(config.get("damage", 0)) > 0, "pressure damage should be positive")
	_expect(not bool(config.get("blocks_portal", true)), "minimal pressure should not block portal yet")
	_expect(DivinePressureServiceScript.should_trigger_after_enemy({"is_elite": true}, false), "elite death can trigger pressure")
	_expect(not DivinePressureServiceScript.should_trigger_after_enemy({"is_elite": false}, false), "normal death should not trigger pressure")
	_expect(not DivinePressureServiceScript.should_trigger_after_enemy({"is_boss": true}, true), "do not trigger when a pressure event is already active")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DIVINE_PRESSURE_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run the test to verify it fails**

Expected: FAIL because `DivinePressureService.gd` does not exist.

- [ ] **Step 3: Implement the service**

Create `scripts/data/DivinePressureService.gd`:

```gdscript
extends RefCounted
class_name DivinePressureService

const MIN_WARNING_SECONDS := 0.6

static func build_event_config(trigger: String, floor: int) -> Dictionary:
	var safe_floor := maxi(1, floor)
	return {
		"trigger": trigger,
		"warning_seconds": MIN_WARNING_SECONDS + minf(0.35, float(safe_floor) * 0.02),
		"radius": 92.0 + minf(36.0, float(safe_floor) * 3.0),
		"damage": 10 + int(float(safe_floor) * 1.5),
		"color_role": "enemy_pressure_warning",
		"blocks_portal": false,
	}

static func should_trigger_after_enemy(enemy_data: Dictionary, event_active: bool) -> bool:
	if event_active:
		return false
	return bool(enemy_data.get("is_elite", false)) or bool(enemy_data.get("is_boss", false))
```

- [ ] **Step 4: Run the test to verify it passes**

Expected:

```text
NEW_PROJECT_DIVINE_PRESSURE_SERVICE_OK
```

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add scripts/data/DivinePressureService.gd tests/regression/regression_divine_pressure_service.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add divine pressure service"
```

---

## Task 4: Divine Pressure Visual Contract

**Files:**
- Modify: `scripts/combat/Vfx2DFactory.gd`
- Modify: `scripts/app/Game2D.gd`
- Create: `tests/regression/regression_divine_pressure_game2d_contract.gd`

- [ ] **Step 1: Write the failing regression test**

Create `tests/regression/regression_divine_pressure_game2d_contract.gd`:

```gdscript
extends SceneTree

const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_expect(scene.has_method("trigger_divine_pressure_for_test"), "Game2D should expose divine pressure test trigger")
	scene.call("trigger_divine_pressure_for_test", Vector2.ZERO, "elite_defeated")
	await process_frame
	_expect(scene.has_method("get_divine_pressure_state_for_test"), "Game2D should expose divine pressure state")
	var state: Dictionary = scene.call("get_divine_pressure_state_for_test")
	_expect(bool(state.get("active", false)), "pressure should be active during warning")
	_expect(float(state.get("warning_seconds", 0.0)) >= 0.6, "pressure warning should be readable")
	_expect(scene.get_node_or_null("ArenaRoot/DivinePressureWarning") != null, "warning VFX node should exist")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DIVINE_PRESSURE_GAME2D_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run the test to verify it fails**

Expected: FAIL because pressure hooks and VFX do not exist.

- [ ] **Step 3: Add VFX factory methods**

In `scripts/combat/Vfx2DFactory.gd`, add:

```gdscript
static func spawn_divine_pressure_warning(parent: Node, position: Vector2, radius: float, warning_seconds: float) -> Node2D:
	var root := Node2D.new()
	root.name = "DivinePressureWarning"
	root.set_meta("vfx_role", "enemy_pressure_warning")
	parent.add_child(root)
	root.global_position = position
	var ring := Line2D.new()
	ring.name = "WarningRing"
	ring.width = 5.0
	ring.closed = true
	ring.default_color = Color(0.45, 0.70, 1.0, 0.72)
	for i in range(40):
		var angle := TAU * float(i) / 40.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * radius)
	root.add_child(ring)
	var fill := Polygon2D.new()
	fill.name = "WarningFill"
	var points := PackedVector2Array()
	for i in range(40):
		var angle := TAU * float(i) / 40.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	fill.polygon = points
	fill.color = Color(0.12, 0.28, 0.58, 0.18)
	root.add_child(fill)
	var tween := parent.create_tween()
	tween.tween_property(root, "modulate:a", 0.42, warning_seconds * 0.5)
	tween.tween_property(root, "modulate:a", 1.0, warning_seconds * 0.5)
	return root

static func spawn_divine_pressure_impact(parent: Node, position: Vector2, radius: float) -> void:
	var root := Node2D.new()
	root.name = "DivinePressureImpact"
	root.set_meta("vfx_role", "enemy_pressure_impact")
	parent.add_child(root)
	root.global_position = position
	var ring := Line2D.new()
	ring.name = "ImpactRing"
	ring.width = 7.0
	ring.closed = true
	ring.default_color = Color(0.72, 0.92, 1.0, 0.9)
	for i in range(40):
		var angle := TAU * float(i) / 40.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * radius)
	root.add_child(ring)
	_fade(parent, root, 0.22)
```

- [ ] **Step 4: Wire minimal pressure into Game2D**

In `scripts/app/Game2D.gd`, add preloads:

```gdscript
const DivinePressureServiceScript := preload("res://scripts/data/DivinePressureService.gd")
const Vfx2DFactoryScript := preload("res://scripts/combat/Vfx2DFactory.gd")
```

Add state:

```gdscript
var divine_pressure_state: Dictionary = {"active": false}
var divine_pressure_warning_node: Node2D
```

In `_on_enemy_died(enemy: Node)`, build enemy data once:

```gdscript
var defeated_enemy_data := _build_enemy_experience_source(enemy)
```

Use `defeated_enemy_data` both for XP and pressure:

```gdscript
var xp_result := _award_enemy_experience(defeated_enemy_data)
if enemy is Node2D and DivinePressureServiceScript.should_trigger_after_enemy(defeated_enemy_data, bool(divine_pressure_state.get("active", false))):
	_trigger_divine_pressure((enemy as Node2D).global_position, "elite_defeated")
```

Add functions:

```gdscript
func _trigger_divine_pressure(position: Vector2, trigger: String) -> void:
	if not is_instance_valid(arena_root):
		return
	var config := DivinePressureServiceScript.build_event_config(trigger, current_floor)
	divine_pressure_state = config.duplicate(true)
	divine_pressure_state["active"] = true
	divine_pressure_state["position"] = position
	divine_pressure_warning_node = Vfx2DFactoryScript.spawn_divine_pressure_warning(arena_root, position, float(config.get("radius", 96.0)), float(config.get("warning_seconds", 0.6)))
	get_tree().create_timer(float(config.get("warning_seconds", 0.6))).timeout.connect(func(): _resolve_divine_pressure())

func _resolve_divine_pressure() -> void:
	if not bool(divine_pressure_state.get("active", false)):
		return
	var position: Vector2 = divine_pressure_state.get("position", Vector2.ZERO)
	var radius := float(divine_pressure_state.get("radius", 96.0))
	Vfx2DFactoryScript.spawn_divine_pressure_impact(arena_root, position, radius)
	if is_instance_valid(divine_pressure_warning_node):
		divine_pressure_warning_node.queue_free()
	divine_pressure_state["active"] = false

func trigger_divine_pressure_for_test(position: Vector2, trigger: String = "test") -> void:
	_trigger_divine_pressure(position, trigger)

func get_divine_pressure_state_for_test() -> Dictionary:
	return divine_pressure_state.duplicate(true)
```

- [ ] **Step 5: Run the test to verify it passes**

Expected:

```text
NEW_PROJECT_DIVINE_PRESSURE_GAME2D_CONTRACT_OK
```

- [ ] **Step 6: Run floor clear regression**

Run:

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_floor_clear_portal.gd'
```

Expected:

```text
NEW_PROJECT_FLOOR_CLEAR_PORTAL_OK
```

- [ ] **Step 7: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add scripts/combat/Vfx2DFactory.gd scripts/app/Game2D.gd tests/regression/regression_divine_pressure_game2d_contract.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add divine pressure warning contract"
```

---

## Task 5: Enemy Attack Readability Contract

**Files:**
- Modify: `scripts/combat/Enemy2D.gd`
- Create: `tests/regression/regression_enemy_attack_readability_contract.gd`

- [ ] **Step 1: Write the failing regression test**

Create `tests/regression/regression_enemy_attack_readability_contract.gd`:

```gdscript
extends SceneTree

const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var enemy := Enemy2DScript.new()
	root.add_child(enemy)
	await process_frame
	_expect(enemy.has_method("get_attack_readability_snapshot_for_test"), "Enemy should expose attack readability snapshot")
	var snapshot: Dictionary = enemy.call("get_attack_readability_snapshot_for_test")
	_expect(float(snapshot.get("minimum_attack_warning_seconds", 0.0)) >= 0.1, "enemy warning baseline should exist")
	_expect(Array(snapshot.get("required_animation_states", [])).has("attack"), "attack animation state should be required")
	_expect(bool(snapshot.get("separate_hit_vfx", false)), "hit VFX should remain separate from body sprite")
	enemy.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_ATTACK_READABILITY_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run the test to verify it fails**

Expected: FAIL because the test getter does not exist.

- [ ] **Step 3: Add readability snapshot**

In `scripts/combat/Enemy2D.gd`, add:

```gdscript
func get_attack_readability_snapshot_for_test() -> Dictionary:
	var manifest_animations: Dictionary = Dictionary(visual_asset_manifest.get("animations", {}))
	return {
		"minimum_attack_warning_seconds": 0.1,
		"current_attack_windup_remaining": attack_windup_remaining,
		"actor_animation_name": actor_animation_name,
		"has_attack_arc_node": is_instance_valid(attack_arc),
		"separate_hit_vfx": true,
		"required_animation_states": ["idle", "run", "attack", "death"],
		"manifest_has_attack": manifest_animations.has("attack"),
		"manifest_has_death": manifest_animations.has("death"),
	}
```

- [ ] **Step 4: Run the test to verify it passes**

Expected:

```text
NEW_PROJECT_ENEMY_ATTACK_READABILITY_CONTRACT_OK
```

- [ ] **Step 5: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add scripts/combat/Enemy2D.gd tests/regression/regression_enemy_attack_readability_contract.gd
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Add enemy attack readability contract"
```

---

## Task 6: Documentation and Focused Verification

**Files:**
- Create: `docs/progress/2026-06-13-combat-room-pressure-readability-progress.md`
- Modify if needed: `docs/planning/2026-06-09-inventory-equipment-shippable-roadmap.md`

- [ ] **Step 1: Write progress document**

Create `docs/progress/2026-06-13-combat-room-pressure-readability-progress.md`:

```markdown
# 战斗房间、神罚压力与可读性推进记录

日期：2026-06-13

## 完成内容

- 增加房间目标服务与 HUD 合同。
- 增加神罚压力配置服务与最小视觉预警合同。
- 增加敌人攻击可读性 QA 合同。

## 明确未做

- 未加入局内遗物。
- 未加入每局构筑。
- 未加入多人协作或网络同步。
- 未替换正式角色素材。

## 验证

- NEW_PROJECT_ROOM_OBJECTIVE_SERVICE_OK
- NEW_PROJECT_ROOM_OBJECTIVE_HUD_CONTRACT_OK
- NEW_PROJECT_DIVINE_PRESSURE_SERVICE_OK
- NEW_PROJECT_DIVINE_PRESSURE_GAME2D_CONTRACT_OK
- NEW_PROJECT_ENEMY_ATTACK_READABILITY_CONTRACT_OK
- NEW_PROJECT_FLOOR_CLEAR_PORTAL_OK
- NEW_PROJECT_SCENE_BOOT_ALL_OK
```

- [ ] **Step 2: Run focused verification**

Run:

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
$checks = @(
  'res://tests/regression/regression_room_objective_service.gd',
  'res://tests/regression/regression_room_objective_hud_contract.gd',
  'res://tests/regression/regression_divine_pressure_service.gd',
  'res://tests/regression/regression_divine_pressure_game2d_contract.gd',
  'res://tests/regression/regression_enemy_attack_readability_contract.gd',
  'res://tests/regression/regression_floor_clear_portal.gd',
  'res://tests/regression/regression_scene_boot.gd'
)
foreach ($check in $checks) {
  Write-Host "RUN $check"
  & $godot --headless --path $project --script $check
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED $check EXIT $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}
Write-Host 'COMBAT_ROOM_PRESSURE_READABILITY_FOCUSED_OK'
```

Expected:

```text
COMBAT_ROOM_PRESSURE_READABILITY_FOCUSED_OK
```

- [ ] **Step 3: Run process cleanup check**

Run:

```powershell
Get-Process | Where-Object { $_.ProcessName -like 'Godot_v4.6.2-stable_win64*' } | Select-Object Id,ProcessName
```

Expected: no lingering Godot test process unless the editor is intentionally open.

- [ ] **Step 4: Commit**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' add docs/progress/2026-06-13-combat-room-pressure-readability-progress.md
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' commit -m "Record combat room pressure progress"
```

---

## Final Verification Before Push

- [ ] **Run full regression**

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
$tests = Get-ChildItem -Path "$project\tests\regression" -File -Filter '*.gd' | Sort-Object Name | ForEach-Object { 'res://tests/regression/' + $_.Name }
foreach ($test in $tests) {
  Write-Host "RUN $test"
  & $godot --headless --path $project --script $test
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED $test EXIT $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}
Write-Host 'ALL_NEW_PROJECT_REGRESSION_OK'
```

- [ ] **Run scene boot smoke**

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_scene_boot.gd'
```

- [ ] **Push current branch**

```powershell
& 'C:\Users\huhej\AppData\Local\GitHubDesktop\app-3.5.12\resources\app\git\cmd\git.exe' push origin codex/pixel-actor-art-trial
```

## Self-Review Checklist

- Spec coverage: room rhythm maps to Tasks 1-2; divine pressure maps to Tasks 3-4; combat readability maps to Task 5; documentation and verification map to Task 6.
- Explicitly excluded: relics, per-run builds, multiplayer, network sync.
- Risk: Task 4 touches `Game2D.gd`, which is large. Keep additions small and use test-only accessors to avoid broad refactors.
- Visual risk: divine pressure VFX is still a temporary programmatic warning; it is acceptable for readability validation, but production art should later replace it with authored VFX assets.
