extends RefCounted
class_name PlaceholderSprite
## Static utility. Call PlaceholderSprite.inject() from each character's _ready().
## Does nothing if the AnimatedSprite2D already has real frames.

static func inject(sprite: AnimatedSprite2D, color: Color, size: Vector2i) -> void:
	if not sprite or not sprite.sprite_frames:
		return
	for anim in sprite.sprite_frames.get_animation_names():
		if sprite.sprite_frames.get_frame_count(anim) > 0:
			return

	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var outline := Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 1.0)
	for x in size.x:
		img.set_pixel(x, 0, outline)
		img.set_pixel(x, size.y - 1, outline)
	for y in size.y:
		img.set_pixel(0, y, outline)
		img.set_pixel(size.x - 1, y, outline)

	var tex := ImageTexture.create_from_image(img)
	for anim in sprite.sprite_frames.get_animation_names():
		sprite.sprite_frames.add_frame(anim, tex)
	sprite.play(sprite.sprite_frames.get_animation_names()[0])
