local key = "SEDSE-F064V0EF"
local hwid = "unknown"
pcall(function() if gethwid then hwid = gethwid() else hwid = game:GetService("RbxAnalyticsService"):GetClientId() end end)

local url = "https://keyxyz-sedse.pages.dev/v1/load?key=" .. game:GetService("HttpService"):UrlEncode(key) .. "&hwid=" .. game:GetService("HttpService"):UrlEncode(hwid) .. "&_cb=" .. tostring(os.clock())

local success, result = pcall(function() return game:HttpGet(url) end)

if success and result then
    if writefile then
        writefile("Sedse-Script.lua", result)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Sedse Script",
            Text = "Saved successfully to Sedse-Script.lua!",
            Duration = 5
        })
    else
        setclipboard(result)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Sedse Script",
            Text = "Successfully copied to Clipboard!",
            Duration = 5
        })
    end
end
