local activeJob, vehicle, npc, repairPoint, towStartPoint, towDropOffPoint, jobBlip, towTruck = nil, nil, nil, nil, nil, nil, nil, nil
local resourceName <const> = GetCurrentResourceName()

local function DrawText3D(coords, text, customEntry)
    local str = TranslateCap(text)
    local start, stop = string.find(str, "~([^~]+)~")
    if start then
        start = start - 2
        stop = stop + 2
        str = ""
        str = str .. string.sub(text, 0, start)
    end

    if customEntry ~= nil then
        AddTextEntry(customEntry, str)
        BeginTextCommandDisplayHelp(customEntry)
    else
        AddTextEntry(resourceName, str)
        BeginTextCommandDisplayHelp(resourceName)
    end
    EndTextCommandDisplayHelp(2, false, false, -1)

    SetFloatingHelpTextWorldPosition(1, vec3(coords.x, coords.y, coords.z + 0.5))
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
end

local function DrawTextOnScreen(string) 
    SetTextFont(4)
    SetTextProportional(7)
    SetTextScale(0.8, 0.8)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString(TranslateCap(string))
    DrawText(0.38, 0.90)
end

local function CreateJobBlip(coords, name)
    if jobBlip then RemoveBlip(jobBlip) end
    jobBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(jobBlip, 357)
    SetBlipColour(jobBlip, 2)
    SetBlipScale(jobBlip, 1.0)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(TranslateCap(name))
    EndTextCommandSetBlipName(jobBlip)
    SetNewWaypoint(coords.x, coords.y)
end

local function DrawOnVehicle(veh)
    SetEntityDrawOutline(veh, true)
    SetEntityDrawOutlineColor(253, 152, 0, 1)
end

local function EndJob()
    if not activeJob then return ESX.ShowNotification(TranslateCap('no_active_job'), "error") end
    ESX.ShowNotification(TranslateCap('job_ended'), "info")

    if jobBlip then RemoveBlip(jobBlip) end
    if repairPoint then repairPoint:delete() end
    if towStartPoint then towStartPoint:delete() end
    if towDropOffPoint then towDropOffPoint:delete() end

    SetEntityAsNoLongerNeeded(vehicle)
    SetEntityAsNoLongerNeeded(npc)

    vehicle, npc, activeJob = nil, nil, nil
end

