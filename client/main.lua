local resourceName <const> = GetCurrentResourceName()

local function ReturnNearbyVehicle()
    local playerCoords = GetEntityCoords(ESX.PlayerData.ped)
    local vehicle = ESX.Game.GetClosestVehicle(playerCoords)
    if not vehicle or vehicle == -1 then
        return nil
    end
    return vehicle
end

ESX.RegisterClientCallback('esx_mechanicjob:client:checkForVehicle', function(cb)
    local vehicle = ReturnNearbyVehicle()
    if not vehicle then
        return cb(false)
    end

    local playerCoords = GetEntityCoords(ESX.PlayerData.ped)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)

    cb(distance < 5.0 and vehicle or false)
end)

CreateThread(function()
    for _, zoneData in pairs(Config.MechanicZones) do
        local blipConfig = zoneData.blip
        local blipLocation = blipConfig.location

        local blip = AddBlipForCoord(blipLocation.x, blipLocation.y, blipLocation.z)
        SetBlipSprite(blip, blipConfig.sprite)
        SetBlipColour(blip, blipConfig.colour)
        SetBlipScale(blip, blipConfig.scale)
        SetBlipAsShortRange(blip, blipConfig.shortRange)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipConfig.name)
        EndTextCommandSetBlipName(blip)
    end
end)

local function ImpoundVehicle()
    local vehicle = ReturnNearbyVehicle()
    if not vehicle then
        return ESX.ShowNotification(TranslateCap('no_vehicle_nearby'), "error")
    end

    ESX.Progressbar(TranslateCap('impounding_vehicle'), Config.ProgressBars.impoundVehicle.time, {
        FreezePlayer = true,
        animation = {
            type = "anim",
            dict = Config.ProgressBars.impoundVehicle.animation.dict,
            lib = Config.ProgressBars.impoundVehicle.animation.lib
        },
        onFinish = function()
            ESX.Game.DeleteVehicle(vehicle)
        end
    })
end

local function BreakVehicle()
    local vehicle = ReturnNearbyVehicle()
    if not vehicle then
        return ESX.ShowNotification(TranslateCap('no_vehicle_nearby'), "error")
    end

    ESX.Progressbar(TranslateCap('breaking_into_vehicle'), Config.ProgressBars.breakIntoVehicle.time, {
        FreezePlayer = true,
        animation = {
            type = "anim",
            dict = Config.ProgressBars.breakIntoVehicle.animation.dict,
            lib = Config.ProgressBars.breakIntoVehicle.animation.lib
        },
        onFinish = function()
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        end
    })
end

local function FixVehicle()
    local vehicle = ReturnNearbyVehicle()
    if not vehicle then
        return ESX.ShowNotification(TranslateCap('no_vehicle_nearby'), "error")
    end

    ESX.Progressbar(TranslateCap('fixing_vehicle'), Config.ProgressBars.fixVehicle.time, {
        FreezePlayer = true,
        animation = {
            type = "anim",
            dict = Config.ProgressBars.fixVehicle.animation.dict,
            lib = Config.ProgressBars.fixVehicle.animation.lib
        },
        onFinish = function()
            SetVehicleEngineHealth(vehicle, 1000)
            SetVehicleFixed(vehicle)
            SetVehicleEngineOn(vehicle, true, true, false)
        end
    })
end

local function CleanVehicle()
    local vehicle = ReturnNearbyVehicle()
    if not vehicle then
        return ESX.ShowNotification(TranslateCap('no_vehicle_nearby'), "error")
    end

    ESX.Progressbar(TranslateCap('cleaning_vehicle'), Config.ProgressBars.cleanVehicle.time, {
        FreezePlayer = true,
        animation = {
            type = "anim",
            dict = Config.ProgressBars.cleanVehicle.animation.dict,
            lib = Config.ProgressBars.cleanVehicle.animation.lib
        },
        onFinish = function()
            WashDecalsFromVehicle(vehicle, ESX.PlayerData.ped, 1.0)
            SetVehicleDirtLevel(vehicle, 0.1)
            ClearPedTasksImmediately(ESX.PlayerData.ped)
        end
    })
end

local function OpenVehInteractMenu()
    local elements = {
        {label = TranslateCap('repair_vehicle'), value = 'repair_veh'},
        {label = TranslateCap('clean_vehicle'), value = 'clean_veh'},
        {label = TranslateCap('break_vehicle'), value = 'break_veh'},
        {label = TranslateCap('impound_vehicle'), value = 'impound_veh'}
    }

    ESX.UI.Menu.Open('default', resourceName, 'vehicle_menu', {
        title = TranslateCap('vehicle_interact_menu'),
        align = 'right',
        elements = elements
    }, function(data, menu)
        menu.close()
        if data.current.value == 'repair_veh' then
            FixVehicle()
        elseif data.current.value == 'clean_veh' then
            CleanVehicle()
        elseif data.current.value == 'break_veh' then
            BreakVehicle()
        elseif data.current.value == 'impound_veh' then
            ImpoundVehicle()
        end
    end, function(data, menu)
        menu.close()
    end)
end

local function OpenMechanicMenu()
    local elements = {
        {label = TranslateCap('vehicle_interactions'), value = 'veh_interact'},
        {label = TranslateCap('billing'), value = 'billing'},
        {label = TranslateCap('npc_jobs'), value = 'npcJobs'}
    }

    ESX.UI.Menu.Open('default', resourceName, 'mechanic_menu', {
        title = TranslateCap('mechanic_menu'),
        align = 'right',
        elements = elements
    }, function(data, menu)
        menu.close()
        if data.current.value == 'veh_interact' then
            OpenVehInteractMenu()
        elseif data.current.value == 'billing' then
            OpenBillingMenu()
        elseif data.current.value == 'npcJobs' then
            OpenNpcMenu()
        end
    end, function(data, menu)
        menu.close()
    end)
end

RegisterCommand('mechanicMenu', function()
    if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
        OpenMechanicMenu()
    end
end, false)

RegisterKeyMapping('mechanicMenu', TranslateCap('open_mechanic_menu'), 'keyboard', Config.Controls.mechanicMenu)
