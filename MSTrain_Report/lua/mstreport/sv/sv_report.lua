-- Thanks for Alexell
-- https://github.com/Alexell/metrostroi_scoreboard_pro

local trainlist = {}
timer.Create("mstreport.timer_svtrainsSet", 1, 60, function()
    for _, c in pairs(Metrostroi.TrainClasses) do
        local aw = scripted_ents.Get(c)
        if not aw.Spawner or not aw.SubwayTrain then continue end
        table.insert(trainlist, c)
    end
    if #trainlist ~= 0 then
        timer.Remove("mstreport.timer_svtrainsSet")
    end
end)

local function GetStationName(st_id,name_num)
    if Metrostroi.StationConfigurations[st_id] then
        if Metrostroi.StationConfigurations[st_id].names[name_num] then
            return Metrostroi.StationConfigurations[st_id].names[name_num]
        else
            return Metrostroi.StationConfigurations[st_id].names[1]
        end
    else
        return ""
    end
end

util.AddNetworkString("mstreport.net_chat")
local function cl_chat(ply, ...)
    net.Start("mstreport.net_chat")
    net.WriteTable({...})
    net.Send(ply)
end

util.AddNetworkString("mstreport.net_debugchat")
local function cl_debugChat(ply, ...)
    net.Start("mstreport.net_debugchat")
    net.WriteTable({Color(250, 150, 5), "[MSTR-DEBUG] ", Color(255,255,255), ...})
    net.Send(ply)
end

util.AddNetworkString("mstreport.net_print")
local function cl_chatprint(ply, msg)
    net.Start("mstreport.net_print")
    net.WriteString(msg)
    net.Send(ply)
end

