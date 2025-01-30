local mechanicZones <const> = Config.MechanicZones

local function OpenBossMenu()
    TriggerEvent('esx_society:openBossMenu', 'mechanic', function(data, menu)
        ESX.CloseContext()
    end)
end

local canInteract = false

CreateThread(function()
    for zoneName, zoneData in pairs(mechanicZones) do
        local bossMenuConfig <const> = zoneData.bossMenu
        local location <const> = bossMenuConfig.location
        local markerConfig <const> = bossMenuConfig.marker

        -- Add Boss Menu Points
        local bossMenuPoints = bossMenuPoints or {}
        bossMenuPoints[#bossMenuPoints + 1] = ESX.Point:new({
            coords = location,
            distance = 2.0,
            enter = function()
                if ESX.PlayerData.job.grade_name ~= 'boss' then return end
                canInteract = true
                local key = ESX.GetInteractKey()
                ESX.TextUI(string.format(TranslateCap('press_to_access_boss_menu'), key), "info")
            end,
            leave = function()
                canInteract = false
                ESX.HideUI()
            end,
            inside = function()
                DrawMarker(
                    markerConfig.type or 22, -- Default marker type
                    location.x, location.y, location.z, -- Marker position
                    0.0, 0.0, 0.0, -- Direction
                    0.0, 0.0, 0.0, -- Rotation
                    markerConfig.scale[1], markerConfig.scale[2], markerConfig.scale[3], -- Dimensions
                    markerConfig.colour[1], markerConfig.colour[2], markerConfig.colour[3], markerConfig.colour[4], -- RGBA
                    false, -- No bobbing
                    false, -- No face camera
                    2, -- P19
                    markerConfig.rotate or false -- Rotation
                )
            end
        })
    end
end)

ESX.RegisterInteraction('bossMenuInteraction', function()
    if canInteract then
        OpenBossMenu()
    end
end)
