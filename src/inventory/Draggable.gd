extends Container
const InvData = preload("res://src/data/inventory_data.gd")

@export var item_style : StyleBox
@export var item_size: Vector2 = Vector2(1,1)
@export var item_id: int = 0
@onready var inventory: Node = get_node("/root/Inventory")
@onready var signal_bus: SignalBus = get_node("/root/SignalBus")
@onready var collision_area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var display: Panel = Panel.new()
@onready var item_data: InvData.InvItemData = InvData.InvItemData.new()

var dragged: bool = false
var start_pos: Vector2 = Vector2.ZERO
var next_pos: Vector2 = Vector2.ZERO
var moffset: Vector2 = Vector2.ZERO

func _ready():
    var item_units = inventory.inv_unit_info.get_inv_unit_info_msg().get_item_info()
    var item_unit_size: Vector2 = Vector2(item_units.get_item_width(), item_units.get_item_height())
    self.size =  item_size * item_unit_size
    display.size = self.size
    display.position = Vector2.ZERO
    display.add_theme_stylebox_override("panel", item_style)
    display.mouse_filter = Control.MOUSE_FILTER_IGNORE
    self.add_child(display)
    collision_shape.shape.set_size(self.size)
    collision_shape.position += self.size/2
    collision_area.input_event.connect(_on_input)
    item_data.set_item_id(item_id)
    item_data.set_item_cols(int(item_size.x))
    item_data.set_item_rows(int(item_size.y))
    $ColorRect.size = Vector2(2,2)


func _input(event):
    if event is InputEventMouse and dragged:
        self.position = event.position - moffset
        signal_bus.INV_HELD_ITEM_MOVED.emit(item_data, self.get_origin())


func _on_input(_viewport, event, _shape_idx):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.is_pressed():
                if not dragged:
                    signal_bus.INV_ITEM_HELD.emit(item_data)
                start_pos = self.position
                moffset = event.position - self.position
                dragged = true
            elif dragged:
                dragged = false
                signal_bus.INV_HELD_ITEM_DROPPED.emit(item_data, self)


func get_origin():
    return self.position


func place(pos: Vector2):
    var item_units = inventory.inv_unit_info.get_inv_unit_info_msg().get_item_info()
    var node_units = inventory.inv_unit_info.get_inv_unit_info_msg().get_node_info()
    var margin = Vector2(item_units.get_item_margin(), item_units.get_item_margin())
    var offset: Vector2 = Vector2(
        (margin.x + node_units.get_node_margin()) * item_size.x,
        (margin.y + node_units.get_node_margin()) * item_size.y)
    self.position = pos + offset/2
    start_pos = position


func reset():
    self.position = start_pos
    signal_bus.INV_ITEM_RETURNED.emit(item_data)
