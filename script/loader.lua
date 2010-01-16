package.path = './script/?.lua;./?.lua;';


GET, POST, FILES, COOKIE, REQUEST = {}, {}, {}, {}, {}

SERVER.REQUEST_METHOD = EVHTTP_REQ_METHOD[SERVER.REQUEST_METHOD]

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
	if not name or not value then
		error("cookie needs a name and a value")
	end
	local t = {};
	table.insert(t, name .. '=' .. escape(value))
	if expire then
		local e = os.date("!%A, %d-%b-%Y %H:%M:%S GMT", expire)
		table.insert(t, 'expires=' .. e)
	end
	if path then table.insert(t, 'path=' .. path) end
	if domain then table.insert(t, 'domain=' .. domain) end
	if secure then table.insert(t, 'secure') end
	
	cgi.set_header("Set-Cookie", table.concat(t, "; "));
end

function deletecookie(name)
	setcookie(name, 'NULL', -1)
	COOKIE[name] = nil
end

-- PARSE POST --

local function getboundary ()
	local ct = cgi.get_header("Content-Type");
	if not ct then return false end
	local _,_,boundary = string.find (ct, "boundary%=(.-)$")
	if not boundary then return false end
	return  "--"..boundary 
end

--
-- Create a table containing the headers of a multipart/form-data field
--
local function breakheaders (hdrdata)
	local headers = {}
	string.gsub (hdrdata, '([^%c%s:]+):%s+([^\n]+)', function(type,val)
		type = string.lower(type)
		headers[type] = val
	end)
	return headers
end

function parse_post(data)
	local val = string.match(data, ".+\r\n(.+)")
	return val
end

-- name,type,size,tmp_name,error
function parse_post_file(data)
	local val = string.match(data, ".+\r\n(.+)")
	local ppf = {}
	local f = io.tmpfile(); f:write(val);-- f:close()
	ppf["tmp_name"] = f
	ppf["size"] = string.len(val)
	ppf["error"] = 0
	return ppf
end

function split_boundary()
	--printl(POST_DATA)
	local POST_TEMP = split(POST_DATA, boundary)
	for i,p in ipairs(POST_TEMP) do 
		local h = breakheaders(p)	
		local t = {}
		local hcd = h["content-disposition"]
		if hcd then
			string.gsub(hcd, ';%s*([^%s=]+)="(.-)"', function(attr, val)
				t[attr] = val
			 end)
		else
			error("Error processing multipart/form-data."..
			  "\nMissing content-disposition header")
		end

		-- Filter POST or FILE
		if h["content-type"] then
			local file = {}
			file['type'] = h["content-type"]
			file['name'] = t["filename"]
			local ppf = parse_post_file(p)
			file['tmp_name'] = ppf["tmp_name"]
			file['size'] = ppf["size"]
			file['error'] = ppf["error"]
			FILES[t.name] = file
		else
			POST[t.name] = parse_post(p) 
		end	
	end
end

-- PARSE GET --
if (SERVER.REQUEST_METHOD == 'GET') then
	parsequery(SERVER.QUERY_STRING, GET)
	--print_r(GET)
elseif (SERVER.REQUEST_METHOD == 'POST') then
	--print_r(POST_DATA)
	boundary = getboundary()
	if boundary then
		split_boundary()
	else
		parsequery(POST_DATA, POST)
	end
end


-- PARSE REQUEST --
-- order GET,POST,COOKIE
for k,v in pairs(GET) do
	REQUEST[k] = v
end
for k,v in pairs(POST) do
	REQUEST[k] = v
end
for k,v in pairs(COOKIE) do
	REQUEST[k] = v
end

-- UPLOAD FUNCTION --
function move_uploaded_file(f, dest)
	local d, err = io.open(dest, "w+"); 
	if d == nil then
		error("Cannot create upload file.\n"..err)
	end     
	d:write(f:read("*a")); d:close()
	f:close()
end


--"\r\n\t <>'\"\\"
-- SESSION FUNCTION --
local function session_filename (token)
	return string.format ("%s/sess_%s.lua", session_save_path, token)
end

local function session_exists (token)
	local fh = io.open(session_filename(token))
	if fh then
		fh:close ()
		return true
	else
		return false
	end
end

function session_new ()
	local ver = 0;
	local token = cgi.microtime(1)
	if session_exists (token) then
		repeat
			token = token .. '.' .. ver
			ver = ver + 1
		until not session_exists (token)
	end
	return token 
end

function session_save (token, data)
	local fh = assert (io.open(session_filename(token), "w+"))
	fh:write "return "
	serialize (data, function (s) fh:write(s) end)
	fh:close()
end

function session_delete (token)
	os.remove (session_filename(token))
end

function session_load (token)
	local f, err = loadfile (session_filename(token))
	if not f then
		return nil, err
	else
		return f()
	end
end

print("<hr>GET<br/>");
print_r(GET)
print("<hr>POST<br/>");
print_r(POST)
print("<hr>COOKIE<br/>");
print_r(COOKIE)
print("<hr>REQUEST<br/>");
print_r(REQUEST)
print("<hr>FILES<br/>");
print_r(FILES)
print("<hr>");
--setcookie('wgj', 'yes')
--setcookie('test2', 'haha', 9527)
--setcookie('test', 'haha', 100, '/', 'domian.com', true)
--cgi.set_header("Set-Cookie", "_cbb=hahahhahahaha");
--print_r(GET_DATA)
--print("================================");
--print("<hr>");
--print("================================");
--print_r(COOKIE)
--print_r(HEADER_DATA)
--print_r(cgi.get_header("Host"))
--print_r(cgi.get_header("Content-Length"))

--print_r(SERVER)

include(SERVER['SCRIPT_FILENAME'])
