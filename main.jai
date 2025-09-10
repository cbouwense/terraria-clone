#import "Basic";
#import "Input";
#import "Math";
#import "Print_Vars";
#import "Random";
#import "String";
#import "System";

#import "raylib";

window_width  := 1600;
window_height := 800;

// Metagame state
should_quit_game := false;
paused           := false;
debug_mode       := false;
free_cam_pos     := Vector2.{ 0, 0 };

// Controls
move_player_left  : bool;
move_player_right : bool;
try_to_jump       : bool;
try_to_attack     : bool;
try_to_interact   : bool;
drag_cam   : bool;

// Texture maps
player_map : Texture;
dirt_map   : Texture;

SCALE :: 2;

PLAYER_MAP_COLS :: 1;
PLAYER_MAP_ROWS :: 26;

PLAYER_MAP_HEAD_TILE_WIDTH  :: 40;
PLAYER_MAP_HEAD_TILE_HEIGHT :: 53;
PLAYER_WORLD_HEAD_SPRITE_WIDTH  :: PLAYER_MAP_HEAD_TILE_WIDTH  * SCALE;
PLAYER_WORLD_HEAD_SPRITE_HEIGHT :: PLAYER_MAP_HEAD_TILE_HEIGHT * SCALE - 5;

// PLAYER_WORLD_SPRITE_WIDTH  :: PLAYER_MAP_TILE_WIDTH  * SCALE;
// PLAYER_WORLD_SPRITE_HEIGHT :: PLAYER_MAP_TILE_HEIGHT * SCALE - 5;
PLAYER_WORLD_BOUNDING_WIDTH  :: PLAYER_WORLD_HEAD_SPRITE_WIDTH  - 40;
PLAYER_WORLD_BOUNDING_HEIGHT :: PLAYER_WORLD_HEAD_SPRITE_HEIGHT - 20;

PLAYER_REACH_DISTANCE :: 300.0;

PLAYER_MOVE_SPEED :: PLAYER_WORLD_BOUNDING_WIDTH * 8;
PLAYER_JUMP_SPEED :: PLAYER_WORLD_BOUNDING_HEIGHT * 8;
PLAYER_ATTACK_COOLDOWN_MS   :: 150;
PLAYER_INTERACT_COOLDOWN_MS :: 150;

ACCEL_DUE_TO_GRAVITY :: PLAYER_WORLD_BOUNDING_HEIGHT * 25;

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_MAP_TILE_WIDTH  :: 18;
DIRT_MAP_TILE_HEIGHT :: 18;
DIRT_WORLD_TILE_WIDTH  :: 18 * SCALE;
DIRT_WORLD_TILE_HEIGHT :: 18 * SCALE;

WORLD_GRID_COLS :: 2000;

PERLIN_NOISE_FREQUENCY :: 2; // How many grid nodes per map
#assert WORLD_GRID_COLS % PERLIN_NOISE_FREQUENCY == 0 "The perlin noise frequency must be a divisor of the number of world columns.";
PERLIN_NOISE_AMPLITUDE :: 300;
PERLIN_NOISE_OCTAVES :: 5;

DEBUG_CAM_SPEED :: 5;

Entity :: struct {
    id       : u32; 
    chunk_id : u32;

    pos : Vector2;
    vel : Vector2;

    bounding_rect : Rectangle; // Used for collision
}

Animation :: struct {
    active            : bool;
    frame_one_coords  : Vector2;
    frame_count       : u32;
    frame_duration_ms : u32;
    timer_ms          : u32;
}

Player :: struct {
    #as using entity : Entity;

    sprite_head_rect : Rectangle;

    idle_animation   : Animation;
    run_animation    : Animation;

    jumps_remaining  : int;
    jumps_capacity   : int; // e.g. 2 if an entity can double jump, 6 for kirby in melee, etc.

    is_facing_left   : bool;

    attack_cooldown_current_ms   : s32;
    interact_cooldown_current_ms : s32;
}

Block :: struct {
    #as using entity : Entity;

    sprite_rect : Rectangle;
}

