-- Inicializácia frameworku
local Framework = nil
if GetResourceState('es_extended') == 'started' then
    Framework = 'ESX'
    ESX = exports["es_extended"]:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    Framework = 'QBCore'
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Kontrola, či je ox_lib dostupný
local oxLibAvailable = GetResourceState('ox_lib') == 'started'
local jprPhoneAvailable = GetResourceState('jpr-phonesystem') == 'started'

local missionActive = false
local missionCooldown = false
local carInspected = false
local carRepaired = false
local missionCompleted = false
local currentNPC, currentVehicle, missionBlip
local targetZones = {}

-- Funkcia na odoslanie notifikácií
local function SendNotify(message, type, duration)
    if Config.DebugMode then
        print(string.format("[DEBUG] Notifikácia: %s, Typ: %s, Dĺžka: %d", message, type, duration))
    end

    if oxLibAvailable and Config.NotifyType == 'ox_lib' then
        lib.notify({ description = message, type = type, duration = duration })
    elseif Config.NotifyType == 'esx' and Framework == 'ESX' then
        ESX.ShowNotification(message)
    elseif Config.NotifyType == 'qbcore' and Framework == 'QBCore' then
        QBCore.Functions.Notify(message, type, duration)
    else
        -- Fallback na print, ak nie je ox_lib dostupný
        print(string.format("[NOTIFY] %s", message))
    end
end

-- Funkcia na odoslanie e-mailu cez jpr-phonesystem
local function SendJPREmail(subject, message)
    if Config.DebugMode then
        print(string.format("[DEBUG] Odosielam JPR e-mail: Predmet: %s, Správa: %s", subject, message))
    end

    TriggerServerEvent('jpr-phonesystem:server:sendEmail', {
        subject = subject,
        message = message,
        sender = "zakaznik.kokoska@rpcko.com",
        event = {},
    })
end

-- Funkcia na odstránenie všetkých target zón
local function RemoveAllTargetZones()
    for zoneName, _ in pairs(targetZones) do
        if Config.TargetSystem == 'qb_target' then
            exports['qb-target']:RemoveZone(zoneName)
        elseif Config.TargetSystem == 'ox_target' then
            exports.ox_target:removeZone(zoneName)
            if zoneName:find('npc_') and DoesEntityExist(currentNPC) then
                exports.ox_target:removeLocalEntity(currentNPC, zoneName)
            end
        end
        targetZones[zoneName] = nil
    end
    if Config.DebugMode then
        print("[DEBUG] Všetky target zóny odstránené")
    end
end

-- Funkcia na aktualizáciu interakcie
function UpdateJobInteraction()
    if not Config.JobStations or #Config.JobStations == 0 then
        if Config.DebugMode then
            print("[DEBUG] Žiadne JobStations definované v Config")
        end
        return
    end

    for _, station in ipairs(Config.JobStations) do
        if not station.coords then
            if Config.DebugMode then
                print("[DEBUG] Neplatné súradnice pre JobStation")
            end
            goto continue
        end

        local zoneName = 'start_job_' .. tostring(station.coords)
        if targetZones[zoneName] then
            if Config.TargetSystem == 'qb_target' then
                exports['qb-target']:RemoveZone(zoneName)
            elseif Config.TargetSystem == 'ox_target' then
                exports.ox_target:removeZone(zoneName)
            end
            targetZones[zoneName] = nil
        end

        if Config.TargetSystem == 'qb_target' then
            exports['qb-target']:AddCircleZone(zoneName, station.coords, 2.0, {
                name = zoneName,
                debugPoly = Config.DebugMode,
                useZ = true,
            }, {
                options = {
                    {
                        label = missionActive and 'Ukončit brigádu' or 'Začít brigádu',
                        event = missionActive and 'mechanic:endJob' or 'mechanic:startJob',
                        canInteract = function() return not missionCooldown end
                    }
                },
                distance = 2.0
            })
        elseif Config.TargetSystem == 'ox_target' then
            exports.ox_target:addSphereZone({
                coords = station.coords,
                radius = 2.0,
                debug = Config.DebugMode,
                name = zoneName,
                options = {
                    {
                        label = missionActive and 'Ukončit brigádu' or 'Začít brigádu',
                        event = missionActive and 'mechanic:endJob' or 'mechanic:startJob',
                        canInteract = function() return not missionCooldown end
                    }
                }
            })
        end
        targetZones[zoneName] = true
        if Config.DebugMode then
            print(string.format("[DEBUG] Pridaná target zóna: %s", zoneName))
        end
        ::continue::
    end
