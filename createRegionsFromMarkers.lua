function CreateRegionsFromMarkers()
    local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local total_markers = num_markers + num_regions
    local markers = {}

    for i = 0, total_markers - 1 do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if not isrgn then
            table.insert(markers, {pos = pos, name = name, index = markrgnindexnumber})
        end
    end

    for i = 1, #markers - 1 do
        local start_pos = markers[i].pos
        local end_pos = markers[i + 1].pos
        local name = markers[i].name
        reaper.AddProjectMarker2(0, true, start_pos, end_pos, name, -1, 0)
    end

    for i = #markers, 1, -1 do
        local index = markers[i].index
        reaper.DeleteProjectMarker(0, index, false)
    end

    reaper.Undo_EndBlock("Create regions from markers and remove markers", -1)
end

reaper.Undo_BeginBlock()
CreateRegionsFromMarkers()
reaper.UpdateArrange()
