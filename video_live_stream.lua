function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

function open_video_preview()
  local stream = "rtmp://localhost/live"
  os.execute("killall ffplay")
  os.execute("ffplay -i " ..  stream .. " -an -x 710 -y 400 &")
  sleep(3)
  os.execute("wmctrl -r " ..  stream .. " -b add,above")
  os.execute("wmctrl -r " ..  stream .. " -e 0,1200,580,-1,-1")
end

function onexit()
--  reaper.ShowConsoleMsg("<-----\n")
end

reaper.defer(open_video_preview)
reaper.atexit(onexit)
