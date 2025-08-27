#import "Basic";
#import "Input";
#import "Math";
#import "Print_Vars";
#import "String";
#import "System";

#import "raylib";

window_width  := 1600;
window_height := 800;

// Metagame state
should_quit_game := false;
paused           := false;
debug_mode       := true;

// Controls
move_player_left  : bool;
move_player_right : bool;
try_to_jump       : bool;
try_to_attack     : bool;

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

ACCEL_DUE_TO_GRAVITY :: 20; // px^2 / s

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_TILE_WIDTH  :: 18;
DIRT_TILE_HEIGHT :: 18;

WORLD_WIDTH  :: 5000;
WORLD_HEIGHT :: 5000;
WORLD_TILE_WIDTH  :: 50;
WORLD_TILE_HEIGHT :: 50;
WORLD_GRID_COLS :: 100;
WORLD_GRID_ROWS :: 100;

Entity :: struct {
    id : u32;

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
    run_animation   : Animation;
}

Control :: struct {
    type:  Type;
    value: s32; // KeyboardKey | MouseButton;
}

Controls :: struct {
    move_player_left  : [3] Control;
    move_player_right : [3] Control;
    jump              : [3] Control;
    attack            : [3] Control;
}

data_folder: string; 

main :: () {
    //
    // Window setup
    //
    InitWindow(1600, 900, "Terraria Clone");
    defer CloseWindow();
    SetTargetFPS(60);

    //
    // Initialization
    //
    base_path := path_strip_filename(get_path_of_running_executable());
    data_folder = join(base_path, "data");

    init_textures();

    // @TODO: is this a good idea?
    global_id_counter : u32 = 0;
    
    player := Player.{
        id = global_id_counter,

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

        run_animation = Animation.{
            active            = false,
            frame_one_coords  = Vector2.{ 2, 0 }, 
            frame_count       = 14,
            frame_duration_ms = 33,
            timer_ms          = 0,
        },
    };
    global_id_counter += 1;

    INITIAL_DIRT_BLOCK_COUNT :: 100;
    dirt_blocks: [..]Entity;
    for i: 0..INITIAL_DIRT_BLOCK_COUNT-1 {
        array_add(*dirt_blocks, Entity.{
            id = global_id_counter,

            rect = Rectangle.{
                x      = (i * WORLD_TILE_WIDTH) - WORLD_WIDTH/2.0,
                y      = xx (GetScreenHeight() - WORLD_TILE_HEIGHT),
                width  = xx (WORLD_TILE_WIDTH),
                height = xx (WORLD_TILE_HEIGHT),
            },
        });
        global_id_counter += 1;
    }

    camera: Camera2D;
    camera.target = Vector2.{ player.rect.x, player.rect.y };
    camera.offset = Vector2.{ GetScreenWidth()/2.0, GetScreenHeight()/2.0 };
    camera.rotation = 0.0;
    camera.zoom = 1.0;

    // @TODO: would a different data structure work better here for perf?
    controls : Controls;
    controls.move_player_left[0]  = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_LEFT)  };
    controls.move_player_left[1]  = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_A)     };
    controls.move_player_right[0] = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_RIGHT) };
    controls.move_player_right[1] = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_D)     };
    controls.jump[0]              = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_SPACE) };
    controls.attack[0]            = Control.{ type = MouseButton, value = (cast(s32) MouseButton.MOUSE_BUTTON_LEFT) };

    while !WindowShouldClose() {
        reset_temporary_storage();

        dt := GetFrameTime();
        mouse_pos_in_world := GetScreenToWorld2D(GetMousePosition(), camera);

        // Reset controls that need to be.
        try_to_jump   = false;
        try_to_attack = false;

        //
        // Input
        //
        {
            if IsKeyPressed(.KEY_P)  paused = !paused;
            if IsKeyPressed(.KEY_F1) debug_mode = !debug_mode;

            move_player_left  = control_down(controls.move_player_left);
            move_player_right = control_down(controls.move_player_right);
            try_to_jump       = control_pressed(controls.jump);
            try_to_attack     = control_pressed(controls.attack);
        }

        //
        // Update
        //
        if !paused {
            // Update player
            {
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
                    player.vel.y = -PLAYER_JUMP_SPEED;
                    player.jumps_remaining -= 1;
                }

                // @TODO: we'll want this to be on the player to actually be like terraria 
                // if try_to_attack && can_attack(player) {

                // }

                // Apply gravity
                player.vel.y += ACCEL_DUE_TO_GRAVITY;

                delta_pos := player.vel * dt;

                try_to_move_x(*player, delta_pos.x, dirt_blocks);
                try_to_move_y(*player, delta_pos.y, dirt_blocks);

                if is_grounded(player, dirt_blocks) {
                    player.jumps_remaining = player.jumps_capacity;
                    player.vel.y = 0;
                }

                // Update animation state
                {
                    using player;

                    idle_animation.active = move_player_left == move_player_right;
                    run_animation.active = move_player_left != move_player_right;
                    
                    if idle_animation.active { idle_animation.timer_ms += xx (dt * 1000); } else { idle_animation.timer_ms = 0; }; 
                    if run_animation.active { run_animation.timer_ms += xx (dt * 1000); } else { run_animation.timer_ms = 0; }; 
                }
            }

            // Update camera
            {
                camera.zoom += (cast(float)GetMouseWheelMove()*0.05);

                if camera.zoom > 3.0 camera.zoom = 3.0;
                else if camera.zoom < 0.25 camera.zoom = 0.25;

                update_camera_center(*camera, *player, GetScreenWidth(), GetScreenHeight());
                // update_camera_center_smooth_follow(*camera, *player, dt, GetScreenWidth(), GetScreenHeight());
            }

            // Update god mode
            {
                if try_to_attack {
                    for dirt_blocks {
                        if CheckCollisionPointRec(mouse_pos_in_world, it.rect) {
                            array_unordered_remove_by_index(*dirt_blocks, it_index);
                        }
                    }
                }
            }
        }

        //
        // Draw
        //
        {
            BeginDrawing();
            defer EndDrawing();

            ClearBackground(SKYBLUE);

            // Draw world
            {
                BeginMode2D(camera);
                defer EndMode2D();

                if debug_mode {
                    WORLD_COL_WIDTH  :: WORLD_WIDTH  / WORLD_GRID_COLS;
                    WORLD_COL_HEIGHT :: WORLD_HEIGHT / WORLD_GRID_ROWS;

                    for c: 0..WORLD_GRID_COLS {
                        col := (c * WORLD_COL_WIDTH) - WORLD_WIDTH/2.0;
                        DrawLineEx(Vector2.{ col, xx -WORLD_HEIGHT }, Vector2.{ col, xx WORLD_HEIGHT }, 1.0, WHITE);
                    }

                    for r: 0..WORLD_GRID_ROWS {
                        row := (r * WORLD_COL_HEIGHT) - WORLD_HEIGHT/2.0;
                        DrawLineEx(Vector2.{ xx -WORLD_WIDTH, row }, Vector2.{ xx WORLD_WIDTH, row }, 1.0, WHITE);
                    }
                }

                // Draw dirt
                {
                    for dirt_blocks {
                        DIRT_TILE_PADDING :: 2;
                        source := Rectangle.{0, 5 * DIRT_TILE_HEIGHT, DIRT_TILE_WIDTH - DIRT_TILE_PADDING, DIRT_TILE_HEIGHT - DIRT_TILE_PADDING};

                        DrawTexturePro(dirt_map, source, it.rect, Vector2.{ 0, 0 }, 0.0, Color.{ 255, 255, 255, 255 });

                        if CheckCollisionPointRec(mouse_pos_in_world, it.rect) {
                            TRANSPARENT_WHITE := Color.{ WHITE.r, WHITE.b, WHITE.a, 100 };
                            DrawRectangleRec(it.rect, TRANSPARENT_WHITE);
                        }

                        if debug_mode {
                            DrawRectangleLinesEx(it.rect, 1.0, LIME);
                        }
                    }
                }

                // Draw player
                {
                    using player;

                    active_animation : Animation = ifx idle_animation.active then idle_animation else run_animation; 

                    frame := (active_animation.timer_ms / active_animation.frame_duration_ms) % active_animation.frame_count;

                    tile := Vector2.{ frame + active_animation.frame_one_coords.x, active_animation.frame_one_coords.y };

                    source_width : float = xx ifx is_facing_left then PLAYER_MAP_TILE_WIDTH else -PLAYER_MAP_TILE_WIDTH;
                    source := Rectangle.{tile.x * PLAYER_MAP_TILE_WIDTH, tile.y * PLAYER_MAP_TILE_HEIGHT, source_width, PLAYER_MAP_TILE_HEIGHT};
                    DrawTexturePro(player_map, source, rect, Vector2.{ 0, 0 }, 0.0, Color.{ 255, 255, 255, 255 });

                    if debug_mode {
                        DrawRectangleLinesEx(player.rect, 1.0, LIME);
                    }
                }
            }

            // Draw UI
            {
                // @TODO: Draw "paused"
                if debug_mode {
                    DrawFPS(10, 10);
                }

                if paused {

                }
            }
        }
    }
}

