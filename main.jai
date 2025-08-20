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

DIRT_MAP_COLS        :: 16;
DIRT_MAP_ROWS        :: 15;
dirt_map             : Texture;
dirt_map_width       : s32;
dirt_map_height      : s32;
dirt_map_tile_width  : float;
dirt_map_tile_height : float;

WORLD_TILE_WIDTH  :: 50;
WORLD_TILE_HEIGHT :: 50;

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

        // Draw tiles
        Simp.set_shader_for_images(*dirt_map);
        dirt_map_tile_width  = DIRT_MAP_COLS / cast(float)dirt_map_width;
        dirt_map_tile_height = DIRT_MAP_ROWS / cast(float)dirt_map_height;

        for col: 0..10 { 
            for row: 0..10 {
                Simp.immediate_quad(
                    p0    = Vector2.{ cast(float)(col + 0) * WORLD_TILE_WIDTH, cast(float)(row + 0) * WORLD_TILE_HEIGHT },
                    p1    = Vector2.{ cast(float)(col + 1) * WORLD_TILE_WIDTH, cast(float)(row + 0) * WORLD_TILE_HEIGHT },
                    p2    = Vector2.{ cast(float)(col + 1) * WORLD_TILE_WIDTH, cast(float)(row + 1) * WORLD_TILE_HEIGHT },
                    p3    = Vector2.{ cast(float)(col + 0) * WORLD_TILE_WIDTH, cast(float)(row + 1) * WORLD_TILE_HEIGHT },
                    color = Vector4.{ 1, 1, 1, 1 },
                    uv0   = Vector2.{ 0, 0 },

                    uv1   = Vector2.{ dirt_map_tile_width, 0 },
                    uv2   = Vector2.{ dirt_map_tile_width, dirt_map_tile_height },
                    uv3   = Vector2.{ 0, dirt_map_tile_height }
                );
            }
        }

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
    dirt_map   = make_texture("tiles_0.png");

    print("dirt_map.width: %", dirt_map.width);
    print("dirt_map.height: %", dirt_map.height);

    dirt_map_width  = dirt_map.width;
    dirt_map_height = dirt_map.height;
}