CHUNK_MAX_WIDTH :: 16;
Chunk :: struct {
    id     : u32;
    blocks : [..] Block;
    bounding_rect : Rectangle;
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
    drag_cam          : [3] Control;
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

    global_id_counter: u32 = 0;
    
    pos := Vector2.{ GetScreenWidth() / 2.0, -1.0 * GetScreenHeight() };
    player := Player.{
        id = global_id_counter,

        pos = pos,
        vel = Vector2.{ 0, 0 },

        bounding_rect = Rectangle.{
            pos.x - floor(PLAYER_WORLD_BOUNDING_WIDTH / 2.0),
            pos.y - floor(PLAYER_WORLD_BOUNDING_HEIGHT / 2.0) + 5,
            xx PLAYER_WORLD_BOUNDING_WIDTH,
            xx PLAYER_WORLD_BOUNDING_HEIGHT,
        },
        sprite_head_rect = Rectangle.{
            pos.x - floor(PLAYER_WORLD_HEAD_SPRITE_WIDTH / 2.0),
            pos.y - floor(PLAYER_WORLD_HEAD_SPRITE_HEIGHT / 2.0),
            xx PLAYER_WORLD_HEAD_SPRITE_WIDTH,
            xx PLAYER_WORLD_HEAD_SPRITE_HEIGHT,
        },

        jumps_capacity  = 2,
        jumps_remaining = 2,

        is_facing_left = false,

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
            frame_one_coords  = Vector2.{ 0, 0 }, 
            frame_count       = 20,
            frame_duration_ms = 33,
            timer_ms          = 0,
        },

        attack_cooldown_current_ms   = 0,
        interact_cooldown_current_ms = 0,
    };
    global_id_counter += 1;

    // @TODO: extract
    // Generate perlin noise for heightmap
    perlin_values: [WORLD_GRID_COLS]float;
    for o: 0..PERLIN_NOISE_OCTAVES {
        octave_factor := pow(2.0, cast(float) o);
        amplitude := PERLIN_NOISE_AMPLITUDE / octave_factor;
        frequency := PERLIN_NOISE_FREQUENCY * octave_factor;
        ratio := WORLD_GRID_COLS / frequency;
        blocks_per_section := cast(int) (WORLD_GRID_COLS / frequency);
    
        random_grid_scalars: [..]float;
        for i: 0..(xx frequency-1) {
            array_add(*random_grid_scalars, random_get_within_range(-1, 1));
        }

        for i: 0..(WORLD_GRID_COLS - (blocks_per_section + 1)) {
            // Get distance from current tile to each grid corner
            f := floor(cast(float) i / ratio);
            delta_l := (i - ratio * f) / blocks_per_section;
            delta_r := (ratio * (f + 1) - i) / blocks_per_section;

            // Get dot products of grid corner vectors and distances
            l_scalar := random_grid_scalars[cast(int) (f)];
            r_scalar := random_grid_scalars[cast(int) (f + 1)];
            l_dot : float = l_scalar * delta_l;
            r_dot : float = r_scalar * delta_r;

            perlin := lerp(l_dot, r_dot, smootherstep(delta_l));
            
            perlin_values[i] += amplitude * perlin;
        }
    }

    chunks : [..] Chunk;

    // Initialize hills
    chunk: Chunk;
    for col: 0..(WORLD_GRID_COLS - 1) {
        chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division.

        if col % CHUNK_MAX_WIDTH == 0 {
            chunk = New(Chunk);
            chunk.id = xx chunk_id;
            array_add(*chunks, chunk);
        }

        blocks_in_col := cast(int) perlin_values[col];
        for height: 0..blocks_in_col {
            rect := Rectangle.{
                x      = ((col - WORLD_GRID_COLS / 2.0) * DIRT_WORLD_TILE_WIDTH) + (GetScreenWidth() / 2.0),
                y      = GetScreenHeight() - cast(float)(DIRT_WORLD_TILE_HEIGHT * height),
                width  = DIRT_WORLD_TILE_WIDTH,
                height = DIRT_WORLD_TILE_HEIGHT,
            };

            // @TODO: post increment macro or something?
            defer global_id_counter += 1;
            array_add(*chunks[chunk_id].blocks, Block.{
                id            = global_id_counter,
                chunk_id      = xx chunk_id,
                pos           = Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 },
                bounding_rect = rect,
                sprite_rect   = rect,
            });
        }
    }

    // Initialize dirt underground
    for col: 0..(WORLD_GRID_COLS - 1) {
        for height: 0..39 {
            rect := Rectangle.{
                x      = ((col - WORLD_GRID_COLS / 2.0) * DIRT_WORLD_TILE_WIDTH) + (GetScreenWidth() / 2.0),
                y      = GetScreenHeight() + cast(float)(DIRT_WORLD_TILE_HEIGHT * height),
                width  = DIRT_WORLD_TILE_WIDTH,
                height = DIRT_WORLD_TILE_HEIGHT,
            };

            // @TODO: post incrememnt macro or something?
            chunk_id := col / CHUNK_MAX_WIDTH;
            defer global_id_counter += 1;
            array_add(*chunks[chunk_id].blocks, Block.{
                id       = global_id_counter,
                chunk_id = xx chunk_id,
                pos           = Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 },
                bounding_rect = rect,
                sprite_rect   = rect,
            });
        }
    }
    
    for *chunks {
        it.bounding_rect = Rectangle.{
            // @TODO: This will actually not work always. What if a chunk has no blocks?
            it.blocks[0].bounding_rect.x,
            // @TODO: Probably make a constant for this.
            -500000,
            it.blocks[it.blocks.count-1].bounding_rect.x - it.blocks[0].bounding_rect.x + it.blocks[0].bounding_rect.width,
            1000000
        };
    }

    // Initialize camera
    camera: Camera2D;
    camera.target = player.pos;
    camera.offset = Vector2.{ GetScreenWidth()/2.0 + player.bounding_rect.width/2.0, GetScreenHeight()/2.0 };
    camera.rotation = 0.0;
    camera.zoom = 0.5;

    // Initialize controls
    // @TODO: would a different data structure work better here for perf?
    controls : Controls;
    controls.move_player_left[0]  = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_LEFT)  };
    controls.move_player_left[1]  = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_A)     };
    controls.move_player_right[0] = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_RIGHT) };
    controls.move_player_right[1] = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_D)     };
    controls.jump[0]              = Control.{ type = KeyboardKey, value = (cast(s32) KeyboardKey.KEY_SPACE) };
    controls.attack[0]            = Control.{ type = MouseButton, value = (cast(s32) MouseButton.MOUSE_BUTTON_LEFT) };
    controls.interact[0]          = Control.{ type = MouseButton, value = (cast(s32) MouseButton.MOUSE_BUTTON_RIGHT) };
    controls.drag_cam[0]          = Control.{ type = MouseButton, value = (cast(s32) MouseButton.MOUSE_BUTTON_MIDDLE) };

    while !WindowShouldClose() {
        defer reset_temporary_storage();

        time := GetTime();
        dt   := GetFrameTime();
        mouse_pos_in_world := GetScreenToWorld2D(GetMousePosition(), camera);

        window_start := GetScreenToWorld2D(Vector2.{ 0, 0 }, camera);
        window_end   := GetScreenToWorld2D(Vector2.{ cast(float)GetScreenWidth(), cast(float)GetScreenHeight()}, camera);

        active_chunks: [..]Chunk;
        active_chunks.allocator = temp;

        active_blocks: [..]Block;
        active_blocks.allocator = temp;

        // @TODO: This is probably still too slow, but it's a step in the right direction.
        for chunks {
            // The last block in a chunk will always be the right-most with the current method for world generation.
            if it.blocks[it.blocks.count-1].pos.x < window_start.x - DIRT_WORLD_TILE_WIDTH continue;
            
            // The first block in a chunk will always be the left-most with the current method for world generation.
            if it.blocks[0].pos.x > window_end.x continue;

            array_add(*active_chunks, it);
            
            for block: it.blocks {
                array_add(*active_blocks, block);
            }
        }

        // Reset controls that need to be.
        try_to_jump     = false;
        try_to_attack   = false;
        try_to_interact = false;

        //
        // Input
        //
        {
            if IsKeyPressed(.KEY_P) paused     = !paused;
            if IsKeyPressed(.KEY_G) debug_mode = !debug_mode;

            move_player_left  = control_down(controls.move_player_left);
            move_player_right = control_down(controls.move_player_right);
            try_to_jump       = control_pressed(controls.jump);
            try_to_attack     = control_down(controls.attack);
            try_to_interact   = control_down(controls.interact); // place blocks, open doors, etc.
            drag_cam          = control_down(controls.drag_cam);
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

                player.vel.y += ACCEL_DUE_TO_GRAVITY * dt * 0.5;

                try_to_move_x(*player, player.vel.x * dt, active_blocks);
                try_to_move_y(*player, player.vel.y * dt, active_blocks);

                player.vel.y += ACCEL_DUE_TO_GRAVITY * dt * 0.5;

                // Update position-dependent fields on player entity
                player.bounding_rect.x    = player.pos.x - PLAYER_WORLD_BOUNDING_WIDTH  / 2.0;
                player.bounding_rect.y    = player.pos.y - PLAYER_WORLD_BOUNDING_HEIGHT / 2.0 + 10;
                player.sprite_head_rect.x = player.pos.x - PLAYER_WORLD_HEAD_SPRITE_WIDTH  / 2.0;
                player.sprite_head_rect.y = player.pos.y - PLAYER_WORLD_HEAD_SPRITE_HEIGHT / 2.0;

                if is_grounded(player, active_blocks) {
                    player.jumps_remaining = player.jumps_capacity;
                    player.vel.y = 0;
                }

                if try_to_attack {
                    is_on_cooldown := player.attack_cooldown_current_ms > 0;

                    if !is_on_cooldown {
                        if Vector2Distance(mouse_pos_in_world, player.pos) < PLAYER_REACH_DISTANCE {
                            // @TODO: there's a function to extract here
                            for active_blocks {
                                if CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) {
                                    removed := array_unordered_remove_entity_by_id(*chunks[it.chunk_id].blocks, it, true);
                                }
                            }
                        }

                        player.attack_cooldown_current_ms = PLAYER_ATTACK_COOLDOWN_MS;
                    }
                }

                // For now this just places down dirt blocks
                if try_to_interact {
                    is_on_cooldown := player.interact_cooldown_current_ms > 0;

                    if !is_on_cooldown {
                        is_within_reach := Vector2Distance(mouse_pos_in_world, player.pos) < PLAYER_REACH_DISTANCE;
                        would_be_on_existing_entity := false;

                        // Check if the block would be placed on any existing blocks
                        for active_blocks {
                            if CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) {
                                would_be_on_existing_entity = true;
                                break;
                            }
                        }

                        new_rect := create_rect_for_tile_from_point(mouse_pos_in_world, DIRT_WORLD_TILE_WIDTH, DIRT_WORLD_TILE_HEIGHT);

                        // Check if the new block would be placed on the player
                        if CheckCollisionRecs(new_rect, player.bounding_rect) {
                            would_be_on_existing_entity = true;
                        }

                        can_place_block := is_within_reach && !would_be_on_existing_entity;
                        
                        if can_place_block { 
                            defer global_id_counter += 1;

                            new_pos  := get_rect_center(new_rect);

                            new_dirt_block := Block.{
                                id            = global_id_counter,
                                pos           = new_pos,
                                bounding_rect = new_rect,
                                sprite_rect   = new_rect,
                            };
                            
                            found_chunk := false;
                            for active_chunks {
                                print("checking chunk %\n", it.id);
                                if !CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) continue;
                                
                                found_chunk = true;
                                new_dirt_block.chunk_id = it.id;
                                array_add(*chunks[it.id].blocks, new_dirt_block);
                                // print_vars(it.id, new_dirt_block);
                                break;
                            }
                            assert(found_chunk);

                            player.interact_cooldown_current_ms = PLAYER_INTERACT_COOLDOWN_MS;
                        }
                    }
                }

                // Update animation state
                {
                    player.idle_animation.active = move_player_left == move_player_right;
                    player.run_animation.active  = move_player_left != move_player_right;
                    
                    // @TODO: metaprogramming moment?
                    if player.idle_animation.active {
                        player.idle_animation.timer_ms += xx (dt * 1000);
                    } else {
                        player.idle_animation.timer_ms = 0;
                    };

                    if player.run_animation.active {
                        player.run_animation.timer_ms += xx (dt * 1000);
                    } else {
                        player.run_animation.timer_ms = 0;
                    }; 
                }

                // Update player cooldowns
                // @TODO: feels like there's some metaprogramming possibility here.
                {
                    if player.attack_cooldown_current_ms > 0 {
                        player.attack_cooldown_current_ms -= xx (dt * 1000);
                    }

                    if player.interact_cooldown_current_ms > 0 {
                        player.interact_cooldown_current_ms -= xx (dt * 1000);
                    }
                }

                // print_vars(player);
            }

            // Update camera
            {
                if drag_cam {
                    free_cam_pos = Vector2Add(free_cam_pos, Vector2Scale(GetMouseDelta(), -1.0 * DEBUG_CAM_SPEED));
                }

                camera.zoom += GetMouseWheelMove() * 0.1;

                if camera.zoom > 3.0 camera.zoom = 3.0;
                else if debug_mode && camera.zoom < 0.01 camera.zoom = 0.01;
                else if !debug_mode && camera.zoom < 0.5 camera.zoom = 0.5;

                if debug_mode {
                    camera.offset = Vector2.{ GetScreenWidth() / 2.0, GetScreenHeight() / 2.0 };
                    camera.target = free_cam_pos;
                } else {
                    update_camera_center(*camera, *player, GetScreenWidth(), GetScreenHeight());
                    free_cam_pos = player.pos;
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

                // Draw dirt
                {
                    for active_blocks {
                        DIRT_TILE_PADDING :: 2;
                        source := Rectangle.{0, 5 * DIRT_MAP_TILE_HEIGHT, DIRT_MAP_TILE_WIDTH - DIRT_TILE_PADDING, DIRT_MAP_TILE_HEIGHT - DIRT_TILE_PADDING};

                        DrawTexturePro(dirt_map, source, it.sprite_rect, Vector2.{ 0, 0 }, 0.0, Color.{ 255, 255, 255, 255 });

                        if Vector2Distance(mouse_pos_in_world, player.pos) < PLAYER_REACH_DISTANCE { 
                            if CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) {
                                TRANSPARENT_WHITE := Color.{ WHITE.r, WHITE.b, WHITE.a, 100 };
                                DrawRectangleRec(it.sprite_rect, TRANSPARENT_WHITE);
                            }
                        }
                    }

                    if debug_mode {
                        for chunks {
                            DrawRectangleLinesEx(it.bounding_rect, 2.0, LIME);
                        }
                        for active_chunks {
                            center := get_rect_center(it.bounding_rect);
                            DrawText(tprint("%\0", it.id).data, xx center.x, xx center.y, 25, WHITE);
                            if CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) {
                                DrawRectangleLinesEx(it.bounding_rect, 2.0, ORANGE);
                            } else {
                                DrawRectangleLinesEx(it.bounding_rect, 2.0, WHITE);
                            }
                        }
                    }
                }

                // Draw player
                {
                    active_animation : Animation = ifx player.idle_animation.active then player.idle_animation else player.run_animation; 

                    // This logic assumes that the animation is a contiguous horizontal strip of tiles.
                    frame := (active_animation.timer_ms / active_animation.frame_duration_ms) % active_animation.frame_count;
                    tile := Vector2.{ frame + active_animation.frame_one_coords.x, active_animation.frame_one_coords.y };

                    source_width : float = xx ifx player.is_facing_left then -PLAYER_MAP_HEAD_TILE_WIDTH else PLAYER_MAP_HEAD_TILE_WIDTH;
                    source := Rectangle.{tile.x * PLAYER_MAP_HEAD_TILE_WIDTH, tile.y * PLAYER_MAP_HEAD_TILE_HEIGHT, source_width, PLAYER_MAP_HEAD_TILE_HEIGHT};
                    DrawTexturePro(player_map, source, player.sprite_head_rect, Vector2.{ 0, 0 }, 0.0, Color.{ 255, 255, 255, 255 });

                    if debug_mode {
                        DrawRectangleLinesEx(player.bounding_rect, 1.0, LIME);
                        DrawCircleV(player.pos, 4.0, RED);
                    }
                }
            }

            // Draw UI
            {
                DrawFPS(10, 10);
                
                if debug_mode {
                    DrawText(tprint("(%, %)\0", mouse_pos_in_world.x, mouse_pos_in_world.y).data, 10, 30, 18, LIME);
                }

                // @TODO: Draw "paused"
                if paused {

                }
            }
        }
    }
}

