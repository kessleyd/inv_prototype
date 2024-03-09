extends Container


@export var item_size: Vector2 = Vector2(2, 2)
@export var item_style : StyleBox
@onready var inventory: Node = get_node("/root/Inventory")
@onready var signal_bus: SignalBus = get_node("/root/SignalBus")
@onready var collision_area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var display: Panel = Panel.new()
var dragged: bool = false
var start_pos: Vector2 = Vector2.ZERO
var next_pos: Vector2 = Vector2.ZERO
var moffset: Vector2 = Vector2.ZERO


func _ready():
    display.size = item_size * inventory.node_size - inventory.item_margin
    display.add_theme_stylebox_override("panel", item_style)
    display.mouse_filter = Control.MOUSE_FILTER_IGNORE
    self.size = display.size
    self.add_child(display)
    collision_shape.shape.set_size(self.size)
    collision_shape.position += self.size/2
    collision_area.input_event.connect(_on_input)
    signal_bus.PROTO_ITEM_ADD.connect(_place_item)
    signal_bus.PROTO_ITEM_DENY.connect(_on_deny)


func _input(event):
    if event is InputEventMouse and dragged:
        self.position = event.position - moffset


func _on_input(_viewport, event, _shape_idx):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.is_pressed():
                start_pos = self.position
                moffset = event.position - self.position
                dragged = true
            elif dragged:
                signal_bus.PROTO_ADD_ITEM.emit(item_size)
                dragged = false


func _place_item(pos: Vector2):
    self.position = pos
    start_pos = pos


func _on_deny():
    self.position = start_pos
