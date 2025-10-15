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
scroll_as_zoom    : bool;
hotbar_swap_next  : bool;
hotbar_swap_prev  : bool;

// Textures and texture maps
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
grass_map                 : Texture;
rock_map                  : Texture;
damage_map                : Texture;
pickaxe_texture           : Texture;

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

item_sprite_dirt    : Sprite;
item_sprite_grass   : Sprite;
item_sprite_rock    : Sprite;
item_sprite_pickaxe : Sprite;

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
PLAYER_ANIMATION_WIELD_DURATION_MS :: PLAYER_ANIMATION_SWING_DURATION_MS / 3;

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

INVENTORY_EMPTY_SLOT :: -1;
INVENTORY_SLOTS      :: 32;
HOTBAR_SLOTS         :: 8;

ACCEL_DUE_TO_GRAVITY :: PLAYER_WORLD_BOUNDING_HEIGHT * 25;

BLOCK_HEALTH_MAX :: 100;

DIRT_MAP_COLS :: 16;
DIRT_MAP_ROWS :: 15;
DIRT_MAP_TILE_WIDTH  :: 18;
DIRT_MAP_TILE_HEIGHT :: 18;
DIRT_MAP_TILE_PADDING :: 2;
DIRT_WORLD_TILE_WIDTH  :: 18 * SCALE;
DIRT_WORLD_TILE_HEIGHT :: 18 * SCALE;
DIRT_STACK_CAPACITY :: 64;
DIRT_HARDNESS :: 0.5;

GRASS_MAP_COLS :: 16;
GRASS_MAP_ROWS :: 22;
GRASS_MAP_TILE_WIDTH  :: 18;
GRASS_MAP_TILE_HEIGHT :: 18;
GRASS_MAP_TILE_PADDING :: 2;
GRASS_WORLD_TILE_WIDTH  :: 18 * SCALE;
GRASS_WORLD_TILE_HEIGHT :: 18 * SCALE;
GRASS_STACK_CAPACITY :: 64;
GRASS_HARDNESS :: 1.0;

ROCK_MAP_COLS :: 16;
ROCK_MAP_ROWS :: 15;
ROCK_MAP_TILE_WIDTH  :: 18;
ROCK_MAP_TILE_HEIGHT :: 18;
ROCK_MAP_TILE_PADDING :: 2;
ROCK_WORLD_TILE_WIDTH  :: 18 * SCALE;
ROCK_WORLD_TILE_HEIGHT :: 18 * SCALE;
ROCK_STACK_CAPACITY :: 64;
ROCK_HARDNESS :: 10.0;

DAMAGE_MAP_COLS :: 10;
DAMAGE_MAP_ROWS :: 1;
DAMAGE_MAP_TILE_WIDTH  :: 16;
DAMAGE_MAP_TILE_HEIGHT :: 16;
DAMAGE_WORLD_TILE_WIDTH  :: 18 * SCALE;
DAMAGE_WORLD_TILE_HEIGHT :: 18 * SCALE;

PICKAXE_TEXTURE_WIDTH  :: 32;
PICKAXE_TEXTURE_HEIGHT :: 32;
PICKAXE_STACK_CAPACITY :: -1;

WIELDED_TOOL_WORLD_LENGTH  :: 65;
WIELDED_BLOCK_WORLD_LENGTH :: 30;

WORLD_GRID_COLS :: 1000;

DEBUG_CAM_SPEED :: 5;

global_id_counter: u32 = 0;

