extends Node
# SOFAI 4H — brand theme.
# Identity: deep charcoal black, electric purple primary, cyan secondary,
# amber edge-accent. Neon glow on everything.

# ---- SOFAI 4H Palette ----
const COL_BG        := Color(0.051, 0.039, 0.082, 1.0)   # deep dark purple-black  #0D0A15
const COL_BG2       := Color(0.071, 0.055, 0.110, 1.0)   # slightly lighter surface #12091C
const COL_PANEL     := Color(0.102, 0.078, 0.161, 1.0)   # panel surface  #1A1429
const COL_PANEL_2   := Color(0.137, 0.106, 0.212, 1.0)   # raised panel   #231836
const COL_DIVIDER   := Color(0.337, 0.192, 0.620, 0.55)  # purple border glow

# Brand primaries
const COL_PURPLE    := Color(0.569, 0.251, 1.000, 1.0)   # electric purple  #9140FF
const COL_PURPLE_2  := Color(0.675, 0.380, 1.000, 1.0)   # lighter purple   #AC61FF
const COL_PURPLE_DK := Color(0.345, 0.129, 0.671, 1.0)   # dark purple      #5821AB
const COL_CYAN      := Color(0.000, 0.831, 1.000, 1.0)   # electric cyan    #00D4FF
const COL_CYAN_DK   := Color(0.000, 0.580, 0.780, 1.0)   # deep cyan        #0094C7
const COL_AMBER     := Color(1.000, 0.722, 0.188, 1.0)   # amber accent     #FFB830
const COL_AMBER_DK  := Color(0.800, 0.510, 0.059, 1.0)   # dark amber       #CC820F

# Status colors
const COL_GREEN     := Color(0.180, 0.898, 0.510, 1.0)   # health green
const COL_RED       := Color(1.000, 0.231, 0.286, 1.0)   # danger red
const COL_GOLD      := COL_AMBER                         # coins = amber
const COL_DIAMOND   := COL_CYAN                          # diamonds = cyan

# Text
const COL_TEXT      := Color(0.941, 0.918, 1.000, 1.0)   # near-white with purple tint
const COL_TEXT_DIM  := Color(0.549, 0.498, 0.690, 1.0)   # muted purple-grey
const COL_DARK      := Color(0.027, 0.020, 0.047, 1.0)   # near-black

# Legacy aliases so battle_map / lobby references keep working
const COL_ACCENT    := COL_PURPLE
const COL_ACCENT_2  := COL_PURPLE_2

var theme: Theme

func _ready() -> void:
	theme = _build_theme()

# ---- StyleBox helpers ----
static func _flat(bg: Color, border: Color = Color(0,0,0,0), bw: int = 0,
		radius: int = 0, cm := Vector2.ZERO) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	if cm != Vector2.ZERO:
		sb.set_content_margin_all(cm.x)
		sb.content_margin_top = cm.y
		sb.content_margin_bottom = cm.y
	return sb

func _build_theme() -> Theme:
	var t := Theme.new()

	# Labels
	t.set_color("font_color", "Label", COL_TEXT)
	t.set_color("font_color", "Button", COL_TEXT)
	t.set_color("font_color", "LineEdit", COL_TEXT)
	t.set_color("font_color", "ProgressBar", Color(1,1,1,0.0))
	t.set_font_size("font_size", "Label", 16)
	t.set_font_size("font_size", "Button", 18)
	t.set_font_size("font_size", "LineEdit", 18)
	t.set_color("font_hover_color", "Button", Color(1,1,1,1))
	t.set_color("font_pressed_color", "Button", Color(1,1,1,1))
	t.set_color("font_disabled_color", "Button", COL_TEXT_DIM)

	# Primary button — electric purple with neon glow shadow
	var normal := _flat(COL_PURPLE, COL_DIVIDER, 1, 10, Vector2(18, 10))
	normal.shadow_color = Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.55)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0, 3)
	var hover := _flat(COL_PURPLE_2, COL_PURPLE, 2, 10, Vector2(18, 10))
	hover.shadow_color = Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.75)
	hover.shadow_size = 10
	hover.shadow_offset = Vector2(0, 3)
	var pressed := _flat(COL_PURPLE_DK, COL_PURPLE, 2, 10, Vector2(18, 10))
	var disabled := _flat(COL_PANEL_2, COL_DIVIDER, 1, 10, Vector2(18, 10))
	t.set_stylebox("normal",   "Button", normal)
	t.set_stylebox("hover",    "Button", hover)
	t.set_stylebox("pressed",  "Button", pressed)
	t.set_stylebox("focus",    "Button", _flat(Color(0,0,0,0), COL_CYAN, 2, 10))
	t.set_stylebox("disabled", "Button", disabled)

	# Panels
	var panel := _flat(COL_PANEL, COL_DIVIDER, 1, 12)
	panel.set_content_margin_all(14)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", _flat(COL_PANEL, COL_DIVIDER, 1, 12))

	# ProgressBar — purple fill
	t.set_stylebox("background", "ProgressBar", _flat(COL_DARK, COL_DIVIDER, 1, 6, Vector2(2,2)))
	t.set_stylebox("fill",       "ProgressBar", _flat(COL_PURPLE, Color(0,0,0,0), 0, 6, Vector2(2,2)))

	# LineEdit
	t.set_stylebox("normal",    "LineEdit", _flat(COL_DARK, COL_DIVIDER, 1, 8, Vector2(12,8)))
	t.set_stylebox("focus",     "LineEdit", _flat(COL_DARK, COL_PURPLE, 2, 8, Vector2(12,8)))
	t.set_stylebox("read_only", "LineEdit", _flat(COL_PANEL_2, COL_DIVIDER, 1, 8, Vector2(12,8)))
	t.set_color("font_color",          "LineEdit", COL_TEXT)
	t.set_color("font_selected_color", "LineEdit", COL_DARK)
	t.set_color("selection_color",     "LineEdit", COL_PURPLE)
	t.set_color("caret_color",         "LineEdit", COL_CYAN)

	# Scrollbar
	t.set_stylebox("scroll",             "VScrollBar", _flat(Color(0,0,0,0)))
	t.set_stylebox("grabber",            "VScrollBar", _flat(COL_PANEL_2, Color(0,0,0,0), 0, 6, Vector2(4,4)))
	t.set_stylebox("grabber_highlight",  "VScrollBar", _flat(COL_PURPLE, Color(0,0,0,0), 0, 6, Vector2(4,4)))

	# Container spacing
	t.set_constant("separation", "HBoxContainer", 10)
	t.set_constant("separation", "VBoxContainer", 10)

	return t

