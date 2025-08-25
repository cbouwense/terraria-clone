#import "Basic";
#import "Input";
#import "Math";
#import "Sloppy_Math";
#import "String";
#import "System";
#import "Window_Creation";
#import "GL";

Simp    :: #import "Simp"; 
Texture :: Simp.Texture;

window_width  := 1600;
window_height := 800;

// Metagame state
should_quit_game := false;
paused           := false;
debug_mode       := true;

current_dt : float = 0.016667;
last_time  : float64;
DT_MAX     : float : 0.15;
EPSILON   :: 0.0001;

// Controls
move_player_left  : bool;
move_player_right : bool;
try_to_jump       : bool;

// Texture maps
player_map : Texture;
dirt_map   : Texture;

PLAYER_MAP_COLS :: 1;
PLAYER_MAP_ROWS :: 26;
PLAYER_MAP_TILE_WIDTH    :: 36  ;
PLAYER_MAP_TILE_HEIGHT   :: 48;
PLAYER_TILE_WORLD_WIDTH  :: PLAYER_MAP_TILE_WIDTH  * 2;
PLAYER_TILE_WORLD_HEIGHT :: PLAYER_MAP_TILE_HEIGHT * 2;
// @TODO: Probably want to tie these to the window size or something
PLAYER_MOVE_SPEED :: PLAYER_TILE_WORLD_WIDTH * 5; // px / s
PLAYER_JUMP_SPEED :: PLAYER_TILE_WORLD_HEIGHT * 5; // px / s

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_TILE_WIDTH  :: 18;
DIRT_TILE_HEIGHT :: 18;

WORLD_TILE_WIDTH  :: 50;
WORLD_TILE_HEIGHT :: 50;

ACCEL_DUE_TO_GRAVITY :: 10; // px^2 / s

Rectangle :: struct {
    x      : int; // bottom-left corner position x 
    y      : int; // bottom-left corner position y 
    width  : int;
    height : int;
}

Entity :: struct {
    rect : Rectangle; // Used for collision
    vel  : Vector2;

    jumps_remaining : int;
    jumps_capacity  : int; // e.g. 2 if an entity can double jump, 6 for kirby in melee, etc.

    is_facing_left : bool;
}

Animation :: struct {
    active            : bool;
    frame_one_coords  : Vector2;
    frame_count       : u32;
    frame_duration_ms : u32;
    timer_ms          : u32;
}

