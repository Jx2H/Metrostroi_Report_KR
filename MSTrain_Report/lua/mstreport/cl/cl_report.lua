mstreport.pr = mstreport.pr or {}

CreateClientConVar("mstreport_debug_view", "0", true, false, "디버그 정보를 표시합니다. (비활성화 0)", 0, 1)

local function init()
    mstreport.pr = {
        ["pid"] = LocalPlayer():SteamID64(),
        ["valid"] = false,
        ["guiOpened"] = false,
        ["statusText"] = "",
        ["Dstart"] = nil,
        ["Dend"] = nil,
        ["Dto"] = nil,
        ["date"] = 0,
        ["Scurrent"] = 0,
        ["Slist"] = {},
        ["Snext"] = 0,
        ["Sprev"] = 0,
        ["frags"] = 0,
        ["Snow"] = 0,
        ["Sstart"] = 0,
        ["Tclass"] = nil,
        ["Tname"] = nil,
        ["Troute"] = 0,
        ["Twagon"] = 0
    }
end

function mstreport:date(s, t)
    return os.date(s, (t or os.time()))
end

local function date_sec(s)
    local hour = math.floor(s/3600)
    local min = math.floor((s%3600)/60)
    local sec = s % 60
    return string.format("%02d:%02d:%02d", hour, min, sec)
end

function mstreport:dateto(a, b, c)
    if not a or not b then return nil end
    if a > b then return nil end
    local d = b - a
    if c then
        return date_sec(d)
    else
        return d
    end
end

local nanstart = false
local nantime = 0

function mstreport.startReport()
    if mstreport.pr["valid"] == true or mstreport.pr["Dend"] then return end
    if nanstart then
        return Derma_Message("빠른 간격으로 보고서 작성하는 것을 방지하고 있습니다.\n남은 시간 - " .. (mstreport:dateto(os.time(), nantime + 60 * 10, true) or "무한 계산중..") .. " 초", "MSTR - 제한", "확인")
    end
    if mstreport.pr.Tname == "N/A" or mstreport.pr.Tname == nil then
        return Derma_Message("열차 인식이 되지 않거나 소환하지 않으셨습니다.", "MSTR", "확인")
    end
    LocalPlayer():ChatPrint("운행 보고 작성을 시작합니다.")
    nanstart = true
    nantime = os.time()
    mstreport.pr["valid"] = true
    mstreport.pr["Dstart"] = os.time()
    mstreport.pr["date"] = mstreport:date("%Y-%m-%d")
    mstreport.backup()
    timer.Simple(60 * 10, function()
        nanstart = false
    end)
    -- 디버깅
    -- for i = 0, 20 do
    --     table.insert(mstreport.pr["Slist"], 1, {
    --         nid = i * 10,
    --         tend = "00:00:00",
    --         tstart = "00:00:00"
    --     })
    -- end
end

