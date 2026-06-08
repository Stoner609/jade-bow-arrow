extends RefCounted

static func choices() -> Array[Dictionary]:
	return [
		{"name": "Power Shot", "desc": "+4 damage", "stat": "power"},
		{"name": "Quick Draw", "desc": "faster auto-fire", "stat": "speed"},
		{"name": "Vitality", "desc": "+18 max HP", "stat": "hp"},
		{"name": "Twin Arrow", "desc": "+1 arrow", "stat": "arrows"},
		{"name": "Piercing", "desc": "arrows pass through 1 enemy", "stat": "pierce"},
		{"name": "Ricochet", "desc": "first hit bounces", "stat": "ricochet"}
	]
