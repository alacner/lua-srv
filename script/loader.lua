package.path = './?.lua;./script/?.lua';

GET, POST, FILES, COOKIE, REQUEST = {}, {}, {}, {}, {}

SERVER.REQUEST_METHOD = setting.cgi.evhttp_req_method[SERVER.REQUEST_METHOD]

-- PARSE COOKIE --
local cookies = cgi.get_header("Cookie") or ""
cookies = ";" .. cookies .. ";"
cookies = string.gsub(cookies, "%s*;%s*", ";")   -- remove extra spaces

for k, v in string.gmatch(cookies, "([%w_]+)=([%w_]+);") do
	COOKIE[k] = v and unescape(v)
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


-- SESSION FUNCTION --
session_started_token = false
function session_start ()
	local client_sessionID = COOKIE[setting.session.name];
	if client_sessionID and session_exists (client_sessionID) then
		session_started_token = client_sessionID 
		SESSION = session_load(session_started_token) 
		return session_started_token 
	end 

	local ver = 0;
	local token = cgi.md5(cgi.microtime(1))
	if session_exists (token) then
		repeat
			token = cgi.md5(token .. '.' .. ver)
			ver = ver + 1
		until not session_exists (token)
	end
	-- save cookie
	setcookie(setting.session.name, token, setting.session.cookie_expire, setting.session.cookie_path, setting.session.cookie_domain, setting.session.cookie_secure)
	session_save(token, {})
	session_started_token = token 
	SESSION = session_load(session_started_token) 
	return session_started_token 
end

--"\r\n\t <>'\"\\"

-- run script --
include(SERVER['SCRIPT_FILENAME'])

-- [[cgi close]] --
-- save session value
if session_started_token then
	session_save(session_started_token, SESSION)
end
