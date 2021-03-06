/**
 * luasrv - a HTTPd for lua 
 * (c) 2009-19 Alacner zhang <alacner@gmail.com>
 * This content is released under the MIT License.
*/

#include <sys/types.h>
#include <sys/time.h>
#include <sys/queue.h>
#include <sys/types.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <netinet/in.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <time.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <assert.h>
#include <signal.h>
#include <stdbool.h>
#include <pthread.h>

#include <err.h>
#include <event.h>
#include <evhttp.h>

#define VERSION "1.0.0"
#define SESSION_CLEANUP_ALARM 3

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#if ! defined (LUA_VERSION_NUM) || LUA_VERSION_NUM < 501
#include "compat-5.1.h"
#endif

#include "libs/lfs.h"
#include "libs/luaiconv.h"
#include "libs/md5.h"
#include "libs/luamysql.h"

#if LUA_VERSION_NUM < 501
#define luaL_register(a, b, c) luaL_openlib((a), (b), (c), 0)
#endif

#define safe_emalloc(nmemb, size, offset)  malloc((nmemb) * (size) + (offset)) 

//Global Setting
lua_State *L; /* lua state handle */
char *luasrv_settings_rootpath = NULL;
struct evhttp *httpd;
struct evbuffer *buf;
struct evkeyvalq *input_headers;
struct evkeyvalq *output_headers;
pthread_t ntid[2];

static void show_help(void)
{
	char *b = "--------------------------------------------------------------------------------------------------\n"
		  "HTTP lua Service - luasrv v" VERSION "\n\n"
		  "Author: Alacner Zhang (http://alacner.com), E-mail: alacner@gmail.com\n"
		  "\n"
		   "-l <ip_addr>  interface to listen on, default is 0.0.0.0\n"
		   "-p <num>      TCP port number to listen on (default: 1206)\n"
		   "-x <path>     root directory (example: /var/www/html)\n"
		   "-t <second>   timeout for an http request (default: 1)\n"		   
		   "-d            run as a daemon\n"
		   "-h            print this help and exit\n\n"
		   "Use command \"killall luasrv\", \"pkill luasrv\" and \"kill PID of luasrv\" to stop luasrv.\n"
		   "Please note that don't use the command \"pkill -9 luasrv\" and \"kill -9 PID of luasrv\"!\n"
		   "\n"
		   "Please visit \"http://alacner.com/pro/luasrv\" for more help information.\n\n"
		   "--------------------------------------------------------------------------------------------------\n"
		   "\n";
	fprintf(stderr, b, strlen(b));
}

#define NUL  '\0'
#define MICRO_IN_SEC 1000000.00
#define SEC_IN_MIN 60
static int luaM_microtime (lua_State *L) {
	struct timeval tp = {0};
	int get_as_float = luaL_optnumber(L, 1, 0);

	if (gettimeofday(&tp, NULL)) {
		lua_pushboolean(L, 0);
    }

    if (get_as_float) {
        lua_pushnumber(L, (double)(tp.tv_sec + tp.tv_usec / MICRO_IN_SEC));
    } else {
		lua_pushfstring(L, "%f %d", tp.tv_usec / MICRO_IN_SEC, tp.tv_sec);
	}

	return 1;	
}

static int luaM_md5 (lua_State *L) {
    struct MD5Context md5c;
    unsigned char ss[16];
	char *s = (char *)luaL_optstring(L, 1, NULL);
	int raw_output = luaL_optnumber(L, 2, 0);
	int i;

    MD5Init( &md5c );
    MD5Update( &md5c, s, strlen(s) );
    MD5Final( ss, &md5c );

	if (raw_output) {
		lua_pushstring(L, (char *)ss);
	}
	else
	{
		char md5_32[32][2];
		for(i=0; i<16; i++ ) {
			sprintf(md5_32[i], "%02x", ss[i]);
			lua_pushstring(L, md5_32[i]);
		}
		lua_concat(L, 16);
	}

	return 1;
}

static int luaM_print (lua_State *L) {
	const char *str = luaL_optstring(L, 1, NULL);
	evbuffer_add_printf(buf, "%s", str);
	return 0;
}

static int luaM_get_header (lua_State *L) {
	const char *header = luaL_optstring(L, 1, NULL);
	const char *header_data = evhttp_find_header (input_headers, header);
	lua_pushstring(L, header_data);
	return 1;
}

static int luaM_set_header (lua_State *L) {
	const char *header = luaL_optstring(L, 1, NULL);
	const char *value = luaL_optstring(L, 2, NULL);
	evhttp_add_header(output_headers, header, value);
	return 0;
}

