printl = print
print = cgi.print
echo = cgi.print
--local print = echo.print
local type = type
local pairs = pairs
local tostring = tostring

function print_r(sth)
    if type(sth) ~= "table" then
        print(sth) 
        return
    end

    local space, deep = string.rep(' ', 4), 0
    local function _dump(t)
        for k,v in pairs(t) do
            local key = tostring(k)
            
            if type(v) == "table" then 
                deep = deep + 2 
                print(string.format("%s[%s] => Table\n%s(",
                                string.rep(space, deep - 1),
                                key,
                                string.rep(space, deep)
                        )
                    ) --print.
                _dump(v)
                
                print(string.format("%s)",string.rep(space, deep)))
                deep = deep - 2 
            else
                print(string.format("%s[%s] => %s",
                                string.rep(space, deep + 1),
                                key,
                                tostring(v)
                        )
                    ) --print.
            end
        end
    end

    print(string.format("Table\n("))
    _dump(sth)
    print(string.format(")"))
end
