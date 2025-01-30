ESX.RegisterServerCallback('esx_mechanicjob:server:getSocietyBillsWithNames', function(source, cb, society)
    local result = MySQL.query.await([[
        SELECT b.identifier, b.amount, b.id, b.label, u.firstname, u.lastname
        FROM billing b
        LEFT JOIN users u ON b.identifier = u.identifier
        WHERE b.target = ?
    ]], { society })

    for i = 1, #result do
        if result[i].firstname and result[i].lastname then
            result[i].fullName = string.format("%s %s", result[i].firstname, result[i].lastname)
        else
            result[i].fullName = "Unknown" -- Handle cases where names are missing
        end
    end

    cb(result)
end)