local function SpawnNPC(coords, heading, pedModel)
    if npc then return npc end
    ESX.Streaming.RequestModel(pedModel)
    npc = CreatePed(0, pedModel, coords.x, coords.y, coords.z - 1.0, heading, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    local dict, anim = "oddjobs@assassinate@bus@", "looking_for_help"
    ESX.Streaming.RequestAnimDict(dict)
    TaskPlayAnim(npc, dict, anim, 8.0, 1.0, -1, 16, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(pedModel)
end

local function MakePedWander()
    FreezeEntityPosition(npc, false)
    SetPedIntoVehicle(npc, vehicle, -1)
    TaskVehicleDriveWander(npc, vehicle, 20.0, 786603) 
end

local function MonitorRepair()
    CreateThread(function()
        while GetVehicleEngineHealth(vehicle) < 950.0 do
            DrawTextOnScreen("repair_zone_enter")
            Wait(0)
        end
            
        ESX.ShowNotification(TranslateCap('vehicle_repaired'), "info")

        if IsPedInVehicle(ESX.PlayerData.ped, vehicle, false) then
            TaskLeaveVehicle(ESX.PlayerData.ped, vehicle, 262144)
        end
        Wait(2000)
        MakePedWander()
        TriggerServerEvent('esx_mechanicjob:server:completeJob', activeJob)
        EndJob()
    end)
end

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

local function CreateRepairPoint(job)
    if repairPoint then repairPoint:delete() end
    repairPoint = ESX.Point:new({
        coords = job.npcCoords,
        distance = 25.0,
        enter = function()
            if vehicle or npc then 
                ESX.ShowNotification(TranslateCap('vehicle_already_spawned'), "info")
                return EndJob()
            end
            local vehNetId = ESX.AwaitServerCallback("esx_mechanicjob:server:spawnVehicle")
            vehicle = NetworkGetEntityFromNetworkId(vehNetId)
            SetVehicleEngineHealth(vehicle, 0)
            SpawnNPC(job.npcCoords, job.npcHeading, job.npcModel)
            Wait(1000)
            DrawOnVehicle(vehicle)
        end,
        inside = function()
            DrawText3D(job.vehicleCoords, "repair_zone_enter", 0.4)
            if not IsControlJustReleased(0, 38) then return end
            MonitorRepair()
            SetEntityDrawOutline(vehicle, false)
            repairPoint:delete()
        end
    })
end

local function CreateTowDropOffPoint(dropOffCoords)
    CreateJobBlip(dropOffCoords, 'job_complete')
    if not dropOffCoords then return end
    if towDropOffPoint then towDropOffPoint:delete() end
    towDropOffPoint = ESX.Point:new({
        coords = dropOffCoords,
        distance = 10.0,
        enter = function()
            local maxTime = 120 
            local startTime = GetGameTimer()
            
            while IsVehicleAttachedToTowTruck(towTruck, vehicle) do
                DrawTextOnScreen("repair_zone_left")
                
                if (GetGameTimer() - startTime) / 1000 >= maxTime then
                    ESX.ShowNotification(TranslateCap("time_limit_exceeded"), "error")
                    return EndJob()
                end
                
                Wait(0)
            end
            ESX.ShowNotification(TranslateCap('job_complete'), "info")
            DeleteEntity(vehicle)
            TriggerServerEvent('esx_mechanicjob:server:completeJob', activeJob)
            EndJob()
        end,
        inside = function()
            DrawMarker(
                20,
                dropOffCoords.x, dropOffCoords.y, dropOffCoords.z, 
                0.0, 0.0, 0.0, 
                0.0, 0.0, 0.0, 
                1.0, 1.0, 1.0, 
                253, 152, 0, 200, 
                false, 
                false, 
                2, 
                true, 
                nil, 
                nil, 
                false 
            )
        end
    })
end

local function CreateTowStartPoint(job)
    if towStartPoint then towStartPoint:delete() end
    towStartPoint = ESX.Point:new({
        coords = job.npcCoords,
        distance = 25.0,
        enter = function()
            if vehicle or npc then 
                return ESX.ShowNotification(TranslateCap('vehicle_already_spawned'), "info")
            end
            local vehNetId = ESX.AwaitServerCallback("esx_mechanicjob:server:spawnVehicle")
            vehicle = NetworkGetEntityFromNetworkId(vehNetId)
            SetVehicleEngineHealth(vehicle, 0)
            SpawnNPC(job.npcCoords, job.npcHeading, job.npcModel)
            Wait(1000)
            DrawOnVehicle(vehicle)
        end,
        inside = function()
            DrawText3D(vec3(job.vehicleCoords.x, job.vehicleCoords.y, job.vehicleCoords.z), "repair_zone_enter", 0.4)
            if not IsControlJustReleased(0, 38) then return end
            local maxTime = 120 
            local startTime = GetGameTimer()
            
            while not IsVehicleAttachedToTowTruck(towTruck, vehicle) do
                if towTruck == 0 then 
                    ESX.ShowNotification(TranslateCap("no_tow_truck"), "error")
                    return EndJob()
                end

                DrawTextOnScreen("repair_zone_left")
                if (GetGameTimer() - startTime) / 1000 >= maxTime then
                    ESX.ShowNotification(TranslateCap("time_limit_exceeded"), "error")
                    return EndJob()
                end
                
                Wait(0)
            end
            
            local dropOffPoint = FindNearestDropOffPoint(job.vehicleCoords)
            CreateTowDropOffPoint(dropOffPoint)
            SetEntityDrawOutline(vehicle, false)
            towStartPoint:delete()
        end
    })
end

RegisterNetEvent('esx_mechanicjob:client:startJob', function(job)
    if activeJob then return ESX.ShowNotification(TranslateCap('already_active_job'), "info") end

    activeJob = job
    
    if job.type == "repair" then
        CreateRepairPoint(job)
    elseif job.type == "tow" then
        towTruck = GetVehiclePedIsIn(ESX.PlayerData.ped, false)
        if towTruck == 0 then
            ESX.ShowNotification(TranslateCap("no_tow_truck"), "error")
            return EndJob()
        end
        CreateTowStartPoint(job)
    end
    CreateJobBlip(job.npcCoords, job.jobName)
end)

function OpenNpcMenu()
    local elements = {
        { label = TranslateCap('start_job'), value = "start_job" },
        { label = TranslateCap('end_job'), value = "end_job" }
    }

    ESX.UI.Menu.Open('default', resourceName, 'npc_job_menu', {
        title = TranslateCap('npc_mechanic_title'),
        align = "right",
        elements = elements
    }, function(data, menu)
        if data.current.value == "start_job" then
            if activeJob then return ESX.ShowNotification(TranslateCap('already_active_job'), "info") end
            TriggerServerEvent('esx_mechanicjob:server:startJob')
        elseif data.current.value == "end_job" then
            EndJob()
        end
    end, function(data, menu)
        menu.close()
    end)
end
