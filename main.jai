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
try_to_interact   : bool;

// Texture maps
player_map : Texture;
dirt_map   : Texture;

SCALE :: 2;

PLAYER_MAP_COLS :: 1;
PLAYER_MAP_ROWS :: 26;
PLAYER_MAP_TILE_WIDTH  :: 36;
PLAYER_MAP_TILE_HEIGHT :: 48;
PLAYER_WORLD_SPRITE_WIDTH  :: PLAYER_MAP_TILE_WIDTH  * SCALE;
PLAYER_WORLD_SPRITE_HEIGHT :: PLAYER_MAP_TILE_HEIGHT * SCALE;
PLAYER_WORLD_BOUNDING_WIDTH  :: PLAYER_WORLD_SPRITE_WIDTH  - 40;
PLAYER_WORLD_BOUNDING_HEIGHT :: PLAYER_WORLD_SPRITE_HEIGHT - 20;

PLAYER_MOVE_SPEED :: PLAYER_WORLD_BOUNDING_WIDTH * 8;
PLAYER_JUMP_SPEED :: PLAYER_WORLD_BOUNDING_HEIGHT * 8;

ACCEL_DUE_TO_GRAVITY :: PLAYER_WORLD_BOUNDING_HEIGHT * 18;

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_MAP_TILE_WIDTH  :: 18;
DIRT_MAP_TILE_HEIGHT :: 18;
DIRT_WORLD_TILE_WIDTH  :: 18 * SCALE;
DIRT_WORLD_TILE_HEIGHT :: 18 * SCALE;

WORLD_WIDTH  :: 5000;
WORLD_HEIGHT :: 5000;
WORLD_GRID_COLS :: 100;
WORLD_GRID_ROWS :: 100;

Entity :: struct {
    id : u32;

    pos : Vector2;
    vel : Vector2;

    bounding_rect : Rectangle; // Used for collision
    sprite_rect   : Rectangle;

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
    interact          : [3] Control;
}

data_folder: string; 

