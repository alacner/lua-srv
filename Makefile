# Makefile for luasrv
#CC=gcc
#RM = rm

MYSQL_DRIVER_LIBS= -L/usr/lib/mysql -lmysqlclient -lz
MYSQL_DRIVER_INCS= -I/usr/include/mysql 

# Name of .pc file. "lua5.1" on Debian/Ubuntu
CFLAGS= -O2 -Wall -L/usr/local/lib -llua -ldl -lm -levent -lpthread $(MYSQL_DRIVER_INCS) $(MYSQL_DRIVER_LIBS)
luasrv: luasrv.c
	$(CC) luasrv.c libs/lfs.c libs/luaiconv.c libs/md5.c libs/luamysql.c $(CFLAGS) -o luasrv

clean: luasrv 
	$(RM) -f luasrv

install: httpsqs
	install $(INSTALL_FLAGS) -m 4755 -o root luasrv $(DESTDIR)/usr/bin
