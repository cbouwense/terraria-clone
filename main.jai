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
dirt_map   : Texture;

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_TILE_TEXEL_WIDTH  :: 18;
DIRT_TILE_TEXEL_HEIGHT :: 18;

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

        for col: 0..50 { 
            for row: 0..5 {
                uv0, uv1, uv2, uv3 := get_tile_uv_coords_by_id(Vector2.{0, 5}, *dirt_map, DIRT_TILE_TEXEL_WIDTH, DIRT_TILE_TEXEL_HEIGHT, Vector4.{2, 2, 0, 0});

                left   := cast(float)((col + 0) * WORLD_TILE_WIDTH ); 
                right  := cast(float)((col + 1) * WORLD_TILE_WIDTH );
                top    := cast(float)((row + 1) * WORLD_TILE_HEIGHT);
                bottom := cast(float)((row + 0) * WORLD_TILE_HEIGHT);  

                Simp.immediate_quad(
                    p0 = Vector2.{ left,  bottom },
                    p1 = Vector2.{ right, bottom },
                    p2 = Vector2.{ right, top    },
                    p3 = Vector2.{ left,  top    },
                    color = Vector4.{ 1, 1, 1, 1 },
                    uv0, uv1, uv2, uv3,
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
    dirt_map   = make_texture("Tiles_0.png");
}

// Transparency margin texels is Vector4.{ bottom, right, top, left }.
get_tile_uv_coords_by_id :: (tile_id: Vector2, map: *Texture, tile_texel_width: s32, tile_texel_height: s32, transparency_margin_texels: Vector4) -> Vector2, Vector2, Vector2, Vector2 {
    tile_uv_width  := cast(float)tile_texel_width  / map.width;
    tile_uv_height := cast(float)tile_texel_height / map.height;

    left   := (tile_uv_width  * (tile_id.x + 0)) - (transparency_margin_texels.w / map.width );
    right  := (tile_uv_width  * (tile_id.x + 1)) - (transparency_margin_texels.y / map.width );
    bottom := (tile_uv_height * (tile_id.y + 0)) + (transparency_margin_texels.x / map.height);
    top    := (tile_uv_height * (tile_id.y + 1)) + (transparency_margin_texels.z / map.height);

    uv0 := Vector2.{ left,  bottom };
    uv1 := Vector2.{ right, bottom };
    uv2 := Vector2.{ right, top    };
    uv3 := Vector2.{ left,  top    };

    return uv0, uv1, uv2, uv3;
}
