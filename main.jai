#import "Basic";
#import "Input";
#import "Math";
#import "String";
#import "System";
#import "Window_Creation";

Simp    :: #import "Simp"; 
Texture :: Simp.Texture;

window_width  := 800;
window_height := 600;

should_quit_game := false;

player_map: Texture;

player_position: Vector2;

data_folder: string; 

main :: () {
    //
    // Window setup
    //
    window := create_window(window_name="Terraria Clone", width=window_width, height=window_height);
    Simp.set_render_target(window);

    //
    // Initialization
    //
    base_path := path_strip_filename(get_path_of_running_executable());
    data_folder = join(base_path, "data");
    print("data_folder is '%'\n", data_folder);

    init_textures();
    player_position.x = .5;
    player_position.y = .05;
    player_color := Vector4.{1, 1, 1, 1};
    player_size  := Vector2.{50*2, 50*2};

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

        // Draw player
        Simp.set_shader_for_images(*player_map);
        Simp.immediate_quad(50, 100, 150, 200, player_color);

        Simp.swap_buffers(window);
    }
}

make_texture :: (name: string) -> Texture, bool {
    filename := tprint("%/%", data_folder, name);

    result: Texture;
    success := Simp.texture_load_from_file(*result, filename);

    return result, success;
}

init_textures :: () {
    player_map = make_texture("ship.png");
}