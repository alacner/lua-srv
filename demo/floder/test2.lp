<html>
<head>
<title>Login</title>
</head>

<body>
    <% if logged then %>
    <p>User <%= username %> logged in</p>
    <a href="<%= logoutURL %>">Logout</a>
    <% else %>
    <p style="color:#ff0000"><%= cgi.get('errmsg') %> </p>
    <form method="post" action="" >
        User name: <input name="username" maxlength="20" size="20" value="<%= cgi.get('username') %>" ><br />
        Password: <input name="pass" type="password" maxlength="20" size="20"><br />
        <input type="submit" value="Login" />
        <input type="reset" value="Reset" />
    </form>
    <% end %>
</body>
</html>
%%%%
<%lua
print_r(SERVER)
%>