Entity :: struct {
    type           : Type;

    id             : u32; 
    chunk_id       : u32;

    pos            : Vector2;
    vel            : Vector2;

    is_facing_left : bool;

    bounding_rect  : Rectangle; // Used for collision
    sprite_rect    : Rectangle;

    health_max     : s32;
    health_curr    : s32;
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

// @TODO: it would be cool to have this like in typescript
// ItemType = BlockType | ToolType;
ItemType :: enum {
    DIRT;
    GRASS;
    ROCK;
    PICKAXE;
}

ItemStack :: struct {
    item_type      : ItemType;
    stack_capacity : s32; // -1 means this isn't really a stack, but just an item. e.g. a pickaxe
    stack_count    : s32;
}

EMPTY_ITEM_SLOT :: ItemStack.{ -1, -1, -1 };

Inventory :: struct {
    item_stacks         : [INVENTORY_SLOTS] ItemStack;
    selected_item_stack : u32;
}

Player :: struct {
    #as using entity : Entity;

    jumps_remaining : int;
    jumps_capacity  : int; // e.g. 2 if an entity can double jump, 6 for kirby in melee, etc.

    cooldown_attack_current_ms   : s32;
    cooldown_interact_current_ms : s32;

    inventory : Inventory;
}

Block :: struct {
    #as using entity : Entity;
    
    item_type    : ItemType;
    hardness     : float32;
    weak_to_tool : ItemType;
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
    scroll_as_zoom    : [3] Control;
    hotbar_slot_1     : [3] Control;
    hotbar_slot_2     : [3] Control;
    hotbar_slot_3     : [3] Control;
    hotbar_slot_4     : [3] Control;
    hotbar_slot_5     : [3] Control;
    hotbar_slot_6     : [3] Control;
    hotbar_slot_7     : [3] Control;
    hotbar_slot_8     : [3] Control;
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
    for col: 0..(WORLD_GRID_COLS - 1) {
        chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division.

        if col % CHUNK_MAX_WIDTH == 0 {
            chunk = New(Chunk);
            chunk.id = xx chunk_id;
            array_add(*chunks, chunk);
        }
    }

    DIRT_PERLIN_NOISE_FREQUENCY :: 2; // How many grid nodes per map
    DIRT_PERLIN_NOISE_AMPLITUDE :: 150;
    DIRT_PERLIN_NOISE_OCTAVES   :: 5;
    DIRT_PERLIN_NOISE_MIN_VALUE :: 10;
    dirt_heights := perlin_noise(WORLD_GRID_COLS, DIRT_PERLIN_NOISE_FREQUENCY, DIRT_PERLIN_NOISE_AMPLITUDE, DIRT_PERLIN_NOISE_OCTAVES, DIRT_PERLIN_NOISE_MIN_VALUE);

    ROCK_PERLIN_NOISE_FREQUENCY :: 4; // How many grid nodes per map
    ROCK_PERLIN_NOISE_AMPLITUDE :: 100;
    ROCK_PERLIN_NOISE_OCTAVES   :: 2;
    ROCK_PERLIN_NOISE_MIN_VALUE :: 0;
    rock_depths := perlin_noise(WORLD_GRID_COLS, ROCK_PERLIN_NOISE_FREQUENCY, ROCK_PERLIN_NOISE_AMPLITUDE, ROCK_PERLIN_NOISE_OCTAVES, ROCK_PERLIN_NOISE_MIN_VALUE);

    initial_x := ((DIRT_WORLD_TILE_WIDTH * WORLD_GRID_COLS + GetScreenWidth()) / 2.0 * -1.0) + 8.0;

    // Initialize blocks
    x := initial_x;

    for columns_generated: 0..WORLD_GRID_COLS {
        col := columns_generated;
        y   := 0;

        // Generate hills
        hill_dirt_blocks := cast(int) abs(dirt_heights[col]);
        for hill_rows_generated: 0..hill_dirt_blocks {
            rect := Rectangle.{
                xx x,
                xx y,
                xx DIRT_WORLD_TILE_WIDTH,
                xx DIRT_WORLD_TILE_HEIGHT,
            };

            // @TODO: post increment macro or something?
            chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division.
            defer global_id_counter += 1;
            array_add(
                *chunks[chunk_id].blocks,
                // @TODO: maybe some sort of constructor could be nice like create_block(.DIRT, x, y, ...)
                Block.{
                    type          = Block,
                    id            = global_id_counter,
                    chunk_id      = xx chunk_id,
                    pos           = Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 },
                    bounding_rect = rect,
                    sprite_rect   = rect,
                    health_curr   = BLOCK_HEALTH_MAX,
                    health_curr   = BLOCK_HEALTH_MAX,
                    item_type     = ifx hill_rows_generated == hill_dirt_blocks then .GRASS else .DIRT,
                    hardness      = DIRT_HARDNESS,
                }
            );

            y -= DIRT_WORLD_TILE_HEIGHT;
        }

        // Generate ground dirt
        ground_dirt_blocks := cast(int) abs(rock_depths[col]);
        y = 0;

        for ground_rows_generated: 0..ground_dirt_blocks {
            rect := Rectangle.{
                xx x,
                xx y,
                xx DIRT_WORLD_TILE_WIDTH,
                xx DIRT_WORLD_TILE_HEIGHT,
            };

            // @TODO: post incrememnt macro or something?
            chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division. @TODO: int division function for clarity? like divide_u32, divide_s64, etc.? 
            defer global_id_counter += 1;
            array_add(
                *chunks[chunk_id].blocks,
                Block.{
                    type          = Block,
                    id            = global_id_counter,
                    chunk_id      = xx chunk_id,
                    pos           = Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 },
                    bounding_rect = rect,
                    sprite_rect   = rect,
                    health_max    = BLOCK_HEALTH_MAX,
                    health_curr   = BLOCK_HEALTH_MAX,
                    item_type    = .DIRT,
                }
            );

            y += DIRT_WORLD_TILE_HEIGHT;
        }

        // Generate rock
        rock_blocks := cast(int) abs(cast(float) rock_depths[col]);

        for rock_rows_generated: 0..(100 - ground_dirt_blocks) {
            rect := Rectangle.{
                xx x,
                xx y,
                xx DIRT_WORLD_TILE_WIDTH,
                xx DIRT_WORLD_TILE_HEIGHT,
            };

            // cast(float)(ROCK_WORLD_TILE_HEIGHT * (ground_dirt_blocks + height))

            // @TODO: post incrememnt macro or something?
            chunk_id := col / CHUNK_MAX_WIDTH; // Intentional integer division.
            defer global_id_counter += 1;
            array_add(
                *chunks[chunk_id].blocks,
                Block.{
                    type          = Block,
                    id            = global_id_counter,
                    chunk_id      = xx chunk_id,
                    pos           = Vector2.{ rect.x + rect.width / 2.0, rect.y + rect.height / 2.0 },
                    bounding_rect = rect,
                    sprite_rect   = rect,
                    health_max    = BLOCK_HEALTH_MAX,
                    health_curr   = BLOCK_HEALTH_MAX,
                    item_type    = .ROCK,
                }
            );

            y += ROCK_WORLD_TILE_HEIGHT;
        }

        x += DIRT_WORLD_TILE_WIDTH;
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
    controls.hotbar_slot_1[0]     = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_ONE             };
    controls.hotbar_slot_2[0]     = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_TWO             };
    controls.hotbar_slot_3[0]     = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_THREE           };
    controls.hotbar_slot_4[0]     = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_FOUR            };
    controls.hotbar_slot_5[0]     = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_FIVE            };
    controls.hotbar_slot_6[0]     = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_SIX             };
    controls.hotbar_slot_7[0]     = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_SEVEN           };
    controls.hotbar_slot_8[0]     = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_EIGHT           };
    controls.scroll_as_zoom[0]    = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_LEFT_CONTROL    };
    controls.scroll_as_zoom[1]    = Control.{ type = KeyboardKey, value = cast(s32) KeyboardKey.KEY_RIGHT_CONTROL   };

    global_swing_timer_ms : u32;

    TRANSPARENT_WHITE := Color.{ WHITE.r, WHITE.b, WHITE.a, 100 };

    while !WindowShouldClose() {
        defer reset_temporary_storage();

        time := GetTime();
        dt   := GetFrameTime();

        player_is_grounded : bool; // updated in player update to reduce calls to is_grounded to once for the player per frame.
        player_is_swinging : bool;

        window_start := GetScreenToWorld2D(Vector2.{ 0, 0 }, camera);
        window_end   := GetScreenToWorld2D(Vector2.{ cast(float) GetScreenWidth(), cast(float) GetScreenHeight()}, camera);

        active_chunks: [..]Chunk;
        active_chunks.allocator = temp;

        active_blocks: [..]*Block;
        active_blocks.allocator = temp;

        // @TODO: Having a notion of active chunks and active blocks is probably still too slow, but it's a step in the right direction.
        derive_active_chunks_and_active_blocks(chunks, *active_chunks, *active_blocks, window_start, window_end);

        mouse_pos_in_world := GetScreenToWorld2D(GetMousePosition(), camera);
        mouse_wheel_move   := GetMouseWheelMove();

        // Reset controls that need to be.
        try_to_jump     = false;
        try_to_attack   = false;
        try_to_interact = false;
        scroll_as_zoom  = false;

        //
        // Input
        //
        {
            if IsKeyPressed(.KEY_P) paused     = !paused;
            if IsKeyPressed(.KEY_G) debug_mode = !debug_mode;
            if IsKeyPressed(.KEY_R) player     = spawn_player();

            move_player_left   = control_down(controls.move_player_left);
            move_player_right  = control_down(controls.move_player_right);
            try_to_jump        = control_pressed(controls.jump);
            try_to_attack      = control_down(controls.attack);
            try_to_interact    = control_down(controls.interact); // place blocks, open doors, etc.
            drag_cam           = control_down(controls.drag_cam);
            scroll_as_zoom     = control_down(controls.scroll_as_zoom); // modifier to hold down to use scroll wheel as zoom.
            hotbar_slot_1     := control_pressed(controls.hotbar_slot_1);
            hotbar_slot_2     := control_pressed(controls.hotbar_slot_2);
            hotbar_slot_3     := control_pressed(controls.hotbar_slot_3);
            hotbar_slot_4     := control_pressed(controls.hotbar_slot_4);
            hotbar_slot_5     := control_pressed(controls.hotbar_slot_5);
            hotbar_slot_6     := control_pressed(controls.hotbar_slot_6);
            hotbar_slot_7     := control_pressed(controls.hotbar_slot_7);
            hotbar_slot_8     := control_pressed(controls.hotbar_slot_8);
            hotbar_swap_next   = mouse_wheel_move < 0 && !scroll_as_zoom; // scroll down to shift one up (think shifting right on minecraft hotbar).
            hotbar_swap_prev   = mouse_wheel_move > 0 && !scroll_as_zoom; // scroll up to shift one down (think shifting left on minecraft hotbar).
        
            if hotbar_slot_1 { player.inventory.selected_item_stack = 0; }
            if hotbar_slot_2 { player.inventory.selected_item_stack = 1; }
            if hotbar_slot_3 { player.inventory.selected_item_stack = 2; }
            if hotbar_slot_4 { player.inventory.selected_item_stack = 3; }
            if hotbar_slot_5 { player.inventory.selected_item_stack = 4; }
            if hotbar_slot_6 { player.inventory.selected_item_stack = 5; }
            if hotbar_slot_7 { player.inventory.selected_item_stack = 6; }
            if hotbar_slot_8 { player.inventory.selected_item_stack = 7; }
        }

        //
        // Update
        //
        if !paused {
            // Update player
            {
                // Movement
                {
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
                    player.bounding_rect.x = player.pos.x - PLAYER_WORLD_BOUNDING_WIDTH     / 2.0;
                    player.bounding_rect.y = player.pos.y - PLAYER_WORLD_BOUNDING_HEIGHT    / 2.0 + 10;
                    player.sprite_rect.x   = player.pos.x - PLAYER_WORLD_HEAD_SPRITE_WIDTH  / 2.0;
                    player.sprite_rect.y   = player.pos.y - PLAYER_WORLD_HEAD_SPRITE_HEIGHT / 2.0;

                    player_is_grounded = is_grounded(player, active_blocks);
                    if player_is_grounded {
                        player.jumps_remaining = player.jumps_capacity;
                        player.vel.y = 0;
                    }
                }

                if try_to_attack {
                    if debug_mode {
                        for chunks {
                            // @TODO: it would be nice to have the chunk the mouse is pointing in, as well as the chunk the player is in.
                            block_mouse_is_over : *Block = cast(*Block) get_colliding_entity_by_vec2(mouse_pos_in_world, it.blocks);
                            if block_mouse_is_over != null {
                                removed_id := array_unordered_remove_entity_by_id(*chunks[block_mouse_is_over.chunk_id].blocks, block_mouse_is_over.*, true);
                                break;
                            }
                        }
                    } else {
                        is_on_cooldown := player.cooldown_attack_current_ms > 0;

                        if !is_on_cooldown {
                            if Vector2Distance(mouse_pos_in_world, player.pos) < PLAYER_REACH_DISTANCE {
                                // @TODO: is there a way in Jai to have some sort of generic whereby I can tell this function that it returns a *Block? 
                                block_mouse_is_over : *Block = cast(*Block) get_colliding_entity_by_vec2(mouse_pos_in_world, active_blocks);

                                if block_mouse_is_over != null {
                                print_vars(block_mouse_is_over.*);
                                    // @TODO: kicking off some little animation of it being sized bigger and smaller like modern terraria does could be cool

                                    selected_item_stack, result      := get_selected_item_stack(player.inventory);
                                    has_an_item_selected             := result == xx ReturnStatus.SUCCESS;

                                    // damage : s32 = xx (1 / block_mouse_is_over.hardness);
                                    block_mouse_is_over.health_curr -= 1;
                                    
                                    if block_mouse_is_over.health_curr <= 0 {
                                        removed_id := array_unordered_remove_entity_by_id(*chunks[block_mouse_is_over.chunk_id].blocks, block_mouse_is_over.*, true);
                                        try_to_add_to_inventory(*player.inventory, block_mouse_is_over.item_type);
                                    }
                                }
                            }

                            player.cooldown_attack_current_ms = PLAYER_COOLDOWN_ATTACK_DURATION_MS;
                        }
                    }
                }

                // @TODO: This should actually not place down blocks, but interact with interactable items like doors.
                if try_to_interact {

                    is_on_cooldown := player.cooldown_interact_current_ms > 0;

                    if !is_on_cooldown {

                        selected_item_stack, result      := get_selected_item_stack(player.inventory);
                        has_an_item_selected             := result == xx ReturnStatus.SUCCESS;
                        item_can_be_placed_down := can_item_be_placed_down(selected_item_stack.item_type);

                        if has_an_item_selected && item_can_be_placed_down {

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
                            new_pos := get_rect_center(new_rect);

                            // Check if the new block would be placed on the player
                            if CheckCollisionRecs(new_rect, player.bounding_rect) {
                                would_be_on_existing_entity = true;
                            }

                            has_neighbor_block := false;
                            for active_blocks {
                                // Check for a neighbor above
                                if it.pos.x == new_pos.x && it.pos.y == new_pos.y - DIRT_WORLD_TILE_HEIGHT {
                                    has_neighbor_block = true;
                                    break;
                                }

                                // Check for a neighbor below
                                if it.pos.x == new_pos.x && it.pos.y == new_pos.y + DIRT_WORLD_TILE_HEIGHT {
                                    has_neighbor_block = true;
                                    break;
                                }

                                // Check for a neighbor left
                                if it.pos.x == new_pos.x - DIRT_WORLD_TILE_WIDTH && it.pos.y == new_pos.y {
                                    has_neighbor_block = true;
                                    break;
                                }

                                // Check for a neighbor right
                                if it.pos.x == new_pos.x + DIRT_WORLD_TILE_WIDTH && it.pos.y == new_pos.y {
                                    has_neighbor_block = true;
                                    break;
                                }
                            }

                            can_place_block := debug_mode || (is_within_reach && !would_be_on_existing_entity && has_neighbor_block);
                            
                            if can_place_block {
                                defer global_id_counter += 1;

                                new_pos := get_rect_center(new_rect);

                                new_block := Block.{
                                    id            = global_id_counter,
                                    pos           = new_pos,
                                    bounding_rect = new_rect,
                                    sprite_rect   = new_rect,
                                    item_type     = selected_item_stack.item_type,
                                    health_max    = BLOCK_HEALTH_MAX,
                                    health_curr   = BLOCK_HEALTH_MAX,
                                };
                                
                                found_chunk := false;
                                for active_chunks {
                                    if !CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) continue;
                                    
                                    found_chunk = true;
                                    new_block.chunk_id = it.id;
                                    add_block_to_chunk(it.id, new_block, *chunks, *active_chunks, *active_blocks, window_start, window_end);

                                    break;
                                }
                                assert(found_chunk);

                                player.inventory.item_stacks[player.inventory.selected_item_stack].stack_count -= 1;

                                player.cooldown_interact_current_ms = PLAYER_COOLDOWN_INTERACT_DURATION_MS;
                            }
                        }
                    }
                }

                // @TODO: this feels not great. I have to remember to add these here.
                // Update sprites and animations
                {
                    trying_to_move_horizontally := move_player_left != move_player_right;
                    trying_to_run               := trying_to_move_horizontally && player_is_grounded;
                    airborne_or_idle            := !trying_to_move_horizontally || !player_is_grounded;
                    idle_on_ground              := !trying_to_move_horizontally && player_is_grounded;
                    falling_quickly             := player.vel.y > 325.0;

                    // Arms swinging
                    {
                        was_previously_active := player_animation_hands_swinging.active;
                        player_began_action   := (try_to_attack || try_to_interact) && !was_previously_active;
                        still_playing_out     := player_animation_hands_swinging.timer_ms <= animation_get_total_duration_ms(player_animation_hands_swinging) &&
                                                 player_animation_hands_swinging.timer_ms > 0;
                        should_start_now := player_began_action;
                        should_continue  := was_previously_active && still_playing_out;
                        
                        player_is_swinging = should_start_now || should_continue;

                        player_animation_hands_swinging.active      = player_is_swinging;
                        player_animation_undershirt_swinging.active = player_is_swinging;
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
                        player_sprite_undershirt_idle.active     = idle_on_ground && !player_is_swinging;
                        player_sprite_hands_idle.active          = idle_on_ground && !player_is_swinging;
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
                        player_animation_undershirt_running.active     = trying_to_run && !player_is_swinging;
                        player_animation_hands_running.active          = trying_to_run && !player_is_swinging;
                    }

                    // Airborne
                    {
                        player_sprite_pants_airborne.active      = !player_is_grounded;
                        player_sprite_shoes_airborne.active      = !player_is_grounded;
                        player_sprite_undershirt_airborne.active = !player_is_grounded && !falling_quickly && !player_is_swinging;
                        player_sprite_hands_airborne.active      = !player_is_grounded && !falling_quickly && !player_is_swinging;
                    }

                    // Falling
                    {
                        player_sprite_chest_falling.active      = falling_quickly;
                        player_sprite_undershirt_falling.active = falling_quickly && !player_is_swinging;
                        player_sprite_hands_falling.active      = falling_quickly && !player_is_swinging;
                    }

                    // Update active animation timers
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

                    if player_is_swinging {
                        global_swing_timer_ms += xx (dt * 1000);
                    } else {
                        global_swing_timer_ms = 0;
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

                // Update inventory
                {
                    if hotbar_swap_next {
                        player.inventory.selected_item_stack = (player.inventory.selected_item_stack + 1) % HOTBAR_SLOTS;
                    }

                    if hotbar_swap_prev {
                        player.inventory.selected_item_stack = (player.inventory.selected_item_stack - 1) % HOTBAR_SLOTS;
                    }
                }
            }

            // Update camera
            {
                if drag_cam {
                    free_cam_pos = Vector2Add(free_cam_pos, Vector2Scale(GetMouseDelta(), -1.0 * DEBUG_CAM_SPEED));
                }

                if scroll_as_zoom {
                    camera.zoom += mouse_wheel_move * 0.1;
                }

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
                        block_map_texture, block_map_source := get_texture_map_by_item_type(it.item_type);

                        DrawTexturePro(block_map_texture, block_map_source, it.sprite_rect, Vector2.{ 0, 0 }, 0.0, WHITE);

                        frame := DAMAGE_MAP_COLS-1 - floor(cast(float32) it.health_curr * DAMAGE_MAP_COLS / it.health_max);

                        // Damage overlay (cracks)
                        if it.health_curr < it.health_max {
                            damage_map_source := Rectangle.{cast(float32) frame * DAMAGE_MAP_TILE_WIDTH, 0, DAMAGE_MAP_TILE_WIDTH, DAMAGE_MAP_TILE_HEIGHT};
                            DrawTexturePro(damage_map, damage_map_source, it.sprite_rect, Vector2.{ 0, 0 }, 0.0, WHITE);
                        }

                        // Mouse overlay (hover)
                        show_block_hover := Vector2Distance(mouse_pos_in_world, player.pos) < PLAYER_REACH_DISTANCE || debug_mode;
                        if show_block_hover {
                            if CheckCollisionPointRec(mouse_pos_in_world, it.bounding_rect) {
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

                        DrawLineEx(Vector2.{-WORLD_GRID_COLS * ROCK_WORLD_TILE_WIDTH / 2.0, 0.0 }, Vector2.{ WORLD_GRID_COLS * ROCK_WORLD_TILE_WIDTH / 2.0, 0.0 }, 2.0, RED);
                    }
                }

                // Draw player
                {
                    for player_sprites    { draw_sprite(it, player, PLAYER_MAP_TILE_WIDTH, PLAYER_MAP_TILE_HEIGHT); }
                    for player_animations { draw_sprite(it, player, PLAYER_MAP_TILE_WIDTH, PLAYER_MAP_TILE_HEIGHT); }

                    // Draw item wielded by player
                    if player_is_swinging {
                        selected_item_stack, result := get_selected_item_stack(player.inventory);
                        has_an_item_selected := result == xx ReturnStatus.SUCCESS;

                        if has_an_item_selected {
                            item_texture_map, item_source_rect := get_texture_map_by_item_type(selected_item_stack.item_type, player.is_facing_left);

                            length := get_item_world_length(selected_item_stack.item_type);
                            rotation : float;
                            destination_rect : Rectangle;
                            origin   := Vector2.{ xx ifx player.is_facing_left then length else 0, length - 10.0 };

                            if global_swing_timer_ms < 3 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                destination_rect = Rectangle.{
                                    ifx player.is_facing_left then player.pos.x + 25.0 else player.pos.x - 25.0,
                                    player.pos.y - 10.0,
                                    length,
                                    length,
                                };
                                
                                if global_swing_timer_ms < PLAYER_ANIMATION_WIELD_DURATION_MS {
                                    rotation = ifx player.is_facing_left then 105.0 else -105.0;
                                }
                                else if global_swing_timer_ms < 2 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                    rotation = ifx player.is_facing_left then 90.0 else  -90.0;
                                } else {
                                    rotation = ifx player.is_facing_left then 75.0 else  -75.0;
                                }
                            }
                            else if global_swing_timer_ms < 6 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                destination_rect = Rectangle.{
                                    ifx player.is_facing_left then player.pos.x - 5.0 else player.pos.x + 5.0,
                                    player.pos.y - 15.0,
                                    length,
                                    length,
                                };
                                
                                if global_swing_timer_ms < 4 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                    rotation = ifx player.is_facing_left then 45.0 else -45.0;
                                }
                                else if global_swing_timer_ms < 5 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                    rotation = ifx player.is_facing_left then 30.0 else -30.0;
                                } else {
                                    rotation = ifx player.is_facing_left then 0.0  else 0.0;
                                }
                            }
                            else if global_swing_timer_ms < 9 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                destination_rect = Rectangle.{
                                    ifx player.is_facing_left then player.pos.x - 15.0 else player.pos.x + 15.0,
                                    player.pos.y + 10.0,
                                    length,
                                    length,
                                };
                                
                                if global_swing_timer_ms < 7 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                    rotation = ifx player.is_facing_left then -15.0 else 15.0;
                                }
                                else if global_swing_timer_ms < 8 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                    rotation = ifx player.is_facing_left then -45.0 else 45.0;
                                } else {
                                    rotation = ifx player.is_facing_left then -60.0 else 60.0;
                                }
                            }
                            else if global_swing_timer_ms < 12 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                destination_rect = Rectangle.{
                                    ifx player.is_facing_left then player.pos.x - 20.0 else player.pos.x + 20.0,
                                    player.pos.y + 20.0,
                                    length,
                                    length,
                                };
                                
                                if global_swing_timer_ms < 10 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                    rotation = ifx player.is_facing_left then -75.0  else 75.0;
                                }
                                else if global_swing_timer_ms < 11 * PLAYER_ANIMATION_WIELD_DURATION_MS {
                                    rotation = ifx player.is_facing_left then -90.0  else 90.0;
                                } else {
                                    rotation = ifx player.is_facing_left then -105.0 else 105.0;
                                }
                            }

                            DrawTexturePro(item_texture_map, item_source_rect, destination_rect, origin, rotation, WHITE);
                        }
                    }

                    if debug_mode {
                        DrawRectangleLinesEx(player.bounding_rect, 1.0, LIME);
                        DrawCircleV(player.pos, 3.0, RED);
                    }
                }

                // Draw cursor
                if debug_mode {
                    DrawRectangleRec(create_rect_for_tile_from_point(mouse_pos_in_world, DIRT_WORLD_TILE_WIDTH, DIRT_WORLD_TILE_HEIGHT), TRANSPARENT_WHITE);
                }
            }

            // Draw UI
            {
                DrawFPS(GetScreenWidth() - 100, 10);

                // Hotbar
                HOTBAR_PANE_LENGTH    :: 50;
                HOTBAR_PANE_THICKNESS :: 3.0;
                for 0..7 {
                    hotbar_pane_rect := Rectangle.{
                        it * (HOTBAR_PANE_LENGTH + 3 * HOTBAR_PANE_THICKNESS) + 2 * HOTBAR_PANE_THICKNESS,
                        0 + 2 * HOTBAR_PANE_THICKNESS,
                        HOTBAR_PANE_LENGTH,
                        HOTBAR_PANE_LENGTH,
                    };
                    hotbar_pane_color := ifx player.inventory.selected_item_stack == it then WHITE else LIGHTGRAY;
                    
                    DrawRectangleRoundedLinesEx(hotbar_pane_rect, 0.1, 1, HOTBAR_PANE_THICKNESS, hotbar_pane_color);

                    item_stack_in_slot := player.inventory.item_stacks[it];
                    if !item_stack_is_empty(item_stack_in_slot) {
                        
                        item_texture_map, item_source_rect := get_texture_map_by_item_type(item_stack_in_slot.item_type);
                        DrawTexturePro(item_texture_map, item_source_rect, hotbar_pane_rect, Vector2.{ 0, 0 }, 0.0, WHITE);
                        
                        if item_type_is_stackable(item_stack_in_slot.item_type) {
                            DrawText(
                                tprint("%\0", item_stack_in_slot.stack_count).data,
                                xx (hotbar_pane_rect.x + 0.50 * HOTBAR_PANE_LENGTH),    
                                xx (hotbar_pane_rect.y + 0.67 * HOTBAR_PANE_LENGTH),    
                                18,
                                WHITE,
                            );
                        }
                    }

                    DrawText(
                        tprint("%\0", it + 1).data,
                        xx (hotbar_pane_rect.x + HOTBAR_PANE_THICKNESS * 1.5),
                        xx (hotbar_pane_rect.y + HOTBAR_PANE_THICKNESS * 1.5),
                        18,
                        WHITE,
                    );
                }

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

// @TODO: have function for getting width and height
draw_sprite :: (sprite: $T/Sprite, entity: Entity, texture_map_tile_width: u32, texture_map_tile_height: u32) {
    if !sprite.active return;

    frame        := animation_get_current_frame(sprite);
    source_width : float = ifx entity.is_facing_left then cast(float) texture_map_tile_width * -1 else cast(float) texture_map_tile_width;
    source_rect  := Rectangle.{xx (frame * texture_map_tile_width), 0.0, source_width, xx texture_map_tile_height};

    DrawTexturePro(sprite.map, source_rect, entity.sprite_rect, Vector2.{ 0, 0 }, 0.0, sprite.color);
}

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
    grass_map                 = LoadTexture("data/Tiles_2.png");
    damage_map                = LoadTexture("data/Damage.png");
    pickaxe_texture           = LoadTexture("data/Pickaxe.png");
}

