#+feature dynamic-literals
package main

import "core:fmt"
import rl "vendor:raylib"

spawn_spawner :: proc(pos: Vec2, type: EntityType) {
	append(
		&state.bullet_spawners,
		BulletSpawner{pos = pos, velocity = 100, bullet_type = type, spawn_frequency = 1},
	)
}

spawn_wall_from_impact :: proc(dir: Vec2, pos: Vec2) {
	perp := Vec2{-dir.y, dir.x}
	p1 := pos + perp * 150
	p2 := pos - perp * 150
	new_wall := Wall {
		p1 = p1,
		p2 = p2,
	}
	append(&state.walls, new_wall)
}

spawn_bullet_from :: proc(spawner: BulletSpawner) {
	bullet_dir := vec_normalize(state.player.position - spawner.pos)
	fmt.println(state.player.position)
	fmt.println(spawner.pos)
	append(
		&state.entities,
		Entity {
			position = spawner.pos,
			direction = bullet_dir,
			speed = spawner.velocity,
			size = 10,
			type = spawner.bullet_type,
		},
	)
}

update_spawners :: proc() {
	for &spawner in state.bullet_spawners {
		spawner.last_spawn += rl.GetFrameTime()
		if spawner.last_spawn > spawner.spawn_frequency {
			spawn_bullet_from(spawner)
			spawner.last_spawn = 0
		}
	}
}
