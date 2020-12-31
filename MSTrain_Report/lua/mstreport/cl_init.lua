local main_path = "mstreport/"
local cl_path = "cl/"
local sh_path = "sh/"

local sh_files = file.Find( main_path..sh_path.."*.lua", "LUA" )
local cl_files = file.Find( main_path..cl_path.."*.lua", "LUA" )

MsgC(Color(255,255,255), "\n>>> [MSTR] 클라이언트 파일 추가중...\n")

-- 설정 로드
include( "config.lua" )

for _, file in ipairs(sh_files) do
    MsgC( Color(40, 110, 255), "sh> "..file.."\n" )
    include(sh_path..file)
end

for _, file in ipairs( cl_files ) do
    MsgC(Color(245, 180, 65), "cl> "..file.."\n")
    include( cl_path..file )
end

MsgC(Color(255,255,255), ">>> [MSTR] 클라이언트 파일 추가 완료\n\n")