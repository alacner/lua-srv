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
--printl(POST_DATA)
--print(POST_DATA)

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

function split_boundary()
	local POST_TEMP = split(POST_DATA, boundary)
	for i,pd in ipairs(POST_TEMP) do 

		local headers = {}
		local hdrdata, post_val = string.match(pd, "(.+)\r\n\r\n(.+)\r\n")
		--printl(hdrdata)

		if hdrdata then
			string.gsub (hdrdata, '([^%c%s:]+):%s+([^\n]+)', function(type,val)
				type = string.lower(type)
				headers[type] = val
			end)
		end

		local t = {}
		local hcd = headers["content-disposition"]
		if hcd then
			string.gsub(hcd, ';%s*([^%s=]+)="(.-)"', function(attr, val)
				t[attr] = val
			 end)
			-- Filter POST or FILE
			if headers["content-type"] then
				-- name,type,size,tmp_name,error
				local file = {}
				file['type'] = headers["content-type"]
				file['name'] = t["filename"]
				local ppf = upload_save (post_val)
				file['tmp_name'] = ppf["tmp_name"]
				file['size'] = ppf["size"]
				file['error'] = ppf["error"]
				FILES[t.name] = file
			else
				POST[t.name] = post_val 
			end	
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
		--printl(boundary)
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
include(SERVER.SCRIPT_FILENAME)

-- [[cgi close]] --
-- save session value
if session_started_token then
	session_save(session_started_token, SESSION)
end
-- upload file cleanup 
for k,v in pairs(FILES) do
	if v.tmp_name then
		os.remove(v.tmp_name)
	end
end

