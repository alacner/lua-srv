package.path = './script/?.lua;./?.lua;';

require "lp"
require "print_r"
require "urlcode"
require "split"
require "serialize"

EVHTTP_REQ_METHOD = {[0]='GET', [1]='POST', [2]='HEAD', [3]='NULL'} -- find at evhttp.h:179:enum evhttp_cmd_type

-- Default path for temporary files
tmp_path = os.getenv("TEMP") or os.getenv ("TMP") or "/tmp"

session_timeout = 10 * 60 -- 10 minutes
session_save_path = tmp_path .. '/sess'

lfs.mkdir(session_save_path)
printl_r(lfs.attributes(session_save_path))


function iconv_all(from, to, text)
	print("\n-- Testing conversion from " .. from .. " to " .. to)
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
	print(ostr)
	return ostr
end
