Config = {}

Config.Locations = {
    {
        name = "Valentine Saloon",
        coords = vector3(-300.54, 777.18, 118.78),
        npcPositions = {
            { x = -313.37, y = 806.02, z = 118.98, heading = 300.69 },
           
        }
    },
	{
        name = "Valentine Store",
        coords = vector3(-328.64, 814.97, 117.4),
        npcPositions = {
            { x = -324.14, y = 803.61, z = 117.88, heading = 300.69 },
           
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
	`cs_fishcollector`,
	
    
    
}

Config.Schedule = {
    enabled = true,
    dayStartHour = 6,           -- NPCs spawn (6 AM)
    nightStartHour = 23,        -- NPCs leave (11 PM)
}

Config.Debug = false  
