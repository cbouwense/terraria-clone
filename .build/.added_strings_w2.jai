// Workspace: Target Program

//
// #insert text. Generated from C:/ThirdParty/jai/modules/Print_Vars.jai:106.
//
    names[0] = #run get_code_name(args[0]);
    value0 := #insert args[0];
    value_strings[0] = tprint("%", value0);

//
// #insert text. Generated from C:/ThirdParty/jai/modules/Print_Vars.jai:125.
//
    print_helper(builder, config, name_width, value_width, names[0], value_strings[0], type_of(value0));
