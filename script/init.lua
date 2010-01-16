package.path = './script/?.lua;./?.lua;';

require "lp"
require "print_r"
require "urlcode"
require "split"
require "serialize"
require "setting"

lfs.mkdir(setting.session.save_path)
printl_r(lfs.attributes(setting.session.save_path))

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
