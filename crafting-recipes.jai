CraftingRecipe :: struct {
    ingredients : [] CraftingIngredient;
    output : ItemStack;
}

CraftingIngredient :: struct {
    item_type  : ItemType;
    item_count : s32;
}

RECIPE_TORCH :: CraftingRecipe.{
    ingredients = CraftingIngredient.[
        CraftingIngredient.{
            item_type  = ItemType.WOOD_ITEM,
            item_count = 1,
        }
        // TODO: Once gel is added
        // CraftingIngredient.{
        //     item_type  = ItemType.GEL;
        //     item_count = 1;
        // }    
    ],
    output = ItemStack.{
        item_type      = ItemType.TORCH,
        stack_capacity = TORCH_STACK_CAPACITY,
        stack_count    = 3,
    },
};

CRAFTING_RECIPES :: CraftingRecipe.[
    RECIPE_TORCH,
];
