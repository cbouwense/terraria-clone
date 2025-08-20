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

        // There is one pixel-art pixel (which I'm calling a "UV pixel") of transparency to the right of each tile for
        // the dirt tiles. So, we actually don't want the uv coords going all the way to the right and bottom of the
        // tile solely based on, say, the column count divided by the entire map width. We need it to go one uv pixel
        // less than that. So, here we define how wide that is so we can later subtract it from  the right and bottom
        // uv coords.
        //
        // There are 9 uv pixels to each dirt tile, only 8 of which are part of each tile per row and column. So, the
        // length of a uv pixel for a dirt tile is 1/9th of the width or height. Let's use the width.
        DIRT_TILE_UV_PIXEL_COUNT :: 9; // name this magic number just to be thorough, even though it's explained. 
        uv_pixel_length := dirt_map_tile_width / DIRT_TILE_UV_PIXEL_COUNT;

        // The "art width" is the area of the tile that is non-spacing transparency. In other words, the tile area minus
        // the transparency between each tile.
        dirt_map_tile_art_width  := dirt_map_tile_width  - uv_pixel_length;
        dirt_map_tile_art_height := dirt_map_tile_height + uv_pixel_length;

        for col: 0..100 { 
            for row: 0..10 {
                // tile_map := ifx row == 10 

                Simp.immediate_quad(
                    p0    = Vector2.{ cast(float)(col + 0) * WORLD_TILE_WIDTH, cast(float)(row + 0) * WORLD_TILE_HEIGHT },
                    p1    = Vector2.{ cast(float)(col + 1) * WORLD_TILE_WIDTH, cast(float)(row + 0) * WORLD_TILE_HEIGHT },
                    p2    = Vector2.{ cast(float)(col + 1) * WORLD_TILE_WIDTH, cast(float)(row + 1) * WORLD_TILE_HEIGHT },
                    p3    = Vector2.{ cast(float)(col + 0) * WORLD_TILE_WIDTH, cast(float)(row + 1) * WORLD_TILE_HEIGHT },
                    color = Vector4.{ 1, 1, 1, 1 },
                    uv0   = Vector2.{                       0, uv_pixel_length },          // Since the uv coordinates start from the bottom of the texture like 
                    uv1   = Vector2.{ dirt_map_tile_art_width, uv_pixel_length },          // a middle school algebra plot, we actually have to bump up the v coord
                    uv2   = Vector2.{ dirt_map_tile_art_width, dirt_map_tile_art_height }, // by the uv_pixel_length to remove the bottom transparency.
                    uv3   = Vector2.{                       0, dirt_map_tile_art_height }
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
