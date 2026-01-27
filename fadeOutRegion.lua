local END_REGION_NAME = "END"
local FADE_DURATION_SECONDS = 5.0

local function getActivePosition()
    local playState = reaper.GetPlayState()
    if playState & 1 == 1 then
        return reaper.GetPlayPosition()
    end

    return reaper.GetCursorPosition()
end

local function findRegionAtPosition(position)
    local numMarkers, numRegions = reaper.CountProjectMarkers(0)

    for i = 0, numMarkers + numRegions - 1 do
        local _, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if isrgn and position >= pos and position <= rgnend then
            return {
                pos = pos,
                rgnend = rgnend,
                name = name,
                index = markrgnindexnumber
            }
        end
    end

    return nil
end

local function findRegionByName(regionName)
    local numMarkers, numRegions = reaper.CountProjectMarkers(0)

    for i = 0, numMarkers + numRegions - 1 do
        local _, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if isrgn and name == regionName then
            return {
                pos = pos,
                rgnend = rgnend,
                name = name,
                index = markrgnindexnumber
            }
        end
    end

    return nil
end

local function applyFadeOutToItemsInRegion(regionStart, regionEnd)
    local fadeStart = math.max(regionEnd - FADE_DURATION_SECONDS, regionStart)
    local totalTracks = reaper.CountTracks(0)
    local itemsAffected = 0
    local affectedItems = {}

    for t = 0, totalTracks - 1 do
        local track = reaper.GetTrack(0, t)
        local itemCount = reaper.CountTrackMediaItems(track)

        for i = 0, itemCount - 1 do
            local item = reaper.GetTrackMediaItem(track, i)
            local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local itemEnd = itemStart + itemLen

            if itemStart < regionEnd and itemEnd > regionEnd then
                reaper.SplitMediaItem(item, regionEnd)
                itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                itemEnd = itemStart + itemLen
            end

            if itemEnd > fadeStart and itemEnd <= regionEnd then
                local available = itemEnd - fadeStart
                local fadeLen = math.min(FADE_DURATION_SECONDS, available)
                if fadeLen > 0 then
                    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeLen)
                    itemsAffected = itemsAffected + 1
                    affectedItems[#affectedItems + 1] = item
                end
            end
        end
    end

    return itemsAffected, affectedItems
end

local function clearFadeOutOnItems(items)
    for i = 1, #items do
        local item = items[i]
        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0.0)
    end
end

local function startEndRegionMonitor(targetRegionEnd, endRegionStart, affectedItems)
    local function monitor()
        local playState = reaper.GetPlayState()
        if playState == 0 then
            return
        end

        local playPos = reaper.GetPlayPosition()
        if playPos >= targetRegionEnd then
            if reaper.GetToggleCommandState(1068) == 1 then
                reaper.Main_OnCommand(1068, 0)
            end
            reaper.GetSet_LoopTimeRange(true, false, 0, 0, false)
            clearFadeOutOnItems(affectedItems)
            reaper.SetEditCurPos2(0, endRegionStart, true, true)
            reaper.Main_OnCommand(1007, 0)
            return
        end

        reaper.defer(monitor)
    end

    reaper.defer(monitor)
end

local function main()
    local position = getActivePosition()
    local currentRegion = findRegionAtPosition(position)
    if not currentRegion then
        reaper.MB("Nenhuma região encontrada na posição atual.", "Erro", 0)
        return
    end

    reaper.Undo_BeginBlock()
    local itemsAffected, affectedItems = applyFadeOutToItemsInRegion(currentRegion.pos, currentRegion.rgnend)
    reaper.Undo_EndBlock("Fade out da região atual (itens)", -1)

    if itemsAffected == 0 then
        reaper.MB("Nenhum item encontrado para aplicar fade out.", "Aviso", 0)
    end

    local endRegion = findRegionByName(END_REGION_NAME)
    if endRegion and endRegion.pos ~= currentRegion.pos then
        startEndRegionMonitor(currentRegion.rgnend, endRegion.pos, affectedItems)
    end
end

main()
