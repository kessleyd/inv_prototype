extends Node
const InvData = preload("res://src/data/inventory_data.gd")
const MsgCommon = preload("res://src/data/common.gd")

@onready var signal_bus : Node = get_node("/root/SignalBus")
var inv_unit_info: MsgCommon.GameMessage = MsgCommon.GameMessage.new()
var node_size: Array[float] = [50, 50, 1, 20]
var item_size: Array[float] = [40, 40, 10]

func _ready():
    _populate_inv_units()
    signal_bus.DUMB_REQUEST.connect(_handle_dumb_req)


func _populate_inv_units():
    var header = inv_unit_info.new_header()
    var body = inv_unit_info.new_inv_unit_info_msg()
    var node_info = body.new_node_info()
    var item_info = body.new_item_info()
    header.set_msg_id(MsgCommon.MESSAGE_ID.INV_UNIT_INFO)
    header.set_bus_mask(0)
    header.set_timestamp(0)
    node_info.set_node_width(node_size[0])
    node_info.set_node_height(node_size[1])
    node_info.set_node_margin(node_size[2])
    node_info.set_container_border_margin(node_size[3])
    item_info.set_item_margin(item_size[2])
    item_info.set_item_width(min(item_size[0], node_size[0] - item_size[2]/2))
    item_info.set_item_height(min(item_size[1], node_size[1] - item_size[2]/2))


func _handle_dumb_req(req: MsgCommon.GameMessage):
    var header = req.get_header()
    if header.get_msg_id() == MsgCommon.MESSAGE_ID.DUMB_REQUEST:
        if req.body.dumb_req_msg.req_msg == MsgCommon.MESSAGE_ID.INV_UNIT_INFO:
            signal_bus.INV_UNIT_INFO_MSG.emit(inv_unit_info)
