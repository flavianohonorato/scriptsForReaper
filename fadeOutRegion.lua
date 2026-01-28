local END_REGION_NAME = "END"
local FADE_DURATION_SECONDS = 8.0
local END_THRESHOLD_SECONDS = 0.25
local END_MUTE_RELEASE_SECONDS = 0.08
local END_STOP_EARLY_SECONDS = 0.03
local END_CLEAR_FADE_DELAY_SECONDS = 0.12
local END_CLEAR_FADE_AFTER_JUMP_SECONDS = 0.2
local END_MUTE_RELEASE_AFTER_JUMP_SECONDS = 0.12
local END_UNMUTE_PLAY_ADVANCE_SECONDS = 0.06
local END_UNMUTE_FAILSAFE_SECONDS = 0.6
local NOTICE_WINDOW_W = 420
local NOTICE_WINDOW_H = 110
local NOTICE_FONT_SIZE = 32

local function setToggleState(isActive)
    local _, _, sectionId, commandId = reaper.get_action_context()
    if commandId == 0 then
        return
    end

    reaper.SetToggleCommandState(sectionId, commandId, isActive and 1 or 0)
    reaper.RefreshToolbar2(sectionId, commandId)
end

local function setFadeIndicator(isActive)
    setToggleState(isActive)
    if isActive then
        gfx.init("Fadeout ativo", NOTICE_WINDOW_W, NOTICE_WINDOW_H, 0)
        gfx.setfont(1, "Arial", NOTICE_FONT_SIZE)
        gfx.set(1, 1, 1, 1)
        gfx.x = 20
        gfx.y = (NOTICE_WINDOW_H - NOTICE_FONT_SIZE) / 2
        gfx.drawstr("FADEOUT ATIVO")
        gfx.update()
    else
        if gfx.getchar() >= 0 then
            gfx.quit()
        end
    end
end

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

local function disableLoopAndTimeSelection()
    if reaper.GetToggleCommandState(1068) == 1 then
        reaper.Main_OnCommand(1068, 0)
    end

    reaper.GetSet_LoopTimeRange(true, false, 0, 0, false)
    reaper.Main_OnCommand(40635, 0)
end

local function setMasterMute(isMuted)
    local master = reaper.GetMasterTrack(0)
    if master then
        reaper.SetMediaTrackInfo_Value(master, "B_MUTE", isMuted and 1 or 0)
    end
end

local function unmuteMasterLater(delaySeconds)
    local startTime = reaper.time_precise()
    local function wait()
        if reaper.time_precise() - startTime >= delaySeconds then
            setMasterMute(false)
            return
        end
        reaper.defer(wait)
    end
    reaper.defer(wait)
end

local function startEndRegionMonitor(targetRegionEnd, endRegionStart, affectedItems)
    local lastPlayPos = reaper.GetPlayPosition()
    local didFinish = false

    local function clearFadesWhenStopped(delaySeconds)
        local startTime = reaper.time_precise()
        local function wait()
            if reaper.GetPlayState() == 0 and (reaper.time_precise() - startTime) >= delaySeconds then
                clearFadeOutOnItems(affectedItems)
                return
            end
            reaper.defer(wait)
        end
        reaper.defer(wait)
    end

    local function clearFadesAfterDelay(delaySeconds)
        local startTime = reaper.time_precise()
        local function wait()
            if reaper.time_precise() - startTime >= delaySeconds then
                clearFadeOutOnItems(affectedItems)
                return
            end
            reaper.defer(wait)
        end
        reaper.defer(wait)
    end

    local function unmuteAndClearAfterJump(jumpStartPos)
        local startTime = reaper.time_precise()
        local function wait()
            local playState = reaper.GetPlayState()
            local playPos = reaper.GetPlayPosition()
            if playState & 1 == 1 and playPos >= (jumpStartPos + END_UNMUTE_PLAY_ADVANCE_SECONDS) then
                setMasterMute(false)
                clearFadeOutOnItems(affectedItems)
                return
            end
            if reaper.time_precise() - startTime >= END_UNMUTE_FAILSAFE_SECONDS then
                setMasterMute(false)
                clearFadeOutOnItems(affectedItems)
                return
            end
            reaper.defer(wait)
        end
        reaper.defer(wait)
    end

    local function handleEnd()
        if didFinish then
            return
        end
        didFinish = true
        setMasterMute(true)
        disableLoopAndTimeSelection()
        setFadeIndicator(false)
        if endRegionStart then
            reaper.SetEditCurPos2(0, endRegionStart, true, true)
            reaper.Main_OnCommand(1007, 0)
            -- Jump and keep playing; only unmute/clear after play advances a bit.
            unmuteAndClearAfterJump(endRegionStart)
        else
            reaper.SetEditCurPos2(0, targetRegionEnd, true, false)
            reaper.Main_OnCommand(1016, 0)
            -- Clear fades after a short stopped delay to avoid the pop.
            clearFadesWhenStopped(END_CLEAR_FADE_DELAY_SECONDS)
            unmuteMasterLater(END_MUTE_RELEASE_SECONDS)
        end
    end

    local function monitor()
        local playState = reaper.GetPlayState()
        local playPos = reaper.GetPlayPosition()
        local endCheck = targetRegionEnd

        local nearEnd = playPos >= endCheck
            or lastPlayPos >= (endCheck - END_THRESHOLD_SECONDS)

        if playState == 0 then
            if nearEnd then
                handleEnd()
            else
                setFadeIndicator(false)
            end
            return
        end

        local endEarly = (not endRegionStart) and playPos >= (endCheck - END_STOP_EARLY_SECONDS)
        local reachedEnd = playPos >= endCheck
            or (playPos < lastPlayPos and lastPlayPos >= (endCheck - END_THRESHOLD_SECONDS))

        if endEarly or reachedEnd then
            handleEnd()
            return
        end

        lastPlayPos = playPos
        reaper.defer(monitor)
    end

    reaper.defer(monitor)
end

local function main()
    setFadeIndicator(true)
    local position = getActivePosition()
    local currentRegion = findRegionAtPosition(position)
    if not currentRegion then
        setFadeIndicator(false)
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
    else
        startEndRegionMonitor(currentRegion.rgnend, nil, affectedItems)
    end
end

main()
