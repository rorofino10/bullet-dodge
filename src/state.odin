package main

import "core:encoding/json"
import "core:flags"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/filepath"
import "vendor:raylib"


WRError :: enum {
	OK,
	Write_Error,
	Read_Error,
}

Error :: union #shared_nil {
	json.Unmarshal_Error,
	json.Marshal_Error,
	mem.Allocator_Error,
	WRError,
}

GameLoopState :: enum {
	PLAYING,
	LOST,
}

EntityType :: enum {
	BulletBouncer,
	BulletConstructor,
	BulletBulldozer,
	Player,
}

Entity :: struct {
	position:      Vec2,
	direction:     Vec2,
	speed:         u32,
	size:          f32,
	type:          EntityType,
	should_remove: bool,
}

Wall :: struct {
	p1:            Vec2,
	p2:            Vec2,
	invulnerable:  bool,
	should_remove: bool,
}


BulletSpawner :: struct {
	pos:             Vec2,
	spawn_frequency: f32,
	velocity:        u32,
	bullet_type:     EntityType,
	last_spawn:      f32,
}


MapState :: struct {
	map_size:        Vec2i,
	wall_thickness:  u32,
	player_speed:    u32,
	walls:           [dynamic]Wall,
	bullet_spawners: [dynamic]BulletSpawner,
	entities:        [dynamic]Entity,
	player:          Entity,
	time_survived:   f32,
}

State :: struct {
	using mapState:  MapState,
	drop_down_open:  bool,
	game_loop_state: GameLoopState,
}

MapSelector :: struct {
	selected_map:   i32,
	open:           bool,
	maps_filenames: []string,
	maps_names:     [dynamic]string,
}

map_selector: MapSelector

map_selector_alloc: mem.Allocator
map_selector_arena: mem.Arena
map_selector_buffer: []byte


state_alloc: mem.Allocator
state_arena: mem.Arena
state_buffer: []byte

state: ^State

init_state_alloc :: proc() {
	err: Error
	state_buffer, err = make([]byte, 1024 * 1024 * 1024)
	if err != nil {
		panic("State Alloc failed")
	}
	mem.arena_init(&state_arena, state_buffer)
	state_alloc = mem.arena_allocator(&state_arena)
}

init_map_selector_alloc :: proc() {
	err: Error
	map_selector_buffer, err = make([]byte, 1024 * 1024)
	if err != nil {
		panic("Map Selector Alloc failed")
	}
	mem.arena_init(&map_selector_arena, map_selector_buffer)
	map_selector_alloc = mem.arena_allocator(&map_selector_arena)
}

load_map_selector :: proc() -> Error {
	free_all(map_selector_alloc) or_return

	map_selector.maps_filenames, _ = filepath.glob("maps/*", map_selector_alloc)
	map_selector.maps_names = make([dynamic]string, 0, map_selector_alloc) or_return
	for filename in map_selector.maps_filenames {
		map_name := filepath.stem(filename)
		append(&map_selector.maps_names, map_name) or_return
	}
	return nil
}

get_json_from_file :: proc(path: string) -> ([]byte, Error) {
	data, ok := os.read_entire_file_from_filename(path, allocator = context.temp_allocator)
	if !ok {
		return nil, WRError.Read_Error
	}
	return data, nil
}

load_state_from_json :: proc() -> Error {
	free_all(state_alloc)
	state = new(State, state_alloc)
	json_from_file := get_json_from_file(
		map_selector.maps_filenames[map_selector.selected_map],
	) or_return
	state.entities = make([dynamic]Entity, state_alloc)
	json.unmarshal(json_from_file, &state.mapState, allocator = state_alloc) or_return

	state.player.speed = state.player_speed
	state.player.size = 20
	state.player.type = .Player
	camera = raylib.Camera2D {
		offset   = raylib.Vector2{screen_size.x / 2, screen_size.y / 2},
		zoom     = screen_size.x / f32(state.map_size.x) - 0.1,
		target   = Vec2(0),
		rotation = 0,
	}
	return nil
}

write_state_to_file :: proc() -> (err: Error) {
	data := json.marshal(state.mapState, allocator = state_alloc) or_return
	w_success := os.write_entire_file("maps/last_save.json", data)
	if !w_success {return WRError.Write_Error}
	return nil
}
