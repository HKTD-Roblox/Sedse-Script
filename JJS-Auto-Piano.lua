local vim = game:GetService("VirtualInputManager")
local pth = "RobloxPiano/Songs"

if not isfolder("RobloxPiano") then makefolder("RobloxPiano") end
if not isfolder(pth) then makefolder(pth) end

local st, idx, lt, song, fpath, fmap = "Stopped", 1, 0, {}, "", {}
local speed = 1.0
local transpose = 0
local looping = false

-- MIDI parser (unchanged, it's solid)
local function pm(data)
    local pos = 1
    local function rb() local b = string.byte(data, pos); pos = pos + 1; return b end
    local function rs(len) local s = string.sub(data, pos, pos + len - 1); pos = pos + len; return s end
    local function r16() return rb() * 256 + rb() end
    local function r32() return rb() * 16777216 + rb() * 65536 + rb() * 256 + rb() end
    local function rvlq()
        local v = 0
        while true do
            local b = rb()
            v = v * 128 + bit32.band(b, 0x7F)
            if bit32.band(b, 0x80) == 0 then break end
        end
        return v
    end

    if rs(4) ~= "MThd" then return {} end
    r32()
    local fmt, ntrk, div = r16(), r16(), r16()
    local evs = {}

    for i = 1, ntrk do
        if rs(4) ~= "MTrk" then break end
        local len = r32()
        local endp, tick, lst = pos + len, 0, 0
        while pos < endp do
            local d = rvlq()
            tick = tick + d
            local s = rb()
            if s < 0x80 then s = lst; pos = pos - 1 else lst = s end
            local et = bit32.rshift(s, 4)
            local ch = bit32.band(s, 0x0F)
            if s == 0xFF then
                local mt = rb()
                local ml = rvlq()
                local md = rs(ml)
                if mt == 0x51 and ml == 3 then
                    local mpqn = string.byte(md, 1) * 65536 + string.byte(md, 2) * 256 + string.byte(md, 3)
                    table.insert(evs, {tick = tick, type = "t", mpqn = mpqn})
                end
            elseif et == 0x9 and ch ~= 9 then
                local n, v = rb(), rb()
                if v > 0 then table.insert(evs, {tick = tick, type = "n", note = n}) end
            elseif et == 0x8 or et == 0xA or et == 0xB or et == 0xE then rb() rb()
            elseif et == 0xC or et == 0xD then rb() end
        end
        pos = endp
    end

    table.sort(evs, function(a, b) return a.tick < b.tick end)
    local res, curt, curtm, mpqn = {}, 0, 0, 500000

    for _, e in ipairs(evs) do
        local dt = e.tick - curt
        if dt > 0 then
            curtm = curtm + (dt / div) * (mpqn / 1000000)
            curt = e.tick
        end
        if e.type == "t" then mpqn = e.mpqn
        elseif e.type == "n" then table.insert(res, {time = curtm, note = e.note}) end
    end
    return res
end

-- Full note map including all shift keys
local nm = {
    [60]="1",[62]="2",[64]="3",[65]="4",[67]="5",[69]="6",[71]="7",[72]="8",[74]="9",[76]="0",
    [77]="q",[79]="w",[81]="e",[83]="r",[84]="t",[86]="y",[88]="u",[89]="i",[91]="o",[93]="p",
    [95]="a",[96]="s",[98]="d",[100]="f",[102]="g",[103]="h",[105]="j",[107]="k",[108]="l",
    [110]="z",[112]="x",[114]="c",[115]="v",[117]="b",[119]="n",[121]="m",
    -- Sharps (shift keys)
    [61]="!",[63]="@",[66]="$",[68]="%",[70]="^",[73]="*",[75]="(",
    [78]="Q",[80]="W",[82]="E",[85]="T",[87]="Y",[90]="I",[92]="O",
    [94]="P",[97]="S",[99]="D",[101]="G",[104]="H",[106]="J",[109]="L",
    [111]="Z",[113]="C",[116]="V",[118]="B"
}

-- Complete key map including ALL shift-key mappings
local km = {
    ["1"]=Enum.KeyCode.One,["2"]=Enum.KeyCode.Two,["3"]=Enum.KeyCode.Three,
    ["4"]=Enum.KeyCode.Four,["5"]=Enum.KeyCode.Five,["6"]=Enum.KeyCode.Six,
    ["7"]=Enum.KeyCode.Seven,["8"]=Enum.KeyCode.Eight,["9"]=Enum.KeyCode.Nine,["0"]=Enum.KeyCode.Zero,
    ["q"]=Enum.KeyCode.Q,["w"]=Enum.KeyCode.W,["e"]=Enum.KeyCode.E,["r"]=Enum.KeyCode.R,
    ["t"]=Enum.KeyCode.T,["y"]=Enum.KeyCode.Y,["u"]=Enum.KeyCode.U,["i"]=Enum.KeyCode.I,
    ["o"]=Enum.KeyCode.O,["p"]=Enum.KeyCode.P,["a"]=Enum.KeyCode.A,["s"]=Enum.KeyCode.S,
    ["d"]=Enum.KeyCode.D,["f"]=Enum.KeyCode.F,["g"]=Enum.KeyCode.G,["h"]=Enum.KeyCode.H,
    ["j"]=Enum.KeyCode.J,["k"]=Enum.KeyCode.K,["l"]=Enum.KeyCode.L,["z"]=Enum.KeyCode.Z,
    ["x"]=Enum.KeyCode.X,["c"]=Enum.KeyCode.C,["v"]=Enum.KeyCode.V,["b"]=Enum.KeyCode.B,
    ["n"]=Enum.KeyCode.N,["m"]=Enum.KeyCode.M,
    -- Shift symbols mapped to their base key
    ["!"]=Enum.KeyCode.One,["@"]=Enum.KeyCode.Two,["$"]=Enum.KeyCode.Four,
    ["%"]=Enum.KeyCode.Five,["^"]=Enum.KeyCode.Six,["*"]=Enum.KeyCode.Eight,["("]=Enum.KeyCode.Nine,
    -- Uppercase = shift + letter (the ones missing before)
    ["Q"]=Enum.KeyCode.Q,["W"]=Enum.KeyCode.W,["E"]=Enum.KeyCode.E,["T"]=Enum.KeyCode.T,
    ["Y"]=Enum.KeyCode.Y,["I"]=Enum.KeyCode.I,["O"]=Enum.KeyCode.O,["P"]=Enum.KeyCode.P,
    ["S"]=Enum.KeyCode.S,["D"]=Enum.KeyCode.D,["G"]=Enum.KeyCode.G,["H"]=Enum.KeyCode.H,
    ["J"]=Enum.KeyCode.J,["L"]=Enum.KeyCode.L,["Z"]=Enum.KeyCode.Z,["C"]=Enum.KeyCode.C,
    ["V"]=Enum.KeyCode.V,["B"]=Enum.KeyCode.B
}

local function isShift(k)
    -- Shift if it's an uppercase letter or a shift symbol
    return k:match("^[A-Z]$") or k:match("^[!@$%%^*(]$")
end

local function pc(ks)
    local un, sh = {}, {}
    for _, k in ipairs(ks) do
        local c = km[k]
        if c then
            if isShift(k) then table.insert(sh, c) else table.insert(un, c) end
        end
    end
    task.spawn(function()
        if #un > 0 then
            for _, c in ipairs(un) do vim:SendKeyEvent(true, c, false, game) end
            task.wait(0.02)
            for _, c in ipairs(un) do vim:SendKeyEvent(false, c, false, game) end
        end
        if #sh > 0 then
            vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.01)
            for _, c in ipairs(sh) do vim:SendKeyEvent(true, c, false, game) end
            task.wait(0.02)
            for _, c in ipairs(sh) do vim:SendKeyEvent(false, c, false, game) end
            vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end
    end)
