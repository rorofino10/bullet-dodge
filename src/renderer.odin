#+feature dynamic-literals

package main

import "core:fmt"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

HUDItem :: struct {
	unformatted_string: cstring,
}
HUD :: struct {
	x_offset:  i32,
	y_offset:  i32,
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

draw_hud :: proc() {

	// ctprint for cstrings and temp_allocator
	hud := new(HUD, context.temp_allocator)
	hud.text_size = 20
	hud.margin = 2
	frame_time_text := fmt.ctprintf("frame_time: %.1fms", rl.GetFrameTime() * 1000)
	rl.DrawText(frame_time_text, hud.x_offset, hud.y_offset, hud.text_size, rl.SKYBLUE)
	hud.y_offset += hud.text_size + hud.margin

	num_bullets_text := fmt.ctprintf("num_bullets: %d", len(state.entities) - 1)
	rl.DrawText(num_bullets_text, hud.x_offset, hud.y_offset, hud.text_size, rl.SKYBLUE)
	hud.y_offset += hud.text_size + hud.margin

	num_walls_text := fmt.ctprintf("num_walls: %d", len(state.walls))
	rl.DrawText(num_walls_text, hud.x_offset, hud.y_offset, hud.text_size, rl.SKYBLUE)
	hud.y_offset += hud.text_size + hud.margin

	fps_text := fmt.ctprintf("fps: %d", rl.GetFPS())
	rl.DrawText(fps_text, hud.x_offset, hud.y_offset, hud.text_size, rl.SKYBLUE)
	hud.y_offset += hud.text_size + hud.margin

	time_survived_text := fmt.ctprintf("time_survived: %.2fs", state.time_survived)
	rl.DrawText(time_survived_text, hud.x_offset, hud.y_offset, hud.text_size, rl.SKYBLUE)
}

draw_map_border :: proc() {
	rl.DrawLine(
		-state.map_width / 2,
		state.map_height / 2,
		-state.map_width / 2,
		-state.map_height / 2,
		rl.WHITE,
	)
	rl.DrawLine(
		-state.map_width / 2,
		state.map_height / 2,
		state.map_width / 2,
		state.map_height / 2,
		rl.WHITE,
	)
	rl.DrawLine(
		state.map_width / 2,
		state.map_height / 2,
		state.map_width / 2,
		-state.map_height / 2,
		rl.WHITE,
	)
	rl.DrawLine(
		-state.map_width / 2,
		-state.map_height / 2,
		state.map_width / 2,
		-state.map_height / 2,
		rl.WHITE,
	)
}

draw_player :: proc() {
	rl.DrawCircleV(state.player.position, state.player.size, entity_type_color[state.player.type])
}

draw_entities :: proc() {

	for entity in state.entities {
		rl.DrawCircleV(entity.position, entity.size, entity_type_color[entity.type])
	}


}
draw_spawners :: proc() {
	for spawner in state.bullet_spawners {
		rl.DrawCircle(
			spawner.x,
			spawner.y,
			10,
			entity_type_color[bullet_string_type[spawner.bullet_type]],
		)
	}
}

draw_walls :: proc() {
	for wall in state.walls {
		startPos := rl.Vector2{f32(wall.x1), f32(wall.y1)}
		endPos := rl.Vector2{f32(wall.x2), f32(wall.y2)}
		// rl.DrawCircleV(points[0], 10, rl.RED)
		// rl.DrawCircleV(points[1], 10, rl.BLUE)
		// rl.DrawCircleV(points[2], 10, rl.WHITE)
		// rl.DrawCircleV(points[3], 10, rl.GREEN)
		rl.DrawLineEx(startPos, endPos, f32(state.wall_thickness), rl.RED)
		// rl.DrawLineV(startPos, endPos, rl.RED)
	}


}

render_playing :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)


	rl.BeginMode2D(camera)

	draw_player()
	draw_entities()
	draw_spawners()
	draw_walls()
	draw_map_border()

	rl.EndMode2D()

	draw_hud()
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
