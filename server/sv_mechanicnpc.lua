-- Inicializácia frameworku
local Framework = nil
local ESX, QBCore
if GetResourceState('es_extended') == 'started' then
    Framework = 'ESX'
    ESX = exports["es_extended"]:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    Framework = 'QBCore'
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Funkcia na odoslanie notifikácií na serveri
local function SendNotify(src, message, type, duration)
    if Config.DebugMode then
        print(string.format("[DEBUG] Server notifikácia pre hráča %d: %s, Typ: %s, Dĺžka: %d", src, message, type, duration))
    end

    if Config.NotifyType == 'ox_lib' then
        TriggerClientEvent('ox_lib:notify', src, { type = type, description = message, duration = duration })
    elseif Config.NotifyType == 'esx' and Framework == 'ESX' then
        TriggerClientEvent('esx:showNotification', src, message)
    elseif Config.NotifyType == 'qbcore' and Framework == 'QBCore' then
        TriggerClientEvent('QBCore:Notify', src, message, type, duration)
    else
        -- Fallback na OX_lib
        TriggerClientEvent('ox_lib:notify', src, { type = type, description = message, duration = duration })
    end
end

RegisterNetEvent('mechanic:reward', function(amount)
    local src = source
    local xPlayer, qbPlayer

    if Framework == 'ESX' then
        xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
    elseif Framework == 'QBCore' then
        qbPlayer = QBCore.Functions.GetPlayer(src)
        if not qbPlayer then return end
    end

    -- ✅ Overenie, či hráč má mechanický job
    local allowedJobs = { "bennys", "lsc" } -- Tu pridaj joby, ktoré môžu dostávať peniaze
    local playerJob

    if Framework == 'ESX' then
        playerJob = xPlayer.getJob().name
    elseif Framework == 'QBCore' then
        playerJob = qbPlayer.PlayerData.job.name
    end

    local isAllowed = false
    for _, job in ipairs(allowedJobs) do
        if playerJob == job then
            isAllowed = true
            break
        end
    end

    if not isAllowed then
        if Config.DebugMode then
            print(string.format("🚨 [MECHANIC JOB] Hráč (%d) sa pokúsil dostať peniaze, ale nemá mechanický job (%s)!", src, playerJob))
        end
        return
    end

    -- ✅ Overenie, či amount je číslo a v rozumnom rozmedzí
    if type(amount) ~= "number" or amount < 10 or amount > 5000 then
        if Config.DebugMode then
            print(string.format("🚨 [MECHANIC JOB] Hráč (%d) sa pokúsil získať neplatnú sumu: $%d", src, amount))
        end
        return
    end

    -- ✅ Pridanie peňazí hráčovi
    if Framework == 'ESX' then
        xPlayer.addMoney(amount)
    elseif Framework == 'QBCore' then
        qbPlayer.Functions.AddMoney('cash', amount)
    end

    SendNotify(src, 'Získal si $'..amount, 'success', 5000)
    if Config.DebugMode then
        print(string.format("✅ [MECHANIC JOB] Hráč (%d) získal $%d", src, amount))
    end
end)

RegisterNetEvent('mechanic:spawnMissionNPC', function(npcCoords, vehicleCoords, vehicleModel)
    local src = source
    local xPlayer, qbPlayer

    if Framework == 'ESX' then
        xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
    elseif Framework == 'QBCore' then
        qbPlayer = QBCore.Functions.GetPlayer(src)
        if not qbPlayer then return end
    end

    -- ✅ Kontrola, či hráč má mechanický job
    local allowedJobs = { "bennys", "lsc" }
    local playerJob

    if Framework == 'ESX' then
        playerJob = xPlayer.getJob().name
    elseif Framework == 'QBCore' then
        playerJob = qbPlayer.PlayerData.job.name
    end

    local isAllowed = false
    for _, job in ipairs(allowedJobs) do
        if playerJob == job then
            isAllowed = true
            break
        end
    end

    if not isAllowed then
        if Config.DebugMode then
            print(string.format("🚨 [MECHANIC JOB] Hráč (%d) sa pokúsil spustiť misiu, ale nemá mechanický job (%s)!", src, playerJob))
        end
        return
    end

    if Config.DebugMode then
        print(string.format("DEBUG: Posielam klientovi informácie na spawn NPC a vozidla hráčovi (%d).", src))
    end
    TriggerClientEvent('mechanic:clientSpawnMission', src, npcCoords, vehicleCoords, vehicleModel)
end)