main :: () {
    //
    // Window setup
    //
    InitWindow(1600, 900, "Terraria Clone");
    defer CloseWindow();
    SetTargetFPS(144);

    //
    // Initialization
    //
    base_path := path_strip_filename(get_path_of_running_executable());
    data_folder = join(base_path, "data");

    init_textures();

    // @TODO: is this a good idea?
    global_id_counter : u32 = 0;
    
    pos := Vector2.{ GetScreenWidth() / 2.0, GetScreenHeight() / 2.0 };
    player := Player.{
        id = global_id_counter,

        pos = pos,
        vel = Vector2.{ 0, 0 },

        // @TODO: can I reference a field on a struct during a literal declaration.
        bounding_rect = Rectangle.{
            pos.x - floor(PLAYER_WORLD_BOUNDING_WIDTH / 2.0),
            pos.y - floor(PLAYER_WORLD_BOUNDING_HEIGHT / 2.0),
            xx PLAYER_WORLD_BOUNDING_WIDTH,
            xx PLAYER_WORLD_BOUNDING_HEIGHT
        },
        sprite_rect = Rectangle.{
            pos.x - floor(PLAYER_WORLD_SPRITE_WIDTH / 2.0),
            pos.y - floor(PLAYER_WORLD_SPRITE_HEIGHT / 2.0),
            xx PLAYER_WORLD_SPRITE_WIDTH,
            xx PLAYER_WORLD_SPRITE_HEIGHT
        },

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

    INITIAL_DIRT_BLOCK_COUNT :: 1000;
    dirt_blocks: [..]Entity;
    for i: 0..INITIAL_DIRT_BLOCK_COUNT-1 {
        array_add(*dirt_blocks, Entity.{
            // @TODO: post incrememnt macro or something?
            id = global_id_counter,

            bounding_rect = Rectangle.{
                x      = (i * DIRT_WORLD_TILE_WIDTH) - WORLD_WIDTH/2.0,
                y      = xx (GetScreenHeight() - DIRT_WORLD_TILE_HEIGHT),
                width  = xx (DIRT_WORLD_TILE_WIDTH),
                height = xx (DIRT_WORLD_TILE_HEIGHT),
            },
            sprite_rect = Rectangle.{
                x      = (i * DIRT_WORLD_TILE_WIDTH) - WORLD_WIDTH/2.0,
                y      = xx (GetScreenHeight() - DIRT_WORLD_TILE_HEIGHT),
                width  = xx (DIRT_WORLD_TILE_WIDTH),
                height = xx (DIRT_WORLD_TILE_HEIGHT),
            }
        });
        global_id_counter += 1;
    }

    camera: Camera2D;
    camera.target = player.pos;
    camera.offset = Vector2.{ GetScreenWidth()/2.0 + player.bounding_rect.width/2.0, GetScreenHeight()/2.0 + player.bounding_rect.height/2.0 };
    camera.rotation = 0.0;
    camera.zoom = 0.5;

    // @TODO: would a different data structure work better here for perf?
    controls : Controls;
    controls.move_player_left[0]  = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_LEFT)  };
    controls.move_player_left[1]  = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_A)     };
    controls.move_player_right[0] = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_RIGHT) };
    controls.move_player_right[1] = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_D)     };
    controls.jump[0]              = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_SPACE) };
    controls.attack[0]            = Control.{ type = MouseButton, value = (cast(s32) MouseButton.MOUSE_BUTTON_LEFT) };
    controls.interact[0]          = Control.{ type = MouseButton, value = (cast(s32) MouseButton.MOUSE_BUTTON_RIGHT) };

    frame := 0;

    while !WindowShouldClose() {
        reset_temporary_storage();

        time := GetTime(); 
        frame += 1;
        dt := GetFrameTime();
        mouse_pos_in_world := GetScreenToWorld2D(GetMousePosition(), camera);

        // @TODO: function?
        // Reset controls that need to be.
        try_to_jump     = false;
        try_to_attack   = false;
        try_to_interact = false;

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
            try_to_interact   = control_pressed(controls.interact); // place blocks, open doors, etc.
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
                    player.vel.x -= PLAYER_MOVE_SPEED * dt;
                    player.is_facing_left = true;
                }
                if move_player_right {
                    player.vel.x += PLAYER_MOVE_SPEED * dt;
                    player.is_facing_left = false;
                }

                if try_to_jump && can_jump(player) {
                    player.vel.y = -PLAYER_JUMP_SPEED;
                    player.jumps_remaining -= 1;
                }

                player.vel.y += ACCEL_DUE_TO_GRAVITY * dt * 0.5;

                try_to_move_x(*player, player.vel.x, dirt_blocks);
                try_to_move_y(*player, player.vel.y * dt, dirt_blocks);

                player.vel.y += ACCEL_DUE_TO_GRAVITY * dt * 0.5;

                // Update position-dependent fields on player entity
                player.bounding_rect.x = player.pos.x - PLAYER_WORLD_BOUNDING_WIDTH  / 2.0;
                player.bounding_rect.y = player.pos.y - PLAYER_WORLD_BOUNDING_HEIGHT / 2.0 + 10;
                player.sprite_rect.x   = player.pos.x - PLAYER_WORLD_SPRITE_WIDTH  / 2.0;
                player.sprite_rect.y   = player.pos.y - PLAYER_WORLD_SPRITE_HEIGHT / 2.0;

                // @TODO: does the order of where this is done matter?
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
                        if CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) {
                            array_unordered_remove_by_index(*dirt_blocks, it_index);
                        }
                    }
                }

                // For now this just places down dirt blocks
                if try_to_interact {
                    defer global_id_counter += 1;

                    new_rect := create_rect_for_tile_from_point(mouse_pos_in_world, DIRT_WORLD_TILE_WIDTH, DIRT_WORLD_TILE_HEIGHT);

                    new_dirt_block := Entity.{
                        id            = global_id_counter,
                        bounding_rect = new_rect,
                        sprite_rect   = new_rect,
                    };
                    
                    array_add(*dirt_blocks, new_dirt_block);
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

                // if debug_mode {
                if false {
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
                        source := Rectangle.{0, 5 * DIRT_MAP_TILE_HEIGHT, DIRT_MAP_TILE_WIDTH - DIRT_TILE_PADDING, DIRT_MAP_TILE_HEIGHT - DIRT_TILE_PADDING};

                        DrawTexturePro(dirt_map, source, it.sprite_rect, Vector2.{ 0, 0 }, 0.0, Color.{ 255, 255, 255, 255 });

                        if CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) {
                            TRANSPARENT_WHITE := Color.{ WHITE.r, WHITE.b, WHITE.a, 100 };
                            DrawRectangleRec(it.sprite_rect, TRANSPARENT_WHITE);
                        }

                        if debug_mode {
                            DrawRectangleLinesEx(it.sprite_rect, 1.0, LIME);
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
                    DrawTexturePro(player_map, source, sprite_rect, Vector2.{ 0, 0 }, 0.0, Color.{ 255, 255, 255, 255 });

                    if debug_mode {
                        DrawRectangleLinesEx(player.bounding_rect, 1.0, LIME);
                        DrawCircleV(player.pos, 4.0, RED);
                    }
                }
            }

            // Draw UI
            {
                if debug_mode {
                    DrawFPS(10, 10);
                }

                // @TODO: Draw "paused"
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

round_to_int :: (f: float) -> int {
    i := cast(int) floor(f);
    decimal_part := f - i;
    if f < 0 {
        return ifx decimal_part >= 0.5 then i - 1 else i;
    } else {
        return ifx decimal_part >= 0.5 then i + 1 else i;
    }
}

// @TODO: maybe dry up these move functions
try_to_move_x :: (entity: *Entity, distance: float, collidables: []Entity) {
    // x_remainder := distance;
    move := round_to_int(distance);
    if (move == 0) return;

    // x_remainder -= move;
    sign := ifx move > 0 then 1 else -1;

    entity_rect_if_move := entity.bounding_rect;
    collided := false;

    while move != 0 {
        entity_rect_if_move.x += sign;
        
        // @TODO: extract?
        for collidables {
            if CheckCollisionRecs(it.bounding_rect, entity_rect_if_move) {
                collided = true;
                break;
            }
        }

        if collided break;

        entity.pos.x += sign;
        move -= sign;
    }
}

// @TODO: maybe dry up these move functions
try_to_move_y :: (entity: *Entity, distance: float, collidables: []Entity) {
    // y_remainder := distance;
    move := round_to_int(distance);
    if (move == 0) return;

    // y_remainder -= move;
    sign := ifx move > 0 then 1 else -1;

    entity_rect_if_move := entity.bounding_rect;
    collided := false;

    while move != 0 {
        entity_rect_if_move.y += sign;
        
        // @TODO: extract?
        for collidables {
            if CheckCollisionRecs(it.bounding_rect, entity_rect_if_move) {
                collided = true;
                break;
            }
        }

        if collided break;

        entity.pos.y += sign;
        move -= sign;
    }
}

can_jump :: (entity: Entity) -> bool {
    return entity.jumps_remaining > 0;
}

is_grounded :: (entity: Entity, collidables: []Entity) -> bool {
    entity_rect_if_move := entity.bounding_rect;
    entity_rect_if_move.y += 1;

    for collidables {
        if CheckCollisionRecs(it.bounding_rect, entity_rect_if_move) return true;
    }

    return false;
}

update_camera_center :: (camera: *Camera2D, player: *Player, width: s32, height: s32) {
    camera.offset = Vector2.{ width/2.0 - player.bounding_rect.width/2.0, height/2.0 - player.bounding_rect.height/2.0 };
    camera.target = player.pos;
}

update_camera_center_smooth_follow :: (camera: *Camera2D, player: *Player, delta: float, width: s32, height: s32) {
    minSpeed: float = 100;
    minEffectLength: float = 1;
    fractionSpeed: float = 1.5;

    camera.offset = Vector2.{ width/2.0, height/2.0 };
    diff: Vector2 = Vector2Subtract(Vector2.{player.bounding_rect.x,player.bounding_rect.y}, camera.target);
    length: float = Vector2Length(diff);

    if (length > minEffectLength) {
        speed: float = max(fractionSpeed*length, minSpeed);
        camera.target = Vector2Add(camera.target, Vector2Scale(diff, speed*delta/length));
    }
}

create_rect_for_tile_from_point :: (pos: Vector2, tile_width: s32, tile_height: s32) -> Rectangle {
    x := pos.x - (xx pos.x % tile_width);
    y := pos.y - (xx pos.y % tile_height);

    if pos.x < 0 { x -= tile_width - 1; }

    new_rect := Rectangle.{
        x      = floor(x),
        y      = floor(y),
        width  = xx tile_width,
        height = xx tile_height,
    };
    print_vars(new_rect, pos);
    return new_rect;
}
