#+feature dynamic-literals
package main

import rl "vendor:raylib"

bullet_string_type := map[string]EntityType {
	"bouncer"     = .BulletBouncer,
	"constructor" = .BulletConstructor,
	"bulldozer"   = .BulletBulldozer,
}

spawn_spawner :: proc(pos: rl.Vector2, type: string) {
	append(
		&state.bullet_spawners,
		BulletSpawner {
			x = i32(pos.x),
			y = i32(pos.y),
			velocity = 100,
			bullet_type = type,
			spawn_frequency = 1,
		},
	)
}

spawn_wall_from_impact :: proc(dir: rl.Vector2, pos: rl.Vector2) {
	perp := rl.Vector2{-dir.y, dir.x}
	p1 := pos + perp * 150
	p2 := pos - perp * 150
	new_wall := Wall {
		x1 = i32(p1.x),
		x2 = i32(p2.x),
		y1 = i32(p1.y),
		y2 = i32(p2.y),
	}
	append(&state.walls, new_wall)
}

spawn_bullet_from :: proc(spawner: BulletSpawner) {
	bullet_dir := rl.Vector2Normalize(
		state.player.position - rl.Vector2{f32(spawner.x), f32(spawner.y)},
	)
	append(
		&state.entities,
		Entity {
			position = rl.Vector2{f32(spawner.x), f32(spawner.y)},
			direction = bullet_dir,
			speed = spawner.velocity,
			size = 10,
			type = bullet_string_type[spawner.bullet_type],
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
