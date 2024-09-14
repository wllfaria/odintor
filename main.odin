package main

import "core:flags"
import "core:fmt"
import "core:mem"
import "core:os"
import "editor"

Options :: struct {
	file: string `args:"pos=0", usage:"something"`,
}

parse_args :: proc(args: []string) -> Options {
	options: Options
	flags.parse(&options, args)
	return options
}

main :: proc() {
	when ODIN_DEBUG {
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
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
		}
	}

	editor.setup_terminal()
	defer editor.reset_terminal()

	options := parse_args(os.args[1:])
	editor.with_file(options.file)
	defer editor.drop()

	editor.run()
}
