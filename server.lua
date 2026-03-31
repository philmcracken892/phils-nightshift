local currentState = nil
local lastProcessedHour = -1

RegisterNetEvent('phils-nightshift:requestState', function()
    TriggerClientEvent('phils-nightshift:setState', source, currentState, Config)
end)

local function GetRealTime()
    local time = os.date("*t")
    return time.hour
end

function ProcessTimeChange(hour)
    local isDay = (hour >= Config.Schedule.dayStartHour and hour < Config.Schedule.nightStartHour)
    local newState = isDay and "day" or "night"
    
    if newState ~= currentState then
        currentState = newState
        if Config.Debug then
            print("[NightShift] State changed to: " .. currentState .. " (hour: " .. hour .. ")")
        end
        TriggerClientEvent('phils-nightshift:setState', -1, currentState, Config)
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    
    while true do
        local hour = GetRealTime()
        
        if hour ~= lastProcessedHour then
            lastProcessedHour = hour
            ProcessTimeChange(hour)
        end
        
        Citizen.Wait(1000)
    end
end)

if Config.Debug then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10000)
            local hour = GetRealTime()
            local isDay = (hour >= Config.Schedule.dayStartHour and hour < Config.Schedule.nightStartHour)
            print("[NightShift] Server Time: " .. hour .. " - " .. (isDay and "DAY" or "NIGHT"))
        end
    end)
end