extends Node
const MsgCommon = preload("res://src/data/common.gd")
const InvData = preload("res://src/data/inventory_data.gd")

# signal ITEM_EVENT(item_event : ItemEvent)
# signal ITEM_ADD_FAIL(item_event : ItemEvent)

signal DUMB_REQUEST(msg_id: int, bus_mask: int)

signal INV_UNIT_INFO_MSG(msg: MsgCommon.GameMessage)
signal INV_CONTAINER_REQ_MSG(msg: MsgCommon.GameMessage)
signal INV_CONTAINER_RSP_MSG(msg: MsgCommon.GameMessage)
signal INV_ITEM_HELD(item_data: InvData.InvItemData)
signal INV_HELD_ITEM_MOVED(item_data: InvData.InvItemData, pos: Vector2)
signal INV_HELD_ITEM_DROPPED(item_data: InvData.InvItemData, item: Node)
signal INV_ITEM_RETURNED(item_data: InvData.InvItemData)
signal INV_ITEM_TRY_HOST(item_data: InvData.InvItemData, host_id: int, host_index: int)
signal INV_HOST_DENY(item_data: InvData.InvItemData, host_id: int, host_index: int)
signal INV_HOST_ACCEPT(item_data: InvData.InvItemData, host_id: int, host_index: int)
signal INV_ITEM_UNHOSTED(item_data: InvData.InvItemData, unhost_id: int)
