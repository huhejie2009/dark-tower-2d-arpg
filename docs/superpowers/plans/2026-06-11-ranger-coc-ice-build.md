# Ranger CoC Ice Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first equipment-driven ranger Build slice: Ice Shot attacks that can be fired by manual input or auto-combat, crit-triggered Ice Lance, simple ranger CoC talents, equipment/gem modifiers, and regression coverage.

**Architecture:** Keep rules in small `scripts/data` and `scripts/rules` services. `Game2D.gd` should only route player input or auto-combat intent into `Player2D`, while `Player2D` delegates skill/trigger math to services and `Skill2DLibrary` handles scene hits/VFX. Gem sockets and talent effects are pure Dictionary transformations so inventory, town, and combat can share them later.

**Tech Stack:** Godot 4.6 GDScript, existing `SceneTree` regression scripts, current pure Dictionary service pattern, no external runtime dependency.

---

## File Structure

- Create `scripts/data/TriggerRuleService.gd`: pure CoC trigger cooldown, crit roll, and trigger result rules.
- Create `scripts/data/GemSocketService.gd`: pure socket defaults, gem install/remove, and modifier aggregation.
- Create `scripts/data/AutoCombatController.gd`: pure helper that picks movement/attack intent from player/enemy positions.
- Modify `scripts/rules/SkillRules.gd`: add `ranger_ice_shot` and `ice_lance`, plus tags and trigger metadata.
- Modify `scripts/combat/Skill2DLibrary.gd`: add projectile-style casts for Ice Shot and Ice Lance while keeping old basic skills working.
- Modify `scripts/combat/Player2D.gd`: expose `set_combat_mode`, `tick_trigger_cooldowns`, `cast_basic` result trigger fields, and ranger CoC stats.
- Modify `scripts/app/Game2D.gd`: add auto/manual mode toggle and route auto-combat intent into `Player2D.cast_basic`.
- Modify `scripts/data/SkillNodeGrowthService.gd`: add 12-15 ranger CoC nodes and reset support.
- Modify `scripts/data/EquipmentDataService.gd`: include CoC stats in totals and score.
- Modify `scripts/rules/EquipmentAffixRules.gd`: add ranger ice/cold/crit drops and starter bow data.
- Test with focused regressions first, then run relevant existing tests.

## Verification Commands

Use the local Godot console path if available. If not, find it before executing tests:

```powershell
$godot = 'C:\Users\huhej\.codex\mcp\godot-bin\Godot_v4.6.2-stable_win64_console.exe'
$project = 'C:\Users\MasterQian\Desktop\锦城\hhj_game\dark-tower-2d-arpg'
& $godot --headless --path $project --script 'res://tests/regression/regression_ranger_coc_trigger_service.gd'
```

Expected focused pass markers are listed in each task.

### Task 1: Skill Rules And Trigger Service

**Files:**
- Modify: `scripts/rules/SkillRules.gd`
- Create: `scripts/data/TriggerRuleService.gd`
- Test: `tests/regression/regression_ranger_coc_trigger_service.gd`

- [ ] **Step 1: Write the failing trigger regression**

Create `tests/regression/regression_ranger_coc_trigger_service.gd`:

