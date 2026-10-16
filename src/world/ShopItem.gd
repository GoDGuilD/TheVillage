# File: ShopItem.gd
# Description: One of Boni's wares on her counter - its icon with the price under it; talking to it makes the offer (the World handles the purchase).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name ShopItem
extends Node2D
## Talkable: the World sees a ShopItem and asks BUY / NO. Ware data (kind, amount, price) is in ItemDB.WARES.

const ICON_LIFT := Vector2(0, -3)        # the icon sits on the table top
const PRICE_OFFSET := Vector2(0, 3)

var ware := ""
var _icon: Sprite2D


func setup(ware_id: String) -> void:
	ware = ware_id


func _ready() -> void:
	add_to_group("talkable")
	_icon = Sprite2D.new()
	_icon.texture = ItemDB.icon(String(ItemDB.WARES[ware]["kind"]))
	_icon.position = ICON_LIFT
	add_child(_icon)
	add_child(PixelText.make(str(int(ItemDB.WARES[ware]["price"])), PRICE_OFFSET, UiTheme.TEXT, PixelText.FONT_SMALL,
			PixelText.Align.CENTER))


func price() -> int:
	return int(ItemDB.WARES[ware]["price"])


func sold_out() -> void:
	remove_from_group("talkable")
	queue_free()


func talk_point() -> Vector2:
	return global_position


func talk(_from: Vector2) -> String:
	return String(ItemDB.WARES[ware]["text"])


func rest() -> void:
	pass
