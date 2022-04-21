local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateUseableItem("gps", function(source, item)
    TriggerClientEvent('tnj-poltrack:use', source)
end)

RegisterNetEvent('tnj-poltrack:server:ToggleGPS', function()
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == 'police' then
      TriggerClientEvent("tnj-poltrack:client:addBlip", -1, tonumber(source), ("[%s] %s %s"):format(Player.PlayerData.metadata.callsign, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname))
    end
end)

QBCore.Functions.CreateCallback('tnj-poltrack:server:GetItem', function(source, cb, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player ~= nil then
        local GPS = Player.Functions.GetItemByName(item)
        if GPS ~= nil and not Player.PlayerData.metadata["isdead"] and not Player.PlayerData.metadata["inlaststand"] then
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)
