local Info       = debug.getinfo (1, 'S');
local ScriptPath = Info.source:match[[^@?(.*[\/])[^\/]-$]];
package.path     = ScriptPath .. './?.lua;' .. package.path;
-- package.path     = ScriptPath .. '../lib2/lua/?.lua;' .. package.path;

local v_rec = require("video_recording_lib")

function onexit()
--  reaper.ShowConsoleMsg("<-----\n")
end

reaper.defer(v_rec.start_recording)
reaper.atexit(onexit)