util.AddNetworkString("mstreport.net_stationInfo")
util.AddNetworkString("mstreport.net_stationResponse")
net.Receive("mstreport.net_stationInfo", function(len, ply)
    cl_debugChat(ply, "현재 역 요청")
    if IsValid(ply.train) then
        local t = ply.train
        net.Start("mstreport.net_stationResponse")
        st = util.TableToJSON({
            c = t:ReadCell(49160),
            n = t:ReadCell(49161),
            p = t:ReadCell(49162)
        })
        net.WriteString(tostring(#st))
        net.WriteData(st, #st)
        net.Send(ply)
        cl_debugChat(ply, "현재 역 응답 /" .. t:ReadCell(49160))
    end
end)

util.AddNetworkString("mstreport.net_trainInfo")
local function net_trainInfo_NA(player)
    net.Start("mstreport.net_trainInfo")
    net.WriteString("N/A")
    net.WriteInt(0, 32)
    net.WriteInt(0, 32)
    net.Send(player)
    cl_debugChat(player, "트래커에서 열차 발견되지 않음.")
end

timer.Create("mstreport.timer_trainInfo", 15, 0, function()
    -- print("[MSTR] 운행 정보 수집됨")
    local local_trains = {}
    for _, l in pairs(trainlist) do
        for _a, train in pairs(ents.FindByClass(l)) do
            local ply = train.Owner
            -- 주의: IsValid 사용할때 ply 있더라도 재접속시 거짓을 반환하는 경우가 있음.
            if not IsValid(ply) then
                if train.sid == nil then continue end
                local i = 0
                for _b, pa in pairs(player.GetHumans()) do
                    if pa:SteamID64() == train.sid then
                        i = i + 1
                    end
                end
                if i == 0 then continue
                else
                    -- 오너 재설정
                    train.Owner = player.GetBySteamID64(train.sid)
                    ply = train.Owner
                end
            end
            train.sid = ply:SteamID64()
            local route = "0"
            if train:GetClass() == "gmod_subway_81-722" or train:GetClass() == "gmod_subway_81-722_3" or train:GetClass() == "gmod_subway_81-7175p" then
                route = tostring(train.RouteNumberSys.CurrentRouteNumber)
            elseif train:GetClass() == "gmod_subway_81-717_6" then
                route = tostring(train.ASNP.RouteNumber)
            else
                if train.RouteNumber then
                    route = train.RouteNumber.RouteNumber
                end
            end
            local a = {
                class = tostring(train:GetClass()),
                route = route,
                wagon = #train.WagonList,
                ply = ply:SteamID64(),
            }
            local i = 0
            for _b, v in pairs(local_trains) do
                if v.ply == a.ply then i = i + 1 end
            end
            if i == 0 then
                table.insert(local_trains, a)
                ply.train = train
            end
        end
    end

    for _a, player in pairs(player.GetHumans()) do
        if #local_trains == 0 then
            net_trainInfo_NA(player)
        else
            local i = 0
            for _, v in pairs(local_trains) do
                if player:SteamID64() == v["ply"] then
                    net.Start("mstreport.net_trainInfo")
                    net.WriteString(v["class"])
                    net.WriteInt(v["wagon"], 32)
                    net.WriteInt(v["route"], 32)
                    net.Send(player)
                    cl_debugChat(player, "트래커에서 열차 발견됨")
                    i = i + 1
                end
            end
            if i == 0 then
                net_trainInfo_NA(player)
            end
        end
        -- print(player:SteamID64())
    end
end)


util.AddNetworkString("mstreport.net_backup")
timer.Create("mstreport.timer_backup", mstreport.config["backup_request"], 0, function()
    net.Start("mstreport.net_backup")
    net.Broadcast()
end)

local mstreport_logout = {}

util.AddNetworkString("mstreport.net_endBackup")
net.Receive("mstreport.net_endBackup", function(len, ply)
    local data = util.JSONToTable(net.ReadData(tonumber(net.ReadString())))
    cl_debugChat(ply, "현재 데이터 임시 저장됨.")
    --print(ply:SteamID64() .. " 백업 받음")
    local function logout()
        --print("나감")
        mstreport_logout[data.pid] = data
        timer.Simple(mstreport.config["logout_waiting"], function()
            local i_ = 0
            for _, ply in pairs(player.GetHumans()) do
                if ply:SteamID64() == data.pid then
                    i_ = i_ + 1
                    break
                end
            end
            if i_ == 0 then
                if mstreport_logout[data.pid] then
                    mstreport_logout[data.pid] = nil
                end
            end 
        end)
    end
    timer.Create("mstreport.timer_backup_".. data.pid, 1, mstreport.config["backup_request"], function()
        local i = 0
        for _, ly in pairs(player.GetHumans()) do
            if ly:SteamID64() == data.pid then
                i = i + 1
            end
        end
        if i == 0 then
            logout()
            return timer.Remove("mstreport.timer_backup_".. data.pid)
        end
    end)
end)

util.AddNetworkString("mstreport.net_takeBackup")
local function mstreport_takeBackup(ply)
    net.Start("mstreport.net_takeBackup")
    local t = util.TableToJSON(mstreport_logout[ply:SteamID64()])
    net.WriteString(tostring(#t))
    net.WriteData(t, #t)
    net.Send(ply)
    --
    ply:SetFrags(mstreport_logout[ply:SteamID64()].frags)
    cl_debugChat(ply, "승객 수 복귀됨.")
    mstreport_logout[ply:SteamID64()] = nil
    cl_debugChat(ply, "이전 백업 데이터 삭제됨.")
end

util.AddNetworkString("mstreport.net_plzBackup")
net.Receive("mstreport.net_plzBackup", function(len, ply)
    if mstreport_logout[ply:SteamID64()] then
        --print("백업 있음")
        cl_debugChat(ply, "백업 데이터 요청함.")
        mstreport_takeBackup(ply)
        cl_debugChat(ply, "백업 데이터 받음.")
    end
end)

util.AddNetworkString("mstreport.net_clBackup")
net.Receive("mstreport.net_clBackup", function(len, ply)
    ply:SetFrags(0)
    cl_debugChat(ply, "승객 수 0 지정됨.")
end)

util.AddNetworkString("mstreport.net_dataResponse")
local function save_reid(id, ply)
    net.Start("mstreport.net_dataResponse")
    net.WriteString(tostring(id))
    net.Send(ply)
    cl_debugChat(ply, "보고서 번호 반환됨.")
end

-- 데이터 파일 저장
util.AddNetworkString("mstreport.net_dataSave")
net.Receive("mstreport.net_dataSave", function(len, ply)
    local t = util.JSONToTable(net.ReadData(tonumber(net.ReadString())))
    local idv = mstreport:data(t)
    cl_debugChat(ply, "보고서 저장됨.")
    if mstreport_logout[ply:SteamID64()] then
        mstreport_logout[ply:SteamID64()] = nil
        cl_debugChat(ply, "임시 저장된 데이터 강제 삭제됨.")
    end
    timer.Remove("mstreport.timer_backup_".. ply:SteamID64())
    save_reid(idv, ply)
end)

-- 조회 전산 및 응답
util.AddNetworkString("mstreport.net_searchResponse")
local function mstreport_searchResponse(ply)
    local t = mstreport.data_search()
    local set = nil
    function send()
        local a = util.TableToJSON(set)
        if not set or not a then
            cl_chat(Color(0, 150, 255), "[MSTR] ", Color(255,255,255), "관련 데이터를 수집할 수 없었습니다. (검색 불가)")
            return
        end
        net.Start("mstreport.net_searchResponse")
        net.WriteString(tostring(#a))
        net.WriteData(a, #a)
        net.Send(ply)
    end
    if ply:IsAdmin() then
        cl_debugChat(ply, "관리자 확인됨. 전체 데이터 반환 중...")
        set = t
        send()
        cl_debugChat(ply, "데이터 반환 준비 끝.")
    else
        cl_debugChat(ply, "본인 보고서 정렬중...")
        set = {}
        for _a, a in pairs(table.GetKeys(t)) do
            for _b, b in pairs(table.GetKeys(t[a])) do
                if ply:SteamID64() == t[a][b]["pid"] then
                    if set[a] == nil then set[a] = {} end
                    if set[a][b] == nil then set[a][b] = {} end
                    set[a][b] = t[a][b]
                end
            end
        end
        send()
        cl_debugChat(ply, "정렬 완료.")
    end
end

-- 조회 요청
util.AddNetworkString("mstreport.net_searchRequest")
net.Receive("mstreport.net_searchRequest", function(len, ply)
    cl_debugChat(ply, "조회 요청.")
    mstreport_searchResponse(ply)
    cl_debugChat(ply, "조회 반환됨.")
end)