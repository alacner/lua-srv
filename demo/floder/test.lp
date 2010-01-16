<html>
<head>
<title>Login</title>
</head>

<body>
    <? local a=4; print(a) ?>
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
--print_r(SERVER)
?>
