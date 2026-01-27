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
        if isrgn and position >= pos and posit
        ion <= rgnend then
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

local function getMasterVolumeEnvelope()
    local masterTrack = reaper.GetMasterTrack(0)
    return reaper.GetTrackEnvelopeByName(masterTrack, "Volume")
end

local function applyFadeOut(envelope, startTime, endTime)
    local value = select(1, reaper.Envelope_Evaluate(envelope, startTime, 0, 0))
    reaper.InsertEnvelopePoint(envelope, startTime, value, 0, 0, false, true)
    reaper.InsertEnvelopePoint(envelope, endTime, 0.0, 0, 0, false, true)
    reaper.Envelope_SortPoints(envelope)
end

local function startEndRegionMonitor(targetRegionEnd, endRegionStart)
    local function monitor()
        local playState = reaper.GetPlayState()
        if playState == 0 then
            return
        end

        local playPos = reaper.GetPlayPosition()
        if playPos >= targetRegionEnd then
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

    local envelope = getMasterVolumeEnvelope()
    if not envelope then
        reaper.MB("Envelope de volume do master não disponível.", "Erro", 0)
        return
    end

    local fadeStart = math.max(currentRegion.rgnend - FADE_DURATION_SECONDS, currentRegion.pos)

    reaper.Undo_BeginBlock()
    applyFadeOut(envelope, fadeStart, currentRegion.rgnend)
    reaper.Undo_EndBlock("Fade out da região atual", -1)

    local endRegion = findRegionByName(END_REGION_NAME)
    if endRegion and endRegion.pos ~= currentRegion.pos then
        startEndRegionMonitor(currentRegion.rgnend, endRegion.pos)
    end
end

main()
