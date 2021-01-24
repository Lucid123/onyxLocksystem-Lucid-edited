ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('onyx:updateSearchedVehTable')
AddEventHandler('onyx:updateSearchedVehTable', function(plate)
    local _source = source
    local vehPlate = plate

    TriggerClientEvent('onyx:returnSearchedVehTable', -1, vehPlate)
end)

RegisterServerEvent('onyx:reqHotwiring')
AddEventHandler('onyx:reqHotwiring', function(plate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer.getInventoryItem('lockpick').count > 0 then
        TriggerClientEvent('onyx:beginHotwire', source, plate)
        local rnd = math.random(1, 25)
        if rnd == 20 then
            xPlayer.removeInventoryItem('lockpick', 1)
            TriggerClientEvent('mythic_notify:client:SendAlert', source, {type = 'error', text = 'Maymuncuğun kırıldı'})
        end
    else
        TriggerClientEvent('mythic_notify:client:SendAlert', source, {type = 'error', text = 'Maymuncuğun yok'})
    end
end)

RegisterServerEvent('onyx:reqHotwiring3')
AddEventHandler('onyx:reqHotwiring3', function(plate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer.getInventoryItem('advancedlockpick').count > 0 then
        TriggerClientEvent('onyx:beginHotwire3', source, plate)
        local rnd = math.random(1, 25)
        if rnd == 20 then
            xPlayer.removeInventoryItem('advancedlockpick', 1)
            TriggerClientEvent('mythic_notify:client:SendAlert', source, {type = 'error', text = 'Maymuncuğun kırıldı'})
        end
    else
        TriggerClientEvent('mythic_notify:client:SendAlert', source, {type = 'error', text = 'Maymuncuğun yok'})
    end
end)


RegisterServerEvent('server-givekeys')
AddEventHandler('server-givekeys', function(id,carPlate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
        TriggerClientEvent('mythic_notify:client:SendAlert', id, {type = 'error', text =carPlate .." Plakalı anahtarın aracı sana verildi."})

        TriggerClientEvent('giveKeys', id,_source,carPlate)
end)