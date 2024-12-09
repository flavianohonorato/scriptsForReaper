local function checkSWSAvailability()
    if not reaper then
        reaper.ShowMessageBox("Reaper API not available", "Erro", 0)
        return false
    end
    
    if not reaper.JS_Window_OnKey and not reaper.JS_Mouse_GetState then
        reaper.ShowMessageBox("SWS Extension not installed", "Erro", 0)
        return false
    end
    
    return true
end

local function getCurrentBPM()
    return reaper.Master_GetTempo()
end

local function setBPM(bpm)
    reaper.Master_SetTempo(bpm, true)
end

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

local function smoothingBPMChange()
    if not smoothing then return false end

    local currentTime = reaper.time_precise()

    -- Verificar intervalo de suavização
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
    local windowUnderMouse = reaper.JS_Window_GetFocus()
    
    if reaper.JS_Window_GetFocus then
        local isZPressed = reaper.JS_Window_OnKey(windowUnderMouse, string.byte('z'), 0)
        if isZPressed then
            initBPMChange(-STEP_DECREASE)
        end

        local isXPressed = reaper.JS_Window_OnKey(windowUnderMouse, string.byte('x'), 0)
        if isXPressed then
            initBPMChange(STEP_INCREASE)
        end
    end

    reaper.defer(checkKeyInput)
end

local function main()
    if not checkSWSAvailability() then
        return
    end

    reaper.defer(checkKeyInput)
end

if reaper then
    main()
else
    reaper.ShowMessageBox("Erro: Unable to access Reaper API", "Erro", 0)
end