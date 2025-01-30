local resourceName <const> = GetCurrentResourceName()
local mechanicZones <const> = Config.MechanicZones
local cloakroomPoints = {}

local function SetMechanicOutfit()
    local skin = ESX.AwaitServerCallback('esx_skin:getPlayerSkin')
    local jobGrade = LocalPlayer.state.job.grade
    local outfit = Config.MechanicOutfits[jobGrade]
    if not outfit then
        return ESX.ShowNotification(TranslateCap('no_outfit_configured'), "error")
    end

    local gender = skin.sex == 0 and "male" or "female"
    TriggerEvent('skinchanger:loadClothes', skin, outfit[gender])
end

local function ResetToCivilianClothes()
    local skin = ESX.AwaitServerCallback('esx_skin:getPlayerSkin')
    TriggerEvent('skinchanger:loadSkin', skin)
    ESX.ShowNotification(TranslateCap('changed_to_civilian'), "success")
end

local function OpenCloakroomMenu()
    local elements = {
        { label = TranslateCap('work_clothes'), value = 'work_clothes' },
        { label = TranslateCap('civilian_clothes'), value = 'civilian_clothes' }
    }

    ESX.UI.Menu.Open(
        'default', resourceName, 'cloakroom_menu',
        {
            title    = TranslateCap('cloakroom'),
            align    = 'right',
            elements = elements
        },
        function(data, menu)
            if data.current.value == 'work_clothes' then
                SetMechanicOutfit()
            elseif data.current.value == 'civilian_clothes' then
                ResetToCivilianClothes()
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end

local canInteract = false
CreateThread(function()
    for zoneName, zoneData in pairs(mechanicZones) do
        local cloakroomConfig <const> = zoneData.cloakroom
        local location <const>  = cloakroomConfig.location
        local markerConfig <const> = cloakroomConfig.marker
        cloakroomPoints[#cloakroomPoints + 1] = ESX.Point:new({
            coords = location,
            distance = 2.0,
            enter = function()
                canInteract = true
                local key = ESX.GetInteractKey()
                ESX.TextUI(string.format(TranslateCap('press_to_open_cloakroom'), key), "info")     
            end,
            leave = function()
                canInteract = false
                ESX.HideUI()
            end,
            inside = function()
                DrawMarker(
                    markerConfig.type or 20, -- Default to cylinder marker
                    location.x, location.y, location.z, -- Position
                    0.0, 0.0, 0.0, -- Direction
                    0.0, 0.0, 0.0, -- Rotation
                    markerConfig.scale[1], markerConfig.scale[2], markerConfig.scale[3], -- Scale
                    markerConfig.colour[1], markerConfig.colour[2], markerConfig.colour[3], markerConfig.colour[4], -- RGBA
                    false, -- Not bobbing
                    false, -- No face camera
                    2, -- P19
                    markerConfig.rotate or false, -- Rotation enabled/disabled
                    nil, -- Texture dictionary
                    nil, -- Texture name
                    false -- Draw on entities
                )
            end
        })
    end
end)

ESX.RegisterInteraction('cloakroomInteraction', function()
    if canInteract then
        OpenCloakroomMenu()
    end
end)
