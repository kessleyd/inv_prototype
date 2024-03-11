extends Node
const MsgCommon = preload("res://src/data/common.gd")
const InvData = preload("res://src/data/inventory_data.gd")

class ItemEntry:
    var data: InvData.InvItemData
    var index: int = 0
    var cells: Array = []
    func _init(pdata: InvData.InvItemData, pindex: int, row_offset: int):
        data = pdata
        index = pindex
        for col in range(0, data.get_item_cols()):
            for row in range(0, data.get_item_rows()):
                cells.append(index + col + row * row_offset)
        cells.sort() #this sort may not be necessary


@export var cell_count = 100
@export var col_count = 10
@export var container_id = 0

@onready var signal_bus: SignalBus = get_node("/root/SignalBus")
var hosted: Dictionary = {}
var occupied: Array = []
var reserved_entry: ItemEntry = null

func _ready():
    signal_bus.INV_CONTAINER_REQ_MSG.connect(_handle_container_req)
    signal_bus.INV_ITEM_TRY_HOST.connect(_host_item)
    signal_bus.INV_ITEM_UNHOSTED.connect(_unhost_item)
    signal_bus.INV_ITEM_HELD.connect(_on_item_held)
    signal_bus.INV_ITEM_RETURNED.connect(_on_item_returned)
    _send_container_info()


func _handle_container_req(req: MsgCommon.GameMessage) -> void:
    var header = req.get_header()
    var valid: bool = header.get_msg_id() == MsgCommon.MESSAGE_ID.INV_CONTAINER_REQ
    valid = valid and req.get_inv_container_req_msg() == container_id
    if valid:
        _send_container_info()


func _send_container_info() -> void:
    var msg: MsgCommon.GameMessage = MsgCommon.GameMessage.new()
    var header = msg.new_header()
    var body = msg.new_inv_container_rsp_msg()
    header.set_msg_id(MsgCommon.MESSAGE_ID.INV_CONTAINER_RSP)
    body.set_container_id(container_id)
    body.set_container_cols(col_count)
    body.set_container_rows(cell_count/col_count)
    signal_bus.INV_CONTAINER_RSP_MSG.emit(msg)


func _host_item(item_data: InvData.InvItemData, host_id: int, host_index:int) -> void:
    if host_id == container_id:
        var entry = ItemEntry.new(item_data, host_index, col_count)
        var unique = not hosted.has(entry.data.get_item_id()) # item is not already in container
        var valid = unique and not entry.cells.any(func(indx): return occupied.has(indx)) # cells we want are free
        valid = valid and (entry.cells.back() % col_count) >= (entry.cells.front() % col_count) # item fits width
        valid = valid and entry.cells.back() < cell_count # item fits in height
        if valid:
            hosted[entry.data.get_item_id()] = entry
            occupied.append_array(entry.cells)
            signal_bus.INV_HOST_ACCEPT.emit(item_data, host_id, host_index)
        elif not unique: # should not happen; items should be unhosted when dragged
            #TODO report error
            pass
        else: #item doesn't fit, emit DENY
            signal_bus.INV_HOST_DENY.emit(item_data, container_id, host_index)


func _unhost_item(item_data: InvData.InvItemData, unhost_id: int) -> void:
    if unhost_id == container_id:
        var id = item_data.get_item_id()
        if hosted.has(id):
            reserved_entry = hosted[id]
            for cell in hosted[id].cells:
                occupied.erase(cell)
            hosted.erase(id)
        else:
            #TODO we don't have this item, report error
            pass


func _on_item_held(item_data: InvData.InvItemData):
    if item_data.get_item_id() in hosted:
        _unhost_item(item_data, container_id)


func _on_item_returned(item_data: InvData.InvItemData):
    if reserved_entry != null && item_data.get_item_id() == reserved_entry.data.get_item_id():
        hosted[reserved_entry.data.get_item_id()] = reserved_entry
        occupied.append_array(reserved_entry.cells)
