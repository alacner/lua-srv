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
