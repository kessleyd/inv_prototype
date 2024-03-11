extends Container
const MsgCommon = preload("res://src/data/common.gd")
const InvData = preload("res://src/data/inventory_data.gd")
const InvContainer = preload("res://src/inventory/InvContainer.gd")
const InvNodeDisplay = preload("res://src/inventory/InvNodeDisplay.gd")

@export var node_style: StyleBox
@export var node_select_style: StyleBox
@export var node_deny_style: StyleBox
@export var linked_id: int = 0

@onready var inventory: Node = get_node("/root/Inventory")
@onready var signal_bus: SignalBus = get_node("/root/SignalBus")

var container: MsgCommon.InvContainerData = null
var select_overlay: Panel = Panel.new()
var cells: Array[InvNodeDisplay] = []
var has_area: bool = false
var has_mouse: bool = false
var candidate: Node = null

func _ready() -> void:
    select_overlay.hide()
    select_overlay.add_theme_stylebox_override("panel", node_select_style)
    self.add_child(select_overlay)
    signal_bus.INV_CONTAINER_RSP_MSG.connect(_on_container_rsp)
    _req_container_info()


func _req_container_info():
    var msg: MsgCommon.GameMessage = MsgCommon.GameMessage.new()
    var header = msg.new_header()
    header.set_msg_id(MsgCommon.MESSAGE_ID.INV_CONTAINER_REQ)
    msg.set_inv_container_req_msg(linked_id)
    signal_bus.INV_CONTAINER_REQ_MSG.emit(msg)


func _on_container_rsp(msg: MsgCommon.GameMessage):
    var header: MsgCommon.Header = msg.get_header()
    var valid: bool = header.get_msg_id() == MsgCommon.MESSAGE_ID.INV_CONTAINER_RSP
    valid = valid and msg.get_inv_container_rsp_msg().get_container_id() == linked_id
    if valid:
        container = msg.get_inv_container_rsp_msg()
        _populate()
        _size_to_grid()
        signal_bus.INV_HELD_ITEM_DROPPED.connect(_on_held_dropped)
        signal_bus.INV_HOST_DENY.connect(_on_host_deny)
        signal_bus.INV_HOST_ACCEPT.connect(_on_host_accept)
        signal_bus.INV_HELD_ITEM_MOVED.connect(_on_item_dragged)
        signal_bus.INV_ITEM_HELD.connect(_on_item_held)
        $Area2D.mouse_entered.connect(func(): has_mouse=true)
        $Area2D.mouse_exited.connect(func(): has_mouse=false)
        $Area2D.area_entered.connect(func(_dc): has_area=true)
        $Area2D.area_exited.connect(func(_dc): has_area=false)


func _populate() -> void:
    var node_units = inventory.inv_unit_info.get_inv_unit_info_msg().get_node_info()
    cells.resize(container.get_container_cols() * container.get_container_rows())
    for i in range(0, cells.size()):
        var x:int  = i % container.get_container_rows()
        var y: int = i / container.get_container_rows()
        var panel = InvNodeDisplay.new(
            i,
            node_style,
            Vector2(
                x * node_units.get_node_width() + node_units.get_node_margin() * (x + 1),
                y * node_units.get_node_width() + node_units.get_node_margin() * (y + 1)),
            node_units.get_node_width(),
            node_units.get_node_height())
        self.add_child(panel)
        cells[i] = panel


func _size_to_grid() -> void:
    var node_units = inventory.inv_unit_info.get_inv_unit_info_msg().get_node_info()
    var grid_rows = container.get_container_rows()
    var grid_cols = container.get_container_cols()
    self.size = Vector2(
        node_units.get_node_width() * grid_rows + node_units.get_node_margin() * (grid_rows + 1),
        node_units.get_node_height() * grid_cols + node_units.get_node_margin() * (grid_cols + 1))
    $Area2D/CollisionShape2D.shape.set_size(self.size)
    $Area2D/CollisionShape2D.position += self.size/2


func _on_held_dropped(item_data: InvData.InvItemData, draggable: Node) -> void:
    select_overlay.hide()
    if has_area or has_mouse:
        cells.sort_custom(InvNodeDisplay.is_closer.bind(draggable.get_origin() - self.position))
        candidate = draggable
        signal_bus.INV_ITEM_TRY_HOST.emit(
            item_data,
            container.get_container_id(),
            cells[0].index)


func _on_host_deny(_item_data: InvData.InvItemData, host_id: int, _host_index: int):
    if host_id == container.get_container_id() and candidate != null:
        candidate.reset()
        candidate = null


func _on_host_accept(_item_data: InvData.InvItemData, host_id: int, _host_index: int):
    if host_id == container.get_container_id() and candidate != null:
        candidate.place(cells[0].position + self.position)
        candidate = null


func _on_item_dragged(item_data: InvData.InvItemData, pos: Vector2):
    if has_mouse:
        cells.sort_custom(InvNodeDisplay.is_closer.bind(pos - self.position))
        _hilight_selected(item_data, cells[0].position)


func _on_item_held(item_data: InvData.InvItemData):
    var item_units = inventory.inv_unit_info.get_inv_unit_info_msg().get_item_info()
    select_overlay.size = Vector2(
        item_data.get_item_cols() * item_units.get_item_width(),
        item_data.get_item_rows() * item_units.get_item_height())


func _hilight_selected(item_data: InvData.InvItemData, pos: Vector2):
    var item_units = inventory.inv_unit_info.get_inv_unit_info_msg().get_item_info()
    var node_units = inventory.inv_unit_info.get_inv_unit_info_msg().get_node_info()
    var margin = node_units.get_node_width() - item_units.get_item_width()
    var offset: Vector2 = Vector2(
        (margin + node_units.get_node_margin()) * item_data.get_item_cols(),
        (margin + node_units.get_node_margin()) * item_data.get_item_rows())
    select_overlay.position = pos + offset/2
    select_overlay.show()