```gdscript
extends SceneTree

const SkillRulesScript := preload("res://scripts/rules/SkillRules.gd")
const TriggerRuleServiceScript := preload("res://scripts/data/TriggerRuleService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ice_shot := SkillRulesScript.get_skill("ranger_ice_shot")
	_expect(str(ice_shot.get("name", "")) == "寒冰射击", "ranger_ice_shot should exist")
	_expect(Array(ice_shot.get("tags", [])).has("projectile"), "ice shot should be projectile-tagged")
	_expect(float(ice_shot.get("physical_to_cold_ratio", 0.0)) == 0.6, "ice shot should convert 60% physical to cold")

	var ice_lance := SkillRulesScript.get_skill("ice_lance")
	_expect(str(ice_lance.get("triggered_by", "")) == "coc", "ice_lance should be CoC-triggered")
	_expect(float(ice_lance.get("trigger_cooldown", 0.0)) == 0.30, "ice_lance should use 0.30s base trigger cooldown")

	var state := TriggerRuleServiceScript.create_trigger_state()
	var ready := TriggerRuleServiceScript.evaluate_coc_trigger(
		{"skill_id": "ranger_ice_shot", "critical_hit": true, "hit_count": 1},
		{"coc_trigger_cooldown": 0.30},
		state
	)
	_expect(bool(ready.get("triggered", false)), "critical ice shot should trigger when ready")
	_expect(str(ready.get("trigger_skill_id", "")) == "ice_lance", "trigger should resolve ice_lance")
	var blocked := TriggerRuleServiceScript.evaluate_coc_trigger(
		{"skill_id": "ranger_ice_shot", "critical_hit": true, "hit_count": 1},
		{"coc_trigger_cooldown": 0.30},
		Dictionary(ready.get("next_state", {}))
	)
	_expect(not bool(blocked.get("triggered", true)), "second trigger should be blocked by cooldown")
	_expect(str(blocked.get("reason", "")) == "cooldown", "blocked reason should be cooldown")
	var ticked := TriggerRuleServiceScript.tick_trigger_state(Dictionary(ready.get("next_state", {})), 0.31)
	var after_cooldown := TriggerRuleServiceScript.evaluate_coc_trigger(
		{"skill_id": "ranger_ice_shot", "critical_hit": true, "hit_count": 1},
		{"coc_trigger_cooldown": 0.30},
		ticked
	)
	_expect(bool(after_cooldown.get("triggered", false)), "trigger should be ready after cooldown tick")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_COC_TRIGGER_SERVICE_OK")
		quit(0)
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
& $godot --headless --path $project --script 'res://tests/regression/regression_ranger_coc_trigger_service.gd'
```

Expected: FAIL because `TriggerRuleService.gd` and `ranger_ice_shot` do not exist.

- [ ] **Step 3: Add minimal skill definitions**

Update `scripts/rules/SkillRules.gd` `SKILLS` entries with:

```gdscript
"ranger_ice_shot": {
	"name": "寒冰射击",
	"range": 300.0,
	"cooldown": 0.34,
	"damage_scale": 0.95,
	"physical_to_cold_ratio": 0.60,
	"tags": ["attack", "ranger", "bow", "projectile", "cold"],
	"coc_trigger_skill_id": "ice_lance",
},
"ice_lance": {
	"name": "冰矛",
	"range": 340.0,
	"cooldown": 0.0,
	"damage_scale": 0.70,
	"triggered_by": "coc",
	"trigger_cooldown": 0.30,
	"tags": ["spell", "triggered", "projectile", "cold"],
},
```

- [ ] **Step 4: Add trigger service**

Create `scripts/data/TriggerRuleService.gd`:

```gdscript
extends RefCounted
class_name TriggerRuleService

const SkillRulesScript := preload("res://scripts/rules/SkillRules.gd")

static func create_trigger_state() -> Dictionary:
	return {"cooldowns": {}}

static func tick_trigger_state(state: Dictionary, delta: float) -> Dictionary:
	var result := state.duplicate(true)
	var cooldowns: Dictionary = Dictionary(result.get("cooldowns", {}))
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns[key]) - maxf(0.0, delta))
	result["cooldowns"] = cooldowns
	return result

static func evaluate_coc_trigger(attack_result: Dictionary, stats: Dictionary, state: Dictionary) -> Dictionary:
	if str(attack_result.get("skill_id", "")) != "ranger_ice_shot":
		return _blocked("wrong_skill", state)
	if int(attack_result.get("hit_count", 0)) <= 0:
		return _blocked("no_hit", state)
	if not bool(attack_result.get("critical_hit", false)):
		return _blocked("not_critical", state)
	var skill := SkillRulesScript.get_skill("ice_lance")
	var cooldown := maxf(0.05, float(stats.get("coc_trigger_cooldown", skill.get("trigger_cooldown", 0.30))))
	var cooldowns: Dictionary = Dictionary(state.get("cooldowns", {}))
	if float(cooldowns.get("ice_lance", 0.0)) > 0.0:
		return _blocked("cooldown", state)
	var next_state := state.duplicate(true)
	var next_cooldowns: Dictionary = Dictionary(next_state.get("cooldowns", {}))
	next_cooldowns["ice_lance"] = cooldown
	next_state["cooldowns"] = next_cooldowns
	return {
		"triggered": true,
		"reason": "ready",
		"trigger_skill_id": "ice_lance",
		"cooldown": cooldown,
		"next_state": next_state,
	}

static func _blocked(reason: String, state: Dictionary) -> Dictionary:
	return {"triggered": false, "reason": reason, "next_state": state.duplicate(true)}
```

