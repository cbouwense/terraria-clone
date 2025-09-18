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
drag_cam          : bool;

// Texture maps
player_head_map           : Texture;
player_hair_1_map         : Texture;
player_eye_white_map      : Texture;
player_eye_iris_map       : Texture;
player_chest_grounded_map : Texture;
player_chest_airborne_map : Texture;
player_undershirt_map     : Texture;
player_pants_map          : Texture;
player_hands_map          : Texture;
player_shoes_map          : Texture;
dirt_map                  : Texture;
rock_map                  : Texture;
damage_map                : Texture;

player_sprite_head_idle                 : Sprite;
player_animation_head_running           : AnimatedSprite;
player_sprite_hair_1_idle               : Sprite;
player_animation_hair_1_running         : AnimatedSprite;
player_sprite_eye_white_idle            : Sprite;
player_animation_eye_white_running      : AnimatedSprite;
player_sprite_eye_iris_idle             : Sprite;
player_animation_eye_iris_running       : AnimatedSprite;
player_sprite_chest_grounded_idle       : Sprite;
player_animation_chest_grounded_running : AnimatedSprite;
player_sprite_chest_falling             : Sprite;
player_sprite_undershirt_idle           : Sprite;
player_animation_undershirt_running     : AnimatedSprite;
player_sprite_undershirt_airborne       : Sprite;
player_sprite_undershirt_falling        : Sprite;
player_animation_undershirt_swinging    : AnimatedSprite;
player_sprite_pants_idle                : Sprite;
player_animation_pants_running          : AnimatedSprite;
player_sprite_pants_airborne            : Sprite;
player_sprite_hands_idle                : Sprite;
player_animation_hands_running          : AnimatedSprite;
player_sprite_hands_airborne            : Sprite;
player_sprite_hands_falling             : Sprite;
player_animation_hands_swinging         : AnimatedSprite;
player_sprite_shoes_idle                : Sprite;
player_animation_shoes_running          : AnimatedSprite;
player_sprite_shoes_airborne            : Sprite;

player_sprites    : [..] *Sprite;
player_animations : [..] *AnimatedSprite;

SCALE :: 2;

PLAYER_MAP_TILE_WIDTH  :: 40;
PLAYER_MAP_TILE_HEIGHT :: 53;
PLAYER_WORLD_HEAD_SPRITE_WIDTH  :: PLAYER_MAP_TILE_WIDTH  * SCALE;
PLAYER_WORLD_HEAD_SPRITE_HEIGHT :: PLAYER_MAP_TILE_HEIGHT * SCALE - 5;

PLAYER_WORLD_BOUNDING_WIDTH  :: PLAYER_WORLD_HEAD_SPRITE_WIDTH  - 40;
PLAYER_WORLD_BOUNDING_HEIGHT :: PLAYER_WORLD_HEAD_SPRITE_HEIGHT - 20;

PLAYER_REACH_DISTANCE :: 300.0;

PLAYER_SPEED_MOVE :: PLAYER_WORLD_BOUNDING_WIDTH * 8;
PLAYER_SPEED_JUMP :: PLAYER_WORLD_BOUNDING_HEIGHT * 8;
PLAYER_SPEED_MAX  :: 3000.0;
PLAYER_COOLDOWN_ATTACK_DURATION_MS   :: 100;
PLAYER_COOLDOWN_INTERACT_DURATION_MS :: 100;

PLAYER_ANIMATION_RUN_DURATION_MS   :: 25;
PLAYER_ANIMATION_SWING_DURATION_MS :: 75;

PLAYER_ANIMATION_FIRST_FRAME_IDLE     :: 0;
PLAYER_ANIMATION_FIRST_FRAME_RUNNING  :: 6;
PLAYER_ANIMATION_FIRST_FRAME_FALLING  :: 5;
PLAYER_ANIMATION_FIRST_FRAME_SWINGING :: 1;

PLAYER_COLOR_SKIN       :: BEIGE;
PLAYER_COLOR_HAIR       :: ORANGE;
PLAYER_COLOR_EYE        :: LIME;
PLAYER_COLOR_CHEST      :: GRAY;
PLAYER_COLOR_UNDERSHIRT :: PINK;
PLAYER_COLOR_PANTS      :: BLUE;
PLAYER_COLOR_SHOES      :: RED;

ACCEL_DUE_TO_GRAVITY :: PLAYER_WORLD_BOUNDING_HEIGHT * 25;

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_MAP_TILE_WIDTH  :: 18;
DIRT_MAP_TILE_HEIGHT :: 18;
DIRT_MAP_TILE_PADDING :: 2;
DIRT_WORLD_TILE_WIDTH  :: 18 * SCALE;
DIRT_WORLD_TILE_HEIGHT :: 18 * SCALE;
DIRT_HEALTH_MAX :: 10;

