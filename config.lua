Config = {}

Config.Locations = {
    {
        name = "Valentine Saloon",
        coords = vector3(-300.54, 777.18, 118.78),
        npcPositions = {
            { x = -313.37, y = 806.02, z = 118.98, heading = 300.69 },
           
        }
    },
}

Config.SpawnSettings = {
    enabled = true,
    checkInterval = 15000,
    maxNPCsPerLocation = 1,
    walkInDelay = 2000,
    removeDelay = 60000 --- 60 seconds
}

Config.NPCModels = {
    `A_M_M_RANCHER_01`,
    
    
}

Config.Schedule = {
    enabled = true,
    nightStartHour = 18,
    dayStartHour = 6,
}

Config.Debug = false  