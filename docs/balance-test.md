# Jade Bow Arrow Balance Test Log

用途：記錄 3 到 5 分鐘完整流程的平衡測試結果，幫助調整關卡、升級、Boss 與操作手感。

## Test Setup

- Build: `Godot iOS debug export`
- Device: `iPhone model / simulator`
- Start room: `Constants.DEBUG_START_ROOM = 1`
- Target session length: `3:00 - 5:00`
- Goal: `Clear room 8 boss`

## Target Ranges

| Metric | Target | Notes |
| --- | ---: | --- |
| Room 1 clear | 0:20 - 0:35 | 新手暖身，不應有死亡壓力 |
| Room 2 clear | 0:40 - 0:55 | 第一次感受到遠程怪 |
| Room 3 clear | 1:05 - 1:25 | 開始需要走位 |
| Room 4 clear | 1:35 - 2:00 | runner 加入，壓力提升 |
| Room 5 clear | 2:05 - 2:35 | brute 加入，檢查輸出是否足夠 |
| Room 6 clear | 2:45 - 3:25 | 三波戰鬥，檢查升級強度 |
| Room 7 clear | 3:25 - 4:10 | Boss 前壓力測試 |
| Boss kill | 4:00 - 5:00 | Boss 不應秒殺，也不應拖太久 |

## Run Log

After each run, copy the Godot/Xcode console line that starts with `[Balance]` into the notes column.

| Run | Date | Build | Device | Result | Death Room | Death Cause | Boss Kill Time | Total Time | Upgrade Combo | Notes |
| --- | --- | --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| 001 | YYYY-MM-DD | debug | iPhone | Win/Lose | - | - | - | - | - | - |
| 002 | YYYY-MM-DD | debug | iPhone | Win/Lose | - | - | - | - | - | - |
| 003 | YYYY-MM-DD | debug | iPhone | Win/Lose | - | - | - | - | - | - |

## Room Timing

| Run | R1 | R2 | R3 | R4 | R5 | R6 | R7 | Boss Start | Boss Kill | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 001 | - | - | - | - | - | - | - | - | - | - |
| 002 | - | - | - | - | - | - | - | - | - | - |
| 003 | - | - | - | - | - | - | - | - | - | - |

## Upgrade Tracking

| Run | Lv.2 | Lv.3 | Lv.4 | Lv.5 | Lv.6+ | Strongest Upgrade | Weakest Upgrade |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 001 | - | - | - | - | - | - | - |
| 002 | - | - | - | - | - | - | - |
| 003 | - | - | - | - | - | - | - |

## Balance Notes

### Too Easy Signals

- Boss dies before `4:00`.
- Player HP rarely drops below 50%.
- `Twin Arrow + Ricochet` clears rooms without meaningful movement.
- Lifesteal offsets most incoming damage.

### Too Hard Signals

- Deaths happen before room 4 with normal movement.
- Boss fight lasts over `1:15`.
- Player cannot kill brutes before being surrounded.
- Spitter/boss projectiles leave no usable dodge path on phone.

## Change Log

| Date | Change | Expected Effect | Result |
| --- | --- | --- | --- |
| YYYY-MM-DD | Example: lower Boss HP by 10% | Faster Boss kill | Pending |
