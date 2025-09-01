// Workspace: Target Program

//
// #insert text. Generated from C:/ThirdParty/jai/modules/Print_Vars.jai:106.
//
    names[0] = #run get_code_name(args[0]);
    value0 := #insert args[0];
    value_strings[0] = tprint("%", value0);
    names[1] = #run get_code_name(args[1]);
    value1 := #insert args[1];
    value_strings[1] = tprint("%", value1);
    names[2] = #run get_code_name(args[2]);
    value2 := #insert args[2];
    value_strings[2] = tprint("%", value2);
    names[3] = #run get_code_name(args[3]);
    value3 := #insert args[3];
    value_strings[3] = tprint("%", value3);

//
// #insert text. Generated from C:/ThirdParty/jai/modules/Print_Vars.jai:125.
//
    print_helper(builder, config, name_width, value_width, names[0], value_strings[0], type_of(value0));
    print_helper(builder, config, name_width, value_width, names[1], value_strings[1], type_of(value1));
    print_helper(builder, config, name_width, value_width, names[2], value_strings[2], type_of(value2));
    print_helper(builder, config, name_width, value_width, names[3], value_strings[3], type_of(value3));
