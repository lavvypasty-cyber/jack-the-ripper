local RSGCore = exports['rsg-core']:GetCoreObject()

local jackPed = nil
local jackNetId = nil
local jackSpawnTime = 0
local isTarget = false
local eventRunning = false

local function debug(...) if Config.Debug then print('[jack-the-ripper]', ...) end end

local function isNightHour()
    local h = GetClockHours()
    return Config.ActiveHours[h] == true
end


local function hasWeathersync()
    return Config.UseWeathersync and GetResourceState('weathersync') == 'started'
end

local function applyHorrorWeather()
    if hasWeathersync() then
       
        exports.weathersync:setMyWeather(Config.WeatherType, Config.WeatherTransition, false)
        exports.weathersync:setMyTime(Config.DarkHour, Config.DarkMinute, 0, Config.WeatherTransition)
    else
        
        Citizen.InvokeNative(0x59174F1AFE095B5A, GetHashKey(Config.WeatherType), true, false, true, Config.WeatherTransition, false)
        Citizen.InvokeNative(0x669E223E64B1903C, Config.DarkHour, Config.DarkMinute, 0, Config.WeatherTransition, true)
    end
end

local function restoreWeather()
    if hasWeathersync() then
        exports.weathersync:setSyncEnabled(true) -- next sync tick restores global weather/time
    else
        Citizen.InvokeNative(0x59174F1AFE095B5A, GetHashKey('sunny'), true, false, true, 30.0, false)
        Citizen.InvokeNative(0x669E223E64B1903C, 12, 0, 0, 30.0, true) -- release override; sync will correct shortly
        Wait(2000)
        Citizen.InvokeNative(0x669E223E64B1903C, GetClockHours(), GetClockMinutes(), GetClockSeconds(), 0.0, false)
    end
end


local function applyDamageBoost()
    local mult = Config.JackDamageMultiplier or 5.0
    
    if SetAiWeaponDamageModifier then
        SetAiWeaponDamageModifier(mult)
    end
    if SetAiMeleeWeaponDamageModifier then
        SetAiMeleeWeaponDamageModifier(mult)
    end
    if SetWeaponDamageModifier then 
        SetWeaponDamageModifier(Config.Weapon, mult)
    end
end

local function restoreDamage()
    if ResetAiWeaponDamageModifier then
        ResetAiWeaponDamageModifier()
    elseif SetAiWeaponDamageModifier then
        SetAiWeaponDamageModifier(1.0)
    end
    if ResetAiMeleeWeaponDamageModifier then
        ResetAiMeleeWeaponDamageModifier()
    elseif SetAiMeleeWeaponDamageModifier then
        SetAiMeleeWeaponDamageModifier(1.0)
    end
    if SetWeaponDamageModifier then
        SetWeaponDamageModifier(Config.Weapon, 1.0)
    end
end


local function loadFrontendBank(name, ref)
    
    pcall(function()
        Citizen.InvokeNative(0x0F2A2175734926D8, name, ref)
    end)
end

local function playNativeSting()
    if not Config.Sound or not Config.Sound.Enabled then return end
    loadFrontendBank(Config.Sound.NativeName, Config.Sound.NativeSet)
    pcall(function()
       
        PlaySoundFrontend(-1, Config.Sound.NativeName, Config.Sound.NativeSet, true)
    end)
end

local function playChaseSound()
    if not Config.Sound or not Config.Sound.Enabled then return end
    local name = Config.Sound.ChaseName or Config.Sound.NativeName
    local ref = Config.Sound.ChaseSet or Config.Sound.NativeSet
    loadFrontendBank(name, ref)
    pcall(function()
        PlaySoundFrontend(-1, name, ref, true)
    end)
end

local function playCustom(file)
    if not Config.Sound or not Config.Sound.Enabled or not Config.Sound.UseCustom then return end
    if not file or file == '' then return end
    TriggerServerEvent('InteractSound_SV:PlayOnSource', file, Config.Sound.CustomVolume or 0.8)
