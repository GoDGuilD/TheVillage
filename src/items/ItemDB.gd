# File: ItemDB.gd
# Description: Static catalogue of everything Joe can receive (items, ammo, keys, heart pieces/containers, gems): display names, icons, the text shown on getting them, and Boni's shop wares with prices.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name ItemDB
extends RefCounted
## "Kinds" are what chests, gifts, pickups and wares hand out. Y-items (GameState.ITEM_ORDER) are a subset.
## The text keys live in assets/data/dialogue.json (checked by the gen_areas.py lint and by test_items.gd).

const ICON_DIR := "res://assets/ui/items/"
const SPRITE_DIR := "res://assets/sprites/items/"

# kind -> {name, icon (texture path shown over Joe's head), text (dialogue key)}
const KINDS := {
	"lantern": {"name": "LANTERN", "icon": ICON_DIR + "lantern.png", "text": "get_lantern"},
	"boomerang": {"name": "BOOMERANG", "icon": ICON_DIR + "boomerang.png", "text": "get_boomerang"},
	"bow": {"name": "BOW", "icon": ICON_DIR + "bow.png", "text": "get_bow"},
	"bombs": {"name": "BOMBS", "icon": ICON_DIR + "bombs.png", "text": "get_bombs"},
	"arrows": {"name": "ARROWS", "icon": "res://assets/ui/hud/arrow_small.png", "text": "get_arrows"},
	"small_key": {"name": "SMALL KEY", "icon": SPRITE_DIR + "small_key.png", "text": "get_small_key"},
	"heart_piece": {"name": "PIECE OF HEART", "icon": SPRITE_DIR + "heart_piece.png", "text": "get_heart_piece"},
	"heart_container": {"name": "HEART CONTAINER", "icon": SPRITE_DIR + "heart_container.png",
			"text": "get_heart_container"},
	"gems": {"name": "GEMS", "icon": "res://assets/sprites/props/gem_red.png", "text": "get_gems"},
}

# Y-items that consume something when used: item -> ammo kind or "magic".
const USES := {"bow": "arrows", "bombs": "bombs", "lantern": "magic"}
const LANTERN_MAGIC := 2                 # magic units (of GameState.MAX_MAGIC) per lantern flame

# Boni's wares: ware -> {kind, amount, price, text (the offer), once (sold out after one sale)}
const WARES := {
	"bombs": {"kind": "bombs", "amount": 5, "price": 20, "text": "shop_bombs", "once": false},
	"arrows": {"kind": "arrows", "amount": 10, "price": 15, "text": "shop_arrows", "once": false},
	"heart_piece": {"kind": "heart_piece", "amount": 1, "price": 100, "text": "shop_heart_piece", "once": true},
}


static func has(kind: String) -> bool:
	return KINDS.has(kind)


static func display_name(kind: String) -> String:
	return String(KINDS.get(kind, {}).get("name", kind.to_upper()))


static func icon(kind: String) -> Texture2D:
	var path := String(KINDS.get(kind, {}).get("icon", ""))
	return load(path) if path != "" and ResourceLoader.exists(path) else null


static func text_key(kind: String) -> String:
	return String(KINDS.get(kind, {}).get("text", ""))


static func is_y_item(kind: String, state: Node) -> bool:
	return state.ITEM_ORDER.has(kind)
