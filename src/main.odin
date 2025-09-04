package main


import "core:fmt"
import "core:mem"
import rl "vendor:raylib"
screen_size := rl.Vector2{1000, 1000}


main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		if len(track.allocation_map) > 0 {
			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		mem.tracking_allocator_destroy(&track)
	}

	{ 	// Init Raylib
		rl.InitWindow(i32(screen_size.x), i32(screen_size.y), "Game Title")
		rl.InitAudioDevice()
		rl.SetTargetFPS(60)
		rl.GuiLoadStyle("styles/style_cherry.rgs")
	}

	{ 	// Init Allocators
		init_state_alloc()
		init_map_selector_alloc()
	}

	{ 	// Load State
		load_map_selector()
		load_state_from_json()
	}


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

	{ 	// Save Game
		save_err := write_state_to_file()
		if save_err != nil {
			fmt.println(save_err)
		}
	}

	{ 	// Cleanup
		delete(state_buffer)
		delete(map_selector_buffer)
		rl.CloseAudioDevice()
		rl.CloseWindow()
	}

}
