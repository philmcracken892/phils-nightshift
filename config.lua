Config = {}

Config.Locations = {
    {
        name = "Valentine Saloon",
        coords = vector3(-300.54, 777.18, 118.78),
        npcPositions = {
            { pos = vector3(-313.37, 806.02, 118.98), heading = 300.69, model = `mes_marston1_males_01` },
        }
    },
    {
        name = "Valentine Store",
        coords = vector3(-328.64, 814.97, 117.4),
        npcPositions = {
            { pos = vector3(-324.14, 803.61, 117.88), heading = 300.69, model = `cs_fishcollector` },
        }
    },
    {
        name = "Valentine gun Store",
        coords = vector3(-251.97, 803.56, 120.58),
        npcPositions = {
            { pos = vector3(-282.0, 778.92, 119.5), heading = 180.0, model = `A_M_M_RANCHER_01` },
        }
    },
    {
        name = "Blackwater Store",
        coords = vector3(-772.4, -1325.63, 43.62),
        npcPositions = {
            { pos = vector3(-785.17, -1322.24, 43.88), heading = 180.0, model = `mes_marston1_males_01` },
        }
    },
	{
        name = "Blackwater SALOON",
        coords = vector3(-773.13, -1313.88, 43.66),
        npcPositions = {
            { pos = vector3(-817.6, -1319.01, 43.68), heading = 300.0, model = `mes_marston1_males_01` },
        }
    },
}

Config.SpawnSettings = {
    enabled = true,
    checkInterval = 15000,
    maxNPCsPerLocation = 1,
    walkInDelay = 2000,
}

Config.NPCModels = {
    `cs_fishcollector`,
    `mes_marston1_males_01`,
    `A_M_M_RANCHER_01`,
}

Config.Schedule = {
    enabled = true,
    dayStartHour = 6,
    nightStartHour = 23,
}

Config.Debug = false