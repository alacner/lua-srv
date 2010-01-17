-- all setting config
setting = {}

-- cgi env
setting.cgi = {}
-- find at evhttp.h:179:enum evhttp_cmd_type
setting.cgi.evhttp_req_method = {[0]='GET', [1]='POST', [2]='HEAD', [3]='NULL'}
-- Default path for temporary files
setting.cgi.tmp_path = os.getenv("TEMP") or os.getenv ("TMP") or "/tmp"

setting.upload = {}
setting.upload.timeout = 60 * 5
setting.upload.max_filesize = 1024 * 1024 * 2 -- 2M
setting.upload.tmp_path = setting.cgi.tmp_path .. '/luasrv_upload'

lfs.mkdir(setting.upload.tmp_path)

-- config session
setting.session = {}
setting.session.timeout = 60 * 10 -- 10 minutes
setting.session.save_path = setting.cgi.tmp_path .. '/luasrv_session'
setting.session.name = "LUASESSID"
setting.session.cookie_expire = 0
setting.session.cookie_path  = "/"
setting.session.cookie_domain = ""
setting.session.cookie_secure = false 

lfs.mkdir(setting.session.save_path)