Player :: struct {
    using #as entity : Entity;

    idle_animation   : Animation;
    walk_animation   : Animation;
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

    last_time = seconds_since_init();

    init_textures();
    
    player := Player.{
        rect = Rectangle.{100, 100, 65, 100},
        vel  = Vector2.{0, 0},

        jumps_capacity  = 2,
        jumps_remaining = 2,

        is_facing_left = true,

        // @TODO: kinda a dumb way to implement idling.
        idle_animation = Animation.{
            active            = true,
            frame_one_coords  = Vector2.{ 0, 0 }, 
            frame_count       = 1,
            frame_duration_ms = 100,
            timer_ms          = 0,
        },

        walk_animation = Animation.{
            active            = false,
            frame_one_coords  = Vector2.{ 1, 0 }, 
            frame_count       = 15,
            frame_duration_ms = 100,
            timer_ms          = 0,
        },
    };

    base_color   := Vector4.{1, 1, 1, 1};
    // @TODO: probably put this in the entity struct
    player_color, tile_color := base_color; 

    dirt_blocks: [50]Entity;
    for i: 0..49 {
        using dirt_blocks[i];

        rect = Rectangle.{
            x      = i * WORLD_TILE_WIDTH,
            y      = 0,
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

        // Reset controls that need to be.
        try_to_jump = false;

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

                if event.key_code == .F1 && event.key_pressed {
                    debug_mode = !debug_mode;
                }

                if event.type == .KEYBOARD {
                    key := event.key_code;

                    // @TODO: metaprogram this?
                    if keycode_array_contains(keybinds.move_player_left, key)  move_player_left  = event.key_pressed > 0;
                    if keycode_array_contains(keybinds.move_player_right, key) move_player_right = event.key_pressed > 0;
                    if keycode_array_contains(keybinds.jump, key)              try_to_jump       = event.key_pressed > 0;
                }
            }
        }

        //
        // Update
        //
        if !paused {
            // I think since we are always going to be controlling the player velocity directly, we can just reset
            // the velocity like this for now. Although, this will have to change if we ever want momentum.
            player.vel.x = 0;

            if move_player_left {
                player.vel.x -= PLAYER_MOVE_SPEED;
                player.is_facing_left = true;
            }
            if move_player_right {
                player.vel.x += PLAYER_MOVE_SPEED;
                player.is_facing_left = false;
            }

            if try_to_jump && can_jump(player) {
                player.vel.y = PLAYER_JUMP_SPEED;
                player.jumps_remaining -= 1;
            }

            // Apply gravity
            player.vel.y -= ACCEL_DUE_TO_GRAVITY;

            delta_pos := player.vel * current_dt;

            try_to_move_x(*player, delta_pos.x, dirt_blocks);
            try_to_move_y(*player, delta_pos.y, dirt_blocks);

            if is_grounded(player, dirt_blocks) {
                player.jumps_remaining = player.jumps_capacity;
                player.vel.y = 0;
            }

            // Update animation state
            {
                using player;

                active_animation := ifx idle_animation.active then idle_animation else walk_animation;

                idle_animation.active = move_player_left == move_player_right;
                walk_animation.active = move_player_left != move_player_right;
                
                if idle_animation.active then { idle_animation.timer_ms += xx (current_dt * 1000); } else { idle_animation.timer_ms = 0; }; 
                if walk_animation.active then { walk_animation.timer_ms += xx (current_dt * 1000); } else { walk_animation.timer_ms = 0; }; 
            }
        }

        //
        // Draw
        //
        {
            Simp.clear_render_target(.2, .3, .3, 1);

            // Draw tiles
            {

                // Dirt 
                for dirt_blocks {
                    Simp.set_shader_for_images(*dirt_map);
                    
                    uv0, uv1, uv2, uv3 := get_tile_uv_coords_by_id(Vector2.{0, 3}, *dirt_map, DIRT_TILE_WIDTH, DIRT_TILE_HEIGHT, Vector4.{2, 2, 0, 0});

                    // @TODO: function for this?
                    left   := cast(float)it.rect.x;
                    right  := cast(float)it.rect.x + it.rect.width;
                    top    := cast(float)it.rect.y + it.rect.height;
                    bottom := cast(float)it.rect.y + 0;

                    Simp.immediate_quad(
                        p0 = Vector2.{ left,  bottom },
                        p1 = Vector2.{ right, bottom },
                        p2 = Vector2.{ right, top    },
                        p3 = Vector2.{ left,  top    },
                        color = Vector4.{ 1, 1, 1, 1 },
                        uv0, uv1, uv2, uv3,
                    );

                    if debug_mode {
                        using it.rect;
                        draw_rect_outline(xx x, xx y, xx width, xx height, color = Vector4.{0,1,0,1});
                    }
                }
            }

            // Draw player
            {
                using player;

                active_animation : Animation = ifx idle_animation.active then idle_animation else walk_animation; 

                frame := (active_animation.timer_ms / active_animation.frame_duration_ms) % active_animation.frame_count;

                tile := Vector2.{ frame + active_animation.frame_one_coords.x, active_animation.frame_one_coords.y };
                uv0, uv1, uv2, uv3 := get_tile_uv_coords_by_id(tile, *player_map, PLAYER_MAP_TILE_WIDTH, PLAYER_MAP_TILE_HEIGHT, Vector4.{0, 0, 0, 0}, !player.is_facing_left);

                left   : float = xx (player.rect.x);
                right  : float = xx (player.rect.x + player.rect.width);
                top    : float = xx (player.rect.y + player.rect.height);
                bottom : float = xx (player.rect.y);

                Simp.set_shader_for_images(*player_map);
                Simp.immediate_quad(
                    p0 = Vector2.{ left,  bottom },
                    p1 = Vector2.{ right, bottom },
                    p2 = Vector2.{ right, top    },
                    p3 = Vector2.{ left,  top    },
                    color = Vector4.{ 1, 1, 1, 1 },
                    uv0, uv1, uv2, uv3,
                );

                if debug_mode {
                    using player.rect;
                    draw_rect_outline(xx x, xx y, xx width, xx height, color = Vector4.{0,1,0,1}, thickness = 2);
                }
            }

            // Draw UI
            // @TODO: Draw "paused"

            Simp.swap_buffers(window);
        }
    }
}

// @TODO: I wonder if I should factor these into a passable struct instead of globals
reset_controls :: () {
    move_player_left  = false;
    // move_player_right = false;
    try_to_jump       = false;
}