init_textures :: () {
    // @TODO: factor out data path?
    player_map = LoadTexture("data/Player_Cropped.png");
    dirt_map   = LoadTexture("data/Tiles_0.png");
}

control_down :: (haystack: [] Control) -> bool {
    for haystack {
        if it.type == KeyboardKey && IsKeyDown(xx it.value) return true;
        if it.type == MouseButton && IsMouseButtonDown(xx it.value) return true;
    }

    return false;
}

control_pressed :: (haystack: [] Control) -> bool {
    for haystack {
        if it.type == KeyboardKey && IsKeyPressed(xx it.value) return true;
        if it.type == MouseButton && IsMouseButtonPressed(xx it.value) return true;
    }

    return false;
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
            if CheckCollisionRecs(it.rect, new_entity_rect) {
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
            if CheckCollisionRecs(it.rect, new_entity_rect) {
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
    entity_rect_if_move.y += 1;

    for collidables {
        if CheckCollisionRecs(it.rect, entity_rect_if_move) return true;
    }

    return false;
}

update_camera_center :: (camera: *Camera2D, player: *Player, width: s32, height: s32) {
    camera.offset = Vector2.{ width/2.0 - player.rect.width/2.0, height/2.0 - player.rect.height/2.0 };
    camera.target = entity_pos(player);
}

update_camera_center_smooth_follow :: (camera: *Camera2D, player: *Player, delta: float, width: s32, height: s32) {
    minSpeed: float = 100;
    minEffectLength: float = 1;
    fractionSpeed: float = 1.5;

    camera.offset = Vector2.{ width/2.0, height/2.0 };
    diff: Vector2 = Vector2Subtract(Vector2.{player.rect.x,player.rect.y}, camera.target);
    length: float = Vector2Length(diff);

    if (length > minEffectLength) {
        speed: float = max(fractionSpeed*length, minSpeed);
        camera.target = Vector2Add(camera.target, Vector2Scale(diff, speed*delta/length));
    }
}

entity_pos :: (e: Entity) -> Vector2 {
    return Vector2.{ e.rect.x, e.rect.y };
}