end


local function playNuiSound()
    if not Config.Sound or Config.Sound.UseNui == false then return end
    SendNUIMessage({ action = 'jackSound', volume = Config.Sound.NuiVolume or 0.8 })
end


local function loadModel(hash)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    return HasModelLoaded(hash)
end

local function pickSpawnCoords()
    local playerPed = PlayerPedId()
    local px, py, pz = table.unpack(GetEntityCoords(playerPed))
    local angle = math.random() * math.pi * 2
    local dist = math.random(Config.SpawnDistanceMin * 10, Config.SpawnDistanceMax * 10) / 10.0
    local x = px + math.cos(angle) * dist
    local y = py + math.sin(angle) * dist
    local _, z = GetGroundZFor_3dCoord(x, y, pz + 50.0, false)
    if z == 0 then z = pz end
    return vector3(x, y, z)
end

local function deleteJack(silent)
    if jackPed and DoesEntityExist(jackPed) then
        if not IsEntityDead(jackPed) and not silent then
            SetEntityHealth(jackPed, 0, 0)
            Wait(2000)
        end
        DeletePed(jackPed)
        SetEntityAsNoLongerNeeded(jackPed)
    end
    jackPed = nil
end

local function spawnJack()
    deleteJack(true)

    local coords = pickSpawnCoords()

    AddRelationshipGroup('JACK_RIPPER')

    
    local spawned = nil
    for _, hash in ipairs(Config.JackModels) do
        if loadModel(hash) then
            local ped = CreatePed(hash, coords.x, coords.y, coords.z, 0.0, true, false, 0, 0)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                
                SetPedOutfitPreset(ped, Config.JackOutfit or 0, false)
                Citizen.InvokeNative(0x283978A15512B2BB, ped, true) 
                SetEntityVisible(ped, true)
                SetEntityAsMissionEntity(ped, true, true)
                Wait(500) 
                if IsEntityVisible(ped) then
                    spawned = ped
                    debug('jack model visible', hash)
                    SetModelAsNoLongerNeeded(hash)
                    break
                else
                    debug('jack model invisible, trying next', hash)
                    DeletePed(ped)
                    SetEntityAsNoLongerNeeded(ped)
                    SetModelAsNoLongerNeeded(hash)
                end
            else
                SetModelAsNoLongerNeeded(hash)
            end
        else
            debug('jack model failed to load, trying next', hash)
        end
    end

    if not spawned then
        print('[jack-the-ripper] no visible jack model found, check Config.JackModels')
        TriggerServerEvent('jack-the-ripper:server:jackDown', 'model failed')
        return
    end

    jackPed = spawned
    SetPedScale(jackPed, Config.JackPedScale)
    SetEntityAsMissionEntity(jackPed, true, true)
    SetPedRelationshipGroupHash(jackPed, GetHashKey('JACK_RIPPER'))
    SetRelationshipBetweenGroups(5, GetHashKey('JACK_RIPPER'), GetHashKey('PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey('JACK_RIPPER'))
    SetPedSeeingRange(jackPed, Config.SeeingRange)
    SetPedHearingRange(jackPed, Config.HearingRange)
    SetPedCombatAttributes(jackPed, 5, true) 
    SetPedCombatAttributes(jackPed, 46, true) 
    SetPedFleeAttributes(jackPed, 0, false)
    SetPedCanRagdoll(jackPed, true)
    SetPedCombatAbility(jackPed, 2) 
    SetPedAccuracy(jackPed, 100)
    GiveWeaponToPed(jackPed, Config.Weapon, 1, true, true, 0, false, 0.0, 1.0, 1.0, false, 0, false)
    SetCurrentPedWeapon(jackPed, Config.Weapon, true)

    if Config.ShowBlip then
        Citizen.InvokeNative(0x23f74c2fda6e7c61, Config.BlipSprite, jackPed)
    end

    jackSpawnTime = GetGameTimer()
    TaskCombatPed(jackPed, PlayerPedId())
   
    local netId = NetworkGetNetworkIdFromEntity(jackPed)
    jackNetId = netId
    TriggerServerEvent('jack-the-ripper:server:jackNetId', netId)
    debug('jack spawned', jackPed)
end

---------------------------------
-- events
---------------------------------
RegisterNetEvent('jack-the-ripper:client:startEvent', function(targetSrc)
    if eventRunning then return end
    eventRunning = true
    isTarget = (GetPlayerServerId(PlayerId()) == targetSrc)

    applyHorrorWeather()
    applyDamageBoost()

    if Config.NotifyOnStart then
        lib.notify({ title = 'Storm rolls in...', description = 'A thunderstorm breaks. The Ripper is on the proul.', type = 'error', duration = 8000 })
    end

    
    playNuiSound()
    playNativeSting()
    playCustom(Config.Sound and Config.Sound.StartFile)

    if isTarget then
        if not isNightHour() then
            debug('not night locally, aborting')
            TriggerServerEvent('jack-the-ripper:server:abortNotNight')
            return
        end
        
        Wait(8000)
        if not eventRunning then return end
        spawnJack()
    end
end)

RegisterNetEvent('jack-the-ripper:client:jackNetId', function(netId)
    jackNetId = netId
end)

RegisterNetEvent('jack-the-ripper:client:endEvent', function()
    eventRunning = false
    isTarget = false
    jackNetId = nil
    deleteJack(true)
    restoreWeather()
    restoreDamage()
end)


CreateThread(function()
    local lastScare = 0
    while true do
        Wait(1000)
        
        if eventRunning and isTarget and jackPed and DoesEntityExist(jackPed) and not IsEntityDead(jackPed) then
            local interval = (Config.Sound and Config.Sound.ChaseInterval) or 10000
            if (GetGameTimer() - lastScare) > interval then
                lastScare = GetGameTimer()
                playChaseSound()
                playCustom(Config.Sound and Config.Sound.ChaseFile)
            end
        end
        if eventRunning and isTarget and jackPed then
            if not DoesEntityExist(jackPed) then
                TriggerServerEvent('jack-the-ripper:server:jackDown', 'despawned')
            elseif IsEntityDead(jackPed) then
                Wait(5000)
                TriggerServerEvent('jack-the-ripper:server:jackDown', 'killed')
            elseif IsEntityDead(PlayerPedId()) then
                TriggerServerEvent('jack-the-ripper:server:jackDown', 'victim died')
            elseif (GetGameTimer() - jackSpawnTime) > Config.Lifetime then
                TriggerServerEvent('jack-the-ripper:server:jackDown', 'timeout')
            elseif (GetGameTimer() % Config.RetaskInterval) < 1000 then
                -- keep pressure on: re-acquire victim
                local target = PlayerPedId()
                if not IsPedInCombat(jackPed, target) then
                    ClearPedTasks(jackPed)
                    TaskCombatPed(jackPed, target)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        deleteJack(true)
        jackNetId = nil
        if eventRunning then
            restoreWeather()
        end
        restoreDamage()
        eventRunning = false
    end
end)


CreateThread(function()
    local lastProx = 0
    while true do
        Wait(1000)
        if eventRunning and jackNetId then
            local interval = (Config.Sound and Config.Sound.ChaseInterval) or 10000
            if (GetGameTimer() - lastProx) > interval then
                local ped = nil
                pcall(function()
                    ped = NetworkGetEntityFromNetworkId(jackNetId)
                end)
                if ped and ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped) then
                    local range = (Config.Sound and Config.Sound.ProximityRange) or 60.0
                    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped))
                    if dist <= range then
                        lastProx = GetGameTimer()
                        playNuiSound()
                    end
                end
            end
        else
            lastProx = 0
        end
    end
end)