# ---- Per-widget helpers used by lobby / battle ----

# Ghost / secondary button — dark background, purple border on hover
func ghost_button(b: Button) -> Button:
	var sb  := _flat(Color(0.102, 0.078, 0.161, 0.88), COL_DIVIDER, 1, 10, Vector2(16,9))
	var sbh := _flat(Color(0.137, 0.106, 0.212, 0.95), COL_PURPLE, 2, 10, Vector2(16,9))
	sbh.shadow_color = Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.4)
	sbh.shadow_size = 6
	var sbp := _flat(Color(0.071, 0.055, 0.110, 0.95), COL_PURPLE_DK, 2, 10, Vector2(16,9))
	b.add_theme_stylebox_override("normal",  sb)
	b.add_theme_stylebox_override("hover",   sbh)
	b.add_theme_stylebox_override("pressed", sbp)
	b.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), COL_CYAN, 2, 10))
	return b

# Amber / gold button — for special calls-to-action (store, loot)
func amber_button(b: Button) -> Button:
	var sb := _flat(COL_AMBER, Color(0,0,0,0.3), 0, 10, Vector2(18,10))
	sb.shadow_color = Color(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 0.45)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(0, 3)
	b.add_theme_stylebox_override("normal",  sb)
	b.add_theme_stylebox_override("hover",   _flat(Color(1.0, 0.82, 0.35), Color(0,0,0,0.3), 0, 10, Vector2(18,10)))
	b.add_theme_stylebox_override("pressed", _flat(COL_AMBER_DK, Color(0,0,0,0.3), 0, 10, Vector2(18,10)))
	b.add_theme_color_override("font_color",         Color(0.08, 0.05, 0.02))
	b.add_theme_color_override("font_hover_color",   Color(0.08, 0.05, 0.02))
	b.add_theme_color_override("font_pressed_color", Color(0.08, 0.05, 0.02))
	return b

# Cyan / diamond button
func cyan_button(b: Button) -> Button:
	var sb := _flat(COL_CYAN, Color(0,0,0,0.3), 0, 10, Vector2(18,10))
	sb.shadow_color = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.45)
	sb.shadow_size = 7
	b.add_theme_stylebox_override("normal",  sb)
	b.add_theme_stylebox_override("hover",   _flat(Color(0.4, 0.95, 1.0), Color(0,0,0,0.3), 0, 10, Vector2(18,10)))
	b.add_theme_stylebox_override("pressed", _flat(COL_CYAN_DK, Color(0,0,0,0.3), 0, 10, Vector2(18,10)))
	b.add_theme_color_override("font_color",         Color(0.0, 0.1, 0.18))
	b.add_theme_color_override("font_hover_color",   Color(0.0, 0.1, 0.18))
	b.add_theme_color_override("font_pressed_color", Color(0.0, 0.1, 0.18))
	return b

# Dark card surface with purple neon glow
func card_stylebox(radius: int = 12, alpha: float = 0.88) -> StyleBoxFlat:
	var sb := _flat(Color(COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, alpha), COL_DIVIDER, 1, radius)
	sb.shadow_color = Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.28)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	return sb

func panel_stylebox(radius: int = 12, alpha: float = 1.0) -> StyleBoxFlat:
	var sb := _flat(Color(COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, alpha), COL_DIVIDER, 1, radius)
	sb.shadow_color = Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.35)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 5)
	return sb

# Neon glow health bar fill (cyan for armor, green for HP, purple for XP)
func health_bar_fill(color: Color) -> StyleBoxFlat:
	var sb := _flat(color, Color(0,0,0,0), 0, 5)
	sb.shadow_color = Color(color.r, color.g, color.b, 0.6)
	sb.shadow_size = 5
	return sb

func bar_bg() -> StyleBoxFlat:
	return _flat(Color(COL_DARK.r, COL_DARK.g, COL_DARK.b, 0.80), COL_DIVIDER, 1, 5)
