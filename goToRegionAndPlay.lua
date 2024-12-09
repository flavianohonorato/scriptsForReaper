function Main()
  local desiredRegionIndex = 1
  
  GoToRegionAndPlay(desiredRegionIndex)
end

function GoToRegionAndPlay(regionIndex)

  local numRegions = reaper.CountProjectMarkers(0)

  if regionIndex > 0 and regionIndex <= numRegions then
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(regionIndex - 1)
    reaper.SetEditCurPos(pos, true, true)
    reaper.SetEditCurPos2(0, pos, true, true)
    reaper.Main_OnCommand(1007, 0)
  else
    reaper.ShowMessageBox("Invalid region index: " .. regionIndex, "Error", 0)
  end
end

Main()
