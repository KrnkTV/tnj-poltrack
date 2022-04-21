local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateUseableItem("gps", function(source, item)
    TriggerClientEvent('tnj-poltrack:use', source)
end)

-- RegisterNetEvent('tnj-poltrack:server:ToggleGPS', function()
--     local source = source
--     local Player = QBCore.Functions.GetPlayer(source)
--     if Player.PlayerData.job.name == 'police' then
--       TriggerClientEvent("tnj-poltrack:client:addBlip", -1, tonumber(source), ("[%s] %s %s"):format(Player.PlayerData.metadata.callsign, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname))
--     end
-- end)

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

local function UpdateBlips()
    local dutyPlayers = {}
    local players = QBCore.Functions.GetQBPlayers()
    for k, v in pairs(players) do
        if (v.PlayerData.job.name == "police") and v.PlayerData.job.onduty then
            local coords = GetEntityCoords(GetPlayerPed(v.PlayerData.source))
            local heading = GetEntityHeading(GetPlayerPed(v.PlayerData.source))
            dutyPlayers[#dutyPlayers+1] = {
                source = v.PlayerData.source,
                label = v.PlayerData.metadata["callsign"],
                job = v.PlayerData.job.name,
                location = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    w = heading
                }
            }
        end
    end
    TriggerClientEvent("tnj-poltrack:client:UpdateBlips", -1, dutyPlayers)
end

CreateThread(function()
    while true do
        Wait(5000)
        UpdateBlips()
    end
end)
