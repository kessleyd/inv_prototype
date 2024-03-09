extends Container


class InvGridNode extends Panel:
    func _init(pstyle: StyleBox, pos: Vector2, nwidth: float, nheight: float):
        add_theme_stylebox_override("panel", pstyle)
        position = pos
        size = Vector2(nwidth, nheight)
        mouse_filter = Control.MOUSE_FILTER_IGNORE

    func set_style(pstyle: StyleBox) -> void:
        add_theme_stylebox_override("panel", pstyle)


@export var best_fit_buffer: Vector2 = Vector2(10, 10)
@export var node_margin: Vector2 = Vector2(1.0, 1.0)
@export var item_margin: Vector2 = Vector2(10.0, 10.0)
@export var node_style: StyleBox
@export var node_select_style: StyleBox
@export var node_deny_style: StyleBox
@onready var inventory: Node = get_node("/root/Inventory")
@onready var signal_bus: SignalBus = get_node("/root/SignalBus")
@onready var collision_area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
var cells: Array[InvGridNode]
var foreign_shape: CollisionShape2D = null
var selected: InvGridNode = null

# Called when the node enters the scene tree for the first time.
func _ready():
    cells.resize(inventory.grid_cell_count)
    for i in range(0, inventory.grid_cell_count):
        var panel = InvGridNode.new(node_style, _indexToVector2(i), inventory.node_size.x, inventory.node_size.y)
        self.add_child(panel)
        cells[i] = panel
    selected = cells[0]
    self.size = Vector2(
        inventory.node_size.x * inventory.grid_width + node_margin.x * (inventory.grid_width + 1),
        inventory.node_size.y * inventory.grid_cols + node_margin.y * (inventory.grid_cols + 1))
    collision_shape.shape.set_size(self.size)
    collision_shape.position += self.size/2
    $Area2D.area_shape_entered.connect(_on_area_2d_area_shape_entered)
    $Area2D.area_shape_exited.connect(_on_area_2d_area_shape_exited)
    signal_bus.PROTO_ADD_ITEM.connect(_on_item_add)


func _process(_delta):
    if foreign_shape != null:
        var ref_point: Array[Vector2] = _getIntersectPoint()
        if not ref_point.is_empty():
            var index: int = _vector2ToIndex(ref_point[0])
            if index < cells.size():
                selected.set_style(node_style)
                selected = _getBestFitNode(index, ref_point[0])
                selected.set_style(node_select_style)


func _on_item_add(psize: Vector2i):
    if foreign_shape != null and selected != null:
        #bounds check
        var index: int = _vector2ToIndex(selected.position)
        var valid_x: bool = (index % inventory.grid_width) + psize.x <= inventory.grid_width
        var valid_y: bool = (index + ((psize.y - 1) * inventory.grid_width)) < inventory.grid_cell_count
        if valid_x and valid_y:
            signal_bus.PROTO_ITEM_ADD.emit(selected.position + item_margin)
        else:
            signal_bus.PROTO_ITEM_DENY.emit()


func _on_area_2d_area_shape_entered(_area_rid: RID, area: Area2D, area_shape_index: int, _local_shape_index: int):
    foreign_shape = area.shape_owner_get_owner(area.shape_find_owner(area_shape_index))


func _on_area_2d_area_shape_exited(_area_rid: RID, _area: Area2D, _area_shape_index: int, _local_shape_index: int):
    foreign_shape = null
    selected.set_style(node_style)


func _getBestFitNode(index: int, pos: Vector2) -> InvGridNode:
    if index + inventory.grid_width < cells.size():
        var candidates = [
            cells[index],
            cells[index + 1],
            cells[index + inventory.grid_width]]
        candidates.sort_custom(_closestNode.bind(pos))
        return candidates[0]
    return cells[index]


#TODO: add an Optional type so I don't have to do this hack of returning an array
func _getIntersectPoint() -> Array[Vector2]:
    var collision_points = collision_shape.shape.collide_and_get_contacts(
        collision_shape.get_global_transform(),
        foreign_shape.shape,
        foreign_shape.get_global_transform())
    if not collision_points.is_empty():
        collision_points.sort()
        var irect = Rect2(collision_points[0],collision_points[3] - collision_points[0])
        if irect.size < foreign_shape.shape.size and irect.size.x > 1:
            return [irect.position]
        return [foreign_shape.global_position - foreign_shape.shape.size/2 - node_margin]
    return []


func _indexToVector2(index) -> Vector2:
    var x = index % inventory.grid_width
    var y = floor(index / inventory.grid_width)
    return Vector2(
        x * inventory.node_size.x + node_margin.x * (x + 1),
        y * inventory.node_size.y + node_margin.y * (y + 1))


func _vector2ToIndex(point) -> int:
    var x: int = floor(point.x / (inventory.node_size.x + node_margin.x))
    var y: int = point.y / (inventory.node_size.y + node_margin.y)
    return x + (y * inventory.grid_width)


func _closestNode(node_a: InvGridNode, node_b: InvGridNode, point: Vector2) -> bool:
    var comp = point - best_fit_buffer
    return comp.distance_squared_to(node_a.position) < comp.distance_squared_to(node_b.position)


func _closestPoint(node_a: Vector2, node_b: Vector2, point: Vector2) -> bool:
    var comp = point - best_fit_buffer
    return comp.distance_squared_to(node_a) < comp.distance_squared_to(node_b)
