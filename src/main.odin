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

	rl.InitWindow(i32(screen_size.x), i32(screen_size.y), "Game Title")
	rl.InitAudioDevice()
	rl.SetTargetFPS(60)
	rl.GuiLoadStyle("styles/style_cherry.rgs")
	run()
	rl.CloseAudioDevice()
	rl.CloseWindow()

	// write_state_to_file()
}