/* 处理模块 */
void luasrv_handler(struct evhttp_request *req, void *arg)
{
	buf = evbuffer_new();
	input_headers = req->input_headers;
	output_headers = req->output_headers;
	
	// GET
	char *decode_uri = strdup((char*) evhttp_request_uri(req));
	lua_pushstring(L, decode_uri);
	lua_setglobal(L, "GET_DATA");

	if (req->type == EVHTTP_REQ_POST) { // POST
		int post_data_len;
		post_data_len = EVBUFFER_LENGTH(req->input_buffer);

		if (post_data_len > 0) {
			char *post_data;
			// copy post data, The string can contain embedded zeros.
			post_data = (char *)malloc(post_data_len + 1);
			memset(post_data, '\0', post_data_len + 1);
			memcpy (post_data, EVBUFFER_DATA(req->input_buffer), post_data_len);

			lua_pushlstring(L, post_data, post_data_len + 1);
			lua_setglobal(L, "POST_DATA");
			free(post_data);
		}
	}

	evhttp_add_header(req->output_headers, "Server", "luasrv " VERSION);
	evhttp_add_header(req->output_headers, "Keep-Alive", "120");
	//evhttp_add_header(req->output_headers, "Connection", "Keep-Alive");

	
	char *script_name = strtok(decode_uri, "?");
	char *query_string = strtok(NULL, "?");

    lua_pushfstring(L, "%s%s", luasrv_settings_rootpath, script_name);
	const char *script_filename = lua_tolstring(L, -1, NULL);
    lua_pop(L, 1);

	struct stat stat_buf;   

	if (lstat(script_filename, &stat_buf) < 0) {  
		fprintf(stderr, "lstat error for %s\r\n", script_filename);  

		evhttp_send_reply(req, HTTP_NOTFOUND, "NOT FOUND", buf);
		/* 内存释放 */
		free(decode_uri);
		evbuffer_free(buf);
		return;
	}  

	if ( !S_ISREG(stat_buf.st_mode)) {//S_ISDIR
		fprintf(stderr, "not found!\n");
		evhttp_send_reply(req, HTTP_NOTFOUND, "NOT FOUND", buf);
		/* 内存释放 */
		free(decode_uri);
		evbuffer_free(buf);
		return;
	}

	lua_newtable(L);

	lua_pushstring(L, "SCRIPT_NAME");
	lua_pushstring(L, script_name);
	lua_rawset(L, -3);

	lua_pushstring(L, "REQUEST_URI");
	lua_pushstring(L, req->uri);
	lua_rawset(L, -3);

	lua_pushstring(L, "REQUEST_TIME");
	lua_pushnumber(L, (int)time((time_t*)NULL));
	lua_rawset(L, -3);

	lua_pushstring(L, "DOCUMENT_ROOT");
	lua_pushstring(L, luasrv_settings_rootpath);
	lua_rawset(L, -3);

	lua_pushstring(L, "SCRIPT_FILENAME");
	lua_pushstring(L, script_filename);
	lua_rawset(L, -3);


	lua_pushstring(L, "REQUEST_METHOD");
	lua_pushnumber(L, req->type);
	lua_rawset(L, -3);

	lua_pushstring(L, "QUERY_STRING");
	lua_pushstring(L, query_string);
	lua_rawset(L, -3);

	lua_pushstring(L, "HTTP_X_FORWARDED_FOR");
	lua_pushstring(L, req->remote_host);
	lua_rawset(L, -3);
	lua_setglobal(L, "SERVER");



	//evbuffer_add_printf(buf, "<br/>%s<br/>", script_filename);

	if (luaL_loadfile(L, "./script/loader.lua") || lua_pcall(L, 0, 0, 0)) {
		fprintf (stderr, "cannot run loader.lua: %s", lua_tostring(L, -1));
		return;
	}

	/* 输出内容给客户端 */
	evhttp_send_reply(req, HTTP_OK, "OK", buf);
	
	/* 内存释放 */
	free(decode_uri);
	evbuffer_free(buf);
}

/* 信号处理 */
static void kill_signal(const int sig) {
	lua_close(L);
    exit(0);
}

static void upload_clearup() {
	while(1) {
		lua_getglobal(L, "upload_cleanup");
		if (lua_pcall(L, 0, 1, 0)) {
			fprintf (stderr, "cannot run upload_clearup: %s\n", lua_tostring(L, -1));
		} else {
			//int cnt = (int) lua_tointeger(L, -1);
			//lua_pop(L, 1);
			//fprintf (stderr, "upload total clearup: %d\n", cnt);
		}
		sleep(1);
	}
}