init_sprites :: () {
    player_sprite_head_idle = Sprite.{
        map               = player_head_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE,
        color             = PLAYER_COLOR_SKIN,
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
        map               = player_hair_1_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = PLAYER_COLOR_HAIR,
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
        map               = player_eye_white_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = WHITE,
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
        map               = player_eye_iris_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = PLAYER_COLOR_EYE,
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
        map               = player_chest_grounded_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = PLAYER_COLOR_CHEST,
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
        map               = player_chest_airborne_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = PLAYER_COLOR_CHEST,
    };

    player_sprite_undershirt_idle = Sprite.{
        map               = player_undershirt_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = PLAYER_COLOR_UNDERSHIRT,
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
        map               = player_undershirt_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        color             = PLAYER_COLOR_UNDERSHIRT,
    };

    player_sprite_undershirt_falling = Sprite.{
        map               = player_undershirt_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_FALLING,
        color             = PLAYER_COLOR_UNDERSHIRT,
    };

    player_animation_undershirt_swinging = AnimatedSprite.{
        map               = player_undershirt_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_SWINGING,
        frame_count       = 4,
        frame_duration_ms = PLAYER_ANIMATION_SWING_DURATION_MS,
        color             = PLAYER_COLOR_UNDERSHIRT,
        loops             = true,
    };

    player_sprite_pants_idle = Sprite.{
        map               = player_pants_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_IDLE, 
        color             = PLAYER_COLOR_PANTS,
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
        map               = player_pants_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_FALLING,
        color             = PLAYER_COLOR_PANTS,
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
        map               = player_hands_map,
        first_frame       = PLAYER_ANIMATION_FIRST_FRAME_RUNNING,
        color             = PLAYER_COLOR_SKIN,
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
        loops             = true,
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

    item_sprite_dirt = Sprite.{
        map   = dirt_map,
        color = WHITE,
    };

    item_sprite_grass = Sprite.{
        map   = grass_map,
        color = WHITE,
    };

    item_sprite_rock = Sprite.{
        map   = rock_map,
        color = WHITE,
    };

    item_sprite_pickaxe = Sprite.{
        map   = pickaxe_texture,
        color = WHITE,
    };
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
        speed: float = ifx fractionSpeed*length > minSpeed then fractionSpeed*length else minSpeed;
        camera.target = Vector2Add(camera.target, Vector2Scale(diff, speed*delta/length));
    }
}