ROCK_MAP_COLS :: 16;
ROCK_MAP_ROWS :: 15;
ROCK_MAP_TILE_WIDTH  :: 18;
ROCK_MAP_TILE_HEIGHT :: 18;
ROCK_MAP_TILE_PADDING :: 2;
ROCK_WORLD_TILE_WIDTH  :: 18 * SCALE;
ROCK_WORLD_TILE_HEIGHT :: 18 * SCALE;
ROCK_HEALTH_MAX :: 100;

DAMAGE_MAP_COLS :: 10;
DAMAGE_MAP_ROWS :: 1;
DAMAGE_MAP_TILE_WIDTH  :: 16;
DAMAGE_MAP_TILE_HEIGHT :: 16;
DAMAGE_WORLD_TILE_WIDTH  :: 18 * SCALE;
DAMAGE_WORLD_TILE_HEIGHT :: 18 * SCALE;

WORLD_GRID_COLS :: 1000;

DEBUG_CAM_SPEED :: 5;

global_id_counter: u32 = 0;

Entity :: struct {
    id       : u32; 
    chunk_id : u32;

    pos : Vector2;
    vel : Vector2;

    bounding_rect : Rectangle; // Used for collision
    sprite_rect   : Rectangle;

    health_max  : s32;
    health_curr : s32;
}

Sprite :: struct {
    map         : Texture;
    active      : bool;
    first_frame : u32; // Starts from 0
    color       : Color;
}

AnimatedSprite :: struct {
    #as using sprite  : Sprite;
    frame_count       : u32;
    frame_duration_ms : u32;
    timer_ms          : u32;
    loops             : bool;
}

Player :: struct {
    #as using entity : Entity;

    jumps_remaining  : int;
    jumps_capacity   : int; // e.g. 2 if an entity can double jump, 6 for kirby in melee, etc.

    is_facing_left   : bool;

    cooldown_attack_current_ms   : s32;
    cooldown_interact_current_ms : s32;
}

BlockType :: enum {
    DIRT;
    ROCK;
}