static void session_clearup() {
	while(1) {
		lua_getglobal(L, "session_cleanup");
		if (lua_pcall(L, 0, 1, 0)) {
			fprintf (stderr, "cannot run session_clearup: %s\n", lua_tostring(L, -1));
		} else {
			//int cnt = (int) lua_tointeger(L, -1);
			//lua_pop(L, 1);
			//fprintf (stderr, "session total clearup: %d\n", cnt);
		}
		sleep(1);
	}
}

int main(int argc, char **argv) {
	int c;
	/* 默认参数设置 */
	char *luasrv_settings_listen = "0.0.0.0";
	int luasrv_settings_port = 1206;
	bool luasrv_settings_daemon = false;
	int luasrv_settings_timeout = 1; /* 单位：秒 */

	L = luaL_newstate();
	luaL_openlibs(L);

	struct luaL_reg driver[] = {
        { "print", luaM_print },
        { "microtime", luaM_microtime },
        { "md5", luaM_md5 },
        { "get_header", luaM_get_header },
        { "set_header", luaM_set_header },
        { NULL, NULL },
    };

	luaL_register (L, "cgi", driver);

	luaopen_lfs (L);
	luaopen_iconv (L);
	luaopen_mysql (L);

	if (luaL_loadfile(L, "./script/init.lua") || lua_pcall(L, 0, 0, 0)) { /* load the compile template functions */
		fprintf (stderr, "cannot run init.lua: %s", lua_tostring(L, -1));
		kill_signal(1);
		return 0;
	}

    /* process arguments */
    while ((c = getopt(argc, argv, "l:p:x:t:dh")) != -1) {
        switch (c) {
        case 'l':
            luasrv_settings_listen = strdup(optarg);
            break;
        case 'p':
            luasrv_settings_port = atoi(optarg);
            break;
        case 'x':
            luasrv_settings_rootpath = strdup(optarg); /* luasrv根路径 */
			if (access(luasrv_settings_rootpath, R_OK) != 0) { /* 如果目录不可写 */
				fprintf(stderr, "luasrv root directory not readable\n");
			}
            break;
        case 't':
            luasrv_settings_timeout = atoi(optarg);
            break;			
        case 'd':
            luasrv_settings_daemon = true;
            break;
		case 'h':
        default:
            show_help();
            return 1;
        }
    }
	
	/* 判断是否加了必填参数 -x */
	if (luasrv_settings_rootpath == NULL) {
		show_help();
		fprintf(stderr, "Attention: Please use the indispensable argument: -x <path>\n\n");		
		kill_signal(1);
	}
	
	/* 如果加了-d参数，以守护进程运行 */
	if (luasrv_settings_daemon == true){
        pid_t pid;

        /* Fork off the parent process */       
        pid = fork();
        if (pid < 0) {
                exit(EXIT_FAILURE);
        }
        /* If we got a good PID, then
           we can exit the parent process. */
        if (pid > 0) {
                exit(EXIT_SUCCESS);
        }
	}
	
	/* 忽略Broken Pipe信号 */
	signal (SIGPIPE, SIG_IGN);
	
	/* 处理kill信号 */
	signal (SIGINT, kill_signal);
	signal (SIGKILL, kill_signal);
	signal (SIGQUIT, kill_signal);
	signal (SIGTERM, kill_signal);
	signal (SIGHUP, kill_signal);
	
	/* more thread */
	if (pthread_create(&ntid[0], NULL, (void *(*)(void *))session_clearup, NULL) != 0) {
		fprintf(stderr, "can't create session_clearup thread.\n");
	}

	if (pthread_create(&ntid[1], NULL, (void *(*)(void *))upload_clearup, NULL) != 0) {
		fprintf(stderr, "can't create upload_clearup thread.\n");
	}

	/* 请求处理部分 */
    event_init();
    httpd = evhttp_start(luasrv_settings_listen, luasrv_settings_port);
    evhttp_set_timeout(httpd, luasrv_settings_timeout);

    /* Set a callback for requests to "/specific". */
    /* evhttp_set_cb(httpd, "/select", select_handler, NULL); */

    /* Set a callback for all other requests. */
    evhttp_set_gencb(httpd, luasrv_handler, NULL);

    event_dispatch();

    /* Not reached in this code as it is now. */
    evhttp_free(httpd);

	return 0;
}