end

-- Inicializácia interakcie pri štarte
CreateThread(function()
    if not Config then
        print("[ERROR] Config.lua nebol načítaný!")
        return
    end
    UpdateJobInteraction()
end)

function IsPlayerAllowedToWork()
    if Framework == 'ESX' then
        local PlayerData = ESX.GetPlayerData()
        if not PlayerData or not PlayerData.job then
            if Config.DebugMode then
                print("[DEBUG] Hráč nemá platné PlayerData alebo job")
            end
            return false
        end
        for _, station in ipairs(Config.JobStations) do
            if PlayerData.job.name == station.job then
                return true
            end
        end
    elseif Framework == 'QBCore' then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if not PlayerData or not PlayerData.job then
            if Config.DebugMode then
                print("[DEBUG] Hráč nemá platné PlayerData alebo job")
            end
            return false
        end
        for _, station in ipairs(Config.JobStations) do
            if PlayerData.job.name == station.job then
                return true
            end
        end
    end
    return false
end

-- Začatie brigády
RegisterNetEvent('mechanic:startJob', function()
    if not IsPlayerAllowedToWork() then
        SendNotify("❌ Nemáš správnu prácu na vykonanie tejto brigády!", "error", 5000)
        return
    end

    if missionActive or missionCooldown then
        SendNotify("Už máš aktivní brigádu nebo počkej na ukončení!", "error", 5000)
        return
    end

    missionCooldown = true
    missionActive = true
    UpdateJobInteraction()

    SendNotify("Brigáda začala. Čekej na zákazku!", "info", 5000)

    local delay = math.random(5000, 30000)
    Wait(delay)

    if not missionActive then
        missionCooldown = false
        return
    end

    StartMechanicJob()
    missionCooldown = false
end)

-- Ukončenie brigády
RegisterNetEvent('mechanic:endJob', function()
    if not missionActive or missionCooldown then return end

    missionCooldown = true
    missionActive = false
    UpdateJobInteraction()

    SendNotify("Brigáda byla ukončena.", "error", 5000)

    if DoesBlipExist(missionBlip) then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
    if DoesEntityExist(currentNPC) then
        DeleteEntity(currentNPC)
        currentNPC = nil
    end
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
    end
    RemoveAllTargetZones()

    carInspected = false
    carRepaired = false
    missionCompleted = false

    Wait(200)
    missionCooldown = false
end)