- [ ] **Step 5: Run focused test**

Run:

```powershell
& $godot --headless --path $project --script 'res://tests/regression/regression_ranger_coc_trigger_service.gd'
```

Expected: `NEW_PROJECT_RANGER_COC_TRIGGER_SERVICE_OK`.

- [ ] **Step 6: Commit**

```powershell
git add scripts/rules/SkillRules.gd scripts/data/TriggerRuleService.gd tests/regression/regression_ranger_coc_trigger_service.gd
$env:GIT_AUTHOR_NAME='Codex'; $env:GIT_AUTHOR_EMAIL='codex@example.invalid'; $env:GIT_COMMITTER_NAME='Codex'; $env:GIT_COMMITTER_EMAIL='codex@example.invalid'
git commit -m "Add ranger CoC trigger rules"
```

### Task 2: Combat Casting Integration

**Files:**
- Modify: `scripts/combat/Skill2DLibrary.gd`
- Modify: `scripts/combat/Player2D.gd`
- Test: `tests/regression/regression_ranger_coc_player_cast.gd`

- [ ] **Step 1: Write failing player cast regression**

Create `tests/regression/regression_ranger_coc_player_cast.gd`:

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
	var data := PlayerDataServiceScript.build_starter_player("slot_1", "CoC Ranger", "ranger")
	data["critical_chance"] = 100
	player.apply_player_data(data)
	var enemy := Enemy2DScript.new()
	arena.add_child(enemy)
	enemy.global_position = Vector2(120, 0)
	enemy.apply_enemy_data({"max_health": 200, "attack_damage": 0, "move_speed": 0.0})
	await process_frame
	var result: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(str(result.get("skill_id", "")) == "ranger_ice_shot", "ranger should cast ice shot")
	_expect(bool(result.get("critical_hit", false)), "100 crit ranger should crit")
	_expect(bool(result.get("triggered", false)), "critical ice shot should trigger ice lance")
	_expect(str(result.get("trigger_skill_id", "")) == "ice_lance", "trigger skill should be ice_lance")
	var blocked: Dictionary = player.cast_basic(Vector2.RIGHT)
	_expect(not bool(blocked.get("triggered", true)), "immediate second cast should not trigger during cooldown or attack recovery")
	arena.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_COC_PLAYER_CAST_OK")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL because ranger still uses `ranger_shot` and cast results have no trigger fields.

- [ ] **Step 3: Route ranger base skill to Ice Shot**

Modify `scripts/rules/ClassRules.gd` ranger entry:

```gdscript
"basic_skill": "ranger_ice_shot",
```

- [ ] **Step 4: Add cast result critical fields**

In `Player2D.gd`, preload trigger service:

```gdscript
const TriggerRuleServiceScript := preload("res://scripts/data/TriggerRuleService.gd")
```

Add member:

```gdscript
var trigger_state: Dictionary = TriggerRuleServiceScript.create_trigger_state()
```

Add helper:

```gdscript
func _build_coc_stats() -> Dictionary:
	return {
		"critical_chance": int(player_data.get("critical_chance", 0)),
		"coc_trigger_cooldown": float(player_data.get("coc_trigger_cooldown", 0.30)),
	}
```

After `Skill2DLibraryScript.cast_basic_skill(...)` in `cast_basic`, set:

```gdscript
var crit_chance := clampi(int(player_data.get("critical_chance", 0)), 0, 100)
var critical_hit := crit_chance >= 100 or (crit_chance > 0 and randi_range(1, 100) <= crit_chance)
result["critical_hit"] = critical_hit
var trigger := TriggerRuleServiceScript.evaluate_coc_trigger(result, _build_coc_stats(), trigger_state)
trigger_state = Dictionary(trigger.get("next_state", trigger_state))
result["triggered"] = bool(trigger.get("triggered", false))
result["trigger_skill_id"] = str(trigger.get("trigger_skill_id", ""))
result["trigger_reason"] = str(trigger.get("reason", ""))
if bool(result.get("triggered", false)):
	var trigger_result := Skill2DLibraryScript.cast_triggered_skill(self, str(result["trigger_skill_id"]), direction, attack_damage)
	result["trigger_hit_count"] = int(trigger_result.get("hit_count", 0))
```

