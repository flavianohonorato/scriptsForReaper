local LAST_REGION_ID = nil
local LAST_POSITION = nil

local EPSILON = 0.0001

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

local function main()
    local cursorPosition = reaper.GetCursorPosition()

    if LAST_POSITION == nil or math.abs(cursorPosition - LAST_POSITION) > EPSILON then
        local region = findRegionAtPosition(cursorPosition)

        if region and region.markerRegionId ~= LAST_REGION_ID then
            reaper.GetSet_LoopTimeRange(true, false, region.startPos, region.endPos, false)
            LAST_REGION_ID = region.markerRegionId
        elseif not region then
            LAST_REGION_ID = nil
        end

        LAST_POSITION = cursorPosition
    end

    reaper.defer(main)
end

main()
