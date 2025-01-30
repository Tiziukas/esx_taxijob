local resourceName <const> = GetCurrentResourceName()

local function IssueBill()
    ESX.UI.Menu.Open(
        'dialog', resourceName, 'billing_amount',
        {
            title = TranslateCap('enter_bill_amount')
        },
        function(data, menu)
            local amount = tonumber(data.value)
            if not amount or amount <= 0 then
                ESX.ShowNotification(TranslateCap('invalid_amount'), "error")
                menu.close()
                return
            end

            menu.close() 

            ESX.UI.Menu.Open(
                'dialog', resourceName, 'billing_reason',
                {
                    title = TranslateCap('enter_billing_reason')
                },
                function(reasonData, reasonMenu)
                    local reason = tostring(reasonData.value)
                    if not reason or reason == '' then
                        ESX.ShowNotification(TranslateCap('empty_reason'), "error")
                        reasonMenu.close()
                        return
                    end

                    local player, distance = ESX.Game.GetClosestPlayer()

                    if player ~= -1 and distance <= 3.0 then
                        local playerId = GetPlayerServerId(player)
                        TriggerServerEvent('esx_billing:sendBill', playerId, 'society_mechanic', reason, amount)
                        ESX.ShowNotification(string.format(TranslateCap('bill_issued'), reason), "success")
                    else
                        ESX.ShowNotification(TranslateCap('no_player_nearby'), "error")
                    end

                    reasonMenu.close()
                end,
                function(reasonData, reasonMenu)
                    reasonMenu.close()
                end
            )
        end,
        function(data, menu)
            menu.close()
        end
    )
end

local function ViewUnpaidBills()
    local bills = ESX.AwaitServerCallback('esx_mechanicjob:server:getSocietyBillsWithNames', 'society_mechanic')
    local elements = {}
    for i = 1, #bills, 1 do
        elements[#elements + 1] = {
            label = string.format("%s - $%d", bills[i].fullName, bills[i].amount),
            value = bills[i].id
        }
    end

    ESX.UI.Menu.Open(
        'default', resourceName, 'unpaid_bills',
        {
            title    = TranslateCap('unpaid_bills'),
            align    = 'right',
            elements = elements
        },
        function(data, menu)
            ESX.ShowNotification(string.format(TranslateCap('selected_bill_id'), data.current.value), "info")
        end,
        function(data, menu)
            menu.close()
        end
    )
end

function OpenBillingMenu()
    local elements = {
        { label = TranslateCap('issue_bill'), value = 'issue_bill' },
        { label = TranslateCap('view_unpaid_bills'), value = 'view_bills' }
    }

    ESX.UI.Menu.Open(
        'default', resourceName, 'billing_menu',
        {
            title    = TranslateCap('billing_menu'),
            align    = 'right',
            elements = elements
        },
        function(data, menu)
            if data.current.value == 'issue_bill' then
                IssueBill()
            elseif data.current.value == 'view_bills' then
                ViewUnpaidBills()
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end