Call trigger cooldown ticking in `_physics_process`:

```gdscript
trigger_state = TriggerRuleServiceScript.tick_trigger_state(trigger_state, delta)
```

- [ ] **Step 5: Add triggered cast in library**

Add to `Skill2DLibrary.gd`:

```gdscript
static func cast_triggered_skill(caster: Node2D, skill_id: String, direction: Vector2, damage: int) -> Dictionary:
	return cast_basic_skill(caster, skill_id, direction, damage)
```

Keep this intentionally simple for the first pass; Task 3 can improve Ice Lance targeting/VFX.

- [ ] **Step 6: Run focused test**

Expected: `NEW_PROJECT_RANGER_COC_PLAYER_CAST_OK`.

- [ ] **Step 7: Run existing combat regressions**

Run:

```powershell
& $godot --headless --path $project --script 'res://tests/regression/regression_player_attack_feel_state.gd'
& $godot --headless --path $project --script 'res://tests/regression/regression_game2d_input_contract.gd'
```

Expected: both pass.

- [ ] **Step 8: Commit**

Commit files touched in this task with message `Add ranger ice shot CoC casting`.

### Task 3: Auto Combat Mode

**Files:**
- Create: `scripts/data/AutoCombatController.gd`
- Modify: `scripts/app/Game2D.gd`
- Test: `tests/regression/regression_auto_combat_controller.gd`
- Test: `tests/regression/regression_game2d_auto_combat_mode.gd`

- [ ] **Step 1: Write pure controller regression**

Create `tests/regression/regression_auto_combat_controller.gd`:

```gdscript
extends SceneTree

const AutoCombatControllerScript := preload("res://scripts/data/AutoCombatController.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var intent := AutoCombatControllerScript.build_intent(
		Vector2.ZERO,
		[{"position": Vector2(160, 0), "alive": true}],
		260.0
	)
	_expect(bool(intent.get("has_target", false)), "auto combat should find target")
	_expect(bool(intent.get("should_attack", false)), "target in range should attack")
	_expect(Vector2(intent.get("attack_direction", Vector2.ZERO)).dot(Vector2.RIGHT) > 0.9, "attack direction should face target")
	var far := AutoCombatControllerScript.build_intent(
		Vector2.ZERO,
		[{"position": Vector2(600, 0), "alive": true}],
		260.0
	)
	_expect(not bool(far.get("should_attack", true)), "far target should not attack")
	_expect(Vector2(far.get("move_vector", Vector2.ZERO)).dot(Vector2.RIGHT) > 0.9, "far target should move toward target")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_AUTO_COMBAT_CONTROLLER_OK")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Implement pure controller**

Create `scripts/data/AutoCombatController.gd`:

```gdscript
extends RefCounted
class_name AutoCombatController

static func build_intent(player_position: Vector2, enemies: Array, attack_range: float) -> Dictionary:
	var best_position := Vector2.ZERO
	var best_distance := INF
	for entry in enemies:
		var data: Dictionary = Dictionary(entry)
		if not bool(data.get("alive", true)):
			continue
		var position: Vector2 = data.get("position", Vector2.ZERO)
		var distance := player_position.distance_to(position)
		if distance < best_distance:
			best_distance = distance
			best_position = position
	if best_distance == INF:
		return {"has_target": false, "should_attack": false, "move_vector": Vector2.ZERO, "attack_direction": Vector2.RIGHT}
	var to_target := best_position - player_position
	var direction := to_target.normalized() if to_target.length_squared() > 0.001 else Vector2.RIGHT
	return {
		"has_target": true,
		"target_position": best_position,
		"target_distance": best_distance,
		"should_attack": best_distance <= attack_range,
		"move_vector": Vector2.ZERO if best_distance <= attack_range * 0.72 else direction,
		"attack_direction": direction,
	}
```

- [ ] **Step 3: Add Game2D auto mode test seam**

Modify `Game2D.gd`:

```gdscript
const AutoCombatControllerScript := preload("res://scripts/data/AutoCombatController.gd")
var combat_control_mode := "manual"