end

-- Main playback loop
task.spawn(function()
    while true do
        if st == "Playing" then
            if idx > #song then
                if looping then
                    idx, lt = 1, 0
                else
                    st, idx, lt = "Stopped", 1, 0
                end
            else
                local e = song[idx]
                -- Apply speed: divide wait by speed so higher = faster
                local w = (e.time - lt) / speed
                if w > 0.001 then task.wait(w) end

                -- Collect chord with dynamic window based on speed
                local window = math.max(0.01, 0.02 / speed)
                local ck, j = {}, idx
                while j <= #song and (song[j].time - e.time) <= window do
                    local note = song[j].note + transpose
                    local k = nm[note]
                    if k then table.insert(ck, k) end
                    j = j + 1
                end
                if #ck > 0 then pc(ck) end
                lt, idx = e.time, j
            end
        else
            task.wait(0.1)
        end
        task.wait()
    end
end)

-- UI
local rf = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local win = rf:CreateWindow({Name = "Sedse's MIDI Player", LoadingTitle = "Loading...", ConfigurationSaving = {Enabled = false}})
local tab = win:CreateTab("Main")

local function scan()
    local dn, lm = {}, {}
    for _, p in ipairs(listfiles(pth)) do
        if p:lower():sub(-4) == ".mid" then
            local n = p:match("([^/\\]+)$") -- handle both / and \ separators
            if n then
                table.insert(dn, n)
                lm[n] = p
            end
        end
    end
    if #dn == 0 then table.insert(dn, "No songs found") end
    table.sort(dn) -- alphabetical order
    return dn, lm
end

local init, imap = scan()
fmap = imap

local drop = tab:CreateDropdown({
    Name = "Song",
    Options = init,
    CurrentOption = {"None"},
    Callback = function(o)
        local n = o[1]
        local p = fmap[n]
        if p then
            local ok, data = pcall(readfile, p)
            if ok then
                local parsed = pm(data)
                if #parsed > 0 then
                    fpath, st, idx, lt = p, "Stopped", 1, 0
                    song = parsed
                end
            end
        end
    end,
})

tab:CreateButton({Name = "Refresh Songs", Callback = function()
    local dn, lm = scan()
    fmap = lm
    -- Safely update dropdown
    pcall(function() drop:Refresh(dn, true) end)
end})

tab:CreateSlider({
    Name = "Speed",
    Range = {0.25, 3},
    Increment = 0.25,
    CurrentValue = 1,
    Callback = function(v) speed = v end,
})

tab:CreateSlider({
    Name = "Transpose (semitones)",
    Range = {-12, 12},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(v) transpose = v end,
})

tab:CreateToggle({
    Name = "Loop",
    CurrentValue = false,
    Callback = function(v) looping = v end,
})

tab:CreateButton({Name = "▶ Play", Callback = function()
    if #song > 0 then
        st = "Playing"
    end
end})

tab:CreateButton({Name = "⏸ Pause", Callback = function()
    if st == "Playing" then st = "Paused" end
end})

tab:CreateButton({Name = "⏹ Stop", Callback = function()
    st, idx, lt = "Stopped", 1, 0
end})
