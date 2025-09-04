package main

import "core:fmt"
import "core:mem"
import "core:path/filepath"
import rl "vendor:raylib"
import rgui "vendor:raylib"
camera: rl.Camera2D


check_collision_circle_line_vec2i :: proc(center: Vec2i, radius: f32, p1, p2: Vec2i) -> bool {
	return rl.CheckCollisionCircleLine(
		vec2i_to_vec2(center),
		radius,
		vec2i_to_vec2(p1),
		vec2i_to_vec2(p2),
	)
}

check_collision_circle_line :: proc {
	rl.CheckCollisionCircleLine,
	check_collision_circle_line_vec2i,
}

check_collision_point_rec_vec2i :: proc(point: Vec2i, rec: rl.Rectangle) -> bool {
	return rl.CheckCollisionPointRec(vec2i_to_vec2(point), rec)
}

check_collision_point_rec :: proc {
	rl.CheckCollisionPointRec,
	check_collision_point_rec_vec2i,
}

check_collision_circles_vec2i :: proc(
	center1: Vec2i,
	radius1: f32,
	center2: Vec2i,
	radius2: f32,
) -> bool {
	return rl.CheckCollisionCircles(
		vec2i_to_vec2(center1),
		radius1,
		vec2i_to_vec2(center2),
		radius2,
	)
}

check_collision_circles :: proc {
	rl.CheckCollisionCircles,
	check_collision_circles_vec2i,
}


get_points_from_wall :: proc(wall: Wall) -> (res: [4]Vec2) {
	wall_dir := vec_normalize(wall.p1 - wall.p2)
	wall_perp := rl.Vector2{wall_dir.y, -wall_dir.x}
	thickness := f32(state.wall_thickness)
	res[0] = wall.p1 - wall_perp * thickness / 2
	res[1] = wall.p1 + wall_perp * thickness / 2
	res[2] = wall.p2 + wall_perp * thickness / 2
	res[3] = wall.p2 - wall_perp * thickness / 2
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
		rl.Vector2Normalize(
			rl.GetScreenToWorld2D(rl.GetMousePosition(), camera) - state.player.position,
		) *
		direction_mul
}


check_wall_collisions :: proc(entity: Entity, pos: Vec2) -> (Wall, bool) {

	for wall in state.walls {
		points := get_points_from_wall(wall)
		is_colliding :=
			check_collision_circle_line(pos, entity.size, points[0], points[1]) ||
			check_collision_circle_line(pos, entity.size, points[1], points[2]) ||
			check_collision_circle_line(pos, entity.size, points[2], points[3]) ||
			check_collision_circle_line(pos, entity.size, points[3], points[0])
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
			state.player.position +
			state.player.direction * f32(state.player.speed) * rl.GetFrameTime()

		wall, collided_with_wall := check_wall_collisions(state.player, newPos)
		if !collided_with_wall {state.player.position = newPos}
	}
	for &entity in state.entities {
		newPos := entity.position + entity.direction * f32(entity.speed) * rl.GetFrameTime()
		wall, collided_with_wall := check_wall_collisions(entity, newPos)
		if collided_with_wall {
			switch entity.type {
			case .BulletBouncer:
				entity.position = newPos
				fmt.println("Bounce", entity.direction)
				entity.direction = Vec2{entity.direction.y, -entity.direction.x}

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
		if !check_collision_point_rec(
			entity.position,
			rl.Rectangle {
				x = f32(-state.map_size.x / 2),
				y = f32(-state.map_size.y / 2),
				width = f32(state.map_size.x),
				height = f32(state.map_size.y),
			},
		) {
			entity.should_remove = true
		}
		if check_collision_circles(
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
