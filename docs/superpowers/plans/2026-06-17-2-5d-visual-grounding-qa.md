# 2.5D Visual Grounding QA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 2.5D billboard 角色在实机场景中更接地，并把彩色调试可读性标记改为默认隐藏、可按 QA 接口开启。

**Architecture:** `BillboardActor3D` 负责角色自身的接地阴影节点和 Manifest 参数消费；`Prototype2_5DCombatRoom` 负责场景级调试标记开关与 QA 快照；`BillboardActorManifestLibrary` 只补充阴影半径、透明度等美术接口数据。

**Tech Stack:** Godot 4.6.2, GDScript, Sprite3D billboard, MeshInstance3D contact shadow, headless regression scripts.

---

### Task 1: 视觉接地回归

**Files:**
- Create: `tests/regression/regression_prototype_2_5d_visual_grounding_contract.gd`
- Modify: `scripts/app/Prototype2_5DCombatRoom.gd`
- Modify: `scripts/prototype/BillboardActor3D.gd`
- Modify: `scripts/prototype/BillboardActorManifestLibrary.gd`

- [ ] **Step 1: Write the failing test**

新增测试，实例化 2.5D 战斗房间并断言：

```text
contact_shadow_count >= 3
visible_contact_shadow_count >= 3
actor_visible_marker_count >= 3
actor_visible_marker_visible_count == 0
debug_readability_markers_enabled == false
set_debug_readability_markers_enabled_for_test(true) 后 actor_visible_marker_visible_count >= 3
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_visual_grounding_contract.gd
```

Expected: FAIL because the scene does not yet expose visual grounding snapshot or marker toggle.

- [ ] **Step 3: Write minimal implementation**

在 `BillboardActor3D` 中新增 `ContactShadow` 子节点，使用透明扁圆柱体贴近地面；`apply_visual_asset_manifest()` 根据 `contact_shadow` 字段控制可见性、半径和透明度。`Prototype2_5DCombatRoom` 新增调试标记开关，并在 QA 快照中统计标记和阴影数量。

- [ ] **Step 4: Run focused verification**

Run:

```powershell
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_visual_grounding_contract.gd
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_visibility_contract.gd
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_visual_qa_contract.gd
& $godot --headless --path $project --script res://tests/regression/regression_prototype_2_5d_real_actor_textures.gd
```

Expected: all PASS.

### Task 2: 文档、完整回归与提交

**Files:**
- Modify: `README.md`
- Create: `docs/progress/2026-06-17-prototype-2-5d-visual-grounding-progress.md`

- [ ] **Step 1: Update docs**

记录接地阴影、调试标记默认隐藏、QA 快照字段和后续实机截图建议。

- [ ] **Step 2: Run full verification**

Run `git diff --check`、完整 regression、主项目 headless 启动，并确认没有本轮 headless 测试残留进程。

- [ ] **Step 3: Commit and push**

Stage only touched files, commit message:

```text
Add 2.5D visual grounding QA
```
