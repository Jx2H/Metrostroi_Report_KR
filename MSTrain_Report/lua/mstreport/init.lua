local main_path = "mstreport/"
local sv_path = "sv/"
local sh_path = "sh/"
local cl_path = "cl/"

local sv_files = file.Find( main_path..sv_path.."*.lua", "LUA" )
local sh_files = file.Find( main_path..sh_path.."*.lua", "LUA" )
local cl_files = file.Find( main_path..cl_path.."*.lua", "LUA" )

MsgC( Color(40, 110, 255), "\n\n[ Metrostroi - Report ]\n" )
MsgC( Color(245, 180, 65), " - Made by Jx2H ( https://steamcommunity.com/id/jx2h/ )\n" )
MsgC( Color(245, 180, 65), " - 본 애드온은 Metrostroi 전용 서버를 위해 개발함.\n\n" )
MsgC( Color(245, 180, 65), " - 자체제작 애드온\n\n" )
Msg(">>> 파일 추가중...\n" )

-- 설정 로드
include( "config.lua" )

for _, file in ipairs(sh_files) do
    MsgC( Color(40, 110, 255), "sh> "..file.."\n" )
    include(sh_path..file)
end

for _, file in ipairs(sv_files) do
    MsgC( Color(77, 245, 65), "sv> "..file.."\n" )
    include(sv_path..file)
end

Msg(">>> 파일 추가 완료\n" )
Msg(">>> 클라이언트 파일 지정중...\n" )
AddCSLuaFile(main_path.."cl_init.lua")
-- 설정 로드
AddCSLuaFile(main_path.."config.lua")

for _, file in ipairs(sh_files) do
    MsgC( Color(40, 110, 255), "sh> "..file.."\n" )
    AddCSLuaFile(main_path..sh_path..file)
end

for _, file in ipairs(cl_files) do
    MsgC( Color(245, 180, 65), "cl> "..file.."\n" )
    AddCSLuaFile(main_path..cl_path..file)
end
Msg(">>> 클라이언트 파일 지정 완료\n\n\n" )