func set_combat_control_mode_for_test(mode: String) -> void:
	combat_control_mode = "auto" if mode == "auto" else "manual"

func get_combat_control_mode_for_test() -> String:
	return combat_control_mode
```

Add helper:

```gdscript
func _build_auto_enemy_snapshots() -> Array:
	var result: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			result.append({"position": (enemy as Node2D).global_position, "alive": true})
	return result
```

In `_physics_process`, use auto intent when mode is auto:

```gdscript
if combat_control_mode == "auto":
	var intent := AutoCombatControllerScript.build_intent(player.global_position, _build_auto_enemy_snapshots(), 280.0)
	player.set_move_vector(intent.get("move_vector", Vector2.ZERO))
	if bool(intent.get("should_attack", false)):
		player.face_world_position(intent.get("target_position", player.global_position + Vector2.RIGHT))
		player.cast_basic(intent.get("attack_direction", Vector2.RIGHT))
else:
	player.set_move_vector(_get_move_vector())
	player.face_world_position(get_global_mouse_position())
```

- [ ] **Step 4: Add Game2D regression**

Create `tests/regression/regression_game2d_auto_combat_mode.gd` that instantiates `Game2D`, calls `set_combat_control_mode_for_test("auto")`, waits frames, and asserts `get_combat_control_mode_for_test() == "auto"` and the player remains valid.

- [ ] **Step 5: Run tests**

Expected: `NEW_PROJECT_AUTO_COMBAT_CONTROLLER_OK` and `NEW_PROJECT_GAME2D_AUTO_COMBAT_MODE_OK`.

- [ ] **Step 6: Commit**

Commit with message `Add auto combat mode`.

### Task 4: Ranger CoC Talents And Reset

**Files:**
- Modify: `scripts/data/SkillNodeGrowthService.gd`
- Modify: `scripts/data/PlayerDataService.gd`
- Test: `tests/regression/regression_ranger_coc_skill_nodes.gd`

- [ ] **Step 1: Write talent regression**

Create a regression that builds a ranger with 6 skill points, upgrades `ranger_coc_precision`, `ranger_ice_mastery`, and `ranger_projectile_split`, verifies stat fields `critical_chance`, `cold_damage`, and `ice_lance_split` increase, then calls reset and verifies points return.

- [ ] **Step 2: Add node definitions**

Add these nodes to `SkillNodeGrowthService.NODES`:

```gdscript
"ranger_coc_precision": {"node_id": "ranger_coc_precision", "title": "CoC Precision", "stat_id": "critical_chance", "stat_label": "Crit", "stat_gain": 3, "max_level": 5, "skill_point_cost": 1, "class_tag": "ranger"},
"ranger_trigger_flow": {"node_id": "ranger_trigger_flow", "title": "Trigger Flow", "stat_id": "coc_cooldown_recovery", "stat_label": "Trigger Recovery", "stat_gain": 4, "max_level": 3, "skill_point_cost": 1, "class_tag": "ranger"},
"ranger_ice_mastery": {"node_id": "ranger_ice_mastery", "title": "Ice Mastery", "stat_id": "cold_damage", "stat_label": "Cold Damage", "stat_gain": 5, "max_level": 5, "skill_point_cost": 1, "class_tag": "ranger"},
"ranger_projectile_split": {"node_id": "ranger_projectile_split", "title": "Split Lance", "stat_id": "ice_lance_split", "stat_label": "Ice Lance Split", "stat_gain": 1, "max_level": 1, "skill_point_cost": 2, "class_tag": "ranger"},
```

- [ ] **Step 3: Normalize new stats**

Add defaults in `_normalize_growth_data`: `cold_damage`, `coc_cooldown_recovery`, `ice_lance_split`.

- [ ] **Step 4: Add reset function**

Add:

```gdscript
static func reset_skill_nodes(player_data: Dictionary) -> Dictionary:
	var result := _normalize_growth_data(player_data)
	var refunded := 0
	var nodes: Dictionary = Dictionary(result.get("unlocked_skill_nodes", {}))
	for node_id in nodes.keys():
		var node := get_node(str(node_id))
		refunded += int(nodes[node_id]) * int(node.get("skill_point_cost", 1))
	result["unlocked_skill_nodes"] = {}
	result["skill_points"] = int(result.get("skill_points", 0)) + refunded
	return {"ok": true, "refunded_skill_points": refunded, "player_data": result}
