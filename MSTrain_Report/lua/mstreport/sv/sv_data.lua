local _path = "mstreport"
file.CreateDir(_path)

local function date(s, t)
    return os.date(s, (t or os.time()))
end

local function date_sec(s)
    local hour = math.floor(s/3600)
    local min = math.floor((s%3600)/60)
    local sec = s % 60
    return string.format("%02d:%02d:%02d", hour, min, sec)
end

function mstreport:data_c()
    local time = date("%Y%m%d")
    file.Write(_path .. "/" .. time .. ".json", "{}")
end

function mstreport:data_r()
    local time = date("%Y%m%d")
    if not file.Exists(_path .. "/" .. time .. ".json", "DATA") then
        mstreport:data_c()
    end
    return file.Read(_path .. "/" .. time .. ".json", "DATA")
end

function mstreport:data_w(t)
    local time = date("%Y%m%d")
    local old_d = util.JSONToTable(mstreport:data_r())
    if old_d == nil then
        mstreport:data_c()
        return mstreport:data_w(t)
    end
    local datesss = date("%y%m%d%H%M") .. tostring(1)
    local wa = table.GetKeys(old_d)
    table.sort(wa, function(a, b) return tonumber(a) < tonumber(b) end)
    for _, v in pairs(wa) do
        if tonumber(v) == tonumber(datesss) then
            datesss = tonumber(v) + 1
        end
    end
    old_d[datesss] = t
    file.Write(_path .. "/" .. time .. ".json", util.TableToJSON(old_d, true))
    return datesss
end

function mstreport:data(t)
    for _, v in pairs({
        "Scurrent",
        "Snext",
        "Snow",
        "Sprev",
        "Sstart",
        "guiOpened",
        "valid",
        "Tclass"
    }) do
        if t[v] ~= nil then
            t[v] = nil
        end
    end
    t["_map"] = game.GetMap() or "_"
    return mstreport:data_w(t)
end

function mstreport:data_search()
    local files, dirs = file.Find(_path .. "/*.json", "DATA", "nameasc")
    local t = {}
    for _, fn in pairs(files) do
        local data = file.Read(_path .. "/" .. fn, "DATA")
        if data == nil then
            file.Write(_path .. "/" .. fn, "{}")
            continue
        end
        local json = util.JSONToTable(data)
        if json == nil then
            file.Write(_path .. "/" .. fn, "{}")
            continue
        end
        local strs = string.Split(fn, ".")
        t[table.concat(strs, ".", nil, #strs - 1)] = json
    end
    return t
end