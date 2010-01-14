package.path = './script/?.lua;./?.lua;';

require "print_r"
require "urlcode"

GET, POST, FILE, COOKIE, REQUEST = {}, {}, {}, {}, {}

-- PARSE COOKIE --
local cookies = cgi.get_header("Cookie") or ""
cookies = ";" .. cookies .. ";"
cookies = string.gsub(cookies, "%s*;%s*", ";")   -- remove extra spaces

for k, v in string.gmatch(cookies, "([%w_]+)=([%w_]+);") do
	COOKIE[k] = v and unescape(v)
end

function setcookie(...)
	--Set-Cookie: _ca=heheheh; expires=Thu, 01-Jan-1970 00:04:10 GMT; path=/; domain=domain; secure
	local name, value, expire, path, domain, secure = ...
	local t = {};
	table.insert(t, name .. '=' .. escape(value))
	if expire then table.insert(t, 'expires=' .. value) end
	if path then table.insert(t, 'path=' .. path) end
	if domain then table.insert(t, 'domain=' .. domain) end
	if secure then table.insert(t, 'secure') end
	
	cgi.set_header("Set-Cookie", table.concat(t, "; "));
end



--setcookie('wgj', 'yes')
--setcookie('test2', 'haha', 9527)
--setcookie('test', 'haha', 100, '/', 'domian.com', true)
--cgi.set_header("Set-Cookie", "_cbb=hahahhahahaha");
print_r(GET_DATA)
print_r(POST_DATA)
print_r(COOKIE)
print_r(HEADER_DATA)
print_r(cgi.get_header("Host"))
print_r(cgi.get_header("Content-Length"))

--print_r(SERVER)

include(SERVER['SCRIPT_FILENAME'])