```

- [ ] **Step 5: Run test**

Expected: `NEW_PROJECT_RANGER_COC_SKILL_NODES_OK`.

- [ ] **Step 6: Commit**

Commit with message `Add ranger CoC skill nodes`.

### Task 5: Equipment And Gem Modifiers

**Files:**
- Create: `scripts/data/GemSocketService.gd`
- Modify: `scripts/data/EquipmentDataService.gd`
- Modify: `scripts/rules/EquipmentAffixRules.gd`
- Test: `tests/regression/regression_gem_socket_service.gd`
- Test: `tests/regression/regression_ranger_coc_equipment_stats.gd`

- [ ] **Step 1: Write gem service regression**

Test weapon sockets accept `frost_gem` and `pierce_gem`, reject duplicate `pierce_gem`, remove gems without deleting item id, and aggregate `cold_damage` and `ice_lance_pierce`.

- [ ] **Step 2: Implement `GemSocketService.gd`**

Create service with:

```gdscript
const GEM_DEFS := {
	"frost_gem": {"name": "寒霜宝石", "stats": {"cold_damage": 6}, "mechanic": false},
	"precision_gem": {"name": "精准宝石", "stats": {"critical_chance": 2}, "mechanic": false},
	"haste_gem": {"name": "迅捷宝石", "stats": {"attack_speed": 4}, "mechanic": false},
	"pierce_gem": {"name": "穿透宝石", "stats": {"ice_lance_pierce": 1}, "mechanic": true},
	"split_gem": {"name": "分裂宝石", "stats": {"ice_lance_split": 1}, "mechanic": true},
}
```

Expose `get_socket_limit(slot)`, `socket_gem(equipment, gem_id)`, `remove_gem(equipment, gem_id)`, and `build_socket_stat_totals(equipment)`.

- [ ] **Step 3: Add equipment total aggregation**

Preload `GemSocketService` in `EquipmentDataService.gd` and add totals keys:

```gdscript
"cold_damage": 0,
"attack_speed": 0,
"coc_cooldown_recovery": 0,
"ice_lance_pierce": 0,
"ice_lance_split": 0,
```

When iterating equipped equipment, also merge:

```gdscript
var socket_totals := GemSocketServiceScript.build_socket_stat_totals(equipment)
for stat_id in socket_totals.keys():
	totals[stat_id] = int(totals.get(stat_id, 0)) + int(socket_totals[stat_id])
