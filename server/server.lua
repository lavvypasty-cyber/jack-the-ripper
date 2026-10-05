local RSGCore = exports['rsg-core']:GetCoreObject()

local activeJack = nil -- { target = src, startedAt = os.time ms }
local nextEventAt = GetGameTimer() + math.random(Config.MinInterval, Config.MaxInterval)

local function debug(...) if Config.Debug then print('[jack-the-ripper]', ...) end end

local function isActive()
    return activeJack ~= nil
end

local function getRandomPlayer()
    local players = RSGCore.Functions.GetPlayers()
    if #players == 0 then return nil end
    return players[math.random(1, #players)]
end


local function startEvent(targetSrc)
    if isActive() then
        debug('already active, ignoring start')
        return false
    end
    if not targetSrc then
        targetSrc = getRandomPlayer()
    end
    if not targetSrc then return false end

   
    local Player = RSGCore.Functions.GetPlayer(targetSrc)
    if not Player then return false end

    activeJack = { target = targetSrc, startedAt = GetGameTimer() }
    debug('starting event for target', targetSrc)
    
    TriggerClientEvent('jack-the-ripper:client:startEvent', -1, targetSrc)
    return true
end

local function endEvent(reason)
    if not isActive() then return end
    debug('ending event:', reason)
    TriggerClientEvent('jack-the-ripper:client:endEvent', -1)
    activeJack = nil
    nextEventAt = GetGameTimer() + math.random(Config.MinInterval, Config.MaxInterval)
end


CreateThread(function()
    while true do
        Wait(60000) -- check every minute
        if not isActive() and GetGameTimer() >= nextEventAt then
            local players = RSGCore.Functions.GetPlayers()
            if #players >= Config.MinPlayers then
                local target = players[math.random(1, #players)]
                debug('scheduler picking target', target)
                startEvent(target)
               
            else
                nextEventAt = GetGameTimer() + 60000
            end
        end
        -- safety: force-end stuck events
        if isActive() and (GetGameTimer() - activeJack.startedAt) > (Config.Lifetime + 120000) then
            endEvent('safety timeout')
        end
    end
end)


RegisterNetEvent('jack-the-ripper:server:abortNotNight', function()
    local src = source
    if activeJack and activeJack.target == src then
        debug('target reports not night, aborting')
        activeJack = nil
        TriggerClientEvent('jack-the-ripper:client:endEvent', -1)
        nextEventAt = GetGameTimer() + (5 * 60 * 1000) -- retry in 5 min
    end
end)


RegisterNetEvent('jack-the-ripper:server:jackDown', function(reason)
    local src = source
    if activeJack and activeJack.target == src then
        endEvent(reason or 'jack down')
    end
end)


RegisterNetEvent('jack-the-ripper:server:jackNetId', function(netId)
    local src = source
    if activeJack and activeJack.target == src then
        activeJack.netId = netId
        TriggerClientEvent('jack-the-ripper:client:jackNetId', -1, netId)
    end
end)


AddEventHandler('playerDropped', function()
    local src = source
    if activeJack and activeJack.target == src then
        endEvent('target dropped')
    end
end)

---------------------------------
-- admin commands
---------------------------------
RSGCore.Commands.Add('jack_start', 'Start Jack the Ripper event (admin)', { { name = 'id', help = 'optional target server id' } }, true, function(source, args)
    local target = tonumber(args[1]) or getRandomPlayer()
    if not target then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Jack', description = 'No players online', type = 'error', duration = 5000 })
        return
    end
    if startEvent(target) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Jack', description = 'Event started on ID ' .. target, type = 'success', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'Jack', description = 'Event already active', type = 'error', duration = 5000 })
    end
end, 'admin')

RSGCore.Commands.Add('jack_stop', 'Stop Jack the Ripper event (admin)', {}, true, function(source)
    endEvent('admin stop')
    TriggerClientEvent('ox_lib:notify', source, { title = 'Jack', description = 'Event stopped, weather restored', type = 'inform', duration = 5000 })
end, 'admin')
