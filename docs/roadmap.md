# Jade Bow Arrow Roadmap

This file tracks the current short-term and mid-term plans so they stay visible between implementation sessions.

## Current Status

- Boss battle tuning is temporarily frozen.
- Phase 2 / Phase 3 warnings, sweep bullets, dash warning, and weighted Boss attack selection are acceptable on device for now.
- Next focus is the full mobile prototype flow before adding more Boss complexity.

## Short-Term Plan

- Run a full room 1 to room 8 device test and confirm there are no blockers in room flow, UI bounds, start, pause, restart, death, and victory screens.
- Reset `DEBUG_START_ROOM` back to the normal run flow when Boss-only testing is no longer needed.
- Do one light gameplay feel pass for player movement, auto-fire cadence, enemy movement speed, and upgrade frequency.
- Record the current Boss state as temporarily accepted so Boss tuning does not keep changing without new device feedback.
- Keep exporting iOS debug builds after gameplay-affecting changes so device testing stays aligned with the project.

## Mid-Term Plan

- Data-drive regular enemy AI values for `crawler`, `runner`, `spitter`, and `brute`.
- Improve room 1 to room 7 pacing so the pre-Boss flow has clearer difficulty growth.
- Add more room variation through obstacle layouts, enemy combinations, wave data, and room prompt text.
- Add basic sound effects for shooting, hits, player damage, pickups, upgrades, room clear, Boss phase changes, and victory/death.
- Review upgrade balance again after a full device playthrough, especially damage stacking, healing, critical hits, movement speed, and Boss damage bonus.

## Later Notes

- Replace prototype shapes with proper art assets.
- Improve main menu, settings, tutorial, pause, result, and upgrade UI presentation.
- Prepare iOS TestFlight requirements: icon, splash, versioning, privacy information, screenshots, and App Store metadata.
- Plan a second Boss or second chapter after the current 3 to 5 minute loop is stable.

## 中文計劃

這份文件用來保存目前短期與中期計劃，避免每次對話後忘記下一步。

### 目前狀態

- 真機完整測試第 1 房到第 8 房，確認房間流程、UI 邊界、開始、暫停、重新開始、死亡、通關畫面沒有阻塞問題。
- 記錄目前 Boss 狀態為暫時接受，避免沒有新真機回饋時一直反覆調 Boss。
- 只要有影響玩法的修改，就維持匯出 iOS debug build，讓真機測試版本跟專案同步。

### 短期計劃

- 做一輪輕量手感調整：玩家移動、自動射擊節奏、敵人移動速度、升級出現頻率。
- 將一般敵人 `crawler`、`runner`、`spitter`、`brute` 的 AI 數值資料化。

### 中期計劃

- 改善第 1 房到第 7 房節奏，讓 Boss 前的流程有更明確的難度成長。
- 增加房間變化：障礙 layout、敵人組合、wave 資料、房間提示文字。
- 新增基本音效：射擊、命中、玩家受傷、拾取、升級、房間清空、Boss 階段切換、勝利與死亡。
- 完整真機流程測過後，再檢查升級平衡，特別是傷害疊加、回血、暴擊、移動速度、Boss 傷害加成。

### 後續備註

- 用正式美術替換目前原型幾何圖形。
- 改善主選單、設定、教學、暫停、結算、升級 UI。
- 準備 iOS TestFlight 需求：icon、啟動畫面、版本號、隱私資訊、截圖、App Store 文字。
- 等目前 3 到 5 分鐘循環穩定後，再規劃第二隻 Boss 或第二章節。
