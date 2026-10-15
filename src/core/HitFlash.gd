# File: HitFlash.gd
# Description: Static helper that gives a sprite the white-flash shader and plays a quick flash-out tween.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-12
# Last edit date: 2026-10-12
# Version: 1.0.0
class_name HitFlash
extends RefCounted

const SHADER := preload("res://assets/shaders/flash.gdshader")
const PARAM := "shader_parameter/flash"
const FLASH_SECONDS := 0.12


# Give `item` its own flash material (call once in _ready).
static func attach(item: CanvasItem) -> void:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	item.material = m


# Snap to solid white, then fade back to normal.
static func flash(item: CanvasItem, seconds: float = FLASH_SECONDS) -> void:
	var m := item.material as ShaderMaterial
	if m == null:
		return
	m.set_shader_parameter("flash", 1.0)
	var tw := item.create_tween()
	tw.tween_property(m, PARAM, 0.0, seconds)


# Hold solid white (used right before a death burst).
static func hold(item: CanvasItem) -> void:
	var m := item.material as ShaderMaterial
	if m != null:
		m.set_shader_parameter("flash", 1.0)
