# Pixel Actor Art Trial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a safe art-only trial where player, rot melee, and shadow archer can move toward dark high-resolution pixel actors while painterly tower environments stay intact.

**Architecture:** Keep gameplay scripts consuming the existing visual manifest interface. Add art metadata and runtime texture filtering so future sprite sheets can be swapped without touching combat, floor, inventory, or save logic.

**Tech Stack:** Godot 4.6.2, GDScript, existing IMAGE2 actor manifest pipeline, regression scripts under `tests/regression`.

---

### Task 1: Lock Pixel Actor Trial Contract

**Files:**
- Create: `tests/regression/regression_pixel_actor_art_trial_contract.gd`

- [x] **Step 1: Write the failing regression**

The test instantiates `Game2D`, reads the default player art contract, and checks `FloorRules` manifests for `rot_melee` and `shadow_archer`.

- [x] **Step 2: Run the regression and confirm failure**

Run:
```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_pixel_actor_art_trial_contract.gd'
```

Expected before implementation: failure because the current manifests do not declare pixel art family, nearest filtering, 4dir target, or contact shadow contract.

### Task 2: Add Manifest Metadata and Runtime Filtering

**Files:**
- Modify: `scripts/app/Game2D.gd`
- Modify: `scripts/rules/FloorRules.gd`
- Modify: `scripts/combat/Player2D.gd`
- Modify: `scripts/combat/Enemy2D.gd`

- [x] **Step 1: Add pixel actor metadata to the player manifest**

Player manifest fields:
```gdscript
"art_family": "dark_high_res_pixel_actor",
"environment_pairing": "painterly_brutalist_tower",
"texture_filter": "nearest",
"directional_target": "4dir",
"separate_combat_vfx": true,
"contact_shadow": {
	"required": true,
	"style": "soft_grounded_cold_ambient",
},
```

- [x] **Step 2: Add the same metadata to rot melee and shadow archer**

Only the first two enemy archetypes are included in this trial. Boss and guardian manifests remain unchanged until the style is approved in play.

- [x] **Step 3: Apply nearest filtering in actor runtime**

`Player2D` and `Enemy2D` read `texture_filter` from the manifest and set `ActorSprite.texture_filter` to `CanvasItem.TEXTURE_FILTER_NEAREST`.

### Task 3: Document Collaboration and Acceptance

**Files:**
- Create: `docs/content/2026-06-11-pixel-actor-art-trial-pipeline.md`
- Create: `docs/progress/2026-06-11-pixel-actor-art-trial-progress.md`
- Modify: `README.md`

- [x] **Step 1: Write the art pipeline note**

The note defines the split: painterly environments, dark high-resolution pixel actors, separate VFX, and future 4-direction sheet targets.

- [x] **Step 2: Write progress note**

The note records what changed and which tests should be used for the next handoff.

- [x] **Step 3: Update README**

README receives a short update that the pixel actor trial is now a formal asset pipeline branch.

### Task 4: Verify

**Files:**
- Test: `tests/regression/regression_pixel_actor_art_trial_contract.gd`
- Test: `tests/regression/regression_default_image2_player_art_contract.gd`
- Test: `tests/regression/regression_rot_melee_image2_manifest.gd`
- Test: `tests/regression/regression_shadow_archer_image2_manifest.gd`
- Test: `tests/regression/regression_actor_directional_manifest_contract.gd`

- [ ] **Step 1: Run focused art contract regressions**

Run the five tests listed above with the Godot console.

- [ ] **Step 2: Run scene boot smoke if focused tests pass**

Run:
```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_scene_boot.gd'
```

Expected: scene boot exits with code 0.
