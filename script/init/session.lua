lfs.mkdir(setting.session.save_path)

function session_filename (token)
	if not token then
		return false
	end

	return string.format ("%s/sess_%s.lua", setting.session.save_path, token)
end

function session_exists (token)
	if not token then
		return false
	end

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

function session_save (token, data)
	local fh = assert (io.open(session_filename(token), "w+"))
	fh:write "return "
	serialize (data, function (s) fh:write(s) end)
	fh:close()
end

function session_load (token)
	if not session_exists(token) then
		return false
	end

	local f, err = loadfile (session_filename(token))
	if not f then
		return nil, err
	else
		return f()
	end
end
