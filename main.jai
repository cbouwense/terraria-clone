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

player_map : Texture;
tile_map   : Texture;

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
    base_color   := Vector4.{1, 1, 1, 1};
    player_color, tile_color := base_color; 
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

        // Draw some tiles
        Simp.set_shader_for_images(*tile_map);
        // TODO: Do some math to figure out the actual UV coordinates.
        Simp.immediate_quad(
            p0=Vector2.{50, 50}, p1=Vector2.{100, 50}, p2=Vector2.{100, 100}, p3=Vector2.{50, 100},
            color=Vector4.{1,1,1,1},
            uv0=Vector2.{0, 0}, uv1=Vector2.{0.05, 0}, uv2=Vector2.{0.05, 0.05}, uv3=Vector2.{0, 0.05}
        );

        // Draw player
        // Simp.set_shader_for_images(*player_map);
        // Simp.immediate_quad(Vector2.{50, 100}, 150, 200, player_color);

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
    tile_map   = make_texture("tiles_0.png");
}