// @TODO: it would be cool to have a debug mode for this and hot swap the debug sprite sheets.
init_textures :: () {
    player_map = LoadTexture("data/Player_Head_Debug.png");
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
    i := cast(int) f;
    decimal_part := abs(f) - abs(i);

    if decimal_part >= 0.5 {
        if f >= 0 return i + 1;
        else      return i - 1;
    }

    return i;
}

// @TODO: maybe dry up these move functions
try_to_move_x :: (entity: *Entity, distance: float, collidables: [] $T/interface Entity) {
    move := round_to_int(distance);
    print_vars(move, distance);
    if (move == 0) return;

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
try_to_move_y :: (entity: *Entity, distance: float, collidables: [] $T/interface Entity) {
    move := round_to_int(distance);
    if (move == 0) return;

    sign := ifx move > 0 then 1 else -1;

    entity_rect_if_move := entity.bounding_rect;
    collided := false;

    while move != 0 {
        entity_rect_if_move.y += sign;
        
        // @TODO: extract
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

can_jump :: (player: Player) -> bool {
    return player.jumps_remaining > 0;
}

is_grounded :: (entity: Entity, collidables: [] $T/interface Entity) -> bool {
    entity_rect_if_move := entity.bounding_rect;
    entity_rect_if_move.y += 1;

    for collidables {
        if CheckCollisionRecs(it.bounding_rect, entity_rect_if_move) return true;
    }

    return false;
}

update_camera_center :: (camera: *Camera2D, player: *Player, width: s32, height: s32) {
    // camera.offset = Vector2.{ width/2.0 - player.bounding_rect.width/2.0, height/2.0 - player.bounding_rect.height/2.0 };
    camera.offset = Vector2.{ width/2.0 - player.bounding_rect.width/2.0, height/2.0 + 100 };
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

    // I don't exactly understand why I have to add this 8, but it makes it placed correctly, so...
    // I have a funny feeling that I'll have to redo the tiling system anyways if I need to have a more
    // robust thing.
    new_rect := Rectangle.{
        x      = floor(x) + 8,
        y      = floor(y),
        width  = xx tile_width,
        height = xx tile_height,
    };
    return new_rect;
}

get_rect_center :: (rect: Rectangle) -> Vector2 {
    return Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 };
}

smoothstep :: (x: float) -> float {
    if x <= 0.0 return 0.0;
    if x >= 1.0 return 1.0;
    return (3 * x * x) - (2 * x * x * x); 
}

smootherstep :: (x: float) -> float {
    if x <= 0.0 return 0.0;
    if x >= 1.0 return 1.0;
    return (6 * x * x * x * x * x) - (15 * x * x * x * x) + (10 * x * x * x); 
}

array_unordered_remove_entity_by_id :: inline (array: *[] $Entity, item: Entity, $stop_after_first := false) -> s64 {
    removed := 0;
    for array.*  if it.id == item.id {
        removed += 1;
        remove it;

        #if stop_after_first  break;   // Early-out optimization.
    }

    return removed;
}
 