```

- [ ] **Step 4: Add ranger CoC drops**

Update ranger weapon drops in `EquipmentAffixRules.gd` to occasionally include `critical_chance`, `cold_damage`, `attack_speed`, `coc_cooldown_recovery`, `ice_lance_pierce`.

- [ ] **Step 5: Run tests**

Expected: `NEW_PROJECT_GEM_SOCKET_SERVICE_OK` and `NEW_PROJECT_RANGER_COC_EQUIPMENT_STATS_OK`.

- [ ] **Step 6: Commit**

Commit with message `Add ranger CoC equipment and gems`.

### Task 6: UI Explanation Hooks

**Files:**
- Modify: `scripts/data/EquipmentCompareSummaryService.gd`
- Modify: `scripts/data/EquipmentRecommendationService.gd`
- Modify: `scripts/ui/InventoryEquipmentWindow.gd`
- Test: `tests/regression/regression_ranger_coc_compare_reasons.gd`

- [ ] **Step 1: Write explanation regression**

Build a ranger, add an item with `critical_chance`, `cold_damage`, and `ice_lance_pierce`, call compare summary, and assert reasons contain:

```text
更频繁触发冰矛
增强寒冰射击和冰矛
冰矛穿透
```

- [ ] **Step 2: Add reason mapping**

In compare/recommendation services, map stat ids:

```gdscript
var RANGER_COC_REASON_TEXT := {
	"critical_chance": "更频繁触发冰矛",
	"attack_speed": "更多寒冰射击尝试，但仍受触发冷却限制",
	"cold_damage": "增强寒冰射击和冰矛",
	"ice_lance_pierce": "冰矛穿透，清理密集敌人更强",
	"coc_cooldown_recovery": "允许更高频率触发冰矛",
}
```

- [ ] **Step 3: Display compact reasons**

Append these reason strings to item detail text in `InventoryEquipmentWindow.describe_item_for_test` path and the visible details label.

- [ ] **Step 4: Run tests**

Expected: `NEW_PROJECT_RANGER_COC_COMPARE_REASONS_OK`.

- [ ] **Step 5: Commit**

Commit with message `Explain ranger CoC equipment reasons`.

### Task 7: Focused Integration And Regression Gate

**Files:**
- Modify: `docs/progress/2026-06-11-ranger-coc-ice-build-progress.md`
- Test: all new focused tests and existing impacted tests

- [ ] **Step 1: Run focused new tests**

Run:

```powershell
$tests = @(
  'res://tests/regression/regression_ranger_coc_trigger_service.gd',
  'res://tests/regression/regression_ranger_coc_player_cast.gd',
  'res://tests/regression/regression_auto_combat_controller.gd',
  'res://tests/regression/regression_game2d_auto_combat_mode.gd',
  'res://tests/regression/regression_ranger_coc_skill_nodes.gd',
  'res://tests/regression/regression_gem_socket_service.gd',
  'res://tests/regression/regression_ranger_coc_equipment_stats.gd',
  'res://tests/regression/regression_ranger_coc_compare_reasons.gd'
)
foreach ($test in $tests) {
  & $godot --headless --path $project --script $test
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
Write-Host 'FOCUSED_RANGER_COC_ICE_BUILD_OK'
```

- [ ] **Step 2: Run impacted existing tests**

Run:

```powershell
$tests = @(
  'res://tests/regression/regression_character_create.gd',
  'res://tests/regression/regression_skill_node_growth_service.gd',
  'res://tests/regression/regression_skill_point_basic_attack_upgrade.gd',
  'res://tests/regression/regression_equipment_score_service.gd',
  'res://tests/regression/regression_equipment_compare_summary_service.gd',
  'res://tests/regression/regression_inventory_item_schema.gd',
  'res://tests/regression/regression_inventory_equipment_actions.gd',
  'res://tests/regression/regression_game2d_input_contract.gd',
  'res://tests/regression/regression_game2d_floor_template_spawn.gd',
  'res://tests/regression/regression_scene_boot.gd'
)
foreach ($test in $tests) {
  & $godot --headless --path $project --script $test
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
Write-Host 'IMPACTED_RANGER_COC_REGRESSION_OK'
```

- [ ] **Step 3: Write progress note**

Create `docs/progress/2026-06-11-ranger-coc-ice-build-progress.md` with:

```markdown
# 游侠寒冰 CoC 构筑进度

日期：2026-06-11

## 完成

- 新增寒冰射击与冰矛技能定义。
- 新增 CoC 触发服务，包含 0.30 秒触发冷却和防循环规则。
- 游侠基础攻击切换为寒冰射击。
- 新增挂机模式最小自动索敌、移动和攻击。
- 新增游侠 CoC 天赋节点和重置入口。
- 新增宝石孔、宝石镶嵌/取下和加成聚合。
- 装备对比新增游侠 CoC 解释文本。

## 验证

- FOCUSED_RANGER_COC_ICE_BUILD_OK
- IMPACTED_RANGER_COC_REGRESSION_OK

## 后续

- 补正式弹道视觉和冰矛特效。
- 扩展挂机策略：危险规避、拾取过滤、Boss 接管提示。
- 做 10 分钟手动/挂机混合刷图验收。
```

- [ ] **Step 4: Commit**

Commit with message `Document ranger CoC ice build progress`.

---

## Self-Review Notes

- Spec coverage: covered skills, trigger cooldown, no trigger loops, auto/manual shared rules, talents, equipment, gems, explanation hooks, and focused verification.
- Scope kept to first playable slice; complex PoE attack-speed breakpoints, socket colors, links, trigger chains, and advanced strategy editor remain out of scope.
- Type consistency: new stat ids are `cold_damage`, `attack_speed`, `coc_cooldown_recovery`, `ice_lance_pierce`, and `ice_lance_split`; these names must stay consistent across tasks.

