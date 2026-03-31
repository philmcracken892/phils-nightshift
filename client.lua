local spawnedLocations = {}

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupAllNPCs()
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupAllNPCs()
    end
end)

function CleanupAllNPCs()
    if Config.Debug then
        print("[NightShift] Cleaning up all NPCs...")
    end
    
    for locationIndex, npcs in pairs(spawnedLocations) do
        for _, npcData in ipairs(npcs) do
            if DoesEntityExist(npcData.ped) then
                DeleteEntity(npcData.ped)
            end
        end
    end
    
    spawnedLocations = {}
end

function GetNPCModel(location, npcPosition)
    if npcPosition.model then
        return npcPosition.model
    end
    
    if location.useRandomModels then
        return Config.NPCModels[math.random(#Config.NPCModels)]
    end
    
    return Config.NPCModels[math.random(#Config.NPCModels)]
end

local serverState = nil

RegisterNetEvent('phils-nightshift:setState', function(state, config)
    serverState = state
    Config = config
    
    if Config.Debug then
        print("[NightShift] Received state: " .. state)
    end
    
    ProcessNPCs()
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    TriggerServerEvent('phils-nightshift:requestState')
end)

function ProcessNPCs()
    if not serverState or not Config then return end
    
    local isDay = (serverState == "day")
    
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
end

function SpawnNPCsForLocation(location, locationIndex)
    if Config.Debug then
        print("[NightShift] Spawning NPCs at: " .. location.name)
    end
    
    spawnedLocations[locationIndex] = {}
    
    local maxNPCs = math.min(Config.SpawnSettings.maxNPCsPerLocation, #location.npcPositions)
    
    for i = 1, maxNPCs do
        local destinationPos = location.npcPositions[i]
        local spawnPos = location.coords
        local model = GetNPCModel(location, destinationPos)
        
        local npc = CreateNPC(model, spawnPos, destinationPos, locationIndex, i)
        if npc then
            table.insert(spawnedLocations[locationIndex], npc)
        end
        
        Citizen.Wait(Config.SpawnSettings.walkInDelay)
    end
end

function CreateNPC(model, spawnPos, destinationPos, locationIndex, index)
    if not IsModelInCdimage(model) then
        return nil
    end
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(model) then
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
        
        local destPos = destinationPos.pos
        TaskGoToCoordAnyMeans(ped, destPos.x, destPos.y, destPos.z, 1.0, 0, false, 786603, 0)
        
        local pedToWatch = ped
        local targetHeading = destinationPos.heading
        
        Citizen.CreateThread(function()
            local maxWaitTime = 60000
            local waited = 0
            
            while DoesEntityExist(pedToWatch) and waited < maxWaitTime do
                local coords = GetEntityCoords(pedToWatch)
                local distance = #(coords - destPos)
                
                if distance < 2.0 then
                    ClearPedTasks(pedToWatch)
                    Citizen.Wait(500)
                    
                    SetEntityHeading(pedToWatch, targetHeading)
                    Citizen.Wait(100)
                    SetEntityHeading(pedToWatch, targetHeading)
                    
                    TaskStandStill(pedToWatch, -1)
                    
                    FreezeEntityPosition(pedToWatch, true)
                    Citizen.Wait(500)
                    FreezeEntityPosition(pedToWatch, false)
                    
                    SetEntityHeading(pedToWatch, targetHeading)
                    TaskStandStill(pedToWatch, -1)
                    
                    break
                end
                
                Citizen.Wait(500)
                waited = waited + 500
            end
            
            if DoesEntityExist(pedToWatch) and waited >= maxWaitTime then
                SetEntityCoords(pedToWatch, destPos.x, destPos.y, destPos.z, false, false, false, false)
                SetEntityHeading(pedToWatch, targetHeading)
                TaskStandStill(pedToWatch, -1)
            end
        end)
        
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
    
    for _, npcData in ipairs(spawnedLocations[locationIndex]) do
        if DoesEntityExist(npcData.ped) then
            FreezeEntityPosition(npcData.ped, false)
            ClearPedTasks(npcData.ped)
            
            local exitPos = npcData.exitPos
            TaskGoToCoordAnyMeans(npcData.ped, exitPos.x, exitPos.y, exitPos.z, 1.0, 0, false, 786603, 0)
            
            local pedToDelete = npcData.ped
            
            Citizen.CreateThread(function()
                local maxWaitTime = 60000
                local waited = 0
                
                while DoesEntityExist(pedToDelete) and waited < maxWaitTime do
                    local coords = GetEntityCoords(pedToDelete)
                    local distance = #(coords - exitPos)
                    
                    if distance < 2.0 then
                        DeleteEntity(pedToDelete)
                        break
                    end
                    
                    Citizen.Wait(500)
                    waited = waited + 500
                end
                
                if DoesEntityExist(pedToDelete) then
                    DeleteEntity(pedToDelete)
                end
            end)
        end
    end
    
    spawnedLocations[locationIndex] = {}
end

RegisterCommand('dayshiftcleanup', function()
    CleanupAllNPCs()
    print("[NightShift] Manual cleanup executed")
end, false)