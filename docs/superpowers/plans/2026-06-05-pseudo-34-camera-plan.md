# Pseudo 3/4 Camera Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将战斗场景第一版改成伪 3/4 俯视观感，同时保持纯 2D 移动、攻击、碰撞、拾取和存档逻辑不变。

**Architecture:** 伪 3/4 只作为表现层实现。`Game2D.gd` 负责镜头和房间视觉；`Player2D.gd`、`Enemy2D.gd` 负责角色/敌人的程序化外观比例、脚底阴影和朝向提示。现有数据服务和保存系统不参与本轮改造。

**Tech Stack:** Godot 4.6.2、GDScript、headless regression scripts。

---

### Task 1: 伪 3/4 视觉契约测试

**Files:**
- Create: `tests/regression/regression_pseudo_34_visual_contract.gd`
- Modify: none

- [ ] **Step 1: Write the failing test**

测试应实例化 `Game2D.tscn` 并断言：
- `Game2D` 暴露 `_get_visual_style_for_test()`
- 返回 `camera_zoom`、`room_visual_mode`、`logic_room_rect`
- 场景内存在 `Pseudo34Floor`
- 玩家存在 `PlayerShadow` 和 `PlayerFacingHint`
- 敌人存在 `EnemyShadow`

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
& $godot --headless --path $project --script 'res://tests/regression/regression_pseudo_34_visual_contract.gd'
```

Expected: fails because the visual contract method and new nodes do not exist yet.

### Task 2: Game2D 房间与镜头表现

**Files:**
- Modify: `scripts/app/Game2D.gd`

- [ ] **Step 1: Implement minimal code**

Add constants for pseudo 3/4 visual mode, camera zoom, and floor skew amount. Replace the current rectangular `DungeonFloor` visual with a `Node2D` named `Pseudo34Floor` containing:
- a skewed `Polygon2D` floor
- compressed tile grid lines
- thick border lines
- several rectangular obstacle visuals

Keep `room_rect` and movement clamp unchanged.

- [ ] **Step 2: Run visual contract test**

Expected: still fails until player/enemy visual nodes are added.

### Task 3: Player/Enemy 程序化外观

**Files:**
- Modify: `scripts/combat/Player2D.gd`
- Modify: `scripts/combat/Enemy2D.gd`

- [ ] **Step 1: Implement minimal code**

For player:
- Add `PlayerShadow` below body.
- Replace pure arrow-like body with taller polygon.
- Add `PlayerFacingHint` at the front.

For enemy:
- Add `EnemyShadow` below body.
- Replace body polygon with taller rounded-ish faceted body.
- Preserve health bar and nameplate behavior.

- [ ] **Step 2: Run visual contract test**

Expected: `NEW_PROJECT_PSEUDO_34_VISUAL_CONTRACT_OK`.

### Task 4: Full Verification And Progress Doc

**Files:**
- Create: `docs/progress/2026-06-05-pseudo-34-camera-progress.md`

- [ ] **Step 1: Run full regression**

Expected: `ALL_NEW_PROJECT_REGRESSION_OK`.

- [ ] **Step 2: Run headless scene startup**

Expected: `HEADLESS_EXIT 0` and no residual Godot test process listed.

- [ ] **Step 3: Write Chinese progress doc**

Document changed files, verification output, and unchanged boundaries:
- no save clearing
- no save schema changes
- no 3D/POLYGON restoration
