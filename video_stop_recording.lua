package.path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]] .. './?.lua;' .. package.path;

local v_rec = require("video_recording_lib")

function onexit()
  -- reaper.ShowConsoleMsg("<-----\n")
end

function run()
  v_rec.stop_recording()
  v_rec.insert_recorded_media_to_current_pos()
end

reaper.defer(run)
reaper.atexit(onexit)
