local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData() -- Just for resource restart (same as event handler)
local onGPS = false
local gpsProp = 0

function isPolice()
    PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData ~= nil then
        local isPolice = false
        if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
            isPolice = true
        end
        return isPolice
    end
end

--Function
local function LoadAnimDic(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
end

local function GpsToggle(toggle)
    onGPS = toggle
    CreateThread(function()
        while onGPS do
            Wait(5000)
            UpdateBlips()
        end
    end)
    -- TriggerServerEvent("tnj-poltrack:server:ToggleGPS")
end

local function toggleGpsAnimation(pState)
	LoadAnimDic("cellphone@")
	if pState then
		TaskPlayAnim(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 2.0, 3.0, -1, 49, 0, 0, 0, 0)
		gpsProp = CreateObject(`prop_cs_hand_radio`, 1.0, 1.0, 1.0, 1, 1, 0)
		AttachEntityToEntity(gpsProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.14, 0.01, -0.02, 110.0, 120.0, -15.0, 1, 0, 0, 0, 2, 1)
	else
		StopAnimTask(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 1.0)
		ClearPedTasks(PlayerPedId())
		if gpsProp ~= 0 then
			DeleteObject(gpsProp)
			gpsProp = 0
		end
	end
end

local function toggleGps(toggle)
    gpsMenu = toggle
    SetNuiFocus(gpsMenu, gpsMenu)
    if gpsMenu then
        toggleGpsAnimation(true)
        SendNUIMessage({type = "open"})
    else
        toggleGpsAnimation(false)
        SendNUIMessage({type = "close"})
    end
end

local function IsGpsOn()
    return onGPS
end

--Exports
exports("IsGpsOn", IsGpsOn)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    GpsToggle(false)
end)

RegisterNetEvent('tnj-poltrack:use', function()
    toggleGps(not gpsMenu)
end)

RegisterNetEvent('tnj-poltrack:onGpsDrop', function()
    GpsToggle(false)
end)

-- NUI
RegisterNUICallback('escape', function(data, cb)
    toggleGps(false)
end)

RegisterNUICallback('GPSON', function(data, cb)
    if not onGPS then
        onGPS = true
        GpsToggle(true)
			QBCore.Functions.Notify('Your GPS has been activated.')
    else
        TriggerEvent("QBCore:Notify", "GPS is already on", 'error')
    end
end)

RegisterNUICallback('GPSOFF', function(data, cb)
    if onGPS then
        onGPS = false
        GpsToggle(false)
			QBCore.Functions.Notify('Your GPS has been deactivated.')
    else
        TriggerEvent("QBCore:Notify", "GPS Isnt on yet", 'error')
    end
end)

--Main Thread
CreateThread(function()
    while true do
        Wait(1000)
        if LocalPlayer.state.isLoggedIn and onGPS and isPolice() then
            QBCore.Functions.TriggerCallback('tnj-poltrack:server:GetItem', function(hasItem)
                if not hasItem then
                    onGPS = false
                    GpsToggle(false)
							QBCore.Functions.Notify('Your GPS has been deactivated.')
                end
            end, "gps")
        end
    end
end)

-- RegisterNetEvent('tnj-poltrack:client:addBlip', function(id, pinfo)
-- 	if isPolice() then
-- 		local id = GetPlayerFromServerId(id)
-- 		local pedUser = GetPlayerPed(id)
-- 		local blip = GetBlipFromEntity(pedUser)

-- 		if not DoesBlipExist(blip) then
-- 			CreateDutyBlips(id, pinfo, 'police', playerLocation)

-- 			if pedUser == PlayerPedId() then
-- 				QBCore.Functions.Notify('Your GPS has been activated.')
-- 			else
-- 				QBCore.Functions.Notify('A police has activated a GPS.')
-- 			end
-- 		else
-- 			RemoveBlip(blip)
-- 			if pedUser == PlayerPedId() then
-- 				QBCore.Functions.Notify('Your GPS has been deactivated.')
-- 			else
--                 QBCore.Functions.Notify('A police has deactivated a GPS.')
-- 			end
-- 		end
-- 	end
-- end)

local function CreateDutyBlips(playerId, playerLabel, playerLocation)
    local ped = GetPlayerPed(playerId)
    local blip = GetBlipFromEntity(ped)
    if not DoesBlipExist(blip) then
        if NetworkIsPlayerActive(playerId) then
            blip = AddBlipForEntity(ped)
        else
            blip = AddBlipForCoord(playerLocation.x, playerLocation.y, playerLocation.z)
        end
        SetBlipSprite(blip, 1)
        ShowHeadingIndicatorOnBlip(blip, true)
        SetBlipRotation(blip, math.ceil(playerLocation.w))
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, 38)
        SetBlipAsShortRange(blip, true)
        SetBlipCategory(blip, 7)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(playerLabel)
        EndTextCommandSetBlipName(blip)
        DutyBlips[#DutyBlips+1] = blip
    end

    if GetBlipFromEntity(PlayerPedId()) == blip then
        -- Ensure we remove our own blip.
        RemoveBlip(blip)
    end
end

RegisterNetEvent('tnj-poltrack:client:UpdateBlips', function(players)
    local player = QBCore.Functions.GetPlayerData()
    if PlayerJob and (PlayerJob.name == 'police') and player.job.onduty then
        if DutyBlips then
            for k, v in pairs(DutyBlips) do
                RemoveBlip(v)
            end
        end
        DutyBlips = {}
        if players then
            for k, data in pairs(players) do
                local id = GetPlayerFromServerId(data.source)
                CreateDutyBlips(id, data.label, data.location)
            end
        end
    end
end)
