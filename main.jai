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

// @TODO: why are these u32s?...
move_player_left  : u32;
move_player_right : u32;
try_to_jump       : u32;

player_map : Texture;
dirt_map   : Texture;

PLAYER_MAP_COLS :: 1;
PLAYER_MAP_ROWS :: 26;
PLAYER_MAP_TILE_WIDTH  :: 40;
PLAYER_MAP_TILE_HEIGHT :: 56;
PLAYER_TILE_WORLD_WIDTH  :: 40 * 2;
PLAYER_TILE_WORLD_HEIGHT :: 56 * 2;
PLAYER_MOVE_SPEED :: 200; // @TODO: Probably want to tie this to the window size or something
PLAYER_JUMP_SPEED :: 300; // @TODO: Probably want to tie this to the window size or something

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_TILE_TEXEL_WIDTH  :: 18;
DIRT_TILE_TEXEL_HEIGHT :: 18;

WORLD_TILE_WIDTH  :: 50;
WORLD_TILE_HEIGHT :: 50;

ACCEL_DUE_TO_GRAVITY :: 5; // m^2 / s

Rectangle :: struct {
    x      : float; // bottom-left corner position x 
    y      : float; // bottom-left corner position y 
    width  : float;
    height : float;
}

Entity :: struct {
    rect : Rectangle; // Used for collision
    vel  : Vector2;

    jumps_remaining : int;
    jumps_capacity  : int; // e.g. 2 if an entity can double jump, 6 for kirby in melee, etc.
}

