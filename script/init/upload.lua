function upload_filename (token)
	if not token then
		return false
	end

	return string.format ("%s/%s", setting.upload.tmp_path, token)
end

function upload_exists (token)
	if not token then
		return false
	end

	local fh = io.open(upload_filename(token))
	if fh then
		fh:close ()
		return true
	else
		return false
	end
end

function upload_cleanup ()
	local cnt = 0
	local rem = {}
	local now = os.time ()
	for file in lfs.dir (setting.upload.tmp_path) do
		local attr = lfs.attributes(setting.upload.tmp_path .. "/" .. file)
		if attr and attr.mode == 'file' then
			if attr.modification + setting.upload.timeout < now then
				table.insert (rem, file)
			end
		end
	end
	for _, file in ipairs (rem) do
		cnt = cnt + 1
		os.remove (setting.upload.tmp_path .. "/" .. file)
	end
	return cnt
end

------------------------------------------------------------------------
UPLOAD_ERR_OK = 0 --There is no error, the file uploaded with success. 
UPLOAD_ERR_SIZE = 1 --The uploaded file exceeds the setting.upload.max_filesize directive in setting.lua. 
UPLOAD_ERR_NO_FILE = 2 --No file was uploaded. 
UPLOAD_ERR_CANT_WRITE = 3 --Failed to write file to disk. 

function upload_save (data)
	local err, tmp_name = UPLOAD_ERR_OK
	local size = string.len(data)

	if size > setting.upload.max_filesize then
		err  = UPLOAD_ERR_SIZE
	else	
		if data and data ~= "" then
		
			local ver = 0;

			local token = cgi.md5(cgi.microtime(1))
			if upload_exists (token) then
				repeat
					token = cgi.md5(token .. '.' .. ver)
					ver = ver + 1
				until not upload_exists (token)
			end

			tmp_name = upload_filename(token)
			local f, e = assert (io.open(tmp_name, "w+"))
			if f == nil then
				err = UPLOAD_ERR_CANT_WRITE
			end

			f:write(data)
			f:close()
		else
			err = UPLOAD_ERR_NO_FILE
		end
	end

	local ppf = {}
	ppf["tmp_name"] = tmp_name 
	ppf["size"] = size
	ppf["error"] = err 

	return ppf
end
