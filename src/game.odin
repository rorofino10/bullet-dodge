package main

import "core:fmt"
import "core:mem"
import "core:path/filepath"
import rl "vendor:raylib"
import rgui "vendor:raylib"
camera: rl.Camera2D


get_points_from_wall :: proc(wall: Wall) -> (res: [4]rl.Vector2) {
	line_point_1 := rl.Vector2{f32(wall.x1), f32(wall.y1)}
	line_point_2 := rl.Vector2{f32(wall.x2), f32(wall.y2)}
	wall_dir := rl.Vector2Normalize(line_point_1 - line_point_2)
	wall_perp := rl.Vector2{wall_dir.y, -wall_dir.x}
	thickness := f32(state.wall_thickness)
	res[0] = line_point_1 - wall_perp * thickness / 2
	res[1] = line_point_1 + wall_perp * thickness / 2
	res[2] = line_point_2 + wall_perp * thickness / 2
	res[3] = line_point_2 - wall_perp * thickness / 2
	return res
}

input :: proc() {
	direction_mul := f32(0)
	if rl.IsKeyDown(rl.KeyboardKey.S) {
		direction_mul -= 1
	}
	if rl.IsKeyDown(rl.KeyboardKey.W) {
		direction_mul += 1
	}

	if rl.IsMouseButtonPressed(.RIGHT) {
		spawn_spawner(rl.GetScreenToWorld2D(rl.GetMousePosition(), camera), "bouncer")
	}
	if rl.IsKeyPressed(.L) {
		spawn_spawner(rl.GetScreenToWorld2D(rl.GetMousePosition(), camera), "bulldozer")
	}
	if rl.IsKeyPressed(.K) {
		spawn_spawner(rl.GetScreenToWorld2D(rl.GetMousePosition(), camera), "constructor")
	}
	state.player.direction =
		rl.Vector2Normalize(
			rl.GetScreenToWorld2D(rl.GetMousePosition(), camera) - state.player.position,
		) *
		direction_mul
}

check_wall_collisions :: proc(entity: Entity, pos: rl.Vector2) -> (Wall, bool) {

	for wall in state.walls {
		points := get_points_from_wall(wall)
		is_colliding :=
			rl.CheckCollisionCircleLine(pos, entity.size, points[0], points[1]) ||
			rl.CheckCollisionCircleLine(pos, entity.size, points[1], points[2]) ||
			rl.CheckCollisionCircleLine(pos, entity.size, points[2], points[3]) ||
			rl.CheckCollisionCircleLine(pos, entity.size, points[3], points[0])
		if is_colliding {
			return wall, true
		}
	}
	return Wall{}, false
}

update_player :: proc() {
	newPos :=
		state.player.position +
		state.player.direction * f32(state.player.speed) * rl.GetFrameTime()

	wall, collided_with_wall := check_wall_collisions(state.player, newPos)
	if !collided_with_wall {state.player.position = newPos}
}

update :: proc() {
	state.time_survived += rl.GetFrameTime()
	update_player()
	for &entity in state.entities {
		newPos := entity.position + entity.direction * f32(entity.speed) * rl.GetFrameTime()
		wall, collided_with_wall := check_wall_collisions(entity, newPos)
		if collided_with_wall {
			fmt.println(entity.type, "Collided")
			switch entity.type {
			case .BulletBouncer:
				entity.position = newPos
				entity.direction *= -1
			case .BulletConstructor:
				spawn_wall_from_impact(entity.direction, entity.position)
				entity.should_remove = true
			case .BulletBulldozer:
				if !wall.invulnerable {
					wall.should_remove = true
				} else {
					entity.should_remove = true
				}
				entity.position = newPos
			case .Player:
			}
		} else {
			entity.position = newPos
		}
		if !rl.CheckCollisionPointRec(
			entity.position,
			rl.Rectangle {
				x = f32(-state.map_width / 2),
				y = f32(-state.map_height / 2),
				width = f32(state.map_width),
				height = f32(state.map_height),
			},
		) {
			entity.should_remove = true
		}
		if rl.CheckCollisionCircles(
			entity.position,
			entity.size,
			state.player.position,
			state.player.size,
		) {
			state.game_loop_state = .LOST
		}
	}
	#reverse for &entity, i in state.entities {
		if entity.should_remove {
			unordered_remove(&state.entities, i)
		}
	}
	#reverse for &wall, i in state.walls {
		if wall.should_remove {
			unordered_remove(&state.walls, i)
		}
	}
	update_spawners()

}


run :: proc() {


	init_state_alloc()
	init_map_selector_alloc()

	load_map_selector()
	load_state_from_json()

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		switch state.game_loop_state {
		case .PLAYING:
			input()
			update()
			render_playing()
		case .LOST:
			render_lost()
		}

	}
	save_err := write_state_to_file()
	if save_err != nil {
		fmt.println(save_err)
	}
	delete(state_buffer)
	delete(map_selector_buffer)
}
