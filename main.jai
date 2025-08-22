#import "Basic";
#import "Input";
#import "Math";
#import "String";
#import "System";
#import "Window_Creation";

Simp    :: #import "Simp"; 
Texture :: Simp.Texture;

window_width  := 1600;
window_height := 800;

should_quit_game := false;
paused           := false;

current_dt : float = 0.016667;
last_time  : float64;
DT_MAX     : float : 0.15;

move_player_left  : u32;
move_player_right : u32;
move_player_down  : u32;
move_player_up    : u32;

player_map : Texture;
dirt_map   : Texture;

PLAYER_MAP_COLS :: 1;
PLAYER_MAP_ROWS :: 26;
PLAYER_MAP_TILE_WIDTH  :: 40;
PLAYER_MAP_TILE_HEIGHT :: 56;
PLAYER_TILE_WORLD_WIDTH  :: 40 * 2;
PLAYER_TILE_WORLD_HEIGHT :: 56 * 2;
PLAYER_MOVE_SPEED :: 200; // @TODO: Probably want to tie this to the window size or something

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_TILE_TEXEL_WIDTH  :: 18;
DIRT_TILE_TEXEL_HEIGHT :: 18;

WORLD_TILE_WIDTH  :: 50;
WORLD_TILE_HEIGHT :: 50;

Player :: struct {
    pos: Vector2;
}

Keybinds :: struct {
    // @TODO: can I have an arbitrary length array as a member?
    move_player_left  : [2] Key_Code;
    move_player_right : [2] Key_Code;
    move_player_down  : [2] Key_Code;
    move_player_up    : [2] Key_Code;
}

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

    last_time = seconds_since_init();

    init_textures();
    
    player := Player.{
        pos = Vector2.{100, 100},
    };
    base_color   := Vector4.{1, 1, 1, 1};
    player_color, tile_color := base_color; 

    keybinds : Keybinds;
    
    keybinds.move_player_left  = .[.ARROW_LEFT , #char "A"];
    keybinds.move_player_right = .[.ARROW_RIGHT, #char "D"];
    keybinds.move_player_down  = .[.ARROW_DOWN , #char "S"];
    keybinds.move_player_up    = .[.ARROW_UP   , #char "W"];

    while !should_quit_game {
        //
        // Input
        //
        {
            reset_temporary_storage();

            update_window_events();
            for get_window_resizes() {
                Simp.update_window(it.window);

                if it.window == window {
                    window_width  = it.width;
                    window_height = it.height;
                }
            }

            now := seconds_since_init();
            delta : float64 = now - last_time;
            current_dt = cast(float) delta;

            if current_dt > DT_MAX current_dt = DT_MAX;

            last_time = now;

            for event : events_this_frame {
                if event.type == .QUIT {
                    should_quit_game = true;
                    break;
                }

                if event.key_code == .ESCAPE && event.key_pressed {
                    should_quit_game = true;
                    break;
                }

                if event.key_code == .SPACEBAR && event.key_pressed {
                    paused = true;
                }

                if event.type == .KEYBOARD {
                    key := event.key_code;

                    // @TODO: metaprogram this?
                    if keycode_array_contains(keybinds.move_player_left, key)  move_player_left  = event.key_pressed;
                    if keycode_array_contains(keybinds.move_player_right, key) move_player_right = event.key_pressed;
                    if keycode_array_contains(keybinds.move_player_down, key)  move_player_down  = event.key_pressed;
                    if keycode_array_contains(keybinds.move_player_up, key)    move_player_up    = event.key_pressed;
                }
            }

            dx: Vector2;

            if move_player_up    dx.y += 1;
            if move_player_left  dx.x -= 1;
            if move_player_down  dx.y -= 1;
            if move_player_right dx.x += 1;
            
            // Normalize, so that you don't move faster diagonally!
            if length(dx) > 1 {
                dx = unit_vector(dx);
            }

            player.pos += dx * PLAYER_MOVE_SPEED * current_dt;
        }


        //
        // Draw
        //
        Simp.clear_render_target(.2, .3, .3, 1);

        // Draw tiles
        {
            Simp.set_shader_for_images(*dirt_map);

            // Dirt 
            // TODO: Randomly select from set of tiles
            for col: 0..50 {
                uv0, uv1, uv2, uv3 := get_tile_uv_coords_by_id(Vector2.{0, 3}, *dirt_map, DIRT_TILE_TEXEL_WIDTH, DIRT_TILE_TEXEL_HEIGHT, Vector4.{2, 2, 0, 0});

                left   : float = cast(float)(col * WORLD_TILE_WIDTH); 
                right  : float = cast(float)((col + 1) * WORLD_TILE_WIDTH);
                top    : float = cast(float)WORLD_TILE_HEIGHT;
                bottom : float = 0;

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
        {
            uv0, uv1, uv2, uv3 := get_tile_uv_coords_by_id(Vector2.{0, 25}, *player_map, PLAYER_MAP_TILE_WIDTH, PLAYER_MAP_TILE_HEIGHT, Vector4.{0, 0, 0, 0});

            left   : float = player.pos.x;
            right  : float = player.pos.x + PLAYER_TILE_WORLD_WIDTH;
            top    : float = player.pos.y + PLAYER_TILE_WORLD_HEIGHT;
            bottom : float = player.pos.y;

            Simp.set_shader_for_images(*player_map);
            Simp.immediate_quad(
                p0 = Vector2.{ left,  bottom },
                p1 = Vector2.{ right, bottom },
                p2 = Vector2.{ right, top    },
                p3 = Vector2.{ left,  top    },
                color = Vector4.{ 1, 1, 1, 1 },
                uv0, uv1, uv2, uv3,
            );
        }

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
    player_map = make_texture("Player_Default.png");
    dirt_map   = make_texture("Tiles_0.png");
}

// Transparency margin texels is Vector4.{ bottom, right, top, left }.
get_tile_uv_coords_by_id :: (tile_id: Vector2, map: *Texture, tile_texel_width: s32, tile_texel_height: s32, transparency_margin_texels: Vector4) -> Vector2, Vector2, Vector2, Vector2 {
    tile_uv_width  := cast(float)tile_texel_width  / map.width;
    tile_uv_height := cast(float)tile_texel_height / map.height;

    left   := (tile_uv_width  * (tile_id.x + 0)) + (transparency_margin_texels.w / map.width );
    right  := (tile_uv_width  * (tile_id.x + 1)) - (transparency_margin_texels.y / map.width );
    bottom := (tile_uv_height * (tile_id.y + 0)) + (transparency_margin_texels.x / map.height);
    top    := (tile_uv_height * (tile_id.y + 1)) - (transparency_margin_texels.z / map.height);

    uv0 := Vector2.{ left,  bottom };
    uv1 := Vector2.{ right, bottom };
    uv2 := Vector2.{ right, top    };
    uv3 := Vector2.{ left,  top    };

    return uv0, uv1, uv2, uv3;
}

// @TODO: does this exist already?
// @TODO: probably use generics here.
keycode_array_contains :: (haystack: [] Key_Code, needle: Key_Code) -> bool {
    for haystack {
        if it == needle return true;
    }
    return false;
} 