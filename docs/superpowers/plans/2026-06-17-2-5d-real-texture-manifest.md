# 2.5D Real Texture Manifest V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将已有 IMAGE2 production 角色贴图通过 Manifest V1 接入 2.5D billboard 战斗原型，替换运行时占位素材链路。

**Architecture:** 新增一个小型 Manifest 库，集中声明玩家、腐化近战敌人、暗影弓手的贴图路径、帧尺寸、动作区间和素材管线元数据。`BillboardActor3D` 只消费标准 Manifest，不直接知道素材常量；`Prototype2_5DCombatRoom` 只负责给玩家和敌人分配对应 Manifest。

**Tech Stack:** Godot 4.6.2, GDScript, Sprite3D billboard, headless regression scripts.

---

### Task 1: Manifest 库与 Actor 加载测试

**Files:**
- Create: `scripts/prototype/BillboardActorManifestLibrary.gd`
- Modify: `scripts/prototype/BillboardActor3D.gd`
- Modify: `scripts/prototype/BillboardActorAnimationProfile.gd`
- Test: `tests/regression/regression_billboard_actor_real_texture_manifest.gd`

- [ ] **Step 1: Write the failing test**

新增测试，断言玩家、近战敌人、弓手敌人的 Manifest 使用 `image2`、`production_dark_armor_v3`、`runtime_flip_2dir`，并且 `BillboardActor3D` 加载贴图后 `Sprite3D.texture` 非空、region 尺寸等于帧尺寸。

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& $godot --headless --path $project --script res://tests/regression/regression_billboard_actor_real_texture_manifest.gd
```

Expected: FAIL because `BillboardActorManifestLibrary.gd` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

新增 `BillboardActorManifestLibrary.gd`，提供：

```gdscript
static func make_player_warrior_v3() -> Dictionary
static func make_rot_melee_v3() -> Dictionary
static func make_shadow_archer_v3() -> Dictionary
```

扩展 `BillboardActor3D.get_actor_animation_state()`，暴露贴图是否加载、Sprite 是否可见、素材管线和滤镜。扩展 `BillboardActorAnimationProfile`，让 Profile 可以输出同一份标准 Manifest。

- [ ] **Step 4: Run test to verify it passes**

Run:

```powershell
& $godot --headless --path $project --script res://tests/regression/regression_billboard_actor_real_texture_manifest.gd
```

Expected: PASS and print `NEW_PROJECT_BILLBOARD_ACTOR_REAL_TEXTURE_MANIFEST_OK`.

### Task 2: 2.5D Combat Room 接入真实贴图

**Files:**
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`
- Test: `tests/regression/regression_prototype_2_5d_real_actor_textures.gd`

- [ ] **Step 1: Write the failing test**

新增场景测试，实例化 `Prototype2_5DCombatRoom.tscn` 后断言：

```text
player -> player_warrior_sheet_v3.png, frame_size 160x160
enemy 1 -> enemy_rot_melee_sheet_v3.png, frame_size 128x128
enemy 2 -> enemy_shadow_archer_sheet_v3.png, frame_size 128x128
all actor sprites visible and texture loaded
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_real_actor_textures.gd
```

Expected: FAIL because the scene still applies `runtime_placeholder` manifests.

- [ ] **Step 3: Write minimal implementation**

在 `Prototype2_5DCombatRoom.gd` 中 preload Manifest 库。创建玩家时应用 `make_player_warrior_v3()`；创建敌人时按索引应用 `make_rot_melee_v3()` 和 `make_shadow_archer_v3()`。保留原默认占位 Manifest 作为缺省回退，不作为正常路径。

- [ ] **Step 4: Run focused verification**

Run:

```powershell
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_real_actor_textures.gd
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_animation_state_sync.gd
& $godot --headless --path $project --script res://tests/regression/regression_billboard_actor_3d_animation_player.gd
```

Expected: all PASS.

### Task 3: 文档、完整回归与提交

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-17-prototype-2-5d-real-texture-manifest-progress.md`

- [ ] **Step 1: Update progress docs**

记录本轮新增的 Manifest V1、真实贴图接入范围、验收测试和后续素材替换接口。

- [ ] **Step 2: Run full verification**

Run `git diff --check`、完整 `tests/regression/*.gd` 回归、主项目 headless 启动，并确认没有残留 Godot 测试进程。

- [ ] **Step 3: Commit and push**

Stage only touched tracked/new files, commit message:

```text
Add 2.5D real texture manifests
```

Push current branch.
