local LAST_REGION_ID = nil
local LAST_POSITION = nil
local LAST_PLAY_STATE = nil

local EPSILON = 0.0001

local function getCurrentReferencePosition()
    local playState = reaper.GetPlayState()
    local isPlaying = (playState & 1) == 1

    if isPlaying then
        return reaper.GetPlayPosition(), playState
    end

    return reaper.GetCursorPosition(), playState
end

local function findRegionAtPosition(position)
    local _, numMarkers, numRegions = reaper.CountProjectMarkers(0)
    local total = numMarkers + numRegions

    local closestFutureRegion = nil

    for i = 0, total - 1 do
        local ok, isRegion, startPos, endPos, _, markerRegionId = reaper.EnumProjectMarkers(i)

        if ok and isRegion then
            if position >= (startPos - EPSILON) and position <= (endPos + EPSILON) then
                return {
                    startPos = startPos,
                    endPos = endPos,
                    markerRegionId = markerRegionId,
                }
            end

            if position < startPos and (not closestFutureRegion or startPos < closestFutureRegion.startPos) then
                closestFutureRegion = {
                    startPos = startPos,
                    endPos = endPos,
                    markerRegionId = markerRegionId,
                }
            end
        end
    end

    return closestFutureRegion
end

local function setLoopToRegion(region)
    reaper.GetSet_LoopTimeRange(true, false, region.startPos, region.endPos, false)
end

local function shouldReevaluate(currentPosition, playState)
    if LAST_POSITION == nil or LAST_PLAY_STATE == nil then
        return true
    end

    local positionChanged = math.abs(currentPosition - LAST_POSITION) > EPSILON
    local stateChanged = playState ~= LAST_PLAY_STATE

    return positionChanged or stateChanged
end

local function main()
    local currentPosition, playState = getCurrentReferencePosition()

    if shouldReevaluate(currentPosition, playState) then
        local region = findRegionAtPosition(currentPosition)

        if region and region.markerRegionId ~= LAST_REGION_ID then
            setLoopToRegion(region)
            LAST_REGION_ID = region.markerRegionId
        elseif not region then
            LAST_REGION_ID = nil
        end

        LAST_POSITION = currentPosition
        LAST_PLAY_STATE = playState
    end

    reaper.defer(main)
end

main()
