local NPCS = {}
local spawnedLocations = {}

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupAllNPCs()
    end
end)

-- Cleanup on player disconnect/server restart
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupAllNPCs()
    end
end)

function CleanupAllNPCs()
    if Config.Debug then
        print("[DayShift] Cleaning up all NPCs...")
    end
    
    for locationIndex, npcs in pairs(spawnedLocations) do
        for _, npcData in ipairs(npcs) do
            if DoesEntityExist(npcData.ped) then
                DeleteEntity(npcData.ped)
                if Config.Debug then
                    print("[DayShift] Deleted NPC from location: " .. locationIndex)
                end
            end
        end
    end
    
    spawnedLocations = {}
    
    if Config.Debug then
        print("[DayShift] Cleanup complete")
    end
end

Citizen.CreateThread(function()
    -- Initial cleanup on script start
    Citizen.Wait(1000)
    CleanupAllNPCs()
    
    while true do
        local hour = GetClockHours()
        local isDay = (hour >= Config.Schedule.dayStartHour and hour < Config.Schedule.nightStartHour)
        
        if isDay then
            for i, location in ipairs(Config.Locations) do
                if not spawnedLocations[i] or #spawnedLocations[i] == 0 then
                    SpawnNPCsForLocation(location, i)
                end
            end
        else
            for i, location in ipairs(Config.Locations) do
                if spawnedLocations[i] and #spawnedLocations[i] > 0 then
                    RemoveNPCsFromLocation(i)
                end
            end
        end
        
        Citizen.Wait(Config.SpawnSettings.checkInterval)
    end
end)

function SpawnNPCsForLocation(location, locationIndex)
    if Config.Debug then
        print("[DayShift] Spawning NPCs at: " .. location.name)
    end
    
    spawnedLocations[locationIndex] = {}
    
    local maxNPCs = math.min(Config.SpawnSettings.maxNPCsPerLocation, #location.npcPositions)
    
    for i = 1, maxNPCs do
        local destinationPos = location.npcPositions[i]
        local spawnPos = location.coords
        local model = Config.NPCModels[math.random(#Config.NPCModels)]
        
        local npc = CreateNPC(model, spawnPos, destinationPos, locationIndex, i)
        if npc then
            table.insert(spawnedLocations[locationIndex], npc)
        end
        
        Citizen.Wait(Config.SpawnSettings.walkInDelay)
    end
end

function CreateNPC(model, spawnPos, destinationPos, locationIndex, index)
    if not IsModelInCdimage(model) then
        if Config.Debug then
            print("[DayShift] Model not found: " .. model)
        end
        return nil
    end
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(model) then
        if Config.Debug then
            print("[DayShift] Model failed to load: " .. model)
        end
        return nil
    end
    
    local ped = CreatePed(model, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, false, false, false, false)
    
    if ped and ped ~= 0 then
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)
        SetPedCanBeTargetted(ped, false)
		Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
        
        TaskGoToCoordAnyMeans(ped, destinationPos.x, destinationPos.y, destinationPos.z, 1.0, 0, false, 786603, 0)
        
        local pedToWatch = ped
        local targetHeading = destinationPos.heading
        local destX, destY, destZ = destinationPos.x, destinationPos.y, destinationPos.z
        
        Citizen.CreateThread(function()
            while DoesEntityExist(pedToWatch) do
                local coords = GetEntityCoords(pedToWatch)
                local distance = #(coords - vector3(destX, destY, destZ))
                
                if distance < 1.5 then
                    SetEntityHeading(pedToWatch, targetHeading)
                    TaskStandStill(pedToWatch, -1)
                    
                    if Config.Debug then
                        print("[DayShift] NPC arrived, heading set to: " .. targetHeading)
                    end
                    break
                end
                
                Citizen.Wait(500)
            end
        end)
        
        if Config.Debug then
            print("[DayShift] NPC spawned, walking to destination")
        end
        
        SetModelAsNoLongerNeeded(model)
        
        return { 
            ped = ped, 
            locationIndex = locationIndex, 
            index = index,
            exitPos = spawnPos
        }
    end
    
    SetModelAsNoLongerNeeded(model)
    return nil
end

function RemoveNPCsFromLocation(locationIndex)
    if not spawnedLocations[locationIndex] then return end
    
    if Config.Debug then
        print("[DayShift] Removing NPCs from location index: " .. locationIndex)
    end
    
    for _, npcData in ipairs(spawnedLocations[locationIndex]) do
        if DoesEntityExist(npcData.ped) then
            local exitPos = npcData.exitPos
            TaskGoToCoordAnyMeans(npcData.ped, exitPos.x, exitPos.y, exitPos.z, 1.0, 0, false, 786603, 0)
            
            local pedToDelete = npcData.ped
            local exitX, exitY, exitZ = exitPos.x, exitPos.y, exitPos.z
            
            Citizen.CreateThread(function()
                local maxWaitTime = 60000
                local waited = 0
                
                while DoesEntityExist(pedToDelete) and waited < maxWaitTime do
                    local coords = GetEntityCoords(pedToDelete)
                    local distance = #(coords - vector3(exitX, exitY, exitZ))
                    
                    if distance < 2.0 then
                        if Config.Debug then
                            print("[DayShift] NPC reached exit, deleting")
                        end
                        DeleteEntity(pedToDelete)
                        break
                    end
                    
                    Citizen.Wait(500)
                    waited = waited + 500
                end
                
                if DoesEntityExist(pedToDelete) then
                    if Config.Debug then
                        print("[DayShift] NPC timeout, force deleting")
                    end
                    DeleteEntity(pedToDelete)
                end
            end)
        end
    end
    
    spawnedLocations[locationIndex] = {}
end

if Config.Debug then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000)
            local hour = GetClockHours()
            local isDay = (hour >= Config.Schedule.dayStartHour and hour < Config.Schedule.nightStartHour)
            local npcCount = 0
            for _, loc in pairs(spawnedLocations) do
                npcCount = npcCount + #loc
            end
            print("[DayShift] Time: " .. hour .. ":00 - " .. (isDay and "DAY" or "NIGHT") .. " | NPCs: " .. npcCount)
        end
    end)
end

-- Export for other resources
function GetDayShiftLocations()
    return Config.Locations
end

-- Command to manually cleanup (admin use)
RegisterCommand('dayshiftcleanup', function()
    CleanupAllNPCs()
    print("[DayShift] Manual cleanup executed")
end, false)