Block :: struct {
    #as using entity : Entity;
    block_type       : BlockType;
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
    // Initialization
    //
    random_seed(123456779);

    InitWindow(1600, 900, "Terraria Clone");
    defer CloseWindow();
    SetTargetFPS(144);

    base_path := path_strip_filename(get_path_of_running_executable());
    data_folder = join(base_path, "data");

    init_textures();
    init_sprites();
    
    player := spawn_player();

    chunks : [..] Chunk;

    // Initialize chunks
    chunk: Chunk;
    // @TODO: this is fucked up
    for col: 0..(WORLD_GRID_COLS - 1) {
        chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division.

        if col % CHUNK_MAX_WIDTH == 0 {
            chunk = New(Chunk);
            chunk.id = xx chunk_id;
            array_add(*chunks, chunk);
        }
    }

    DIRT_PERLIN_NOISE_FREQUENCY :: 4; // How many grid nodes per map
    DIRT_PERLIN_NOISE_AMPLITUDE :: 200;
    DIRT_PERLIN_NOISE_OCTAVES   :: 5;
    dirt_heights := perlin_noise(WORLD_GRID_COLS, DIRT_PERLIN_NOISE_FREQUENCY, DIRT_PERLIN_NOISE_AMPLITUDE, DIRT_PERLIN_NOISE_OCTAVES);

    ROCK_PERLIN_NOISE_FREQUENCY :: 4; // How many grid nodes per map
    ROCK_PERLIN_NOISE_AMPLITUDE :: 100;
    ROCK_PERLIN_NOISE_OCTAVES   :: 5;
    rock_depths := perlin_noise(WORLD_GRID_COLS, ROCK_PERLIN_NOISE_FREQUENCY, ROCK_PERLIN_NOISE_AMPLITUDE, ROCK_PERLIN_NOISE_OCTAVES);

    GROUND_HEIGHT := GetScreenHeight() / 4;

    // Initialize blocks
    for col: 0..(WORLD_GRID_COLS - 1) {
        // Generate hills
        hill_dirt_blocks := cast(int) abs(dirt_heights[col]);
        for height: 0..hill_dirt_blocks {
            rect := Rectangle.{
                x      = ((col - WORLD_GRID_COLS / 2.0) * DIRT_WORLD_TILE_WIDTH) + (GetScreenWidth() / 2.0),
                y      = GROUND_HEIGHT - cast(float) (DIRT_WORLD_TILE_HEIGHT * height),
                width  = DIRT_WORLD_TILE_WIDTH,
                height = DIRT_WORLD_TILE_HEIGHT,
            };

            // @TODO: post increment macro or something?
            chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division.
            defer global_id_counter += 1;
            array_add(
                *chunks[chunk_id].blocks,
                Block.{
                    id            = global_id_counter,
                    chunk_id      = xx chunk_id,
                    pos           = Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 },
                    bounding_rect = rect,
                    sprite_rect   = rect,
                    health_max    = DIRT_HEALTH_MAX,
                    health_curr   = DIRT_HEALTH_MAX,
                    block_type    = .DIRT,
                }
            );
        }

        // Generate ground dirt
        ground_dirt_blocks := cast(int) abs(rock_depths[col]);
        for height: 0..ground_dirt_blocks {
            rect := Rectangle.{
                x      = ((col - WORLD_GRID_COLS/2.0) * DIRT_WORLD_TILE_WIDTH) + GetScreenWidth()/2.0,
                y      = GROUND_HEIGHT + cast(float)(DIRT_WORLD_TILE_HEIGHT * height),
                width  = DIRT_WORLD_TILE_WIDTH,
                height = DIRT_WORLD_TILE_HEIGHT,
            };

            // @TODO: post incrememnt macro or something?
            chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division.
            defer global_id_counter += 1;
            array_add(
                *chunks[chunk_id].blocks,
                Block.{
                    id            = global_id_counter,
                    chunk_id      = xx chunk_id,
                    pos           = Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 },
                    bounding_rect = rect,
                    sprite_rect   = rect,
                    health_max    = DIRT_HEALTH_MAX,
                    health_curr   = DIRT_HEALTH_MAX,
                    block_type    = .DIRT,
                }
            );
        }

        // Generate rock
        rock_blocks := cast(int) abs(cast(float) rock_depths[col]);
        for height: 0..rock_blocks {
            rect := Rectangle.{
                x      = ((col - WORLD_GRID_COLS/2.0) * ROCK_WORLD_TILE_WIDTH) + GetScreenWidth()/2.0,
                y      = GROUND_HEIGHT + ground_dirt_blocks + cast(float)(ROCK_WORLD_TILE_HEIGHT * height),
                width  = ROCK_WORLD_TILE_WIDTH,
                height = ROCK_WORLD_TILE_HEIGHT,
            };

            // @TODO: post incrememnt macro or something?
            chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division.
            defer global_id_counter += 1;
            array_add(
                *chunks[chunk_id].blocks,
                Block.{
                    id            = global_id_counter,
                    chunk_id      = xx chunk_id,
                    pos           = Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 },
                    bounding_rect = rect,
                    sprite_rect   = rect,
                    health_max    = ROCK_HEALTH_MAX,
                    health_curr   = ROCK_HEALTH_MAX,
                    block_type    = .ROCK,
                }
            );
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
    camera.target   = player.pos;
    camera.offset   = Vector2.{ GetScreenWidth()/2.0 + player.bounding_rect.width/2.0, GetScreenHeight()/2.0 };
    camera.rotation = 0.0;
    camera.zoom     = 0.5;

    // Initialize controls
    controls : Controls;
    controls.move_player_left[0]  = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_LEFT            };
    controls.move_player_left[1]  = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_A               };
    controls.move_player_right[0] = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_RIGHT           };
    controls.move_player_right[1] = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_D               };
    controls.jump[0]              = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_SPACE           };
    controls.attack[0]            = Control.{ type = MouseButton, value = cast(s32) MouseButton.MOUSE_BUTTON_LEFT   };
    controls.interact[0]          = Control.{ type = MouseButton, value = cast(s32) MouseButton.MOUSE_BUTTON_RIGHT  };
    controls.drag_cam[0]          = Control.{ type = MouseButton, value = cast(s32) MouseButton.MOUSE_BUTTON_MIDDLE };

    while !WindowShouldClose() {
        defer reset_temporary_storage();

        time := GetTime();
        dt   := GetFrameTime();
        mouse_pos_in_world := GetScreenToWorld2D(GetMousePosition(), camera);

        player_is_grounded : bool; // updated in player update to reduce calls to is_grounded to once for the player per frame.

        window_start := GetScreenToWorld2D(Vector2.{ 0, 0 }, camera);
        window_end   := GetScreenToWorld2D(Vector2.{ cast(float) GetScreenWidth(), cast(float) GetScreenHeight()}, camera);

        active_chunks: [..]Chunk;
        active_chunks.allocator = temp;

        active_blocks: [..]*Block;
        active_blocks.allocator = temp;

        // @TODO: Having a notion of active chunks and active blocks is probably still too slow, but it's a step in the right direction.
        for chunks {
            // The last block in a chunk will always be the right-most with the current method for world generation.
            if it.blocks[it.blocks.count-1].pos.x < window_start.x - DIRT_WORLD_TILE_WIDTH continue;
            
            // The first block in a chunk will always be the left-most with the current method for world generation.
            if it.blocks[0].pos.x > window_end.x continue;

            array_add(*active_chunks, it);
            
            // @TODO: draw active blocks, but simulate active chunks. Or something.
            for block: it.blocks {
                array_add(*active_blocks, *block);
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
            if IsKeyPressed(.KEY_P) paused = !paused;
            if IsKeyPressed(.KEY_G) debug_mode = !debug_mode;
            if IsKeyPressed(.KEY_R) player.pos = Vector2.{ GetScreenWidth() / 2.0, -1.0 * GetScreenHeight() };

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
                    player.vel.x -= PLAYER_SPEED_MOVE;
                    player.is_facing_left = true;
                }

                if move_player_right {
                    player.vel.x += PLAYER_SPEED_MOVE;
                    player.is_facing_left = false;
                }

                if try_to_jump && can_jump(player) {
                    player.vel.y = -PLAYER_SPEED_JUMP;
                    player.jumps_remaining -= 1;
                }

                if player.vel.y < PLAYER_SPEED_MAX player.vel.y += ACCEL_DUE_TO_GRAVITY * dt * 0.5;

                collided_horizontally := try_to_move(*player, player.vel.x * dt, active_blocks, true)  != null;
                collided_vertically   := try_to_move(*player, player.vel.y * dt, active_blocks, false) != null;

                if collided_horizontally player.vel.x = 0;
                if collided_vertically {
                    player.vel.y = 0;
                } else {
                    if player.vel.y < PLAYER_SPEED_MAX player.vel.y += ACCEL_DUE_TO_GRAVITY * dt * 0.5;
                }

                // Respawn player if they fall through the world
                if player.pos.y > 500000 {
                    player = spawn_player();
                }

                // Update position-dependent fields on player entity
                player.bounding_rect.x    = player.pos.x - PLAYER_WORLD_BOUNDING_WIDTH  / 2.0;
                player.bounding_rect.y    = player.pos.y - PLAYER_WORLD_BOUNDING_HEIGHT / 2.0 + 10;
                player.sprite_rect.x = player.pos.x - PLAYER_WORLD_HEAD_SPRITE_WIDTH  / 2.0;
                player.sprite_rect.y = player.pos.y - PLAYER_WORLD_HEAD_SPRITE_HEIGHT / 2.0;

                player_is_grounded = is_grounded(player, active_blocks);
                if player_is_grounded {
                    player.jumps_remaining = player.jumps_capacity;
                    player.vel.y = 0;
                }

                if try_to_attack {
                    is_on_cooldown := player.cooldown_attack_current_ms > 0;

                    if !is_on_cooldown {
                        if Vector2Distance(mouse_pos_in_world, player.pos) < PLAYER_REACH_DISTANCE {
                            // @TODO: is there a way in Jai to have some sort of generic whereby I can tell this function that it returns a *Block? 
                            block_mouse_is_over : *Block = cast(*Block) get_colliding_entity_by_vec2(mouse_pos_in_world, active_blocks);
                            if block_mouse_is_over != null {
                                // @TODO: kicking off some little animation of it being sized bigger and smaller like modern terraria does could be cool

                                // @TODO: when there is an inventory, this 1 will have to be whatever attack stat the equipped weapon has.
                                block_mouse_is_over.health_curr -= 1;
                                if block_mouse_is_over.health_curr <= 0 {
                                    removed := array_unordered_remove_entity_by_id(*chunks[block_mouse_is_over.chunk_id].blocks, block_mouse_is_over.*, true);
                                }
                            }
                        }

                        player.cooldown_attack_current_ms = PLAYER_COOLDOWN_ATTACK_DURATION_MS;
                    }
                }

                // For now this just places down dirt blocks
                if try_to_interact {
                    is_on_cooldown := player.cooldown_interact_current_ms > 0;

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
                                if !CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) continue;
                                
                                found_chunk = true;
                                new_dirt_block.chunk_id = it.id;
                                array_add(*chunks[it.id].blocks, new_dirt_block);

                                break;
                            }
                            assert(found_chunk);

                            player.cooldown_interact_current_ms = PLAYER_COOLDOWN_INTERACT_DURATION_MS;
                        }
                    }
                }

                // @TODO: this feels not great. I have to remember to add these here.
                // Update animations
                {
                    swinging : bool;

                    trying_to_move_horizontally := move_player_left != move_player_right;
                    trying_to_run               := trying_to_move_horizontally && player_is_grounded;
                    airborne_or_idle            := !trying_to_move_horizontally || !player_is_grounded;
                    idle_on_ground              := !trying_to_move_horizontally && player_is_grounded;
                    falling_quickly             := player.vel.y > 325.0;

                    // Arms swinging
                    {
                        was_previously_active := player_animation_hands_swinging.active;
                        // @NOTE: this check relies on the assumption that the interaction cooldown will always be reset when
                        // a player does something. This seems like a fairly reasonable assumption, but it's possible that this
                        // will not always be the case. A more explicit record of what the player actually did this frame and the
                        // previous frame is what is probably needed to bulletproof this.
                        player_began_action   := player.cooldown_interact_current_ms == PLAYER_COOLDOWN_INTERACT_DURATION_MS ||
                                                 player.cooldown_attack_current_ms   == PLAYER_COOLDOWN_ATTACK_DURATION_MS;
                        still_playing_out     := player_animation_hands_swinging.timer_ms <= animation_get_total_duration_ms(player_animation_hands_swinging);
                        should_start_now := !was_previously_active && player_began_action;
                        should_continue  := was_previously_active && still_playing_out;
                        
                        swinging = should_start_now || should_continue;

                        player_animation_hands_swinging.active      = swinging;
                        player_animation_undershirt_swinging.active = swinging;
                    }

                    // Idle (or airborne)
                    {
                        player_sprite_head_idle.active           = airborne_or_idle;
                        player_sprite_hair_1_idle.active         = airborne_or_idle;
                        player_sprite_eye_white_idle.active      = airborne_or_idle;
                        player_sprite_eye_iris_idle.active       = airborne_or_idle;
                        player_sprite_pants_idle.active          = idle_on_ground;
                        player_sprite_shoes_idle.active          = idle_on_ground;
                        player_sprite_chest_grounded_idle.active = idle_on_ground || (!player_is_grounded && !falling_quickly);
                        player_sprite_undershirt_idle.active     = idle_on_ground && !swinging;
                        player_sprite_hands_idle.active          = idle_on_ground && !swinging;
                    }

                    // Running
                    {
                        player_animation_head_running.active           = trying_to_run;
                        player_animation_hair_1_running.active         = trying_to_run;
                        player_animation_eye_white_running.active      = trying_to_run;
                        player_animation_eye_iris_running.active       = trying_to_run;
                        player_animation_chest_grounded_running.active = trying_to_run;
                        player_animation_pants_running.active          = trying_to_run;
                        player_animation_shoes_running.active          = trying_to_run;
                        player_animation_undershirt_running.active     = trying_to_run && !swinging;
                        player_animation_hands_running.active          = trying_to_run && !swinging;
                    }

                    // Airborne
                    {
                        player_sprite_pants_airborne.active      = !player_is_grounded;
                        player_sprite_shoes_airborne.active      = !player_is_grounded;
                        player_sprite_undershirt_airborne.active = !player_is_grounded && !falling_quickly && !swinging;
                        player_sprite_hands_airborne.active      = !player_is_grounded && !falling_quickly && !swinging;
                    }

                    // Falling
                    {
                        player_sprite_chest_falling.active      = falling_quickly;
                        player_sprite_undershirt_falling.active = falling_quickly && !swinging;
                        player_sprite_hands_falling.active      = falling_quickly && !swinging;
                    }

                    for player_animations {
                        if it.active {
                            it.timer_ms += xx (dt * 1000);

                            if !it.loops && it.timer_ms > animation_get_total_duration_ms(it.*) {
                                it.timer_ms = 0;
                                it.active   = false;
                            }   
                        } else {
                            it.timer_ms = 0;
                        };
                    }
                }

                // Update player cooldowns
                // @TODO: feels like there's some metaprogramming possibility here, or at least a loop.
                {
                    if player.cooldown_attack_current_ms > 0 {
                        player.cooldown_attack_current_ms -= xx (dt * 1000);
                    }

                    if player.cooldown_interact_current_ms > 0 {
                        player.cooldown_interact_current_ms -= xx (dt * 1000);
                    }
                }
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

                // Draw blocks
                {
                    for active_blocks {
                        block_map : Texture;
                        source    : Rectangle;

                        if it.block_type == {
                            case .DIRT;
                                block_map = dirt_map;
                                source    = Rectangle.{0, 5 * DIRT_MAP_TILE_HEIGHT, DIRT_MAP_TILE_WIDTH - DIRT_MAP_TILE_PADDING, DIRT_MAP_TILE_HEIGHT - DIRT_MAP_TILE_PADDING};
                            case .ROCK;
                                block_map = rock_map;
                                source    = Rectangle.{1 * ROCK_MAP_TILE_WIDTH, 1 * ROCK_MAP_TILE_HEIGHT, ROCK_MAP_TILE_WIDTH - ROCK_MAP_TILE_PADDING, ROCK_MAP_TILE_HEIGHT - ROCK_MAP_TILE_PADDING};
                            case;
                                assert(false, "Unknown block type");
                        }

                        DrawTexturePro(block_map, source, it.sprite_rect, Vector2.{ 0, 0 }, 0.0, WHITE);

                        frame := DAMAGE_MAP_COLS-1 - floor(cast(float32) it.health_curr * DAMAGE_MAP_COLS / it.health_max);

                        // Damage overlay (cracks)
                        if it.health_curr < it.health_max {
                            source = Rectangle.{cast(float32) frame * DAMAGE_MAP_TILE_WIDTH, 0, DAMAGE_MAP_TILE_WIDTH, DAMAGE_MAP_TILE_HEIGHT};
                            DrawTexturePro(damage_map, source, it.sprite_rect, Vector2.{ 0, 0 }, 0.0, WHITE);
                        }

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
                    // @TODO: DRY
                    for player_sprites {
                        if !it.active continue;

                        frame        := it.first_frame;
                        source_width : float = xx ifx player.is_facing_left then -PLAYER_MAP_TILE_WIDTH else PLAYER_MAP_TILE_WIDTH;
                        source_rect  := Rectangle.{xx (frame * PLAYER_MAP_TILE_WIDTH), 0.0, source_width, PLAYER_MAP_TILE_HEIGHT};

                        DrawTexturePro(it.map, source_rect, player.sprite_rect, Vector2.{ 0, 0 }, 0.0, it.color);
                    }

                    for player_animations {
                        if !it.active continue;

                        frame        := animation_get_current_frame(it);
                        source_width : float = xx ifx player.is_facing_left then -PLAYER_MAP_TILE_WIDTH else PLAYER_MAP_TILE_WIDTH;
                        source_rect  := Rectangle.{xx (frame * PLAYER_MAP_TILE_WIDTH), 0.0, source_width, PLAYER_MAP_TILE_HEIGHT};

                        DrawTexturePro(it.map, source_rect, player.sprite_rect, Vector2.{ 0, 0 }, 0.0, it.color);
                    }

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

                // @TODO: Draw pause menu
                if paused {

                }
            }
        }
    }
}

