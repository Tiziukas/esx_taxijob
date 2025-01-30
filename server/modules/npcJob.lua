local jobCooldowns = {}
local activeJobs = {}

local JOB_TYPE_REPAIR <const> = "repair"
local JOB_TYPE_TOW <const> = "tow"
local MAX_JOB_DISTANCE <const> = 15.0
local MAX_VEHICLE_SPAWN_DISTANCE <const> = 30.0
local JOB_COOLDOWN_TIME <const> = 60

function dropPlayer(_source, message)
    local xPlayer = ESX.Player(_source)
    xPlayer.kick("Cheating")
    error(string.format('%s was dropped due to %s', GetPlayerName(_source), message))
end

ESX.RegisterServerCallback('esx_mechanicjob:server:spawnVehicle', function(source, cb)
    local _source <const> = source 
    local session = activeJobs[_source]
    if not session then 
        return dropPlayer("Attempted to spawn vehicle without being in an active job")
    end

    if session.vehicle then
        return dropPlayer("Car was already spawned")
    end 
    local playerCoords = GetEntityCoords(GetPlayerPed(_source))
    local distance = #(playerCoords - vec3(session.job.vehicleCoords.x, session.job.vehicleCoords.y, session.job.vehicleCoords.z))
    if distance > MAX_VEHICLE_SPAWN_DISTANCE then
        return dropPlayer(_source, "Player was too far")
    end
    local netId = ESX.OneSync.SpawnVehicle(session.job.carModel, vector3(session.job.vehicleCoords.x, session.job.vehicleCoords.y, session.job.vehicleCoords.z), 0, {engineHealth = 0.0})
    Wait(250)
    cb(netId)
  end)

local function FindNearestDropOffPoint(coords)
    local closestPoint, closestDistance = nil, math.huge
    for _, zone in pairs(Config.MechanicZones) do
        local dropOffPointCoords = vector3(zone.dropOffPoint.x, zone.dropOffPoint.y, zone.dropOffPoint.z)
        local distance = #(dropOffPointCoords - vec3(coords.x, coords.y, coords.z))
        if distance < closestDistance then
            closestDistance = distance
            closestPoint = dropOffPointCoords
        end
    end
    return closestPoint
end

RegisterNetEvent('esx_mechanicjob:server:startJob', function()
    local _source <const> = source
    local xPlayer <const> = ESX.Player(_source)
    local xPlayerJob = xPlayer.getJob()
    if not xPlayer then return end

    if not xPlayerJob or xPlayerJob.name ~= "mechanic" then
        return dropPlayer(_source, "You are not a mechanic!")
    end
    local job = Config.NPCJobs[math.random(#Config.NPCJobs)]

    activeJobs[_source] = {job = job, dropOffPoint = FindNearestDropOffPoint(job.vehicleCoords)}

    TriggerClientEvent("esx_mechanicjob:client:startJob", _source, job)
    --print(string.format('Player %s started job %s', GetPlayerName(_source), job.type))
end)

RegisterNetEvent('esx_mechanicjob:server:completeJob', function(job)
    local _source <const> = source
    local xPlayer <const> = ESX.Player(_source)
    local xPlayerJob = xPlayer.getJob()
    local distance

    if not xPlayer then return end

    if not xPlayerJob or xPlayerJob.name ~= "mechanic" then
        return dropPlayer(_source, "Not Mechanic")
    end

    if not activeJobs[_source] then
        return dropPlayer(_source, "Job was not active")
    end

    local currentJob = activeJobs[_source]
    if currentJob.job.type ~= job.type then
        return dropPlayer(_source, "Job type mismatch!")
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(_source))
    if currentJob.job.type == 'repair' then
        distance = #(playerCoords - vec3(currentJob.job.vehicleCoords.x, currentJob.job.vehicleCoords.y, currentJob.job.vehicleCoords.z))
    else
        distance = #(playerCoords - vec3(currentJob.dropOffPoint.x, currentJob.dropOffPoint.y, currentJob.dropOffPoint.z))
    end

    if distance > MAX_JOB_DISTANCE then
        return dropPlayer(_source, "Player was too far")
    end

    if jobCooldowns[_source] and jobCooldowns[_source] > os.time() then
        return dropPlayer(_source, "Cooldown breached.")
    end

    jobCooldowns[_source] = os.time() + JOB_COOLDOWN_TIME

    local reward = Config.Rewards[currentJob.job.type]
    if currentJob.job.type == JOB_TYPE_REPAIR then
        xPlayer.addMoney(reward) -- Cash or bank add
    elseif currentJob.job.type == JOB_TYPE_TOW then
        xPlayer.addMoney(reward)-- Cash or bank add
    else
        return dropPlayer(_source, "Unknown job type.")
    end

    activeJobs[_source] = nil
    --print(string.format('Mechanic job completed: %s for player %s', currentJob.type, _source))
end)