make_texture :: (name: string) -> Texture, bool {
    filename := tprint("%/%", data_folder, name);

    result: Texture;
    success := Simp.texture_load_from_file(*result, filename);

    return result, success;
}

init_textures :: () {
    player_map = make_texture("Player_Cropped.png");
    dirt_map   = make_texture("Tiles_0.png");
}

// Transparency margin pixels is Vector4.{ bottom, right, top, left }.
get_tile_uv_coords_by_id :: (tile_id: Vector2, map: *Texture, tile_width: s32, tile_height: s32, transparency_margin_pixels: Vector4, flip: bool = false) -> Vector2, Vector2, Vector2, Vector2 {
    tile_uv_width  := cast(float)tile_width  / map.width;
    tile_uv_height := cast(float)tile_height / map.height;

    left   := (tile_uv_width  * (ifx flip then tile_id.x + 1 else tile_id.x + 0 )) + (transparency_margin_pixels.w / map.width );
    right  := (tile_uv_width  * (ifx flip then tile_id.x + 0 else tile_id.x + 1 )) - (transparency_margin_pixels.y / map.width );
    bottom := (tile_uv_height * (ifx flip then tile_id.y + 0 else tile_id.y + 0 )) + (transparency_margin_pixels.x / map.height);
    top    := (tile_uv_height * (ifx flip then tile_id.y + 1 else tile_id.y + 1 )) - (transparency_margin_pixels.z / map.height);

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

round :: (f: float) -> int {
    i := cast(int)f;
    decimal_part := f - i;
    return ifx decimal_part >= 0.5 then i + 1 else i;
}

// @TODO: maybe dry up these move functions
try_to_move_x :: (entity: *Entity, distance: float, collidables: []Entity) {
    x_remainder := distance;
    move := round(distance);
    if (move == 0) return;

    x_remainder -= move;
    sign := ifx move > 0 then 1 else -1;
    while move != 0 {
        collided := false;
        new_entity_rect := entity.rect;
        new_entity_rect.x += sign;
        
        // @TODO: extract?
        for collidables {
            if check_collisions_rects(it.rect, new_entity_rect) {
                collided = true;
                break;
            }
        }

        if collided {
            break;
        } else {
            entity.rect.x += sign;
            move -= sign;
        }
    }
}

try_to_move_y :: (entity: *Entity, distance: float, collidables: []Entity) {
    y_remainder := distance;
    move := round(distance);
    if (move == 0) return;

    y_remainder -= move;
    sign := ifx move > 0 then 1 else -1;
    while move != 0 {
        collided := false;
        new_entity_rect := entity.rect;
        new_entity_rect.y += sign;
        
        // @TODO: extract?
        for collidables {
            if check_collisions_rects(it.rect, new_entity_rect) {
                collided = true;
                break;
            }
        }

        if collided {
            break;
        } else {
            entity.rect.y += sign;
            move -= sign;
        }
    }
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

draw_rect_frame :: (x: float, y: float, w: float, h: float, color := Vector4.{1,1,1,1}, thickness: float = 1.0) {
    p0 := Vector2.{ x-thickness/2     , y-thickness/2     };  // tl
    p1 := Vector2.{ x+thickness/2 + w , y-thickness/2     };  // tr
    p2 := Vector2.{ x-thickness/2     , y+thickness/2 + h };  // bl
    p3 := Vector2.{ x+thickness/2 + w , y+thickness/2 + h };  // br
    
    Simp.set_shader_for_color(true);
    
    Simp.immediate_line(p0-.{thickness/2, 0}, p1+.{thickness/2, 0}, thickness, color);  // top
    Simp.immediate_line(p2-.{thickness/2, 0}, p3+.{thickness/2, 0}, thickness, color);  // bottom
    Simp.immediate_line(p1, p3, thickness, color);  // right
    Simp.immediate_line(p2, p0, thickness, color);  // left
}

draw_rect_outline :: (x: float, y: float, w: float, h: float, color := Vector4.{1,1,1,1}, thickness: float = 1.0) {
    p0 := Vector2.{ x     , y     };  // tl
    p1 := Vector2.{ x + w , y     };  // tr
    p2 := Vector2.{ x     , y + h };  // bl
    p3 := Vector2.{ x + w , y + h };  // br
    
    Simp.set_shader_for_color(true);
    
    Simp.immediate_line(p0, p1, thickness, color);  // top
    Simp.immediate_line(p2, p3, thickness, color);  // bottom
    Simp.immediate_line(p1, p3, thickness, color);  // right
    Simp.immediate_line(p2, p0, thickness, color);  // left
}