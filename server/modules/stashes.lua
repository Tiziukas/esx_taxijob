ESX.RegisterServerCallback('esx_mechanicjob:getPlayerInventory', function(source, cb)
    local _source <const> = source
    local xPlayer <const> = ESX.Player(_source)

    cb({items = xPlayer.getInventory(true)})
end)

ESX.RegisterServerCallback('esx_mechanicjob:getStockItems', function(source, cb)
    local _source <const> = source
    local xPlayer <const> = ESX.Player(_source)
    local xPlayerJob = xPlayer.getJob()

    if xPlayerJob.name ~= 'mechanic' then
        return dropPlayer(source, TranslateCap('unauthorized_access'))
    end

    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mechanic', function(inventory)
        cb(inventory.items)
    end)
end)

RegisterServerEvent('esx_mechanicjob:putStockItems', function(itemName, count)
    local _source <const> = source
    local xPlayer <const> = ESX.Player(_source)
    local xPlayerJob = xPlayer.getJob()

    if xPlayerJob.name ~= 'mechanic' then
        return dropPlayer(source, TranslateCap('unauthorized_access'))
    end

    if type(itemName) ~= 'string' or type(count) ~= 'number' or count <= 0 then
        return xPlayer.showNotification(TranslateCap('invalid_parameters'))
    end

    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mechanic', function(inventory)
        local item = inventory.getItem(itemName)
        local playerItemCount = xPlayer.getInventoryItem(itemName).count

        if not item or playerItemCount < count then
            return xPlayer.showNotification(TranslateCap('insufficient_items'))
        end

        xPlayer.removeInventoryItem(itemName, count)
        inventory.addItem(itemName, count)
        xPlayer.showNotification(TranslateCap('item_deposited', count, item.label))
    end)
end)

RegisterServerEvent('esx_mechanicjob:getStockItem', function(itemName, count)
    local _source <const> = source
    local xPlayer <const> = ESX.Player(_source)
    local xPlayerJob = xPlayer.getJob()

    if xPlayerJob.name ~= 'mechanic' then
        return dropPlayer(source, TranslateCap('unauthorized_access'))
    end

    if type(itemName) ~= 'string' or type(count) ~= 'number' or count <= 0 then
        return xPlayer.showNotification(TranslateCap('invalid_parameters'))
    end

    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mechanic', function(inventory)
        local item = inventory.getItem(itemName)

        if not item or item.count < count then
            return xPlayer.showNotification(TranslateCap('insufficient_stock'))
        end

        if not xPlayer.canCarryItem(itemName, count) then
            return xPlayer.showNotification(TranslateCap('cannot_carry'))
        end

        inventory.removeItem(itemName, count)
        xPlayer.addInventoryItem(itemName, count)
        xPlayer.showNotification(TranslateCap('item_withdrawn', count, item.label))
    end)
end)
