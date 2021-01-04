-- **********************************
-- User variables
-- **********************************
local yi_path = os.getenv("HOME") .. "/Videos/"
local yi_video_file = yi_path .. "yi_video.mkv"
local yi_audio_file = yi_path .. "yi_video.wav"
local rtmp_stream = "rtmp://localhost/live"

-- **********************************
-- Constants
-- **********************************
local TRACK_YI_VIDEO = "YI video"
local TRACK_YI_AUDIO = "YI audio"
local TRACK_PIANO_MIDI = "Piano MIDI"
local TRACK_PIANO_AUDIO = "Piano audio"

local TRACKS = {}

RECORDING_SHELL_COMMAND_START = "ffmpeg -i " .. rtmp_stream .. " -c copy -an -y " .. yi_video_file .. " -vn -y " .. yi_audio_file .. " &"
RECORDING_SHELL_COMMAND_STOP = "killall ffmpeg"

-- **********************************
-- Helper Functions
-- **********************************
function parse_tracks()
  for i = 0, reaper.CountTracks() - 1 do
    local mtrack = reaper.GetTrack(0, i)
    _, name = reaper.GetTrackName(mtrack)
    TRACKS[name] = mtrack
  end
end

function initialize_project()
  for i=0, 3 do
    reaper.InsertTrackAtIndex(i, false)
    local mtrack = reaper.GetTrack(0, i)
  end

  reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, 0), "P_NAME", TRACK_YI_VIDEO, true)
  reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, 1), "P_NAME", TRACK_YI_AUDIO, true)
  reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, 2), "P_NAME", TRACK_PIANO_MIDI, true)
  reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, 3), "P_NAME", TRACK_PIANO_AUDIO, true)

  -- #TODOs:
  -- mute yi audio
  -- increase piano midi volume => +8 dB
  -- setup sending piano midi => piano audio
  -- setup sending piano midi output => casio piano
  -- save the project

  parse_tracks()
end

function is_project_initialized()
  parse_tracks()

  if TRACKS[TRACK_YI_VIDEO]
      and TRACKS[TRACK_YI_AUDIO]
      and TRACKS[TRACK_PIANO_MIDI]
      and TRACKS[TRACK_PIANO_AUDIO] then
    return true
  end

  return false
end

function insert_media_to_track(track, file_path, cursor_pos)
  if reaper.file_exists(file_path) then
    reaper.SetOnlyTrackSelected(track)
    reaper.SetEditCurPos(cursor_pos, false, false)
    reaper.InsertMedia(file_path, 0)
    reaper.SetTrackSelected(track, false)
  end
end

-- **********************************
-- Library Methods
-- **********************************
local video_recording_lib = {}

function video_recording_lib.sleep(n)
  os.execute("sleep " .. tonumber(n))
end

function video_recording_lib.start_recording()
  os.execute(RECORDING_SHELL_COMMAND_START)

  -- clear all selections
  reaper.SelectAllMediaItems(0, false)
  for i = 0, reaper.CountTracks() - 1 do
    local mtrack = reaper.GetTrack(0, i)
    reaper.SetTrackSelected(mtrack, false)
  end

  reaper.CSurf_OnRecord()
end

function video_recording_lib.stop_recording()
  reaper.CSurf_OnStop()
  os.execute(RECORDING_SHELL_COMMAND_STOP)
  -- group the newly recorded media items (they are staying selected right after recording)
  reaper.Main_OnCommand(40032, 0)
end

function video_recording_lib.insert_recorded_media_to_current_pos()
  -- #FIXME wait for the video file is saved by ffmpeg
  video_recording_lib.sleep(1)

  -- prepare for groupping the new items
  reaper.SelectAllMediaItems(0, false)

  -- insert recorded YI media
  cursor_pos = reaper.GetCursorPosition()

  insert_media_to_track(TRACKS[TRACK_YI_AUDIO], yi_audio_file, cursor_pos)
  -- reaper.Main_OnCommand(40108, 0) -- normalize the YI audio volume

  insert_media_to_track(TRACKS[TRACK_YI_VIDEO], yi_video_file, cursor_pos)

  -- group newly inserted YI media items (they are staying selected right after insertion)
  reaper.Main_OnCommand(40032, 0)

  -- move edit cursor to the track start position
  video_recording_lib.reset_cursor_pos()
end

function video_recording_lib.clear_all_selected_items()
  local num_of_items = reaper.CountSelectedMediaItems(0)
  for i=num_of_items-1, 0, -1 do
    item =  reaper.GetSelectedMediaItem(0, i)
    reaper.DeleteTrackMediaItem( reaper.GetMediaItemTrack(item), item )
  end
end

function video_recording_lib.get_track_media_items(track)
  local mitems = {}
  local num_of_items = reaper.CountTrackMediaItems(track)
  for item_idx=0, num_of_items-1 do
    table.insert( mitems, reaper.GetTrackMediaItem( track, item_idx) )
  end
  return mitems
end

function video_recording_lib.clear_content_on_target_tracks()
  for _, track in pairs(TRACKS) do
    for _, mitem in pairs( video_recording_lib.get_track_media_items(track) ) do
      reaper.DeleteTrackMediaItem( track, mitem )
    end
  end
end

function video_recording_lib.prepare_recording()
  -- arm required tracks
  reaper.SetMediaTrackInfo_Value(TRACKS[TRACK_PIANO_MIDI], "I_RECARM", 1)
  reaper.SetMediaTrackInfo_Value(TRACKS[TRACK_PIANO_AUDIO], "I_RECARM", 1)

  -- move edit cursor to the beginning of the take before starting recording
  video_recording_lib.reset_cursor_pos()

  -- remove all media items on them
  video_recording_lib.clear_content_on_target_tracks()

  -- unselect all remaining media items
  reaper.SelectAllMediaItems(0, false)
end

function video_recording_lib.get_media_item_pos(track)
  local item = reaper.GetTrackMediaItem(track, 0)
  if item then
    return reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  else
    return 0
  end
end

function video_recording_lib.set_media_item_pos(track, position)
  local item = reaper.GetTrackMediaItem(track, 0)
  if item then
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
    return true
  else
    return false
  end
end

function video_recording_lib.reset_cursor_pos()
  local track = TRACKS[TRACK_PIANO_MIDI]
  local item_start_pos = video_recording_lib.get_media_item_pos(track) -- #FIXME check all the target tracks in the future
  local item_exists = reaper.CountTrackMediaItems(track) > 0
  if item_exists then
    reaper.SetEditCurPos(item_start_pos, false, false)
  end
end

-- **********************************
-- Script Body
-- **********************************

-- #TODO show a popup "do you want to initialize project?"
-- preconditions: check if the project contains all the 4 required tracks (by track name)
if not is_project_initialized() then
  -- show_initialization_popup()
  -- then if YES => do intialization
  initialize_project()
  -- #TODO return otherwise
end

return video_recording_lib
