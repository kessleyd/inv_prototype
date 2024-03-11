extends Panel
class_name InvNodeDisplay

var index: int = 0

func _init(pindex: int, pstyle: StyleBox, pos: Vector2, nwidth: float, nheight: float):
    index = pindex
    add_theme_stylebox_override("panel", pstyle)
    position = pos
    size = Vector2(nwidth, nheight)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_style(pstyle: StyleBox) -> void:
    add_theme_stylebox_override("panel", pstyle)


static func is_closer(lhs: InvNodeDisplay, rhs: InvNodeDisplay, pos: Vector2) -> bool:
    return pos.distance_squared_to(lhs.position + (lhs.size/2)) < \
           pos.distance_squared_to(rhs.position + (rhs.size/2))
