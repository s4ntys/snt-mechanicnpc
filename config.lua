Config = {}

-- Konfigurácia notifikácií, target systému a debugu
Config.UseLBPhone = false -- true = používať LB-phone notifikácie, false = používať štandardné notifikácie
Config.UseJPRPhone = true
Config.NotifyType = 'qbcore' -- Možnosti: 'esx', 'qbcore', 'ox_lib'
Config.TargetSystem = 'qb_target' -- Možnosti: 'qb_target', 'ox_target'
Config.DebugMode = true -- true = zapnúť debug správy, false = vypnúť debug správy

-- Lokality mechanických dielní (target pre začatie práce)
Config.JobStations = {
    {job = "bennys", coords = vector3(-194.05, -1332.37, 35.64)},
    -- {job = "lsc", coords = vector3(-345.85125732422, -130.42454528809, 38.909900665283)},
    --- dalsia joba s coordom
}

-- Miesta, kde sa spawnujú NPC a autá
Config.RepairLocations = {
    {
        npc = vector4(-633.6788, -1785.8456, 24.1661, 155.4270), 
        vehicle = vector4(-635.9504, -1780.2073, 23.4994, 122.1630)
    },
    {
        npc = vector4(-1461.1730, -927.8550, 10.0463, 257.3221), 
        vehicle = vector4(-1467.3164, -926.5490, 9.4302, 317.4957)
    },
    {
        npc = vector4(-401.5338, 826.0215, 224.5145, 270.1230), 
        vehicle = vector4(-403.8692, 825.1840, 223.9570, 192.1583)
    },
    {
        npc = vector4(811.2355, 1360.2556, 348.1892, 336.9673), 
        vehicle = vector4(816.2474, 1356.8779, 348.2383, 246.7235)
    },
    {
        npc = vector4(-527.3442, 924.2172, 243.1688, 141.7232), 
        vehicle = vector4(-527.7617, 926.7904, 242.5349, 54.1713)
    },
    {
        npc = vector4(-803.6945, 1838.0813, 165.7996, 151.7997), 
        vehicle = vector4(-800.4085, 1837.8849, 165.2579, 127.6450)
    },
    {
        npc = vector4(-2289.2146, 408.7314, 174.4666, 143.0187), 
        vehicle = vector4(-2289.4775, 412.1877, 173.8396, 144.6588)
    },
    {
        npc = vector4(-3077.4438, 373.6778, 7.1272, 259.0742), 
        vehicle = vector4(-3079.9187, 370.9223, 6.4986, 256.2986)
    },
    {
        npc = vector4(-1609.4492, -896.2398, 9.2154, 238.4938), 
        vehicle = vector4(-1611.8127, -897.2184, 8.5267, 198.8556)
    },
    {
        npc = vector4(-825.3499, -1130.0208, 8.2549, 257.4280), 
        vehicle = vector4(-828.9808, -1131.2736, 7.3471, 211.3227)
    },
    {
        npc = vector4(-629.5814, -1646.8259, 25.8251, 52.5709), 
        vehicle = vector4(-626.2790, -1645.8372, 25.1980, 55.6760)
    },
    {
        npc = vector4(-466.0644, -2782.0659, 6.0004, 245.1490), 
        vehicle = vector4(-463.2254, -2777.6489, 5.3733, 134.4175)
    },
    {
        npc = vector4(-632.8638, -2206.4690, 5.9973, 135.7045), 
        vehicle = vector4(-631.4832, -2204.1033, 5.3693, 49.6576)
    },
    {
        npc = vector4(1091.3379, -2287.6028, 30.1427, 287.8068), 
        vehicle = vector4(1088.4576, -2289.7590, 29.5499, 267.8747)
    },
    {
        npc = vector4(1035.3918, -2268.2073, 30.5935, 264.2001), 
        vehicle = vector4(1032.5350, -2270.4661, 29.8796, 265.2300)
    },
    {
        npc = vector4(920.5221, -2143.4436, 30.3777, 239.5745), 
        vehicle = vector4(921.3622, -2138.8550, 29.7516, 178.0925)
    },
    {
        npc = vector4(784.2034, -2194.4131, 29.3138, 356.5862), 
        vehicle = vector4(788.6896, -2191.1724, 28.8772, 82.6578)
    },
    {
        npc = vector4(449.1811, -11.8074, 81.8073, 247.2062), 
        vehicle = vector4(446.8651, -12.3128, 81.1289, 183.3889)
    },
    {
        npc = vector4(490.4432, -74.7567, 77.6507, 3.8163), 
        vehicle = vector4(491.5912, -77.4701, 77.0545, 336.1782)
    },
    {
        npc = vector4(340.6835, -192.7955, 57.1593, 344.4661), 
        vehicle = vector4(337.7152, -190.1331, 56.6664, 248.0437)
    },
    {
        npc = vector4(-178.6243, -165.1646, 44.0323, 164.2773), 
        vehicle = vector4(-185.4191, -163.1507, 42.9952, 159.4436)
    },
    {
        npc = vector4(-159.0419, -153.6003, 43.6212, 162.0676), 
        vehicle = vector4(-159.0199, -156.7957, 42.9943, 69.1660)
    },
    {
        npc = vector4(912.2028, -18.9379, 78.7641, 155.9210), 
        vehicle = vector4(912.3598, -15.7175, 78.1369, 149.6195)
    },
    {
        npc = vector4(1217.0270, -517.0109, 66.1905, 215.1630), 
        vehicle = vector4(1220.7902, -519.4161, 65.8509, 54.1405)
    },
    {
        npc = vector4(930.2048, -571.3410, 57.8489, 210.3479), 
        vehicle = vector4(924.7961, -564.2264, 57.3405, 206.7410)
    },
    {
        npc = vector4(908.2645, -617.8557, 58.0490, 226.2715), 
        vehicle = vector4(916.1882, -629.3868, 57.4221, 319.2509)
    },
    {
        npc = vector4(-853.0128, 695.3911, 148.7929, 4.3682), 
        vehicle = vector4(-863.2054, 699.2455, 148.4065, 325.9598)
    },
}

Config.NPCModels = {
    "a_m_m_business_01",
}

-- Vozidlá, ktoré sa môžu spawnovať
Config.RepairableVehicles = {
    -- Bežné autá
    "blista", "buffalo", "sultan", "tornado", "futo", "banshee", "comet2", "schafter2", "dominator", "yosemite3", "cypher", "komoda", "kuruma",
}

-- Výška odmeny
Config.RewardFixOnSite = {100, 180}  -- Oprava na mieste