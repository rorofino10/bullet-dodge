#+feature dynamic-literals

package main

import "core:fmt"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"


draw_line_exi :: proc(startPos, endPos: Vec2, thick: u32, color: rl.Color) {
	rl.DrawLineEx(startPos, endPos, f32(thick), color)
}

draw_line :: proc {
	rl.DrawLineEx,
	rl.DrawLine,
	rl.DrawLineV,
	draw_line_exi,
}

draw_circle :: proc {
	rl.DrawCircle,
	rl.DrawCircleV,
	rl.DrawCircle3D,
}

HUD :: struct {
	offset:    Vec2i,
	margin:    i32,
	text_size: i32,
}

entity_type_color := map[EntityType]rl.Color {
	.Player            = rl.RED,
	.BulletConstructor = rl.BLUE,
	.BulletBulldozer   = rl.ORANGE,
	.BulletBouncer     = rl.GREEN,
}

DROPDOWN_WIDTH :: 100
DROPDOWN_HEIGHT :: 50

draw_dropdown :: proc() {
	maps_to_show := strings.join(map_selector.maps_names[:], ";", context.temp_allocator)
	maps_to_show_cstring := strings.clone_to_cstring(maps_to_show, context.temp_allocator)
	if rl.GuiDropdownBox(
		rl.Rectangle{screen_size.x - 100, 100, DROPDOWN_WIDTH, DROPDOWN_HEIGHT},
		maps_to_show_cstring,
		&map_selector.selected_map,
		map_selector.open,
	) {
		if map_selector.open {
			load_map_selector()
			load_state_from_json()
		}
		map_selector.open = !map_selector.open
	}
}

render_playing :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)


	rl.BeginMode2D(camera)

	// player
	draw_circle(state.player.position, state.player.size, entity_type_color[state.player.type])

	// entities
	for entity in state.entities {
		draw_circle(entity.position, entity.size, entity_type_color[entity.type])
	}

	//spawners
	for spawner in state.bullet_spawners {
		draw_circle(spawner.pos, 10, entity_type_color[spawner.bullet_type])
	}

	//walls
	for wall in state.walls {
		draw_line(wall.p1, wall.p2, state.wall_thickness, rl.RED)
	}

	// map_border
	{
		startPos: Vec2
		endPos: Vec2
		startPos = Vec2{-state.map_size.x / 2, state.map_size.y / 2}
		endPos = Vec2{-state.map_size.x / 2, -state.map_size.y / 2}
		draw_line(startPos, endPos, rl.WHITE)

		startPos = Vec2{-state.map_size.x / 2, state.map_size.y / 2}
		endPos = Vec2{state.map_size.x / 2, state.map_size.y / 2}
		draw_line(startPos, endPos, rl.WHITE)

		startPos = Vec2{state.map_size.x / 2, state.map_size.y / 2}
		endPos = Vec2{state.map_size.x / 2, -state.map_size.y / 2}
		draw_line(startPos, endPos, rl.WHITE)

		startPos = Vec2{-state.map_size.x / 2, -state.map_size.y / 2}
		endPos = Vec2{state.map_size.x / 2, -state.map_size.y / 2}
		draw_line(startPos, endPos, rl.WHITE)
	}

	rl.EndMode2D()


	// hud
	{

		// ctprint for cstrings and temp_allocator
		hud := new(HUD, context.temp_allocator)
		hud.text_size = 20
		hud.margin = 2
		frame_time_text := fmt.ctprintf("frame_time: %.1fms", rl.GetFrameTime() * 1000)
		rl.DrawText(frame_time_text, hud.offset.x, hud.offset.y, hud.text_size, rl.SKYBLUE)
		hud.offset.y += hud.text_size + hud.margin

		num_bullets_text := fmt.ctprintf("num_bullets: %d", len(state.entities))
		rl.DrawText(num_bullets_text, hud.offset.x, hud.offset.y, hud.text_size, rl.SKYBLUE)
		hud.offset.y += hud.text_size + hud.margin

		num_walls_text := fmt.ctprintf("num_walls: %d", len(state.walls))
		rl.DrawText(num_walls_text, hud.offset.x, hud.offset.y, hud.text_size, rl.SKYBLUE)
		hud.offset.y += hud.text_size + hud.margin

		fps_text := fmt.ctprintf("fps: %d", rl.GetFPS())
		rl.DrawText(fps_text, hud.offset.x, hud.offset.y, hud.text_size, rl.SKYBLUE)
		hud.offset.y += hud.text_size + hud.margin

		time_survived_text := fmt.ctprintf("time_survived: %.2fs", state.time_survived)
		rl.DrawText(time_survived_text, hud.offset.x, hud.offset.y, hud.text_size, rl.SKYBLUE)
	}
	draw_dropdown()
	rl.EndDrawing()

}
LOST_TEXT_FONT_SIZE :: 50
TIME_SURVIVED_FONT_SIZE :: 30

render_lost :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.RED)

	rl.DrawText(
		"YOU LOST",
		i32(screen_size.x / 2),
		i32(screen_size.y / 2),
		LOST_TEXT_FONT_SIZE,
		rl.WHITE,
	)
	rl.DrawText(
		fmt.ctprintf("Time Survived: %.2f", state.time_survived),
		i32(screen_size.x / 2),
		i32(screen_size.y / 2) + LOST_TEXT_FONT_SIZE,
		TIME_SURVIVED_FONT_SIZE,
		rl.WHITE,
	)
	draw_dropdown()

	rl.EndDrawing()
}
