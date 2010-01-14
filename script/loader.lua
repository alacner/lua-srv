package.path = './script/?.lua;./?.lua;';

require "print_r"

include(SERVER['SCRIPT_FILENAME'])
--print_r(SERVER)
