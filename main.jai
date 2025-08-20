#import "Basic";
#import "Input";
#import "Window_Creation";
Simp :: #import "Simp"; 

window_width  := 800;
window_height := 600;

should_quit_game := false;

main :: () {
    window := create_window(window_name="Terraria Clone", width=window_width, height=window_height);
    Simp.set_render_target(window);

    while !should_quit_game {
        //
        // Input
        //
        reset_temporary_storage();
        update_window_events();
        for get_window_resizes() {
            Simp.update_window(it.window);

            if it.window == window {
                should_reinit := (it.width != window_width) || (it.height != window_height);

                window_width  = it.width;
                window_height = it.height;
            }
        }

        for event : events_this_frame {
            if event.type == .QUIT {
                should_quit_game = true;
                break;
            }

            if event.key_code == .ESCAPE && event.key_pressed {
                should_quit_game = true;
                break;
            }
        }

        //
        // Draw
        //
        Simp.clear_render_target(.2, .3, .3, 1);
        Simp.swap_buffers(window);
    }
}