function mstreport.endReport()
    local function m()
        local i = 0
        if mstreport.pr.Tname == "N/A" then i = i + 1 end
        if mstreport.pr.Dstart == nil then i = i + 1 end
        if i == 0 then
            return false
        else
            return true
        end
    end
    local function send()
        mstreport.pr["Dend"] = os.time()
        mstreport.pr["Dto"] = mstreport:dateto(mstreport.pr.Dstart, mstreport.pr.Dend, true)
        net.Start("mstreport.net_dataSave")
        local t = util.TableToJSON(mstreport.pr)
        net.WriteString(tostring(#t))
        net.WriteData(t, #t)
        net.SendToServer()
        --
        net.Start("mstreport.net_clBackup")
        net.SendToServer()
        timer.Simple(3, function()
            init()
        end)
    end
    if not mstreport.pr["valid"] then
        return Derma_Message("운행 시작한 후 종료할 수 있습니다.", "MSTR", "확인")
    end
    Derma_Query("운행을 종료하시겠습니까?", "MSTR", "아니요", nil, "네", function()
        LocalPlayer():ChatPrint("운행 보고를 마칩니다.")
        if m() then
            return Derma_Query("데이터가 유효하지 않습니다. 그래도 저장할까요?", "MSTR", "저장 안함", function()
                init()
                net.Start("mstreport.net_clBackup")
                net.SendToServer()
            end, "네", function()
                send()
            end)
        end
        send()
    end)
end

function mstreport:BstatusSave(v)
    if v == "" and mstreport.pr["statusText"] == "" then
        return LocalPlayer():ChatPrint("비고 란에 아무것도 입력하지 않으셨습니다.")
    elseif v == "" and mstreport.pr["statusText"] ~= "" or v then
        mstreport.pr["statusText"] = v or ""
        LocalPlayer():ChatPrint("비고 내용을 저장하였습니다.")
    end
end

function mstreport.PLZbackup()
    net.Start("mstreport.net_plzBackup")
    net.SendToServer()
end

function mstreport:T(str,...)
	return string.format(Metrostroi.GetPhrase(str),...)
end

function mstreport:GetTrainName(class)
    local result = "N/A"
	if class ~= "N/A" then
        local train_name = mstreport:T("Entities."..class..".Name")
		local s1,s2 = string.find(train_name," головной") or string.find(train_name," head")
		if s1 then
			result = string.sub(train_name,1,s1-1)..")"
		else
			result = train_name
		end
	end
	return result
end

function mstreport.guireopen()
    mstreport:cl_gui(true)
    timer.Simple(0.1, function()
        mstreport.cl_gui()
    end)
end

function mstreport.backup()
    if not mstreport.pr["valid"] then return end
    print("[MSTR] 현재 데이터가 서버에 임시 저장되었습니다.")
    net.Start("mstreport.net_endBackup")
    local t = util.TableToJSON(mstreport.pr)
    net.WriteString(tostring(#t))
    net.WriteData(t, #t)
    net.SendToServer()
end

local function mstreport_chat(...)
    chat.AddText(...)
end

function mstreport:searchRequest(callback)
    net.Start("mstreport.net_searchRequest")
    net.SendToServer()
    -- 
    net.Receive("mstreport.net_searchResponse", function()
        local data = util.JSONToTable(net.ReadData(tonumber(net.ReadString())))
        callback(data)
    end)
end

local mstreport_hud = false
local mstreport_hud_str = ""
local mstreport_hud_now = 0
local mstreport_hud_gui = nil

function mstreport:hud()
    if mstreport_hud then
        mstreport_hud = false
        mstreport:hudGui(true)
        return LocalPlayer():ChatPrint("HUD 비활성화")
    end
    mstreport_hud = true
    mstreport:hudGui()
    LocalPlayer():ChatPrint("HUD 활성화")
end

local function mstreport_hudClear()
    timer.Simple(5, function()
        mstreport_hud_str = ""
    end)
end

function mstreport:hudGui(c)
    if c and mstreport_hud_gui then
        mstreport_hud_gui:Close()
        return
    end
    local f = vgui.Create("DFrame")
    mstreport_hud_gui = f
    f:SetSize(700, 100)
    f:SetPos(ScrW() * 0.5 - (f:GetWide() / 2), ScrH() * 0.18 - f:GetTall())
    f:SetTitle("")
    f:SetDraggable( false )
    f:SetScreenLock( true )
    f:ShowCloseButton( false )
    f:SetMouseInputEnabled( true )
    f:SetKeyboardInputEnabled( false )
    f.Paint = function(_, w, h)
        -- draw.SimpleText(mstreport_hud_str, "mstr_r30", w / 2, 0, Color(255,255,255,255), 1)
    end
    f.OnClose = function()
        mstreport_hud_gui = nil
    end
    local l = vgui.Create("DLabel", f)
    l:SetPos(0,0)
    l:SetSize(f:GetWide(), 35)
    l:SetText("")
    l:SetFont("mstr_r30")
    l:SetColor(Color(255,255,255))
    l:SetContentAlignment(5)

    f.Think = function()
        l:SetText(mstreport_hud_str)
    end
end

timer.Create("mstreport.cl_timer_hud", 1, 0, function()
    if mstreport_hud then
        if mstreport.pr["Scurrent"] ~= 0 and mstreport_hud_now == 0 then
            mstreport_hud_now = mstreport.pr["Scurrent"]
            mstreport_hud_str = mstreport.pr["Scurrent"] .. "역 " .. mstreport:date("%H:%M:%S") .. " 도착"
            mstreport_hudClear()
        elseif mstreport_hud_now ~= 0 and mstreport.pr["Scurrent"] == 0 then
            mstreport_hud_str = mstreport_hud_now .. "역 " .. mstreport:date("%H:%M:%S") .. " 출발"
            mstreport_hud_now = 0
            mstreport_hudClear()
        end
    end
end)

timer.Create("mstreport.cl_timer_stationRequest", 1, 0, function()
    net.Start("mstreport.net_stationInfo")
    net.SendToServer()
end)

timer.Create("mstreport.cl_timer_stationLoad", 1, 0, function()
    if mstreport.pr["valid"] then
        if mstreport.pr["Scurrent"] ~= 0 and mstreport.pr["Snow"] == 0 then
            mstreport.pr["Snow"] = mstreport.pr["Scurrent"]
            mstreport.pr["Send"] = mstreport:date("%H:%M:%S")
        elseif mstreport.pr["Snow"] ~= 0 and mstreport.pr["Scurrent"] == 0 then
            table.insert(mstreport.pr["Slist"], 1, {
                nid = mstreport.pr["Snow"],
                tend = mstreport.pr["Send"],
                tstart = mstreport:date("%H:%M:%S")
            })
            mstreport.pr["Snow"] = 0
        end
    end
end)

timer.Create("mstreport.cl_timer_fragsSave", 10, 0, function()
    if mstreport.pr["valid"] then
        mstreport.pr["frags"] = LocalPlayer():Frags()
    end
end)

hook.Add("InitPostEntity", "mstreport.cl_playerset", function()
    init()
    local code = GetConVarString("gmod_language")
    if string.lower(code) == "ko" and GetConVarString("metrostroi_language") ~= "kr" then
    --    LocalPlayer():ChatPrint("[MSTR] 메트로스트로이 언어 설정을 한국어로 변경되었습니다.")
        RunConsoleCommand("metrostroi_language", "kr")
    end
end)

hook.Add("OnPlayerChat", "mstreport.cl_chatsay", function( ply, text, bTeam, bDead )
    if LocalPlayer() ~= ply then return end
    if text == "!report" then
        mstreport.cl_gui()
    end
    if text == "!report -t" then
        PrintTable(mstreport.pr)
    end
    if text == "!report -s" then
        mstreport.startReport()
    end
    if text == "!report -p" then
        mstreport.endReport()
    end
end)

hook.Add( "PlayerButtonDown", "mstreport.cl_guiOpen", function( ply, button )
    if button == KEY_F3 then
        mstreport.cl_gui()
    end
end)

net.Receive("mstreport.net_trainInfo", function()
    mstreport.pr.Tclass = net.ReadString()
    mstreport.pr.Twagon = net.ReadInt(32)
    mstreport.pr.Troute = net.ReadInt(32)
    mstreport.pr.Tname = mstreport:GetTrainName(mstreport.pr.Tclass)
    --print("[MSTR] 트래커 작동중 / " .. mstreport.pr.Tclass .. " (" .. tostring(mstreport.pr.Twagon) .. "량) 열번: " .. tostring(mstreport.pr.Troute))
end)

net.Receive("mstreport.net_takeBackup", function()
    local data = util.JSONToTable(net.ReadData(tonumber(net.ReadString())))
    local a = mstreport.pr
    print("[MSTR] 백업 데이터 받음.")
    if mstreport.pr["valid"] then return end
    -- Derma_Message("임시 저장된 데이터를 불러왔습니다.\n(잘못된 데이터인 경우 \"운행종료\"를 반드시 눌러주세요.)", "MSTR", "확인")
    function w()
        Derma_Query("임시 저장된 데이터를 불러왔습니다.\n이제 운행을 하지 않으신다면 '운행중단'을 눌러주세요.", "MSTR - BackUp", 
            "불러오기", function()
                mstreport.pr = data
                mstreport.pr["guiOpened"] = a["guiOpened"]
                mstreport.guireopen()
            end,
            "운행중단", function()
                Derma_Query("정말 '운행중단' 하시겠습니까?", "MSTR - BackUp",
                    "아니요", function()
                        w()
                    end,
                    "네", function()
                        -- mstreport.endReport()
                        net.Start("mstreport.net_clBackup")
                        net.SendToServer()
                    end)
            end)
    end
    w()
end)

net.Receive("mstreport.net_backup", function()
    mstreport.backup()
end)

net.Receive("mstreport.net_stationResponse", function()
    local data = util.JSONToTable(net.ReadData(tonumber(net.ReadString())))
    mstreport.pr["Scurrent"] = data.c
    mstreport.pr["Snext"] = data.n
    mstreport.pr["Sprev"] = data.p
end)

net.Receive("mstreport.net_dataResponse", function()
    LocalPlayer():ChatPrint("성공적으로 저장되었습니다.\n이번 보고서 번호는 " .. tostring(net.ReadString()) .. " (으)로 기록되었습니다.")
end)

net.Receive("mstreport.net_chat", function()
    mstreport_chat(unpack(net.ReadTable()))
end)

net.Receive("mstreport.net_debugchat", function()
    if GetConVarNumber("mstreport_debug_view") == 1 then
        mstreport_chat(unpack(net.ReadTable()))
    end
end)

net.Receive("mstreport.net_print", function()
    LocalPlayer():ChatPrint(net.ReadString())
end)