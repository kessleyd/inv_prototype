extends Node

@onready var signal_bus : Node = get_node("/root/SignalBus")
@export var node_size: Vector2 = Vector2(50, 50)
@export var item_margin: Vector2 = Vector2(10, 10)
@export var grid_width: int = 15
@export var grid_cell_count: int = 150
@onready var grid_cols: int = floori(grid_cell_count/grid_width)

func _ready():
    grid_width = min(grid_cell_count, grid_width)
