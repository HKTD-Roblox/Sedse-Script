local key = "KEY_HERE"
loadstring(game:HttpGet("https://keyxyz-sedse.pages.dev/v1/load?key=" .. game:GetService("HttpService"):UrlEncode(key) .. "&_cb=" .. tostring(os.clock())))()