// @TODO: it would be cool to have a debug mode for this and hot swap the debug sprite sheets.
init_textures :: () {
    player_head_map           = LoadTexture("data/Player_Head_Release.png");
    player_hair_1_map         = LoadTexture("data/Player_Hair_1_Release.png");
    player_eye_white_map      = LoadTexture("data/Player_Eye_White_Release.png");
    player_eye_iris_map       = LoadTexture("data/Player_Eye_Iris_Release.png");
    player_chest_grounded_map = LoadTexture("data/Player_Chest_Grounded_Release.png");
    player_chest_airborne_map = LoadTexture("data/Player_Chest_Airborne_Release.png");
    player_undershirt_map     = LoadTexture("data/Player_Undershirt_Release.png");
    player_pants_map          = LoadTexture("data/Player_Pants_Release.png");
    player_hands_map          = LoadTexture("data/Player_Hands_Release.png");
    player_shoes_map          = LoadTexture("data/Player_Shoes_Release.png");
    dirt_map                  = LoadTexture("data/Tiles_0.png");
    rock_map                  = LoadTexture("data/Tiles_1.png");
    damage_map                = LoadTexture("data/Damage.png");
}

init_sprites :: () {
    player_sprite_head_idle = Sprite.{
        map         = player_head_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_IDLE,
        color       = PLAYER_COLOR_SKIN,
    };

    player_animation_head_running = AnimatedSprite.{
        map               = player_head_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = PLAYER_COLOR_SKIN,
        loops             = true,
    };

    player_sprite_hair_1_idle = Sprite.{
        map         = player_hair_1_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color       = PLAYER_COLOR_HAIR,
    };

    player_animation_hair_1_running = AnimatedSprite.{
        map               = player_hair_1_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = PLAYER_COLOR_HAIR,
        loops             = true,
    };

    player_sprite_eye_white_idle = Sprite.{
        map         = player_eye_white_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color       = WHITE,
    };

    player_animation_eye_white_running = AnimatedSprite.{
        map               = player_eye_white_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = WHITE,
        loops             = true,
    };
    
    player_sprite_eye_iris_idle = Sprite.{
        map         = player_eye_iris_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color       = PLAYER_COLOR_EYE,
    };

    player_animation_eye_iris_running = AnimatedSprite.{
        map               = player_eye_iris_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = PLAYER_COLOR_EYE,
        loops             = true,
    };

    player_sprite_chest_grounded_idle = Sprite.{
        map         = player_chest_grounded_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color       = PLAYER_COLOR_CHEST,
    };

    player_animation_chest_grounded_running = AnimatedSprite.{
        map               = player_chest_grounded_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = PLAYER_COLOR_CHEST,
        loops             = true,
    };

    // There's not really a need for a running version of this since it's a different sprite sheet.
    player_sprite_chest_falling = Sprite.{
        map         = player_chest_airborne_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color       = PLAYER_COLOR_CHEST,
    };

    player_sprite_undershirt_idle = Sprite.{
        map         = player_undershirt_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color       = PLAYER_COLOR_UNDERSHIRT,
    };

    player_animation_undershirt_running = AnimatedSprite.{
        map               = player_undershirt_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = PLAYER_COLOR_UNDERSHIRT,
        loops             = true,
    };

    player_sprite_undershirt_airborne = Sprite.{
        map         = player_undershirt_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        color       = PLAYER_COLOR_UNDERSHIRT,
    };

    player_sprite_undershirt_falling = Sprite.{
        map         = player_undershirt_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_FALLING,
        color       = PLAYER_COLOR_UNDERSHIRT,
    };

    player_animation_undershirt_swinging = AnimatedSprite.{
        map               = player_undershirt_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_SWINGING,
        frame_count       = 4,
        frame_duration_ms = PLAYER_ANIMATION_SWING_DURATION_MS,
        color             = PLAYER_COLOR_UNDERSHIRT,
        loops             = false,
    };

    player_sprite_pants_idle = Sprite.{
        map         = player_pants_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color       = PLAYER_COLOR_PANTS,
    };

    player_animation_pants_running = AnimatedSprite.{
        map               = player_pants_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = PLAYER_COLOR_PANTS,
        loops             = true,
    };

    player_sprite_pants_airborne = Sprite.{
        map         = player_pants_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_FALLING,
        color       = PLAYER_COLOR_PANTS,
    };

    player_sprite_hands_idle = Sprite.{
        map               = player_hands_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = PLAYER_COLOR_SKIN,
    };

    player_animation_hands_running = AnimatedSprite.{
        map               = player_hands_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = PLAYER_COLOR_SKIN,
        loops             = true,
    };

    player_sprite_hands_airborne = Sprite.{
        map         = player_hands_map,
        first_frame = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        color       = PLAYER_COLOR_SKIN,
    };

    player_sprite_hands_falling = Sprite.{
        map               = player_hands_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_FALLING,
        color             = PLAYER_COLOR_SKIN,
    };

    player_animation_hands_swinging = AnimatedSprite.{
        map               = player_hands_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_SWINGING,
        frame_count       = 4,
        frame_duration_ms = PLAYER_ANIMATION_SWING_DURATION_MS,
        color             = PLAYER_COLOR_SKIN,
        loops             = false,
    };

    player_sprite_shoes_idle = Sprite.{
        map               = player_shoes_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = PLAYER_COLOR_SHOES,
    };

    player_animation_shoes_running = AnimatedSprite.{
        map               = player_shoes_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        frame_count       = 14,
        frame_duration_ms = PLAYER_ANIMATION_RUN_DURATION_MS,
        color             = PLAYER_COLOR_SHOES,
        loops             = true,
    };

    player_sprite_shoes_airborne = Sprite.{
        map               = player_shoes_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_FALLING,
        color             = PLAYER_COLOR_SHOES,
    };

    array_add(*player_sprites, *player_sprite_head_idle);
    array_add(*player_sprites, *player_sprite_hair_1_idle);
    array_add(*player_sprites, *player_sprite_eye_white_idle);
    array_add(*player_sprites, *player_sprite_eye_iris_idle);
    array_add(*player_sprites, *player_sprite_chest_grounded_idle);
    array_add(*player_sprites, *player_sprite_chest_falling);
    array_add(*player_sprites, *player_sprite_undershirt_airborne);
    array_add(*player_sprites, *player_sprite_undershirt_falling);
    array_add(*player_sprites, *player_sprite_undershirt_idle);
    array_add(*player_sprites, *player_sprite_pants_idle);
    array_add(*player_sprites, *player_sprite_pants_airborne);
    array_add(*player_sprites, *player_sprite_hands_idle);
    array_add(*player_sprites, *player_sprite_hands_airborne);
    array_add(*player_sprites, *player_sprite_hands_falling);
    array_add(*player_sprites, *player_sprite_shoes_idle);
    array_add(*player_sprites, *player_sprite_shoes_airborne);

    array_add(*player_animations, *player_animation_head_running);
    array_add(*player_animations, *player_animation_hair_1_running);
    array_add(*player_animations, *player_animation_eye_white_running);
    array_add(*player_animations, *player_animation_eye_iris_running);
    array_add(*player_animations, *player_animation_chest_grounded_running);
    array_add(*player_animations, *player_animation_undershirt_running);
    array_add(*player_animations, *player_animation_undershirt_swinging);
    array_add(*player_animations, *player_animation_pants_running);
    array_add(*player_animations, *player_animation_hands_running);
    array_add(*player_animations, *player_animation_hands_swinging);
    array_add(*player_animations, *player_animation_shoes_running);
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

is_colliding :: (subject: Entity, collidables: [] $T/interface Entity) -> bool {
    for collidables {
        if CheckCollisionRecs(it.bounding_rect, subject.bounding_rect) {
            return true;
        }
    }

    return false;
}

get_colliding_by_rect :: (subject_rect: Rectangle, collidables: [] $T/interface *Entity) -> *Entity {
    for collidables {
        if CheckCollisionRecs(it.bounding_rect, subject_rect) {
            return it;
        }
    }

    return null;
}

get_colliding_entity_by_vec2 :: (subject_vec2: Vector2, collidables: [] $T/interface *Entity) -> result: *Entity {
    for collidables {
        if CheckCollisionPointRec(subject_vec2, it.bounding_rect) {
            return it;
        }
    }

    return null;
}

// Returns a pointer to the entity the subject collided with, if anything.
try_to_move :: (entity: *Entity, distance: float, collidables: [] $T/interface *Entity, horizontal: bool) -> *Entity {
    move := round_to_int(distance);
    if move == 0 return null;

    sign := ifx move > 0 then 1 else -1;

    entity_rect_if_move := entity.bounding_rect;

    while move != 0 {
        if horizontal {
            entity_rect_if_move.x += sign;
        } else {
            entity_rect_if_move.y += sign;
        }

        entity_subject_would_have_collided_with := get_colliding_by_rect(entity_rect_if_move, collidables);
        if entity_subject_would_have_collided_with != null return entity_subject_would_have_collided_with;

        if horizontal {
            entity.pos.x += sign;
        } else {
            entity.pos.y += sign;
        }
        
        move -= sign;
    }

    return null;
}

can_jump :: (player: Player) -> bool {
    return player.jumps_remaining > 0;
}

is_grounded :: (entity: Entity, collidables: [] $T/interface Entity) -> bool {
    entity_rect_if_move := entity.bounding_rect;
    entity_rect_if_move.y += 1;
    return get_colliding_by_rect(entity_rect_if_move, collidables) != null;
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

animation_get_current_frame :: (animation: AnimatedSprite) -> u32 {
    if animation.frame_duration_ms == 0 return 0;
    return ((animation.timer_ms / animation.frame_duration_ms) % animation.frame_count) + animation.first_frame;
}

// Returns the duration of one full playing of the animation. So, if there are 10 frames, each 50 ms long, the
// duration would be 500ms
animation_get_total_duration_ms :: (animation: AnimatedSprite) -> u32 {
    return animation.frame_count * animation.frame_duration_ms;
}

spawn_player :: () -> Player {
    pos := Vector2.{ GetScreenWidth() / 2.0, -1.0 * GetScreenHeight() };

    global_id_counter += 1;
    return Player.{
        id = global_id_counter,

        pos = pos,
        vel = Vector2.{ 0, 0 },

        bounding_rect = Rectangle.{
            pos.x - floor(PLAYER_WORLD_BOUNDING_WIDTH / 2.0),
            pos.y - floor(PLAYER_WORLD_BOUNDING_HEIGHT / 2.0) + 5,
            xx PLAYER_WORLD_BOUNDING_WIDTH,
            xx PLAYER_WORLD_BOUNDING_HEIGHT,
        },
        sprite_rect = Rectangle.{
            pos.x - floor(PLAYER_WORLD_HEAD_SPRITE_WIDTH / 2.0),
            pos.y - floor(PLAYER_WORLD_HEAD_SPRITE_HEIGHT / 2.0),
            xx PLAYER_WORLD_HEAD_SPRITE_WIDTH,
            xx PLAYER_WORLD_HEAD_SPRITE_HEIGHT,
        },

        jumps_capacity  = 2,
        jumps_remaining = 2,

        is_facing_left = false,

        cooldown_attack_current_ms   = 0,
        cooldown_interact_current_ms = 0,
    };
}

perlin_noise :: (desired_values: u32, starting_frequency: u32, starting_amplitude: float32, octaves: u32) -> [..] float {
    assert(desired_values % starting_frequency == 0, "The perlin noise frequency must be a divisor of the number of desired values.");

    results : [..] float;
    for i: 0..desired_values {
        array_add(*results, 0.0);
    }

    for o: 0..octaves {
        octave_factor      := pow(2.0, cast(float) o);
        amplitude          := starting_amplitude / octave_factor;
        frequency          := starting_frequency * octave_factor;
        ratio              := desired_values / frequency;
        blocks_per_section := cast(int) (desired_values / frequency);
    
        // print_vars(octave_factor, amplitude, frequency, ratio, blocks_per_section);

        random_grid_scalars: [..]float;
        for i: 0..(xx frequency-1) {
            array_add(*random_grid_scalars, random_get_within_range(-1, 1));
        }

        // @TODO: maybe loop around to the first section's left gradient?
        for i: 0..(desired_values - (blocks_per_section + 1)) {
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
            results[i] += amplitude * perlin;
        }
    }

    return results;
}