create_rect_for_tile_from_point :: (pos: Vector2, tile_width: s32, tile_height: s32) -> Rectangle {
    // First of all, chop off any decimal info from the pos. Placing blocks should only ever occur with on int coords.
    int_pos_x : int = cast(int) floor(pos.x);
    int_pos_y : int = cast(int) floor(pos.y);

    // Next calculate the amount we need to subtract to the position to get axis aligned.
    // In this diagram, dX is the amount to shift the pos to the left, and dY is the amount to shift up.
    //  +-----------+
    //  |   ^       |
    //  |   |       |
    //  |   |       |
    //  |<~~o       |
    //  |           |
    //  +-----------+
    d_x : int = int_pos_x % tile_width;
    d_y : int = int_pos_y % tile_height;

    if d_x < 0 { d_x += tile_width;  };
    if d_y < 0 { d_y += tile_height; };

    x := int_pos_x - d_x;
    y := int_pos_y - d_y;

    new_rect := Rectangle.{
        x      = xx x,
        y      = xx y,
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

animation_get_current_frame :: (sprite: $T/Sprite) -> u32 {
    #if type_of(sprite) == Sprite {
        return sprite.first_frame;
    } else {
        if sprite.frame_duration_ms == 0 return 0;
        return ((sprite.timer_ms / sprite.frame_duration_ms) % sprite.frame_count) + sprite.first_frame;
    }
}

// Returns the duration of one full playing of the animation. So, if there are 10 frames, each 50 ms long, the
// duration would be 500ms
animation_get_total_duration_ms :: (animation: AnimatedSprite) -> u32 {
    return animation.frame_count * animation.frame_duration_ms;
}

spawn_player :: () -> Player {
    pos := Vector2.{ GetScreenWidth() / 2.0, -1.0 * GetScreenHeight() };

    global_id_counter += 1;
    player := Player.{
        type = Player,
        id   = global_id_counter,

        pos  = pos,
        vel  = Vector2.{ 0, 0 },

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

    // Initialize inventory
    {
        // Fill in the rest of the item stacks with invalid data
        for *player.inventory.item_stacks {
            it.* = EMPTY_ITEM_SLOT;
        }

        player.inventory.selected_item_stack = 2;
        
        player.inventory.item_stacks[0] = ItemStack.{
            item_type     = .DIRT,
            stack_capacity = DIRT_STACK_CAPACITY,
            stack_count    = DIRT_STACK_CAPACITY,
        };
        player.inventory.item_stacks[1] = ItemStack.{
            item_type     = .ROCK,
            stack_capacity = ROCK_STACK_CAPACITY,
            stack_count    = ROCK_STACK_CAPACITY,
        };
        player.inventory.item_stacks[2] = ItemStack.{
            item_type     = .PICKAXE,
            stack_capacity = PICKAXE_STACK_CAPACITY,
            stack_count    = PICKAXE_STACK_CAPACITY,
        };
    }

    return player;
}

perlin_noise :: (desired_values: u32, starting_frequency: u32, starting_amplitude: float32, octaves: u32, min_value := 0.0) -> [..] float {
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

    // @PERF
    for *results {
        if it.* < min_value {
            it.* = min_value + abs(it.*);
        }
    }

    return results;
}

ReturnStatus :: enum u16 {
    SUCCESS;
    NOT_FOUND;
}

get_selected_item_stack :: (inventory: Inventory) -> item_stack: ItemStack, return_status: ReturnStatus {
    item_stack := inventory.item_stacks[inventory.selected_item_stack];

    return_status := ifx item_stack_is_empty(item_stack) then ReturnStatus.NOT_FOUND else ReturnStatus.SUCCESS;

    return item_stack, return_status;
}

get_block_hardness :: (item_type: ItemType) -> float {
    if item_type == {
        case .DIRT;  return DIRT_HARDNESS;
        case .GRASS; return GRASS_HARDNESS;
        case .ROCK;  return ROCK_HARDNESS;

        case .PICKAXE; assert(false, "Tried to get the block hardness of a pickaxe"); #through;

        case;
            print_vars(item_type);
            assert(false, "Invalid block type");
            return -1; // Unreachable
    }
}

can_item_be_placed_down :: (item_type: ItemType) -> bool {
    if item_type == {
        case .DIRT;    return true;
        case .GRASS;   return true; // @TODO: false?
        case .ROCK;    return true;

        case .PICKAXE; return false;

        case;
            print_vars(item_type);
            assert(false, "Invalid block type");
            return false; // Unreachable
    }
}

// @TODO: this feels wrong that I have to remember the derived state to pass to this function
add_block_to_chunk :: (chunk_id: u32, new_block: Block, chunks: *[..] Chunk, active_chunks: *[..] Chunk, active_blocks: *[..] *Block, window_start: Vector2, window_end: Vector2) {
    array_add(*((chunks.*)[chunk_id].blocks), new_block);
    derive_active_chunks_and_active_blocks(chunks.*, active_chunks, active_blocks, window_start, window_end);
}

derive_active_chunks_and_active_blocks :: (chunks: [..] Chunk, active_chunks: *[..] Chunk, active_blocks: *[..] *Block, window_start: Vector2, window_end: Vector2) {
    array_reset(active_chunks);
    array_reset(active_blocks);
    
    for chunks {
        // The last block in a chunk will always be the right-most with the current method for world generation.
        if it.blocks[it.blocks.count-1].pos.x < window_start.x - DIRT_WORLD_TILE_WIDTH continue;
        
        // The first block in a chunk will always be the left-most with the current method for world generation.
        if it.blocks[0].pos.x > window_end.x continue;

        array_add(active_chunks, it);
        
        // @TODO: draw active blocks, but simulate active chunks. Or something.
        for block: it.blocks {
            array_add(active_blocks, *block);
        }
    }
}

item_stack_is_empty :: (item_stack: ItemStack) -> bool {
    return (
        item_stack.item_type      == EMPTY_ITEM_SLOT.item_type && 
        item_stack.stack_capacity == EMPTY_ITEM_SLOT.stack_capacity &&
        item_stack.stack_count    == EMPTY_ITEM_SLOT.stack_count
    );
}

get_stack_capacity_by_item_type :: (item_type: ItemType) -> s32 {
    if item_type == {
        case .DIRT;  return DIRT_STACK_CAPACITY;
        case .GRASS; return GRASS_STACK_CAPACITY;
        case .ROCK;  return ROCK_STACK_CAPACITY;
        case;
            assert(false, "Invalid item type");
            return -1;
    }
}

get_texture_map_by_item_type :: (item_type: ItemType, is_facing_left: bool = false) -> texture: Texture, source: Rectangle {
    map_texture : Texture;
    map_source  : Rectangle;
    
    if item_type == {
        case .DIRT;
            map_texture = dirt_map;
            map_source  = Rectangle.{
                0,
                5 * DIRT_MAP_TILE_HEIGHT,
                DIRT_MAP_TILE_WIDTH - DIRT_MAP_TILE_PADDING,
                DIRT_MAP_TILE_HEIGHT - DIRT_MAP_TILE_PADDING,
            };

            if is_facing_left map_source.width *= -1;
        case .GRASS;
            map_texture = grass_map;
            map_source  = Rectangle.{
                3 * GRASS_MAP_TILE_WIDTH,
                0 * GRASS_MAP_TILE_HEIGHT,
                GRASS_MAP_TILE_WIDTH - GRASS_MAP_TILE_PADDING,
                GRASS_MAP_TILE_HEIGHT - GRASS_MAP_TILE_PADDING,
            };

            if is_facing_left map_source.width *= -1;
        case .ROCK;
            map_texture = rock_map;
            map_source  = Rectangle.{
                1 * ROCK_MAP_TILE_WIDTH,
                1 * ROCK_MAP_TILE_HEIGHT,
                ROCK_MAP_TILE_WIDTH - ROCK_MAP_TILE_PADDING,
                ROCK_MAP_TILE_HEIGHT - ROCK_MAP_TILE_PADDING,
            };

            if is_facing_left map_source.width *= -1;
        case .PICKAXE;
            map_texture = pickaxe_texture;
            map_source  = Rectangle.{
                PICKAXE_TEXTURE_HEIGHT,
                PICKAXE_TEXTURE_HEIGHT,
                PICKAXE_TEXTURE_HEIGHT,
                PICKAXE_TEXTURE_HEIGHT,
            };

            if is_facing_left map_source.width *= -1;
        case;
            assert(false, "You forgot an item type in your switch statement");
    }

    return map_texture, map_source;
}


get_sprite_by_item_type :: (item_type: ItemType) -> *Sprite {
    if item_type == {
        case .DIRT;    return *item_sprite_dirt;
        case .GRASS;   return *item_sprite_grass;
        case .ROCK;    return *item_sprite_rock;
        case .PICKAXE; return *item_sprite_pickaxe;
        case;
            assert(false, "You forgot an item type in your switch statement");
            return null;
    }
}

item_type_is_stackable :: (item_type: ItemType) -> bool {
    if item_type == {
        case .DIRT;    return true;
        case .GRASS;   return true;
        case .ROCK;    return true;

        case .PICKAXE; return false;

        case;
            assert(false, "Forgot an item type in your switch statement");
            return false; // Unreachable
    } 
}

get_item_world_length :: (item_type: ItemType) -> float {
    if item_type == {
        case .DIRT;    return WIELDED_BLOCK_WORLD_LENGTH;
        case .GRASS;   return WIELDED_BLOCK_WORLD_LENGTH;
        case .ROCK;    return WIELDED_BLOCK_WORLD_LENGTH;

        case .PICKAXE; return WIELDED_TOOL_WORLD_LENGTH;

        case;
            assert(false, "Forgot an item type in your switch statement");
            return 0; // Unreachable
    } 
}

TryToAddToInventoryReturnStatus :: enum u16 {
    SUCCESS;
    INVENTORY_FULL;
}

// @TODO: might need a quantity param
try_to_add_to_inventory :: (inventory: *Inventory, item_type : ItemType) -> TryToAddToInventoryReturnStatus {
    print_vars(item_type);
    // First, try to find an existing stack that has room.
    for *inventory.item_stacks {
        if it.item_type == item_type {
            if it.stack_count < it.stack_capacity {
                it.stack_count += 1;
                return TryToAddToInventoryReturnStatus.SUCCESS;
            }
        }
    }

    // If there is no existing stack with space, then just try to find an empty slot.
    for *inventory.item_stacks {
        if item_stack_is_empty(it) {
            it.item_type      = item_type;
            it.stack_count    = 1;
            it.stack_capacity = get_stack_capacity_by_item_type(item_type);

            return TryToAddToInventoryReturnStatus.SUCCESS;
        }
    }

    // If there are neither existing stacks with space nor empty slots, we can't add the
    // block to the inventory.
    return TryToAddToInventoryReturnStatus.INVENTORY_FULL;
}