-- Funkcia na spustenie brigády po oneskorení
function StartMechanicJob()
    if #Config.RepairLocations == 0 or #Config.RepairableVehicles == 0 then
        SendNotify("❌ Chyba: Žiadne lokácie alebo vozidlá definované!", "error", 5000)
        if Config.DebugMode then
            print("[DEBUG] RepairLocations alebo RepairableVehicles sú prázdne")
        end
        missionActive = false
        missionCooldown = false
        UpdateJobInteraction()
        return
    end

    local playerPed = PlayerPedId()
    local isInVehicle = IsPedInAnyVehicle(playerPed, false)

    -- Odoslanie správy
    if Config.UseJPRPhone and jprPhoneAvailable then
        SendJPREmail("Zakázka od zákazníka", "Zákazník potřebuje opravit auto. Máš nastavenou lokaci na GPS, zkontroluj co je za problém a vyřeš ho prosím.")
    elseif Config.UseLBPhone and GetResourceState('lb-phone') == 'started' then
        exports["lb-phone"]:SendNotification({
            app = "Mail",
            title = "Zakazník",
            avatar = "https://cdn.discordapp.com/attachments/1234847902887579688/1340832353487949927/latest.png?ex=67b3caf0&is=67b27970&hm=ff3fc5e4a3fb34740fb62694e5e62921fdabc3d56c33de1d67569a5af0f64f97&",
            thumbnail = "https://media.discordapp.net/attachments/1234847902887579688/1340832617762656256/image.png?ex=67b3cb2f&is=67b279af&hm=8524d781efae32e0813f3436c61f9665bb5e34ed187995de9059fa1c48ccbb25&=&format=webp&quality=lossless",
            showAvatar = true,
            content = "Zákazník potřebuje opravit auto. Máš nastavenou lokaci na GPS, zkontroluj co je za problém a vyřeš ho prosím.",
        })
    else
        SendNotify("Zákazník potřebuje opravit auto. Máš nastavenou lokaci na GPS!", "info", 5000)
    end

    if isInVehicle then
        SendNotify("Dostal jsi zakázku. Podívej se na mapu!", "info", 5000)
        local missionSpot = Config.RepairLocations[math.random(#Config.RepairLocations)]
        local vehicleModel = Config.RepairableVehicles[math.random(#Config.RepairableVehicles)]
        TriggerServerEvent('mechanic:spawnMissionNPC', missionSpot.npc, missionSpot.vehicle, vehicleModel)
        missionBlip = AddBlipForCoord(missionSpot.npc.x, missionSpot.npc.y, missionSpot.npc.z)
        SetBlipSprite(missionBlip, 402)
        SetBlipColour(missionBlip, 1)
        SetBlipRoute(missionBlip, true)
        return
    end

    local animDict, animName = "friends@frl@ig_1", "phone_lamar"
    local propDict, propAnim = "friends@frl@ig_1", "phone_phone"
    local propModel = GetHashKey("ba_prop_battle_amb_phone")

    RequestAnimDict(animDict)
    RequestModel(propModel)
    while not HasAnimDictLoaded(animDict) or not HasModelLoaded(propModel) do
        Wait(10)
    end

    local scenePos = GetEntityCoords(playerPed)
    local sceneRot = vector3(0.0, 0.0, GetEntityHeading(playerPed))
    local netScene = NetworkCreateSynchronisedScene(scenePos, sceneRot, 2, false, false, 1065353216, 0, 1.3)
    local phoneProp = CreateObject(propModel, scenePos, true, true, false)
    NetworkAddPedToSynchronisedScene(playerPed, netScene, animDict, animName, 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(phoneProp, netScene, propDict, propAnim, 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(netScene)

    Wait(7000)
    NetworkStopSynchronisedScene(netScene)
    DeleteObject(phoneProp)
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(propModel)

    local missionSpot = Config.RepairLocations[math.random(#Config.RepairLocations)]
    local vehicleModel = Config.RepairableVehicles[math.random(#Config.RepairableVehicles)]
    TriggerServerEvent('mechanic:spawnMissionNPC', missionSpot.npc, missionSpot.vehicle, vehicleModel)
    missionBlip = AddBlipForCoord(missionSpot.npc.x, missionSpot.npc.y, missionSpot.npc.z)
    SetBlipSprite(missionBlip, 402)
    SetBlipColour(missionBlip, 1)
    SetBlipRoute(missionBlip, true)
end

-- Spawnovanie NPC a auta
RegisterNetEvent('mechanic:clientSpawnMission', function(npcCoords, vehicleCoords, vehicleModel)
    if not Config.NPCModels or #Config.NPCModels == 0 then
        SendNotify("❌ Chyba: Žiadne modely NPC definované!", "error", 5000)
        if Config.DebugMode then
            print("[DEBUG] NPCModels je prázdny")
        end
        return
    end

    local npcModel = Config.NPCModels[math.random(#Config.NPCModels)]
    local vehicleHash = GetHashKey(vehicleModel)

    RequestModel(GetHashKey(npcModel))
    RequestModel(vehicleHash)
    while not HasModelLoaded(GetHashKey(npcModel)) or not HasModelLoaded(vehicleHash) do Wait(10) end

    currentNPC = CreatePed(4, GetHashKey(npcModel), npcCoords.x, npcCoords.y, npcCoords.z - 1, npcCoords.w, true, true)
    if not DoesEntityExist(currentNPC) then
        SendNotify("❌ Chyba: Nepodarilo sa vytvoriť NPC!", "error", 5000)
        if Config.DebugMode then
            print(string.format("[DEBUG] Zlyhalo vytvorenie NPC s modelom %s na %s", npcModel, json.encode(npcCoords)))
        end
        SetModelAsNoLongerNeeded(GetHashKey(npcModel))
        SetModelAsNoLongerNeeded(vehicleHash)
        return
    end

    SetBlockingOfNonTemporaryEvents(currentNPC, true)
    TaskStartScenarioInPlace(currentNPC, "WORLD_HUMAN_SMOKING", 0, true)
    FreezeEntityPosition(currentNPC, true)
    SetEntityAsMissionEntity(currentNPC, true, true)

    currentVehicle = CreateVehicle(vehicleHash, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleCoords.w, true, false)
    if not DoesEntityExist(currentVehicle) then
        SendNotify("❌ Chyba: Nepodarilo sa vytvoriť vozidlo!", "error", 5000)
        if Config.DebugMode then
            print(string.format("[DEBUG] Zlyhalo vytvorenie vozidla %s na %s", vehicleModel, json.encode(vehicleCoords)))
        end
        if DoesEntityExist(currentNPC) then
            DeleteEntity(currentNPC)
            currentNPC = nil
        end
        SetModelAsNoLongerNeeded(GetHashKey(npcModel))
        SetModelAsNoLongerNeeded(vehicleHash)
        return
    end

    SetVehicleEngineHealth(currentVehicle, math.random(200, 500))
    SetVehicleBodyHealth(currentVehicle, math.random(200, 500))
    SetVehicleDoorOpen(currentVehicle, 4, false, true)
    SetEntityAsMissionEntity(currentVehicle, true, true)

    local npcZoneName = 'npc_talk_' .. tostring(NetworkGetNetworkIdFromEntity(currentNPC))
    if Config.TargetSystem == 'qb_target' then
        exports['qb-target']:AddEntityZone(npcZoneName, currentNPC, {
            name = npcZoneName,
            debugPoly = Config.DebugMode,
            useZ = true,
        }, {
            options = {
                {
                    label = 'Promluvit si se zákazníkem',
                    event = 'mechanic:talkToNPC'
                }
            },
            distance = 4.0
        })
    elseif Config.TargetSystem == 'ox_target' then
        exports.ox_target:addLocalEntity(currentNPC, {
            name = npcZoneName,
            label = 'Promluvit si se zákazníkem',
            event = 'mechanic:talkToNPC',
            distance = 4.0,
            debug = Config.DebugMode
        })
    end
    targetZones[npcZoneName] = true

    SetModelAsNoLongerNeeded(GetHashKey(npcModel))
    SetModelAsNoLongerNeeded(vehicleHash)

    if Config.DebugMode then
        print(string.format("[DEBUG] NPC spawnuté na %s, vozidlo %s na %s", json.encode(npcCoords), vehicleModel, json.encode(vehicleCoords)))
    end
end)

RegisterNetEvent('mechanic:talkToNPC', function()
    CreateThread(function()
        if not oxLibAvailable then
            SendNotify("❌ Chyba: ox_lib nie je dostupný!", "error", 5000)
            return
        end

        local response = lib.alertDialog({
            header = '📩 Nová zakázka',
            content = 'Zákazníkovi se z motoru valí hustý dým, potřebuje nutně opravu. Chceš se na to podívat? Zkontroluj auto a oprav vady',
            cancel = false,
            labels = {confirm = "Jdu na to"}
        })

        if response then
            local npcZoneName = 'npc_talk_' .. tostring(NetworkGetNetworkIdFromEntity(currentNPC))
            if Config.TargetSystem == 'qb_target' then
                exports['qb-target']:RemoveZone(npcZoneName)
            elseif Config.TargetSystem == 'ox_target' then
                exports.ox_target:removeLocalEntity(currentNPC, npcZoneName)
            end
            targetZones[npcZoneName] = nil

            SendNotify("Rozhovor ukončen. Zkontroluj vozidlo!", "info", 5000)

            local inspectCoords = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.0, 2.0, 0.3)
            local inspectZoneName = 'inspect_vehicle_' .. tostring(NetworkGetNetworkIdFromEntity(currentVehicle))
            if Config.TargetSystem == 'qb_target' then
                exports['qb-target']:AddCircleZone(inspectZoneName, inspectCoords, 2.0, {
                    name = inspectZoneName,
                    debugPoly = Config.DebugMode,
                    useZ = true,
                }, {
                    options = {
                        {
                            label = 'Skontrolovať auto',
                            event = 'mechanic:inspectVehicle'
                        }
                    },
                    distance = 2.0
                })
            elseif Config.TargetSystem == 'ox_target' then
                exports.ox_target:addSphereZone({
                    coords = inspectCoords,
                    radius = 2.0,
                    debug = Config.DebugMode,
                    name = inspectZoneName,
                    options = {
                        {
                            label = 'Skontrolovať auto',
                            event = 'mechanic:inspectVehicle'
                        }
                    }
                })
            end
            targetZones[inspectZoneName] = true
        else
            SendNotify("Rozhodl jsi se neopravit vozidlo.", "error", 5000)
        end
    end)
end)

-- Kontrola vozidla (iba raz)
RegisterNetEvent('mechanic:inspectVehicle', function()
    if carInspected then
        SendNotify("Už jsi toto vozidlo zkontroloval!", "error", 5000)
        return
    end

    carInspected = true
    local inspectZoneName = 'inspect_vehicle_' .. tostring(NetworkGetNetworkIdFromEntity(currentVehicle))
    if Config.TargetSystem == 'qb_target' then
        exports['qb-target']:RemoveZone(inspectZoneName)
    elseif Config.TargetSystem == 'ox_target' then
        exports.ox_target:removeZone(inspectZoneName)
    end
    targetZones[inspectZoneName] = nil

    local playerPed = PlayerPedId()
    local hoodCoords = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.0, 2.0, 0.5)
    TaskGoStraightToCoord(playerPed, hoodCoords.x, hoodCoords.y, hoodCoords.z, 1.0, 5000, GetEntityHeading(currentVehicle), 0.1)
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)

    if oxLibAvailable then
        lib.progressBar({
            duration = 5000,
            label = "Kontrola vozidla...",
            useWhileDead = false,
            canCancel = false,
            disable = {car = true, move = true, combat = true}
        })
    else
        Wait(5000)
    end

    ClearPedTasks(playerPed)
    SendNotify("Vozidlo zkontrolováno, můžeš ho opravit!", "info", 5000)

    if not carRepaired then
        local repairCoords = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.0, 2.0, 0.3)
        local repairZoneName = 'repair_vehicle_' .. tostring(NetworkGetNetworkIdFromEntity(currentVehicle))
        if Config.TargetSystem == 'qb_target' then
            exports['qb-target']:AddCircleZone(repairZoneName, repairCoords, 2.0, {
                name = repairZoneName,
                debugPoly = Config.DebugMode,
                useZ = true,
            }, {
                options = {
                    {
                        label = 'Opravit vozidlo',
                        event = 'mechanic:repairVehicle'
                    }
                },
                distance = 2.0
            })
        elseif Config.TargetSystem == 'ox_target' then
            exports.ox_target:addSphereZone({
                coords = repairCoords,
                radius = 2.0,
                debug = Config.DebugMode,
                name = repairZoneName,
                options = {
                    {
                        label = 'Opravit vozidlo',
                        event = 'mechanic:repairVehicle'
                    }
                }
            })
        end
        targetZones[repairZoneName] = true
    end
end)

-- Oprava vozidla (iba raz)
RegisterNetEvent('mechanic:repairVehicle', function()
    if carRepaired then
        SendNotify("Vozidlo již bylo opraveno!", "error", 5000)
        return
    end

    carRepaired = true
    local repairZoneName = 'repair_vehicle_' .. tostring(NetworkGetNetworkIdFromEntity(currentVehicle))
    if Config.TargetSystem == 'qb_target' then
        exports['qb-target']:RemoveZone(repairZoneName)
    elseif Config.TargetSystem == 'ox_target' then
        exports.ox_target:removeZone(repairZoneName)
    end
    targetZones[repairZoneName] = nil

    local playerPed = PlayerPedId()
    local vehicle = currentVehicle
    local hoodCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 2.2, 0.5)
    SetVehicleDoorOpen(currentVehicle, 4, false, true)

    TaskGoStraightToCoord(playerPed, hoodCoords.x, hoodCoords.y, hoodCoords.z, 1.0, 5000, GetEntityHeading(vehicle), 0.1)
    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do Wait(100) end
    TaskPlayAnim(playerPed, "mini@repair", "fixing_a_player", 8.0, -8.0, 10000, 1, 0, false, false, false)

    if oxLibAvailable then
        lib.progressBar({
            duration = 10000,
            label = "Oprava vozidla...",
            useWhileDead = false,
            canCancel = false,
            disable = {car = true, move = true, combat = true}
        })
    else
        Wait(10000)
    end

    ClearPedTasks(playerPed)
    RemoveAnimDict("mini@repair")
    SetVehicleFixed(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleDoorShut(vehicle, 4, false)

    SendNotify("Vozidlo bylo opraveno!", "success", 5000)

    if not missionCompleted then
        local paymentZoneName = 'npc_payment_' .. tostring(NetworkGetNetworkIdFromEntity(currentNPC))
        if Config.TargetSystem == 'qb_target' then
            exports['qb-target']:AddEntityZone(paymentZoneName, currentNPC, {
                name = paymentZoneName,
                debugPoly = Config.DebugMode,
                useZ = true,
            }, {
                options = {
                    {
                        label = 'Získat odměnu',
                        event = 'mechanic:collectPayment'
                    }
                },
                distance = 5.0
            })
        elseif Config.TargetSystem == 'ox_target' then
            exports.ox_target:addLocalEntity(currentNPC, {
                name = paymentZoneName,
                label = 'Získat odměnu',
                event = 'mechanic:collectPayment',
                distance = 5.0,
                debug = Config.DebugMode
            })
        end
        targetZones[paymentZoneName] = true
    end
end)

-- Vyplatenie peňazí + Možnosť pokračovať alebo ukončiť brigádu
RegisterNetEvent('mechanic:collectPayment', function()
    if missionCompleted then
        SendNotify("❌ Odměnu jsi již obdržel!", "error", 5000)
        return
    end

    missionCompleted = true
    local paymentZoneName = 'npc_payment_' .. tostring(NetworkGetNetworkIdFromEntity(currentNPC))
    if Config.TargetSystem == 'qb_target' then
        exports['qb-target']:RemoveZone(paymentZoneName)
    elseif Config.TargetSystem == 'ox_target' then
        exports.ox_target:removeLocalEntity(currentNPC, paymentZoneName)
    end
    targetZones[paymentZoneName] = nil

    local playerPed = PlayerPedId()
    local animDict = "anim@scripted@robbery@tun_prep_pris_ig1_handover@"
    local npcAnim = "action_dealer"
    local playerAnim = "action_mwxgoon"
    local paperBagModel = GetHashKey("h4_prop_h4_cash_bag_01a")
    local ciggyModel = GetHashKey("p_cs_ciggy_01b_s")

    if not DoesEntityExist(currentNPC) then
        local playerCoords = GetEntityCoords(playerPed)
        currentNPC = CreatePed(4, `mp_m_freemode_01`, playerCoords.x + 1, playerCoords.y, playerCoords.z, 0.0, true, true)
        SetEntityAsMissionEntity(currentNPC, true, true)
        if Config.DebugMode then
            print("[DEBUG] NPC neexistovalo, vytvorené nové")
        end
    end

    ClearPedTasksImmediately(currentNPC)
    RequestAnimDict(animDict)
    RequestModel(paperBagModel)
    RequestModel(ciggyModel)
    while not HasAnimDictLoaded(animDict) or not HasModelLoaded(paperBagModel) or not HasModelLoaded(ciggyModel) do
        Wait(10)
    end

    local npcCoords = GetEntityCoords(currentNPC)
    local playerPos = GetOffsetFromEntityInWorldCoords(currentNPC, 0.0, 1.0, 0.0)
    TaskGoStraightToCoord(playerPed, playerPos.x, playerPos.y, playerPos.z, 1.0, 3000, GetEntityHeading(currentNPC) + 180.0, 0.1)
    while GetDistanceBetweenCoords(GetEntityCoords(playerPed), playerPos, true) > 1.0 do
        Wait(100)
    end

    SetEntityHeading(playerPed, GetEntityHeading(currentNPC) + 180.0)
    SetEntityHeading(currentNPC, GetEntityHeading(playerPed) - 180.0)
    local scenePos = vector3(npcCoords.x, npcCoords.y, npcCoords.z - 1.0)
    local sceneRot = vector3(0.0, 0.0, GetEntityHeading(currentNPC))
    local netScene = NetworkCreateSynchronisedScene(scenePos, sceneRot, 2, true, false, 1.0, 0, 1.3)
    local paperBag = CreateObjectNoOffset(paperBagModel, scenePos, true, true, false)
    local ciggy = CreateObjectNoOffset(ciggyModel, scenePos, true, true, false)
    NetworkAddPedToSynchronisedScene(currentNPC, netScene, animDict, npcAnim, 1.5, -4.0, 1, 16, 0, 0)
    NetworkAddPedToSynchronisedScene(playerPed, netScene, animDict, playerAnim, 1.5, -4.0, 1, 16, 0, 0)
    NetworkAddEntityToSynchronisedScene(paperBag, netScene, animDict, "action_paperbag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(ciggy, netScene, animDict, "action_ciggy", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(netScene)

    Wait(5000)
    TriggerServerEvent('mechanic:reward', math.random(Config.RewardFixOnSite[1], Config.RewardFixOnSite[2]))
    Wait(1000)
    DeleteObject(paperBag)
    DeleteObject(ciggy)
    ClearPedTasks(playerPed)
    ClearPedTasks(currentNPC)
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(paperBagModel)
    SetModelAsNoLongerNeeded(ciggyModel)

    FreezeEntityPosition(currentNPC, false)
    if DoesEntityExist(currentVehicle) then
        local vehicleCoords = GetEntityCoords(currentVehicle)
        TaskGoStraightToCoord(currentNPC, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 1.0, 2000, 0.0, 0.0)
        local timeout = GetGameTimer() + 2000
        while GetDistanceBetweenCoords(GetEntityCoords(currentNPC), vehicleCoords, true) > 2.0 and GetGameTimer() < timeout do
            Wait(100)
        end

        SetEntityHeading(currentNPC, GetEntityHeading(currentVehicle))
        TaskEnterVehicle(currentNPC, currentVehicle, -1, -1, 1.0, 1, 0)
        local enterTimeout = GetGameTimer() + 7000
        while not IsPedInVehicle(currentNPC, currentVehicle, false) and GetGameTimer() < enterTimeout do
            Wait(100)
        end

        if IsPedInVehicle(currentNPC, currentVehicle, false) then
            TaskVehicleDriveWander(currentNPC, currentVehicle, 15.0, 786603)
        else
            if Config.DebugMode then
                print("[DEBUG] NPC nestihlo nastúpiť do auta!")
            end
        end
    end

    if DoesBlipExist(missionBlip) then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
    missionActive = false
    missionCompleted = false
    carInspected = false
    carRepaired = false
    currentNPC = nil
    currentVehicle = nil
    RemoveAllTargetZones()

    local nextMissionDelay = math.random(0, 2000)
    Wait(nextMissionDelay)
    if missionActive then
        return
    end

    if oxLibAvailable then
        lib.registerContext({
            id = 'mechanic_job_menu',
            title = 'Nová zakázka',
            options = {
                {
                    title = 'Pokračovat v práci',
                    description = 'Přijmout další zakázku a pokračovat v brigádě.',
                    icon = 'circle-check',
                    onSelect = function()
                        StartNextMechanicJob()
                    end
                },
                {
                    title = 'Zrušit práci',
                    description = 'Ukončit brigádu a už nepřijde další SMS.',
                    icon = 'ban',
                    onSelect = function()
                        CancelMechanicJob()
                    end
                }
            }
        })
        lib.showContext('mechanic_job_menu')
    else
        SendNotify("Chcete pokračovať v práci? (ox_lib nie je dostupný, manuálne spustite mechanic:startJob)", "info", 5000)
    end
end)

-- Funkcia na pokračovanie v práci
function StartNextMechanicJob()
    if missionCooldown then return end

    missionActive = true
    missionCooldown = true
    UpdateJobInteraction()

    local nextMissionDelay = math.random(10000, 20000)
    Wait(nextMissionDelay)

    if not missionActive then
        missionCooldown = false
        return
    end

    StartMechanicJob()
    missionCooldown = false
end

-- Funkcia na úplné zrušenie brigády
function CancelMechanicJob()
    if missionCooldown then return end

    missionActive = false
    missionCooldown = true
    UpdateJobInteraction()

    if DoesBlipExist(missionBlip) then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
    if DoesEntityExist(currentNPC) then
        DeleteEntity(currentNPC)
        currentNPC = nil
    end
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
    end
    RemoveAllTargetZones()

    carInspected = false
    carRepaired = false
    missionCompleted = false

    SendNotify("❌ Brigáda byla ukončena. Pokud chceš znovu pracovat, musíš ji začít od začátku.", "error", 5000)
    Wait(2000)
    missionCooldown = false
end