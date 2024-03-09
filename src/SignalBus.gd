extends Node

# const ItemEvent = preload("res://src/Inventory/ItemEvent.gd")

# signal ITEM_EVENT(item_event : ItemEvent)
# signal ITEM_ADD_FAIL(item_event : ItemEvent)

signal PROTO_ADD_ITEM(size: Vector2i)
signal PROTO_ITEM_ADD(pos: Vector2)
signal PROTO_ITEM_DENY()
