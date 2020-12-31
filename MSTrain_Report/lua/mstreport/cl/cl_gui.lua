mstreport.pr = mstreport.pr or {}

local mstreport_gui = nil

function mstreport:cl_gui(close)
    if close then
        if mstreport_gui then
            mstreport_gui:Close()
        end
    end
    if mstreport.pr["guiOpened"] == true then return end
    mstreport.pr.guiOpened = true

    timer.Simple(0, function()
        mstreport.PLZbackup()
    end)

    local ply = LocalPlayer()
    local start_offset = 5

    local f = vgui.Create("DFrame")
    mstreport_gui = f
    f:SetSize(420, 640)
    f:Center()
    f:SetTitle("")
    f:SetDraggable( false )
    f:SetScreenLock( true )
    f:ShowCloseButton( false )
    f:MakePopup()
    f.OnClose = function()
        timer.Remove("mstreport.cl_timer_stationlist")
        mstreport.pr["guiOpened"] = false
        mstreport_gui = nil
    end
    f.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 0))
    end

    local Bclose = vgui.Create( "DImageButton", f )
    Bclose:SetPos(f:GetWide() - 18 - 6, 6)
    Bclose:SetSize(18, 18)
    Bclose:SetImage("icon16/cross.png")
    Bclose:SetTooltip("창 닫기")
    Bclose.Paint = function() end
    Bclose.DoClick = function()
        f:Close()
    end

    local Bsearch = vgui.Create("DImageButton", f)
    Bsearch:SetPos(f:GetWide() - 40 - 6, 6)
    Bsearch:SetSize(18, 18)
    Bsearch:SetImage("icon16/magnifier.png")
    Bsearch:SetTooltip("보고서 검색")
    Bsearch.Paint = function() end
    Bsearch.DoClick = function()
        mstreport:searchGui()
        f:Close()
    end

    -- local Bhelp = vgui.Create("DImageButton", f)
    -- Bhelp:SetPos(f:GetWide() - 60 - 10, 5)
    -- Bhelp:SetSize(18, 18)
    -- Bhelp:SetImage("icon16/information.png")
    -- Bhelp:SetTooltip("도움말")
    -- Bhelp.Paint = function() end
    -- Bhelp.DoClick = function()
    -- end

    local Bhudopen = vgui.Create("DImageButton", f)
    Bhudopen:SetPos(5, 6)
    Bhudopen:SetSize(18, 18)
    Bhudopen:SetImage("icon16/comments.png")
    Bhudopen:SetTooltip("HUD 활성화/비활성화")
    Bhudopen.Paint = function() end
    Bhudopen.DoClick = function()
        mstreport.hud()
    end

    local fp = vgui.Create( "DPanel", f )
    fp:Dock(FILL)
    fp:SetSize(f:GetWide(), f:GetTall())
    fp.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(250, 250, 250))
        -- Tname
        draw.SimpleText(mstreport.pr.Tname or "", "mstr_r20", start_offset + 50, 60, Color(0,0,0))
        -- Twagon
        draw.SimpleText(mstreport.pr.Twagon or 0, "mstr_r20", start_offset + 50, 85, Color(0,0,0))
        -- Troute
        draw.SimpleText(mstreport.pr.Troute or 0, "mstr_r20", start_offset + 260, 85, Color(0,0,0))
        -- Frags
        draw.SimpleText(ply:Frags(), "mstr_r20", start_offset + 260, 135, Color(0,0,0))
        -- Data
        draw.SimpleText(mstreport.pr.valid and mstreport.pr.date or "시작 안함", "mstr_r20", start_offset + 240, 35, Color(0,0,0))
        -- Dstart
        draw.SimpleText(mstreport.pr.Dstart ~= nil and mstreport:date("%H:%M:%S", mstreport.pr.Dstart) or "측정 대기", "mstr_r20", start_offset + 80, 110, Color(0,0,0))
        -- Dend
        draw.SimpleText(mstreport.pr.Dend ~= nil and mstreport:date("%H:%M:%S", mstreport.pr.Dend) or "측정 대기", "mstr_r20", start_offset + 80, 135, Color(0,0,0))
        -- Dto
        draw.SimpleText(mstreport:dateto(mstreport.pr.Dstart, mstreport.pr.Dend or os.time(), true) or "측정 대기", "mstr_r20", start_offset + 260, 110, Color(0,0,0))
    end

    local Ltitle = vgui.Create( "DLabel", fp)
    Ltitle:SetPos(0, 0)
    Ltitle:SetText("운행보고서")
    Ltitle:SetFont("mstr_r30")
    Ltitle:SetSize(fp:GetWide() - 10, 30)
    Ltitle:SetContentAlignment(5)
    Ltitle:SetColor(Color(0, 0, 0))

    local Lauthor = vgui.Create( "DLabel", fp )
    Lauthor:SetPos(start_offset + 5, 35)
    Lauthor:SetText("작성자: " .. ply:Name())
    Lauthor:SetFont("mstr_r20")
    Lauthor:SetSize(170, 20)
    Lauthor:SetColor(Color(0, 0, 0))

    local Ldate = vgui.Create( "DLabel", fp )
    Ldate:SetPos(start_offset + 180, 35)
    Ldate:SetText("작성일: ")
    Ldate:SetFont("mstr_r20")
    Ldate:SetSize(170, 20)
    Ldate:SetColor(Color(0, 0, 0))

    local Ltclass = vgui.Create( "DLabel", fp )
    Ltclass:SetPos(start_offset + 5, 60)
    Ltclass:SetText("차종: ")
    Ltclass:SetFont("mstr_r20")
    Ltclass:SetSize(fp:GetWide(), 20)
    Ltclass:SetColor(Color(0, 0, 0))

    local Ltwagon = vgui.Create( "DLabel", fp )
    Ltwagon:SetPos(start_offset + 5, 85)
    Ltwagon:SetText("량수: ")
    Ltwagon:SetFont("mstr_r20")
    Ltwagon:SetSize(fp:GetWide(), 20)
    Ltwagon:SetColor(Color(0, 0, 0))

    local Ltroute = vgui.Create( "DLabel", fp )
    Ltroute:SetPos(start_offset + 180, 85)
    Ltroute:SetText("열차번호: ")
    Ltroute:SetFont("mstr_r20")
    Ltroute:SetSize(fp:GetWide(), 20)
    Ltroute:SetColor(Color(0, 0, 0))

    local Lstartdate = vgui.Create( "DLabel", fp )
    Lstartdate:SetPos(start_offset + 5, 110)
    Lstartdate:SetText("시작시간: ")
    Lstartdate:SetFont("mstr_r20")
    Lstartdate:SetSize(fp:GetWide(), 20)
    Lstartdate:SetColor(Color(0, 0, 0))

    local Ltodate = vgui.Create( "DLabel", fp )
    Ltodate:SetPos(start_offset + 180, 110)
    Ltodate:SetText("운행시간: ")
    Ltodate:SetFont("mstr_r20")
    Ltodate:SetSize(fp:GetWide(), 20)
    Ltodate:SetColor(Color(0, 0, 0))

    local Lenddate = vgui.Create( "DLabel", fp )
    Lenddate:SetPos(start_offset + 5, 135)
    Lenddate:SetText("작성시간: ")
    Lenddate:SetFont("mstr_r20")
    Lenddate:SetSize(fp:GetWide(), 20)
    Lenddate:SetColor(Color(0, 0, 0))

    local Lfrags = vgui.Create( "DLabel", fp )
    Lfrags:SetPos(start_offset + 180, 135)
    Lfrags:SetText("총 승객수: ")
    Lfrags:SetFont("mstr_r20")
    Lfrags:SetSize(fp:GetWide(), 20)
    Lfrags:SetColor(Color(0, 0, 0))

    local Bstart = vgui.Create("DButton", fp)
    Bstart:SetPos(fp:GetWide() - start_offset - 230, 160)
    Bstart:SetText("운행시작")
    Bstart:SetFont("mstr_r20")
    Bstart:SetSize(100, 25)
    Bstart:SetColor(Color(0, 0, 0))
    Bstart.DoClick = function()
        mstreport.startReport()
    end

    local Bend = vgui.Create("DButton", fp)
    Bend:SetPos(fp:GetWide() - start_offset - 120, 160)
    Bend:SetText("운행종료")
    Bend:SetFont("mstr_r20")
    Bend:SetSize(100, 25)
    Bend:SetColor(Color(0, 0, 0))
    Bend.DoClick = function()
        mstreport.endReport()
    end

    local Lstlist = vgui.Create("DLabel", fp)
    Lstlist:SetPos(start_offset + 2, 160)
    Lstlist:SetText("시간 기록표")
    Lstlist:SetFont("mstr_r25")
    Lstlist:SetSize(120, 25)
    Lstlist:SetColor(Color(0, 0, 0))

    local st_list = vgui.Create("DListView", fp)
    st_list:SetPos(start_offset, 190)
    st_list:SetSize(fp:GetWide() - start_offset - 15, 200)
    st_list.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
        surface.SetDrawColor( 0,0,0 )
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    for a_, col in pairs({"역 번호", "도착 시간", "출발 시간"}) do
        local st_list_col = st_list:AddColumn(col)
        st_list_col.Header:SetFont("mstr_r15")
        st_list_col.Header.Paint = function(_, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
            surface.SetDrawColor( 0, 0, 0 )
            surface.DrawOutlinedRect(0, 0, w, h)
        end
        if a_ == 1 then
            st_list_col:SetFixedWidth(60)
        else
            st_list_col:SetFixedWidth(170)
        end
    end

    local function stlistrset()
        for _, s in pairs(mstreport.pr.Slist) do
            local a = st_list:AddLine(s.nid, s.tend, s.tstart)
            a.Paint = function() end
            for __, b in pairs(a.Columns) do
                b:SetFont("mstr_r15")
                b:SetColor(Color(0, 0, 0))
                b:SetContentAlignment(5)
            end
        end
    end
    stlistrset()

    timer.Create("mstreport.cl_timer_stationlist", 1, 0, function()
        st_list:Clear()
        stlistrset()
    end)

    local Lstatus = vgui.Create("DLabel", fp)
    Lstatus:SetPos(start_offset + 2, 404)
    Lstatus:SetText("비고")
    Lstatus:SetFont("mstr_r25")
    Lstatus:SetColor(Color(0,0,0))

    local status_text = vgui.Create("DTextEntry", fp)
    status_text:SetPos(start_offset, 430)
    status_text:SetSize(fp:GetWide() - start_offset - 15, 170)
    status_text:SetMultiline(true)
    status_text:SetText(mstreport.pr.statusText)
    status_text:SetPlaceholderText("아무것도 입력하지 않으셨습니다.")
    status_text:SetFont("mstr_r15")
    status_text:SetTextColor(Color(0,0,0))

    local Bstatus_save = vgui.Create("DButton", fp)
    Bstatus_save:SetPos(start_offset + 55, 402)
    Bstatus_save:SetText("저장")
    Bstatus_save:SetSize(40, 25)
    Bstatus_save:SetFont("mstr_r15")
    Bstatus_save:SetColor(Color(255, 255, 255))
    Bstatus_save.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 150, 255))
    end

    Bstatus_save.DoClick = function(_)
        _:ColorTo(Color(0, 95, 255), 0.1, 0, function()
            mstreport:BstatusSave(status_text:GetValue())
            _:ColorTo(Color(255, 255, 255), 0.3, 0)
        end)
    end