Keybinds :: struct {
    move_player_left  : [2] Key_Code;
    move_player_right : [2] Key_Code;
    jump              : [2] Key_Code;
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
    
    player := Entity.{
        rect = Rectangle.{100, 100, 65, 100},
        vel  = Vector2.{0, 0},

        jumps_capacity  = 2,
        jumps_remaining = 2,
    };
    base_color   := Vector4.{1, 1, 1, 1};
    player_color, tile_color := base_color; 

    dirt_blocks: [50]Entity;
    for i: 0..49 {
        using dirt_blocks[i];

        rect = Rectangle.{
            x = cast(float)i * WORLD_TILE_WIDTH,
            y = 0,
            width  = WORLD_TILE_WIDTH,
            height = WORLD_TILE_HEIGHT,
        };
    }

    keybinds : Keybinds;
    
    keybinds.move_player_left  = .[.ARROW_LEFT , #char "A"];
    keybinds.move_player_right = .[.ARROW_RIGHT, #char "D"];
    keybinds.jump              = .[.SPACEBAR   , .SPACEBAR]; // @TODO: can I pass null here or something? or even better, arbitrarily sized arrays

    while !should_quit_game {
        reset_temporary_storage();

        try_to_jump = 0;

        //
        // Input
        //
        {
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

                if event.key_code == #char "P" && event.key_pressed {
                    paused = !paused;
                }

                if event.type == .KEYBOARD {
                    key := event.key_code;

                    // @TODO: metaprogram this?
                    if keycode_array_contains(keybinds.move_player_left, key)  move_player_left  = event.key_pressed;
                    if keycode_array_contains(keybinds.move_player_right, key) move_player_right = event.key_pressed;
                    if keycode_array_contains(keybinds.jump, key)              try_to_jump       = event.key_pressed;
                }
            }
        }

        //
        // Update
        //
        if !paused {
            print("jumps: %\n", player.jumps_remaining);
            // I think since we are always going to be controlling the player velocity directly, we can just reset
            // the velocity like this for now. Although, this will have to change if we ever want momentum.
            player.vel.x = 0;

            if move_player_left {
                player.vel.x -= PLAYER_MOVE_SPEED;
            }
            if move_player_right {
                player.vel.x += PLAYER_MOVE_SPEED;
            }
            if try_to_jump && can_jump(player) {
                player.vel.y = PLAYER_JUMP_SPEED;
                player.jumps_remaining -= 1;
            }
            player.vel.y -= ACCEL_DUE_TO_GRAVITY;

            // Normalize, so that you don't move faster diagonally!
            // if length(player.vel) > 1 {
            //     player.vel = unit_vector(player.vel);
            // }
            // Stretch to actual length we want to move.
            delta_pos := player.vel * current_dt;

            try_to_move(*player, delta_pos, dirt_blocks);

            if is_grounded(player, dirt_blocks) {
                player.jumps_remaining = player.jumps_capacity;
                player.vel.y = 0;
            }
        }

        //
        // Draw
        //
        {
            Simp.clear_render_target(.2, .3, .3, 1);

            // Draw tiles
            {
                Simp.set_shader_for_images(*dirt_map);

                // Dirt 
                for dirt_blocks {
                    uv0, uv1, uv2, uv3 := get_tile_uv_coords_by_id(Vector2.{0, 3}, *dirt_map, DIRT_TILE_TEXEL_WIDTH, DIRT_TILE_TEXEL_HEIGHT, Vector4.{2, 2, 0, 0});

                    // @TODO: function for this?
                    left   : float = it.rect.x;
                    right  : float = it.rect.x + it.rect.width;
                    top    : float = it.rect.y + it.rect.height;
                    bottom : float = it.rect.y + 0;

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

                left   : float = player.rect.x;
                right  : float = player.rect.x + player.rect.width;
                top    : float = player.rect.y + player.rect.height;
                bottom : float = player.rect.y;

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

            // Draw UI
            // @TODO: Draw "paused"

            Simp.swap_buffers(window);
        }
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

// @TODO: probably use generics here.
keycode_array_contains :: (haystack: [] Key_Code, needle: Key_Code) -> bool {
    for haystack {
        if it == needle return true;
    }
    return false;
}

check_collisions_rects :: (rect1: Rectangle, rect2: Rectangle) -> bool {
    collision := false;

    if ((rect1.x < (rect2.x + rect2.width) && (rect1.x + rect1.width) > rect2.x) &&
        (rect1.y < (rect2.y + rect2.height) && (rect1.y + rect1.height) > rect2.y)) collision = true;

    return collision;
}

// @TODO: generics?
sign :: (n: float) -> float {
    if (n > 0) return 1;
    if (n < 0) return -1;
    return 0;
}

// Returns whether or not the entity collided with something in each dimension
try_to_move :: (entity: *Entity, delta: Vector2, collidables: []Entity) -> bool, bool {
    STEPS :: 10;
    
    x_remaining_steps := STEPS;
    y_remaining_steps := STEPS;

    x_collided := false;
    y_collided := false;

    if (x_remaining_steps == 0 && y_remaining_steps == 0) return x_collided, y_collided;

    x_epsilon := delta.x / STEPS;
    y_epsilon := delta.y / STEPS;

    // @PERF: looping through all collidable things seems like it'll probably be super slow
    while x_remaining_steps > 0 || y_remaining_steps > 0 {
        // Try to move in the x direction first
        {
            entity_rect_if_move := entity.rect;
            entity_rect_if_move.x += x_epsilon;

            for collidables {
                if check_collisions_rects(it.rect, entity_rect_if_move) {
                    x_collided = true;
                }
            }

            if x_collided {
                x_remaining_steps = 0;
            } else {
                entity.rect.x += x_epsilon;
                x_remaining_steps -= 1;
            }
        }

        // Then try to move in the y direction
        {
            entity_rect_if_move := entity.rect;
            entity_rect_if_move.y += y_epsilon;

            for collidables {
                if check_collisions_rects(it.rect, entity_rect_if_move) {
                    y_collided = true;
                }
            }

            if y_collided {
                y_remaining_steps = 0;
            } else {
                entity.rect.y += y_epsilon;
                y_remaining_steps -= 1;
            }
        }
    }

    return x_collided, y_collided;
}

can_jump :: (entity: Entity) -> bool {
    return entity.jumps_remaining > 0;
}

is_grounded :: (entity: Entity, collidables: []Entity) -> bool {
    entity_rect_if_move := entity.rect;
    entity_rect_if_move.y -= 1;

    for collidables {
        if check_collisions_rects(it.rect, entity_rect_if_move) {
            return true;
        }
    }

    return false;
}