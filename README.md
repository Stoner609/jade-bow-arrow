# Jade Bow Arrow

A small portrait mobile Archero-like action roguelite prototype built in Godot 4.5.

## Play

- Tap `Start Run` to begin.
- Move by dragging in the lower touch area, or use `WASD` / arrow keys on desktop.
- Stop moving to automatically fire at the nearest enemy.
- Dodge melee enemies and purple projectiles.
- Pick up blue XP orbs and green hearts.
- Tap an upgrade card, or choose with `1`, `2`, or `3` when you level up.
- Clear each room's waves and enter the glowing gate.
- Survive through room 8 and defeat the boss to win.
- Use the pause button to resume, restart, toggle sound, or return to the start screen.
- Press `R` to restart during desktop testing.

## Mobile / iOS

The prototype is designed for portrait mobile play with a 540 x 960 reference canvas.
The playfield is centered for different phone sizes, while the surrounding background fills extra screen space.

- Primary target: iPhone portrait orientation.
- Touch movement: drag anywhere in the lower control area; the virtual joystick appears at the touch position.
- Combat: the player auto-fires when standing still.
- UI: start screen, pause menu, upgrade choices, death restart, victory restart, and sound toggle are touch-friendly.
- Current iOS workflow: export the Godot project to Xcode, then run it on a connected iPhone from Xcode.
- App Store / TestFlight are not part of the current prototype flow yet.

## Test

```sh
godot --headless --path . --script res://tests/smoke_test.gd
```

## Balance Testing

Use [docs/balance-test.md](/Users/hsuhaoche/rogue-game/docs/balance-test.md) to record 3-5 minute run timing, death points, boss kill time, and upgrade combinations.

## Roadmap

Use [docs/roadmap.md](/Users/hsuhaoche/rogue-game/docs/roadmap.md) to track the current short-term and mid-term plans.

## iOS Export

```sh
godot --headless --path . --export-debug iOS ./exports/ios/JadeBowArrow.xcodeproj
```

Open the exported Xcode project, enable automatic signing with your Apple team, select the connected iPhone, and press Run.

## 中文說明

`Jade Bow Arrow` 是一個使用 Godot 4.5 製作的手機直式動作 Roguelite 原型，玩法方向接近《弓箭傳說》：玩家移動時閃避敵人，停止移動時自動攻擊最近的敵人。

### 玩法

- 點擊 `Start Run` 開始遊戲。
- 在畫面下方操作區拖曳即可移動角色，虛擬搖桿會出現在觸碰位置。
- 停止移動時，角色會自動朝最近敵人射擊。
- 閃避近戰敵人與紫色敵方子彈。
- 拾取藍色 XP 球升級，拾取綠色愛心回血。
- 升級時可點選升級卡片，桌機測試時也可按 `1`、`2`、`3` 選擇。
- 清完房間內的敵人後，進入發光傳送門前往下一房。
- 通過第 8 房並擊敗 Boss 即可通關。
- 遊戲中可使用暫停按鈕繼續、重新開始、切換音效或回到開始畫面。

### 手機 / iOS

目前原型以 iPhone 直式遊玩為主要目標，參考畫布為 540 x 960。
不同手機尺寸會讓主要場地置中，外圍用背景延伸填滿，避免畫面比例不同時影響遊戲區域。

- 主要目標平台：iPhone 直式。
- 觸控操作：畫面下方大區域皆可拖曳移動。
- 戰鬥節奏：角色停止移動時自動射擊。
- 目前已有：開始畫面、暫停選單、升級選單、死亡重開、通關重開、音效開關。
- 目前測試方式：Godot 匯出 Xcode 專案，再用 Xcode 跑到連接的 iPhone。
- App Store / TestFlight 尚未正式接入，目前仍屬於真機測試原型階段。

### 測試

```sh
godot --headless --path . --script res://tests/smoke_test.gd
```

### 平衡測試

使用 [docs/balance-test.md](/Users/hsuhaoche/rogue-game/docs/balance-test.md) 記錄 3 到 5 分鐘流程、死亡點、Boss 擊殺時間與升級組合。

### 後續計劃

使用 [docs/roadmap.md](/Users/hsuhaoche/rogue-game/docs/roadmap.md) 追蹤目前短期與中期計劃。

### iOS 匯出

```sh
godot --headless --path . --export-debug iOS ./exports/ios/JadeBowArrow.xcodeproj
```

匯出後用 Xcode 開啟專案，啟用 `Automatically manage signing`，選擇 Apple Team，接上 iPhone 後按 Run。

## Code Structure

- `scenes/actors/`: instanced player and enemy scene nodes.
- `scenes/projectiles/`: instanced projectile scene nodes.
- `scenes/pickups/`: instanced pickup scene nodes.
- `scenes/ui/`: interactive HUD scene for status text, start, pause, upgrades, death, and win flow.
- `scripts/core/`: game controller, shared constants, and run-level state.
- `scripts/actors/`: player/enemy data helpers and visual node scripts.
- `scripts/projectiles/`: player/enemy projectile data helpers and projectile node script.
- `scripts/pickups/`: XP/healing pickup helpers and pickup node script.
- `scripts/rendering/`: combat drawing helpers for players, enemies, projectiles, gates, and boss UI.
- `scripts/rooms/`: room layout, gate, and spawn positioning helpers.
- `scripts/ui/`: HUD scene interactions, HUD text presenter, upgrade choices, and touch-control helpers.
- `scripts/utils/`: shared collision helpers.
