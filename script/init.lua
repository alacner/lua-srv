package.path = './script/?.lua;./?.lua;';

require "lp"
require "print_r"
require "urlcode"
require "split"
require "serialize"

EVHTTP_REQ_METHOD = {[0]='GET', [1]='POST', [2]='HEAD', [3]='NULL'} -- find at evhttp.h:179:enum evhttp_cmd_type

-- Default path for temporary files
tmp_path = os.getenv("TEMP") or os.getenv ("TMP") or "/tmp"

session_timeout = 10 * 60 -- 10 minutes
session_save_path = tmp_path .. '/sess'

lfs.mkdir(session_save_path)
printl_r(lfs.attributes(session_save_path))

