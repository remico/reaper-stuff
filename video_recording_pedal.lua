package.path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]] .. './?.lua;' .. package.path;

local v_rec = require("video_recording_lib")

local name, x, y, w, h = "Video Recording", 1600, 200, 220, 200

STATE_INIT = 1
STATE_READY = 2
STATE_MAIN_LOOP_WAITING = 4
STATE_RECORDING = 8

STATE = STATE_INIT  -- holds current state

function is_state(state)
  return state & STATE == state
end

function set_state(state)
  STATE = state
end

-- *********************************
-- ******** FUNCTIONS **************
-- *********************************

function loop_init()
  local char = gfx.getchar()
  local is_ctrl_pressed = gfx.mouse_cap == 4
  local is_esc_pressed = char == 27
  local is_ctrl_q_pressed = char == 17

  -- quit on "Ctrl + Esc" is pressed or GUI is closed
  if (is_ctrl_pressed and is_esc_pressed) or char == -1 then
    return 0
  end

  -- enter main loop
  if is_ctrl_pressed then
    v_rec.prepare_recording()
    set_state(STATE_MAIN_LOOP_WAITING)
    reaper.defer(loop_main)
    return 0
  end

  local is_new,name,secID,cmdID,rel_mode,res,val = reaper.get_action_context()
  if is_new then

    if val == 0 then
      -- quit if still not in main loop yet
      if is_state(STATE_INIT) then
        set_state(STATE_READY)
      elseif is_state(STATE_READY) then
        return 0
      end
    end

  end

  reaper.defer(loop_init)
  return is_ctrl_pressed
end

function loop_main()
  local char = gfx.getchar()
  local is_ctrl_pressed = gfx.mouse_cap == 4
  local is_esc_pressed = char == 27
  local is_ctrl_q_pressed = char == 17

  -- quit on "Ctrl + Esc" is pressed or GUI is closed
  if (is_ctrl_pressed and is_esc_pressed) or char == -1 then
    return 0
  end

  -- display technical info in the glx window
  gfx.x, gfx.y = 50, 50
  if is_ctrl_pressed then
    gfx.drawstr("CTRL" .. " | " .. char)
  elseif is_esc_pressed then
    gfx.drawstr("ESC")
  elseif is_state(STATE_MAIN_LOOP_WAITING) then
    gfx.drawstr("READY" .. " | " .. char)
  elseif is_state(STATE_RECORDING) then
    gfx.drawstr("RECORDING" .. " | " .. char)
  else
    gfx.drawstr(char)
  end
  -- gfx.update()

  if is_ctrl_pressed and is_esc_pressed then
    v_rec.reset_cursor_pos()
  end

  local is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
  if is_new then
    -- reaper.ShowConsoleMsg(name .. "\nrel: " .. rel .. "\nres: " .. res .. "\nval = " .. val .. "\n")

    if val == 127 then
      if is_state(STATE_RECORDING) then
        v_rec.stop_recording()
      end

      if is_ctrl_pressed then
        v_rec.insert_recorded_media_to_current_pos()
        set_state(STATE_MAIN_LOOP_WAITING)
      else
        set_state(STATE_RECORDING)
        v_rec.clear_content_on_target_tracks()
        v_rec.start_recording()
      end
    end
  end

  reaper.defer(loop_main)
end

function onexit()
  -- reaper.ShowConsoleMsg("<-----\n")
  local being_recorded = is_state(STATE_RECORDING)
  v_rec.stop_recording()
  if being_recorded then
    v_rec.insert_recorded_media_to_current_pos()
  end
end

gfx.init(name, w, h, 0, x, y)
reaper.defer(loop_init)
reaper.atexit(onexit)
