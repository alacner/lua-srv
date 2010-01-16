-- ICONV --
function iconv_all(from, to, text)
	local cd = iconv.new(to .. "//TRANSLIT", from)
	assert(cd, "Failed to create a converter object.")
	local ostr, err = cd:iconv(text)

	if err == iconv.ERROR_INCOMPLETE then
		print("ERROR: Incomplete input.")
	elseif err == iconv.ERROR_INVALID then
		print("ERROR: Invalid input.")
	elseif err == iconv.ERROR_NO_MEMORY then
		print("ERROR: Failed to allocate memory.")
	elseif err == iconv.ERROR_UNKNOWN then
		print("ERROR: There was an unknown error.")
	end
	return ostr
end