end

function mstreport:searchGui()
    local f = vgui.Create("DFrame")
    f:SetSize(700, 400)
    f:Center()
    f:SetTitle("")
    f:SetDraggable( false )
    f:SetScreenLock( true )
    f:ShowCloseButton( false )
    f:MakePopup()
    f.Paint = function(_, w, h) end

    local Bclose = vgui.Create("DImageButton", f)
    Bclose:SetPos(f:GetWide() - 25, 6)
    Bclose:SetSize(18, 18)
    Bclose:SetImage("icon16/cross.png")
    Bclose:SetTooltip("창 닫기")
    Bclose.Paint = function() end
    Bclose.DoClick = function()
        f:Close()
    end

    local Breturn = vgui.Create("DImageButton", f)
    Breturn:SetPos(5, 6)
    Breturn:SetSize(16, 16)
    Breturn:SetImage("icon16/arrow_undo.png")
    Breturn:SetTooltip("운행보고서 창으로 돌아가기")
    Breturn.Paint = function() end
    Breturn.DoClick = function()
        mstreport.cl_gui()
        f:Close()
    end

    local fp = vgui.Create("DPanel", f)
    fp:SetSize(f:GetWide(), f:GetTall())
    fp:Dock(FILL)
    fp.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(255,255,255))
        draw.SimpleText("운행보고서 - 조회시스템", "mstr_r25", f:GetWide() / 2 - 203, 3, Color(0,0,0))
    end

    local t = vgui.Create("DTree", fp)
    t:SetSize(140)
    t:Dock(LEFT)

    local rp = vgui.Create("DPanel", fp)
    rp:SetPos(150, 30)
    rp:SetSize(fp:GetWide() - 140 - 25, fp:GetTall() - 65)
    rp.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
        draw.SimpleText("Player(Name Or ID):", "mstr_r20", 10, 5, Color(0, 0, 0))
        draw.SimpleText("Train Name:", "mstr_r20", 10, 30, Color(0, 0, 0))
        draw.SimpleText("Train Wagon:", "mstr_r20", 10, 55, Color(0, 0, 0))
        draw.SimpleText("Train Number:", "mstr_r20", w / 2, 55, Color(0, 0, 0))
        draw.SimpleText("Date:", "mstr_r20", 10, 80, Color(0, 0, 0))
        draw.SimpleText("Operating Time:", "mstr_r20", w / 2, 80, Color(0, 0, 0))
        draw.SimpleText("Start Time:", "mstr_r20", 10, 105, Color(0, 0, 0))
        draw.SimpleText("End Time:", "mstr_r20", w / 2, 105, Color(0, 0, 0))
        draw.SimpleText("Passengers:", "mstr_r20", w / 2, 130, Color(0, 0, 0))
        draw.SimpleText("Station Record Table", "mstr_r25", 10, 140, Color(0, 0, 0))
    end

    local Smap = vgui.Create("DLabel", fp)
    Smap:SetPos(410, 10)
    Smap:SetText("")
    Smap:SetSize(300, 15)
    Smap:SetFont("mstr_r15")
    Smap:SetColor(Color(0, 0, 0))

    local Sname = vgui.Create("DLabel", rp )
    Sname:SetPos(180, 5)
    Sname:SetSize(rp:GetWide() - 10 - 180 - 100, 20)
    Sname:SetText("")
    Sname:SetFont("mstr_r20")
    Sname:SetColor(Color(0, 0, 0))

    local Stname = vgui.Create("DLabel", rp)
    Stname:SetPos(120, 30)
    Stname:SetSize(rp:GetWide() - 10 - 120, 20)
    Stname:SetText("")
    Stname:SetFont("mstr_r20")
    Stname:SetColor(Color(0, 0, 0))

    local Stwagon = vgui.Create("DLabel", rp)
    Stwagon:SetPos(130, 55)
    Stwagon:SetSize(100, 20)
    Stwagon:SetText("")
    Stwagon:SetFont("mstr_r20")
    Stwagon:SetColor(Color(0, 0, 0))

    local Stroute = vgui.Create("DLabel", rp)
    Stroute:SetPos(395, 55)
    Stroute:SetSize(100, 20)
    Stroute:SetText("")
    Stroute:SetFont("mstr_r20")
    Stroute:SetColor(Color(0, 0, 0))

    local Sdate = vgui.Create("DLabel", rp)
    Sdate:SetPos(65, 80)
    Sdate:SetSize(200, 20)
    Sdate:SetText("")
    Sdate:SetFont("mstr_r20")
    Sdate:SetColor(Color(0, 0, 0))

    local Sdto = vgui.Create("DLabel", rp)
    Sdto:SetPos(410, 80)
    Sdto:SetSize(100, 20)
    Sdto:SetText("")
    Sdto:SetFont("mstr_r20")
    Sdto:SetColor(Color(0, 0, 0))

    local Sdstart = vgui.Create("DLabel", rp)
    Sdstart:SetPos(110, 105)
    Sdstart:SetSize(200, 20)
    Sdstart:SetText("")
    Sdstart:SetFont("mstr_r20")
    Sdstart:SetColor(Color(0, 0, 0))

    local Sdend = vgui.Create("DLabel", rp)
    Sdend:SetPos(365, 105)
    Sdend:SetSize(100, 20)
    Sdend:SetText("")
    Sdend:SetFont("mstr_r20")
    Sdend:SetColor(Color(0, 0, 0))

    local Sfrags = vgui.Create("DLabel", rp)
    Sfrags:SetPos(380, 130)
    Sfrags:SetSize(100, 20)
    Sfrags:SetText("")
    Sfrags:SetFont("mstr_r20")
    Sfrags:SetColor(Color(0, 0, 0))

    local st_list = vgui.Create("DListView", rp)
    st_list:SetPos(10, 166)
    st_list:SetSize(270, 160)
    st_list.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
        surface.SetDrawColor( 0,0,0 )
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    for a_, col in pairs({"역 번호", "도착 시간", "출발 시간"}) do
        local st_list_col = st_list:AddColumn(col)
        st_list_col.Header:SetFont("mstr_r15")
        st_list_col.Header.Paint = function(_, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
            surface.SetDrawColor( 0, 0, 0 )
            surface.DrawOutlinedRect(0, 0, w, h)
        end
        if a_ == 1 then
            st_list_col:SetFixedWidth(50)
        else
            st_list_col:SetFixedWidth(110)
        end
    end

    local dtext = vgui.Create("DTextEntry", rp)
    dtext:SetPos(285, 166)
    dtext:SetSize(250, 160)
    dtext:SetMultiline(true)
    dtext:SetFont("mstr_r15")
    dtext:SetPlaceholderText("비고 없음")

    mstreport:searchRequest(function(data)
        local keys = table.GetKeys(data)
        table.sort(keys, function(a, b) return a > b end)
        for _a, a in pairs(keys) do
            if table.Count(data[a]) == 0 then continue end
            local t_1 = t:AddNode(a, "icon16/folder.png")
            if _a == 1 then
                timer.Simple(0.3, function()
                    t_1:SetExpanded(true)
                end)
            end
            local keys2 = table.GetKeys(data[a])
            table.sort(keys2, function(a, b) return a > b end)
            for _b, b in pairs(keys2) do
                local t_2 = t_1:AddNode(b, "icon16/report.png")
                t_2.OnNodeSelected = function(_, selected)
                    if selected:IsRootNode() then return end
                    local d = data[a][b] or data[a][tonumber(selected:GetText())]
                    -- for _, awds in pairs(table.GetKeys(d)) do
                    --     print(awds)
                    --     PrintTable(d[awds])
                    -- end
                    local pname = false
                    for _, ply in pairs(player.GetHumans()) do
                        if ply:SteamID64() == tostring(d["pid"]) then
                            pname = ply:GetName()
                            break
                        end
                    end
                    Smap:SetText(d["_map"] or "[근무지 파악 불가]")
                    Sname:SetText(pname or d["pid"])
                    Stname:SetText(d["Tname"])
                    Stwagon:SetText(tostring(d["Twagon"]))
                    Stroute:SetText(tostring(d["Troute"]))
                    Sdate:SetText(d["date"])
                    Sdto:SetText(d["Dto"])
                    Sdstart:SetText(mstreport:date("%H:%M:%S", d["Dstart"]))
                    Sdend:SetText(mstreport:date("%H:%M:%S", d["Dend"]))
                    Sfrags:SetText(tostring(d["frags"]))
                    dtext:SetText(d["statusText"])
                    st_list:Clear()
                    if table.Count(d["Slist"]) ~= 0 then
                        for _, c in pairs(d["Slist"]) do
                            local sl = st_list:AddLine(tostring(c["nid"]), c["tend"], c["tstart"])
                            sl.Paint = function() end
                            for __, sla in pairs(sl.Columns) do
                                sla:SetFont("mstr_r15")
                                sla:SetColor(Color(0, 0, 0))
                                sla:SetContentAlignment(5)
                            end
                        end
                    end
                end
            end
        end
    end)
end