local STEP_DECREASE = 5
local STEP_INCREASE = 5
local SMOOTH_STEPS = 20
local SMOOTH_INTERVAL = 0.05
local DECREASE_KEY = 'z'
local INCREASE_KEY = 'x'

local currentBPM = 0
local targetBPM = 0
local smoothing = false
local lastSmoothingTime = 0

local function getCurrentBPM()
    return reaper.Master_GetTempo()
end

local function setBPM(bpm)
    reaper.SetCurrentBPM(0, bpm, true)
end

local function smoothingBPMChange()
    if not smoothing then return false end

    local currentTime = reaper.time_precise()

    if currentTime - lastSmoothingTime < SMOOTH_INTERVAL then
        reaper.defer(smoothingBPMChange)
        return true
    end

    local currentStep = math.abs(currentBPM - targetBPM) / SMOOTH_STEPS

    if currentBPM < targetBPM then
        currentBPM = math.min(currentBPM + currentStep, targetBPM)
    elseif currentBPM > targetBPM then
        currentBPM = math.max(currentBPM - currentStep, targetBPM)
    end

    setBPM(currentBPM)
    lastSmoothingTime = currentTime

    if math.abs(currentBPM - targetBPM) < 0.01 then
        smoothing = false
        return false
    end

    reaper.defer(smoothingBPMChange)
    return true
end

local function initBPMChange(change)
    currentBPM = getCurrentBPM()
    targetBPM = currentBPM + change
    smoothing = true
    lastSmoothingTime = 0

    smoothingBPMChange()
end

local function checkKeyInput()
    local char = reaper.JS_Window_OnKey(string.byte(DECREASE_KEY), 0)
    if char then
        initBPMChange(-STEP_DECREASE)
    end

    char = reaper.JS_Window_OnKey(string.byte(INCREASE_KEY), 0)
    if char then
        initBPMChange(STEP_INCREASE)
    end

    reaper.defer(checkKeyInput)
end

local function main()
    if not reaper.JS_Window_OnKey then
        reaper.ShowMessageBox("Por favor, instale a extensão SWS", "Erro", 0)
        return
    end

    reaper.defer(checkKeyInput)
end

main()