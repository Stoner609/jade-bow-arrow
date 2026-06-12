extends RefCounted

const PHASE_TWO_RATIO := 0.7
const PHASE_THREE_RATIO := 0.4

const PHASE_ONE_SPREAD_COUNT := 3
const PHASE_ONE_SPREAD_ANGLE := 0.28
const PHASE_ONE_COOLDOWN_MIN := 1.15
const PHASE_ONE_COOLDOWN_MAX := 1.55

const PHASE_TWO_SPREAD_COUNT := 3
const PHASE_TWO_SPREAD_ANGLE := 0.36
const PHASE_TWO_SWEEP_COUNT := 3
const PHASE_TWO_SWEEP_ANGLE := 0.18
const PHASE_TWO_SWEEP_WARNING := 0.36
const PHASE_TWO_SWEEP_SPEED_SCALE := 1.14
const PHASE_TWO_COOLDOWN_MIN := 0.98
const PHASE_TWO_COOLDOWN_MAX := 1.3

const PHASE_THREE_SPREAD_COUNT := 5
const PHASE_THREE_SPREAD_ANGLE := 0.46
const PHASE_THREE_SWEEP_COUNT := 5
const PHASE_THREE_SWEEP_ANGLE := 0.18
const PHASE_THREE_SWEEP_WARNING := 0.36
const PHASE_THREE_SWEEP_SPEED_SCALE := 1.16
const PHASE_THREE_DELAYED_COUNT := 5
const PHASE_THREE_DELAYED_ANGLE := 0.34
const PHASE_THREE_DELAYED_SPEED_SCALE := 0.58
const PHASE_THREE_DELAYED_LIFE := 4.2
const PHASE_THREE_DASH_DISTANCE := 82.0
const PHASE_THREE_DASH_WARNING := 0.68
const PHASE_THREE_COOLDOWN_MIN := 0.82
const PHASE_THREE_COOLDOWN_MAX := 1.08

const BULLET_NORMAL := {
	"style": "normal",
	"speed_scale": 1.0,
	"damage_scale": 1.0,
	"radius": 7.0,
	"visual_radius": 7.0,
	"glow_color": Color(1.0, 0.18, 0.82, 0.18),
	"core_color": Color(1.0, 0.16, 0.78),
	"highlight_color": Color(1.0, 0.76, 1.0)
}

const BULLET_SWEEP := {
	"style": "sweep",
	"speed_scale": 1.0,
	"damage_scale": 0.92,
	"radius": 7.0,
	"visual_radius": 7.0,
	"glow_color": Color(1.0, 0.62, 0.16, 0.22),
	"core_color": Color(1.0, 0.52, 0.08),
	"highlight_color": Color(1.0, 0.94, 0.48)
}

const BULLET_DELAYED := {
	"style": "delayed",
	"speed_scale": 1.0,
	"damage_scale": 1.08,
	"radius": 8.0,
	"visual_radius": 8.0,
	"glow_color": Color(0.24, 0.86, 1.0, 0.24),
	"core_color": Color(0.14, 0.72, 1.0),
	"highlight_color": Color(0.78, 1.0, 1.0)
}
