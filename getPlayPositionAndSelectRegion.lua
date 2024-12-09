function Main()
    playCursor = reaper.GetPlayPosition()
    markerRegionIndex, regionIndex = reaper.GetLastMarkerAndCurRegion(0, playCursor)
    retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(regionIndex) -- Mudança aqui
    if isrgn then -- Adicionado condicional para verificar se é uma região
        reaper.GetSet_LoopTimeRange(true, false, pos, rgnend, false)
    else
        reaper.MB("Nenhuma região encontrada na posição atual!", "Error", 0)
    end
end

Main()

