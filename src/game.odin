package main

import "core:fmt"
import "core:math/linalg"
import "core:mem"
import "core:path/filepath"
import rl "vendor:raylib"
import rgui "vendor:raylib"
camera: rl.Camera2D


check_collisions :: proc {
	rl.CheckCollisionCircles,
	rl.CheckCollisionCircleLine,
	rl.CheckCollisionCircleRec,
	rl.CheckCollisionPointCircle,
	rl.CheckCollisionPointRec,
	rl.CheckCollisionRecs,
}

get_points_from_wall :: proc(wall: Wall) -> (res: [4]Vec2) {
	wall_normal := wall_normal(wall.p1, wall.p2)
	thickness := state.wall_thickness
	res[0] = wall.p1 - wall_normal * thickness / 2
	res[1] = wall.p1 + wall_normal * thickness / 2
	res[2] = wall.p2 + wall_normal * thickness / 2
	res[3] = wall.p2 - wall_normal * thickness / 2
	return res
}

input :: proc() {
	direction_mul: f32
	if rl.IsKeyDown(rl.KeyboardKey.S) {
		direction_mul -= 1
	}
	if rl.IsKeyDown(rl.KeyboardKey.W) {
		direction_mul += 1
	}

	mousePos := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
	if rl.IsMouseButtonPressed(.RIGHT) {
		spawn_spawner(mousePos, .BulletBouncer)
	}
	if rl.IsKeyPressed(.L) {
		spawn_spawner(mousePos, .BulletBulldozer)
	}
	if rl.IsKeyPressed(.K) {
		spawn_spawner(mousePos, .BulletConstructor)
	}
	state.player.direction =
		vec_normalize(
			rl.GetScreenToWorld2D(rl.GetMousePosition(), camera) - state.player.position,
		) *
		direction_mul
}


check_wall_collisions :: proc(entity: Entity, pos: Vec2) -> (Wall, bool) {

	for wall in state.walls {
		points := get_points_from_wall(wall)
		is_colliding :=
			check_collisions(pos, entity.size, points[0], points[1]) ||
			check_collisions(pos, entity.size, points[1], points[2]) ||
			check_collisions(pos, entity.size, points[2], points[3]) ||
			check_collisions(pos, entity.size, points[3], points[0])
		if is_colliding {
			return wall, true
		}
	}
	return Wall{}, false
}

update :: proc() {
	state.time_survived += rl.GetFrameTime()
	{ 	// Update Player
		newPos :=
			state.player.position + state.player.direction * state.player.speed * rl.GetFrameTime()

		wall, collided_with_wall := check_wall_collisions(state.player, newPos)
		if !collided_with_wall {state.player.position = newPos}
	}
	for &entity in state.entities {
		newPos := entity.position + entity.direction * entity.speed * rl.GetFrameTime()
		wall, collided_with_wall := check_wall_collisions(entity, newPos)
		if collided_with_wall {
			switch entity.type {
			case .BulletBouncer:
				entity.position = newPos

				entity.direction = linalg.reflect(entity.direction, wall_normal(wall.p1, wall.p2))

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
		if !check_collisions(
			entity.position,
			rl.Rectangle {
				x = -state.map_size.x / 2,
				y = -state.map_size.y / 2,
				width = state.map_size.x,
				height = state.map_size.y,
			},
		) {
			entity.should_remove = true
		}
		if check_collisions(
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
