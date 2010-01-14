package.path = './script/?.lua;./?.lua;';

require "print_r"
require "urlcode"

GET, POST, COOKIE, REQUEST = {}, {}, {}, {}

-- PARSE COOKIE --
local cookies = cgi.get_header("Cookie") or ""
cookies = ";" .. cookies .. ";"
cookies = string.gsub(cookies, "%s*;%s*", ";")   -- remove extra spaces

for k, v in string.gmatch(cookies, "([%w_]+)=([%w_]+);") do
	COOKIE[k] = v and unescape(v)
end

print_r(GET_DATA)
print_r(POST_DATA)
print_r(COOKIE)
print_r(HEADER_DATA)
print_r(cgi.get_header("Host"))
print_r(cgi.get_header("Content-Length"))

--print_r(SERVER)

include(SERVER['SCRIPT_FILENAME'])
