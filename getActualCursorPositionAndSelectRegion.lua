function SelectRegionAtPlayPosition()
    playPos = reaper.GetPlayPosition()
    numMarkers, numRegions = reaper.CountProjectMarkers(0)

    for i = 0, numRegions - 1 do
        retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if isrgn and playPos >= pos and playPos <= rgnend then
            reaper.GetSet_LoopTimeRange(true, false, pos, rgnend, false)
            return
        end
    end

    reaper.defer(SelectRegionAtPlayPosition)
end

SelectRegionAtPlayPosition()
