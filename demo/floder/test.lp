<?lua
--local db, err = mysql.connect('localhost', 'root', 'kernel')
--printl(db)
--printl(err)
session_start()
--local md5 = cgi.md5('中国人1', 1)
--local md52 = cgi.md5('中国人1')
--print("<br>=================<br>")
--e = json.encode({["f"]="哈哈fdsafdsa"})
--print_r(json.decode(e))
--print("<br>=================<br>")
--print(md5)
--print("<br>=================<br>")
--print(md52)
--print("<br>=================<br>")
?>
<html>
<head>
<title>Login</title>
</head>

<body>
    <?lua
--local a=4; print(a)
?>
<br/>
    <?= math.pi ?>
    <? if logged then ?>
    <p>User <?= username ?> logged in</p>
    <a href="<?= logoutURL ?>">Logout</a>
    <? else ?>
    <p style="color:#ff0000"><?= GET.errmsg ?> </p>
    <form method="post" action="" enctype="multipart/form-data" >
        User name: <input name="username" maxlength="20" size="20" value="<?= GET.username ?>" ><br />
        Password: <input name="pass" type="password" maxlength="20" size="20"><br />
        file1: <input name="file1" type="file"><br />
        file2: <input name="file2" type="file"><br />
        <textarea name="content" ></textarea><br />
        <input type="submit" value="Login" />
        <input type="reset" value="Reset" />
    </form>
    <form method="post" action="" >
        User name: <input name="username" maxlength="20" size="20" value="<?= GET.username ?>" ><br />
        Password: <input name="pass" type="password" maxlength="20" size="20"><br />
        file1: <input name="file1" type="file"><br />
        file2: <input name="file2" type="file"><br />
        <textarea name="content" ></textarea><br />
        <input type="submit" value="Login" />
        <input type="reset" value="Reset" />
    </form>
    <? end ?>
</body>
</html>

<?lua
setcookie('love', os.time(), 9527)
--print_r(POST)
?>
<?lua
SESSION.haha = os.time()
print("<hr>GET<br/>");
print_r(GET)
print("<hr>POST<br/>");
print_r(POST)
print("<hr>COOKIE<br/>");
print_r(COOKIE)
print("<hr>REQUEST<br/>");
print_r(REQUEST)
print("<hr>FILES<br/>");
print_r(FILES)
print("<hr>SESSION<br/>");
print_r(SESSION)
print("<hr>");

local d = {1,3,4,5}
SERVER.ser = d
print_r(SERVER)
--local x = iconv_all("utf8", "gbk", "ahah呵呵")
--print_r(x)

?>
