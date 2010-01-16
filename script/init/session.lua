lfs.mkdir(setting.session.save_path)

local function session_filename (token)
	return string.format ("%s/sess_%s.lua", setting.session.save_path, token)
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

function session_cleanup ()
	local cnt = 0
	local rem = {}
	local now = os.time ()
	for file in lfs.dir (setting.session.save_path) do
		local attr = lfs.attributes(setting.session.save_path .. "/" .. file)
		if attr and attr.mode == 'file' then
			if attr.modification + setting.session.timeout < now then
				table.insert (rem, file)
			end
		end
	end
	for _, file in ipairs (rem) do
		cnt = cnt + 1
		os.remove (setting.session.save_path .. "/" .. file)
	end
	return cnt
end

function session_start ()
	local ver = 0;
	local token = cgi.microtime(1)
	if session_exists (token) then
		repeat
			token = token .. '.' .. ver
			ver = ver + 1
		until not session_exists (token)
	end
	-- save cookie
	setcookie(setting.session.name, token, setting.session.cookie_expire, setting.session.cookie_path, setting.session.cookie_domain, setting.session.cookie_secure)
	return token 
end

function session_save (token, data)
	local fh = assert (io.open(session_filename(token), "w+"))
	fh:write "return "
	serialize (data, function (s) fh:write(s) end)
end
