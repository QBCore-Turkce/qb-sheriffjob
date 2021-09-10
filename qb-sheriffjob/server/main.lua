local Plates = {}
cuffedPlayers = {}
PlayerStatus = {}
Casings = {}
BloodDrops = {}
FingerDrops = {}
local Objects = {}


Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(1000 * 60 * 10)
        local curCops = GetCurrentCops()
        TriggerClientEvent("sheriff:SetCopCount", -1, curCops)
    end
end)

RegisterServerEvent('sheriff:server:TakeOutImpound')
AddEventHandler('sheriff:server:TakeOutImpound', function(plate)
    local src = source       
    exports['ghmattimysql']:execute('UPDATE player_vehicles SET state = @state WHERE plate = @plate', {['@state'] = 0, ['@plate'] = plate})
    TriggerClientEvent('QBCore:Notify', src, "Vehicle is taken out of Impound!")  
end)

RegisterServerEvent('sheriff:server:CuffPlayer')
AddEventHandler('sheriff:server:CuffPlayer', function(playerId, isSoftcuff)
    local src = source
    local Player = QBCore.Functions.GetPlayer(source)
    local CuffedPlayer = QBCore.Functions.GetPlayer(playerId)
    if CuffedPlayer ~= nil then
        if Player.Functions.GetItemByName("handcuffs") ~= nil or Player.PlayerData.job.name == "sheriff" then
            TriggerClientEvent("sheriff:client:GetCuffed", CuffedPlayer.PlayerData.source, Player.PlayerData.source, isSoftcuff)           
        end
    end
end)

RegisterServerEvent('sheriff:server:EscortPlayer')
AddEventHandler('sheriff:server:EscortPlayer', function(playerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(source)
    local EscortPlayer = QBCore.Functions.GetPlayer(playerId)
    if EscortPlayer ~= nil then
        if (Player.PlayerData.job.name == "sheriff" or Player.PlayerData.job.name == "ambulance" or Player.PlayerData.job.name == "doctor") or (EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"] or EscortPlayer.PlayerData.metadata["inlaststand"]) then
            TriggerClientEvent("sheriff:client:GetEscorted", EscortPlayer.PlayerData.source, Player.PlayerData.source)
        else
            TriggerClientEvent('chatMessage', src, "SYSTEM", "error", "Person is not dead or cuffed!")
        end
    end
end)

RegisterServerEvent('sheriff:server:KidnapPlayer')
AddEventHandler('sheriff:server:KidnapPlayer', function(playerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(source)
    local EscortPlayer = QBCore.Functions.GetPlayer(playerId)
    if EscortPlayer ~= nil then
        if EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"] or EscortPlayer.PlayerData.metadata["inlaststand"] then
            TriggerClientEvent("sheriff:client:GetKidnappedTarget", EscortPlayer.PlayerData.source, Player.PlayerData.source)
            TriggerClientEvent("sheriff:client:GetKidnappedDragger", Player.PlayerData.source, EscortPlayer.PlayerData.source)
        else
            TriggerClientEvent('chatMessage', src, "SYSTEM", "error", "Person is not dead or cuffed!")
        end
    end
end)

RegisterServerEvent('sheriff:server:SetPlayerOutVehicle')
AddEventHandler('sheriff:server:SetPlayerOutVehicle', function(playerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(source)
    local EscortPlayer = QBCore.Functions.GetPlayer(playerId)
    if EscortPlayer ~= nil then
        if EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"] then
            TriggerClientEvent("sheriff:client:SetOutVehicle", EscortPlayer.PlayerData.source)
        else
            TriggerClientEvent('chatMessage', src, "SYSTEM", "error", "Person is not dead or cuffed!")
        end
    end
end)

RegisterServerEvent('sheriff:server:PutPlayerInVehicle')
AddEventHandler('sheriff:server:PutPlayerInVehicle', function(playerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(source)
    local EscortPlayer = QBCore.Functions.GetPlayer(playerId)
    if EscortPlayer ~= nil then
        if EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"] then
            TriggerClientEvent("sheriff:client:PutInVehicle", EscortPlayer.PlayerData.source)
        else
            TriggerClientEvent('chatMessage', src, "SYSTEM", "error", "Person is not dead or cuffed!")
        end
    end
end)

RegisterServerEvent('sheriff:server:BillPlayer')
AddEventHandler('sheriff:server:BillPlayer', function(playerId, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
    if Player.PlayerData.job.name == "sheriff" then
        if OtherPlayer ~= nil then
            OtherPlayer.Functions.RemoveMoney("bank", price, "paid-bills")
            TriggerClientEvent('QBCore:Notify', OtherPlayer.PlayerData.source, "You received a fine of $"..price)
        end
    end
end)

RegisterServerEvent('sheriff:server:JailPlayer')
AddEventHandler('sheriff:server:JailPlayer', function(playerId, time)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
    local currentDate = os.date("*t")
    if currentDate.day == 31 then currentDate.day = 30 end

    if Player.PlayerData.job.name == "sheriff" then
        if OtherPlayer ~= nil then
            OtherPlayer.Functions.SetMetaData("injail", time)
            OtherPlayer.Functions.SetMetaData("criminalrecord", {
                ["hasRecord"] = true,
                ["date"] = currentDate
            })
            TriggerClientEvent("sheriff:client:SendToJail", OtherPlayer.PlayerData.source, time)
            TriggerClientEvent('QBCore:Notify', src, "You sent the person to prison for "..time.." months")
        end
    end
end)

RegisterServerEvent('sheriff:server:SetHandcuffStatus')
AddEventHandler('sheriff:server:SetHandcuffStatus', function(isHandcuffed)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player ~= nil then
		Player.Functions.SetMetaData("ishandcuffed", isHandcuffed)
	end
end)

RegisterServerEvent('heli:spotlight')
AddEventHandler('heli:spotlight', function(state)
	local serverID = source
	TriggerClientEvent('heli:spotlight', -1, serverID, state)
end)

RegisterServerEvent('sheriff:server:FlaggedPlateTriggered')
AddEventHandler('sheriff:server:FlaggedPlateTriggered', function(camId, plate, street1, street2, blipSettings)
    local src = source
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if (Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty) then
                if street2 ~= nil then
                    TriggerClientEvent("112:client:SendsheriffAlert", v, "flagged", {
                        camId = camId,
                        plate = plate,
                        streetLabel = street1.. " "..street2,
                    }, blipSettings)
                else
                    TriggerClientEvent("112:client:SendsheriffAlert", v, "flagged", {
                        camId = camId,
                        plate = plate,
                        streetLabel = street1
                    }, blipSettings)
                end
            end
        end
	end
end)

RegisterServerEvent('sheriff:server:sheriffAlertMessage')
AddEventHandler('sheriff:server:sheriffAlertMessage', function(title, streetLabel, coords)
    local src = source

    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty) then
                TriggerClientEvent("sheriff:client:sheriffAlertMessage", v, title, streetLabel, coords)
            elseif Player.Functions.GetItemByName("radioscanner") ~= nil and math.random(1, 100) <= 50 then
                TriggerClientEvent("sheriff:client:sheriffAlertMessage", v, title, streetLabel, coords)
            end
        end
    end
end)

RegisterServerEvent('sheriff:server:GunshotAlert')
AddEventHandler('sheriff:server:GunshotAlert', function(streetLabel, isAutomatic, fromVehicle, coords, vehicleInfo)
    local src = source

    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty) then
                TriggerClientEvent("sheriff:client:GunShotAlert", Player.PlayerData.source, streetLabel, isAutomatic, fromVehicle, coords, vehicleInfo)
            elseif Player.Functions.GetItemByName("radioscanner") ~= nil and math.random(1, 100) <= 50 then
                TriggerClientEvent("sheriff:client:GunShotAlert", Player.PlayerData.source, streetLabel, isAutomatic, fromVehicle, coords, vehicleInfo)
            end
        end
    end
end)

RegisterServerEvent('sheriff:server:VehicleCall')
AddEventHandler('sheriff:server:VehicleCall', function(pos, msg, alertTitle, streetLabel, modelPlate, modelName)
    local src = source
    local alertData = {
        title = "Vehicle theft",
        coords = {x = pos.x, y = pos.y, z = pos.z},
        description = msg,
    }
    TriggerClientEvent("sheriff:client:VehicleCall", -1, pos, alertTitle, streetLabel, modelPlate, modelName)
    TriggerClientEvent("qb-phone:client:addsheriffAlert", -1, alertData)
end)

RegisterServerEvent('sheriff:server:HouseRobberyCall')
AddEventHandler('sheriff:server:HouseRobberyCall', function(coords, message, gender, streetLabel)
    local src = source
    local alertData = {
        title = "Burglary",
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = message,
    }
    TriggerClientEvent("sheriff:client:HouseRobberyCall", -1, coords, message, gender, streetLabel)
    TriggerClientEvent("qb-phone:client:addsheriffAlert", -1, alertData)
end)

RegisterServerEvent('sheriff:server:SendEmergencyMessage')
AddEventHandler('sheriff:server:SendEmergencyMessage', function(coords, message)
    local src = source
    local MainPlayer = QBCore.Functions.GetPlayer(src)
    local alertData = {
        title = "911 alert - "..MainPlayer.PlayerData.charinfo.firstname .. " " .. MainPlayer.PlayerData.charinfo.lastname .. " ("..src..")",
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = message,
    }
    TriggerClientEvent("qb-phone:client:addsheriffAlert", -1, alertData)
    TriggerClientEvent('sheriff:server:SendEmergencyMessageCheck', -1, MainPlayer, message, coords)
end)

RegisterServerEvent('sheriff:server:SearchPlayer')
AddEventHandler('sheriff:server:SearchPlayer', function(playerId)
    local src = source
    local SearchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if SearchedPlayer ~= nil then 
        TriggerClientEvent('chatMessage', source, "SYSTEM", "warning", "Person has $"..SearchedPlayer.PlayerData.money["cash"]..",- on him..")
        TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, "You are being searched..")
    end
end)

RegisterServerEvent('sheriff:server:SeizeCash')
AddEventHandler('sheriff:server:SeizeCash', function(playerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local SearchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if SearchedPlayer ~= nil then 
        local moneyAmount = SearchedPlayer.PlayerData.money["cash"]
        local info = {
            cash = moneyAmount,
        }
        SearchedPlayer.Functions.RemoveMoney("cash", moneyAmount, "sheriff-cash-seized")
        Player.Functions.AddItem("moneybag", 1, false, info)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["moneybag"], "add")
        TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, "Your cash is confiscated..")
    end
end)

RegisterServerEvent('sheriff:server:SeizeDriverLicense')
AddEventHandler('sheriff:server:SeizeDriverLicense', function(playerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local SearchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if SearchedPlayer ~= nil then
        local driverLicense = SearchedPlayer.PlayerData.metadata["licences"]["driver"]
        if driverLicense then
            local licenses = {
                ["driver"] = false,
                ["business"] = SearchedPlayer.PlayerData.metadata["licences"]["business"]
            }
            SearchedPlayer.Functions.SetMetaData("licences", licenses)
            TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, "Your driving license has been confiscated..")
        else
            TriggerClientEvent('QBCore:Notify', src, "Can't confiscate driving license..", "error")
        end
    end
end)

RegisterServerEvent('sheriff:server:RobPlayer')
AddEventHandler('sheriff:server:RobPlayer', function(playerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local SearchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if SearchedPlayer ~= nil then 
        local money = SearchedPlayer.PlayerData.money["cash"]
        Player.Functions.AddMoney("cash", money, "sheriff-player-robbed")
        SearchedPlayer.Functions.RemoveMoney("cash", money, "sheriff-player-robbed")
        TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, "You have been robbed of $"..money)
	TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, "You have stolen $"..money)
    end
end)

RegisterServerEvent('sheriff:server:UpdateBlips')
AddEventHandler('sheriff:server:UpdateBlips', function()
	--KEEP FOR REF BUT NOT NEEDED ANYMORE.
end)

Citizen.CreateThread(function()
    while true do
      Citizen.Wait(5000)

      UpdateBlips()
    end
end)

function UpdateBlips()

  local dutyPlayers = {}
  for k, v in pairs(QBCore.Functions.GetPlayers()) do
      local Player = QBCore.Functions.GetPlayer(v)
      if Player ~= nil then
          if ((Player.PlayerData.job.name == "sheriff" or Player.PlayerData.job.name == "ambulance" or Player.PlayerData.job.name == "doctor") and Player.PlayerData.job.onduty) then
              
	      local coords = GetEntityCoords(GetPlayerPed(Player.PlayerData.source))
              local heading = GetEntityHeading(GetPlayerPed(Player.PlayerData.source))

              table.insert(dutyPlayers, {
                  source = Player.PlayerData.source,
                  label = Player.PlayerData.metadata["callsign"],
                  job = Player.PlayerData.job.name,
                  location = {x=coords.x,y=coords.y,z=coords.z,w=heading},
              })
          end
      end
  end
  TriggerClientEvent("sheriff:client:UpdateBlips", -1, dutyPlayers)

end

RegisterServerEvent('sheriff:server:spawnObject')
AddEventHandler('sheriff:server:spawnObject', function(type)
    local src = source
    local objectId = CreateObjectId()
    Objects[objectId] = type
    TriggerClientEvent("sheriff:client:spawnObject", src, objectId, type, src)
end)

RegisterServerEvent('sheriff:server:deleteObject')
AddEventHandler('sheriff:server:deleteObject', function(objectId)
    local src = source
    TriggerClientEvent('sheriff:client:removeObject', -1, objectId)
end)

RegisterServerEvent('sheriff:server:Impound')
AddEventHandler('sheriff:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local src = source
    local price = price ~= nil and price or 0
    if IsVehicleOwned(plate) then
        if not fullImpound then
            exports['ghmattimysql']:execute('UPDATE player_vehicles SET state = @state, depotprice = @depotprice, body = @body, engine = @engine, fuel = @fuel WHERE plate = @plate', {
                ['@state'] = 0, 
                ['@depotprice'] = price, 
                ['@plate'] = plate,
                ['@body'] = body, 
                ['@engine'] = engine, 
                ['@fuel'] = fuel
            })
            TriggerClientEvent('QBCore:Notify', src, "Vehicle taken into depot for $"..price.."!")
        else
            exports['ghmattimysql']:execute('UPDATE player_vehicles SET state = @state, body = @body, engine = @engine, fuel = @fuel WHERE plate = @plate', {
                ['@state'] = 2, 
                ['@plate'] = plate,
                ['@body'] = body, 
                ['@engine'] = engine, 
                ['@fuel'] = fuel
            })
            TriggerClientEvent('QBCore:Notify', src, "Vehicle completely seized!")
        end
    end
end)

RegisterServerEvent('sheriff:server:TakeOutImpound')
AddEventHandler('sheriff:server:TakeOutImpound', function(plate)
    local src = source       
    exports['ghmattimysql']:execute('UPDATE player_vehicles SET state = @state WHERE plate = @plate', {['@state'] = 0, ['@plate'] = plate})
    TriggerClientEvent('QBCore:Notify', src, "Vehicle is taken out of Impound!")
      
end)

RegisterServerEvent('evidence:server:UpdateStatus')
AddEventHandler('evidence:server:UpdateStatus', function(data)
    local src = source
    PlayerStatus[src] = data
end)

RegisterServerEvent('evidence:server:CreateBloodDrop')
AddEventHandler('evidence:server:CreateBloodDrop', function(citizenid, bloodtype, coords)
    local src = source
    local bloodId = CreateBloodId()
    BloodDrops[bloodId] = {dna = citizenid, bloodtype = bloodtype}
    TriggerClientEvent("evidence:client:AddBlooddrop", -1, bloodId, citizenid, bloodtype, coords)
end)

RegisterServerEvent('evidence:server:CreateFingerDrop')
AddEventHandler('evidence:server:CreateFingerDrop', function(coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local fingerId = CreateFingerId()
    FingerDrops[fingerId] = Player.PlayerData.metadata["fingerprint"]
    TriggerClientEvent("evidence:client:AddFingerPrint", -1, fingerId, Player.PlayerData.metadata["fingerprint"], coords)
end)

RegisterServerEvent('evidence:server:ClearBlooddrops')
AddEventHandler('evidence:server:ClearBlooddrops', function(blooddropList)
    if blooddropList ~= nil and next(blooddropList) ~= nil then 
        for k, v in pairs(blooddropList) do
            TriggerClientEvent("evidence:client:RemoveBlooddrop", -1, v)
            BloodDrops[v] = nil
        end
    end
end)

RegisterServerEvent('evidence:server:AddBlooddropToInventory')
AddEventHandler('evidence:server:AddBlooddropToInventory', function(bloodId, bloodInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem("empty_evidence_bag", 1) then
        if Player.Functions.AddItem("filled_evidence_bag", 1, false, bloodInfo) then
            TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items["filled_evidence_bag"], "add")
            TriggerClientEvent("evidence:client:RemoveBlooddrop", -1, bloodId)
            BloodDrops[bloodId] = nil
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You must have an empty evidence bag with you", "error")
    end
end)

RegisterServerEvent('evidence:server:AddFingerprintToInventory')
AddEventHandler('evidence:server:AddFingerprintToInventory', function(fingerId, fingerInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem("empty_evidence_bag", 1) then
        if Player.Functions.AddItem("filled_evidence_bag", 1, false, fingerInfo) then
            TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items["filled_evidence_bag"], "add")
            TriggerClientEvent("evidence:client:RemoveFingerprint", -1, fingerId)
            FingerDrops[fingerId] = nil
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You must have an empty evidence bag with you", "error")
    end
end)

RegisterServerEvent('evidence:server:CreateCasing')
AddEventHandler('evidence:server:CreateCasing', function(weapon, coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local casingId = CreateCasingId()
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    local serieNumber = nil
    if weaponInfo ~= nil then 
        local weaponItem = Player.Functions.GetItemByName(weaponInfo["name"])
        if weaponItem ~= nil then
            if weaponItem.info ~= nil and  weaponItem.info ~= "" then 
                serieNumber = weaponItem.info.serie
            end
        end
    end
    TriggerClientEvent("evidence:client:AddCasing", -1, casingId, weapon, coords, serieNumber)
end)


RegisterServerEvent('sheriff:server:UpdateCurrentCops')
AddEventHandler('sheriff:server:UpdateCurrentCops', function()
    local amount = 0
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty) then
                amount = amount + 1
            end
        end
    end
    TriggerClientEvent("sheriff:SetCopCount", -1, amount)
end)

RegisterServerEvent('evidence:server:ClearCasings')
AddEventHandler('evidence:server:ClearCasings', function(casingList)
    if casingList ~= nil and next(casingList) ~= nil then 
        for k, v in pairs(casingList) do
            TriggerClientEvent("evidence:client:RemoveCasing", -1, v)
            Casings[v] = nil
        end
    end
end)

RegisterServerEvent('evidence:server:AddCasingToInventory')
AddEventHandler('evidence:server:AddCasingToInventory', function(casingId, casingInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem("empty_evidence_bag", 1) then
        if Player.Functions.AddItem("filled_evidence_bag", 1, false, casingInfo) then
            TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items["filled_evidence_bag"], "add")
            TriggerClientEvent("evidence:client:RemoveCasing", -1, casingId)
            Casings[casingId] = nil
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You must have an empty evidence bag with you", "error")
    end
end)

RegisterServerEvent('sheriff:server:showFingerprint')
AddEventHandler('sheriff:server:showFingerprint', function(playerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(playerId)

    TriggerClientEvent('sheriff:client:showFingerprint', playerId, src)
    TriggerClientEvent('sheriff:client:showFingerprint', src, playerId)
end)

RegisterServerEvent('sheriff:server:showFingerprintId')
AddEventHandler('sheriff:server:showFingerprintId', function(sessionId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local fid = Player.PlayerData.metadata["fingerprint"]

    TriggerClientEvent('sheriff:client:showFingerprintId', sessionId, fid)
    TriggerClientEvent('sheriff:client:showFingerprintId', src, fid)
end)

RegisterServerEvent('sheriff:server:SetTracker')
AddEventHandler('sheriff:server:SetTracker', function(targetId)
    local Target = QBCore.Functions.GetPlayer(targetId)
    local TrackerMeta = Target.PlayerData.metadata["tracker"]

    if TrackerMeta then
        Target.Functions.SetMetaData("tracker", false)
        TriggerClientEvent('QBCore:Notify', targetId, 'Your anklet is taken off.', 'error', 5000)
        TriggerClientEvent('QBCore:Notify', source, 'You took off an ankle bracelet from '..Target.PlayerData.charinfo.firstname.." "..Target.PlayerData.charinfo.lastname, 'error', 5000)
        TriggerClientEvent('sheriff:client:SetTracker', targetId, false)
    else
        Target.Functions.SetMetaData("tracker", true)
        TriggerClientEvent('QBCore:Notify', targetId, 'You put on an ankle strap.', 'error', 5000)
        TriggerClientEvent('QBCore:Notify', source, 'You put on an ankle strap to '..Target.PlayerData.charinfo.firstname.." "..Target.PlayerData.charinfo.lastname, 'error', 5000)
        TriggerClientEvent('sheriff:client:SetTracker', targetId, true)
    end
end)

RegisterServerEvent('sheriff:server:SendTrackerLocation')
AddEventHandler('sheriff:server:SendTrackerLocation', function(coords, requestId)
    local Target = QBCore.Functions.GetPlayer(source)
    local TrackerMeta = Target.PlayerData.metadata["tracker"]

    local msg = "The location of "..Target.PlayerData.charinfo.firstname.." "..Target.PlayerData.charinfo.lastname.." is marked on your map."

    local alertData = {
        title = "Anklet location",
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = msg
    }

    TriggerClientEvent("sheriff:client:TrackerMessage", requestId, msg, coords)
    TriggerClientEvent("qb-phone:client:addsheriffAlert", requestId, alertData)
end)

--[[ RegisterServerEvent('sheriff:server:SendsheriffEmergencyAlert')
AddEventHandler('sheriff:server:SendsheriffEmergencyAlert', function(streetLabel, coords, callsign)
    local data = {
        displayCode = 10-99,
        description = "Emergency button pressed by ".. callsign .. " at "..streetLabel,
        isImportant = 1,
        recipientList = {'sheriff'},
        length = '10000',
        infoM = 'fa-info-circle',
        info = 'All Units Respond',
    }

    local dispatchData = {
        dispatchData = data,
        caller = callsign,
        coords = coords
    }
    TriggerEvent('wf-alerts:svNotify', dispatchData)
    --TriggerClientEvent("qb-phone:client:addsheriffAlert", -1, alertData)
end) ]]

QBCore.Functions.CreateCallback('sheriff:server:isPlayerDead', function(source, cb, playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    cb(Player.PlayerData.metadata["isdead"])
end)

QBCore.Functions.CreateCallback('sheriff:GetPlayerStatus', function(source, cb, playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    local statList = {}
	if Player ~= nil then
        if PlayerStatus[Player.PlayerData.source] ~= nil and next(PlayerStatus[Player.PlayerData.source]) ~= nil then
            for k, v in pairs(PlayerStatus[Player.PlayerData.source]) do
                table.insert(statList, PlayerStatus[Player.PlayerData.source][k].text)
            end
        end
	end
    cb(statList)
end)

QBCore.Functions.CreateCallback('sheriff:IsSilencedWeapon', function(source, cb, weapon)
    local Player = QBCore.Functions.GetPlayer(source)
    local itemInfo = Player.Functions.GetItemByName(QBCore.Shared.Weapons[weapon]["name"])
    local retval = false
    if itemInfo ~= nil then 
        if itemInfo.info ~= nil and itemInfo.info.attachments ~= nil then 
            for k, v in pairs(itemInfo.info.attachments) do
                if itemInfo.info.attachments[k].component == "COMPONENT_AT_AR_SUPP_02" or itemInfo.info.attachments[k].component == "COMPONENT_AT_AR_SUPP" or itemInfo.info.attachments[k].component == "COMPONENT_AT_PI_SUPP_02" or itemInfo.info.attachments[k].component == "COMPONENT_AT_PI_SUPP" then
                    retval = true
                end
            end
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('sheriff:GetDutyPlayers', function(source, cb)
    local dutyPlayers = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if ((Player.PlayerData.job.name == "sheriff" or Player.PlayerData.job.name == "ambulance") and Player.PlayerData.job.onduty) then
                table.insert(dutyPlayers, {
                    source = Player.PlayerData.source,
                    label = Player.PlayerData.metadata["callsign"],
                    job = Player.PlayerData.job.name,
                })
            end
        end
    end
    cb(dutyPlayers)
end)

function CreateBloodId()
    if BloodDrops ~= nil then
		local bloodId = math.random(10000, 99999)
		while BloodDrops[caseId] ~= nil do
			bloodId = math.random(10000, 99999)
		end
		return bloodId
	else
		local bloodId = math.random(10000, 99999)
		return bloodId
	end
end

function CreateFingerId()
    if FingerDrops ~= nil then
		local fingerId = math.random(10000, 99999)
		while FingerDrops[caseId] ~= nil do
			fingerId = math.random(10000, 99999)
		end
		return fingerId
	else
		local fingerId = math.random(10000, 99999)
		return fingerId
	end
end

function CreateCasingId()
    if Casings ~= nil then
		local caseId = math.random(10000, 99999)
		while Casings[caseId] ~= nil do
			caseId = math.random(10000, 99999)
		end
		return caseId
	else
		local caseId = math.random(10000, 99999)
		return caseId
	end
end

function CreateObjectId()
    if Objects ~= nil then
		local objectId = math.random(10000, 99999)
		while Objects[caseId] ~= nil do
			objectId = math.random(10000, 99999)
		end
		return objectId
	else
		local objectId = math.random(10000, 99999)
		return objectId
	end
end

function IsVehicleOwned(plate)
    local result = exports.ghmattimysql:scalarSync('SELECT plate FROM player_vehicles WHERE plate = @plate', {['@plate'] = plate})
    return result
end

QBCore.Functions.CreateCallback('sheriff:GetImpoundedVehicles', function(source, cb)
    local vehicles = {}
    exports['ghmattimysql']:execute('SELECT * FROM player_vehicles WHERE state = @state', {['@state'] = 2}, function(result)
        if result[1] ~= nil then
            vehicles = result
        end
        cb(vehicles)
    end)
end)

QBCore.Functions.CreateCallback('sheriff:IsPlateFlagged', function(source, cb, plate)
    local retval = false
    if Plates ~= nil and Plates[plate] ~= nil then
        if Plates[plate].isflagged then
            retval = true
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('sheriff:GetCops', function(source, cb)
    local amount = 0
    
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty) then
                amount = amount + 1
            end
        end
    end
	cb(amount)
end)

--[[ QBCore.Commands.Add("setsheriff", "Hire An Officer (sheriff Only)", {{name="id", help="Player ID"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local Myself = QBCore.Functions.GetPlayer(source)
    if Player ~= nil then 
        if (Myself.PlayerData.job.name == "sheriff" and Myself.PlayerData.job.onduty) and IsHighCommand(Myself.PlayerData.citizenid) then
            Player.Functions.SetJob("sheriff")
        end
    end
end) ]]

QBCore.Commands.Add("spikestrip", "Place Spike Strip (sheriff Only)", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player ~= nil then 
        if (Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty) then
            TriggerClientEvent('sheriff:client:SpawnSpikeStrip', source)
        end
    end
end)

QBCore.Commands.Add("grantlicense", "Grant a license to someone", {{name="id", help="ID of a person"},{name="license", help="License Type"}}, true, function(source, args)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.grade.level >= 2 then
        if args[2] == "driver" or args[2] == "weapon" then
            local SearchedPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
            if SearchedPlayer ~= nil then
                local licenseTable = SearchedPlayer.PlayerData.metadata["licences"]
                licenseTable[args[2]] = true
                SearchedPlayer.Functions.SetMetaData("licences", licenseTable)
                TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, "You have been granted a license", "success", 5000)
                TriggerClientEvent('QBCore:Notify', source, "You granted a license", "success", 5000)
            end
        else
            TriggerClientEvent('QBCore:Notify', source, "Invalid license type", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', source, "You must be a Sergeant to grant licenses!", "error")
    end
end)

QBCore.Commands.Add("revokelicense", "Revoke a license from someone", {{name="id", help="ID of a person"},{name="license", help="License Type"}}, true, function(source, args)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.grade.level >= 2 then
        if args[2] == "driver" or args[2] == "weapon" then
            local SearchedPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
            if SearchedPlayer ~= nil then
                local licenseTable = SearchedPlayer.PlayerData.metadata["licences"]
                licenseTable[args[2]] = false
                SearchedPlayer.Functions.SetMetaData("licences", licenseTable)
                TriggerClientEvent('QBCore:Notify', SearchedPlayer.PlayerData.source, "You've had a license revoked", "error", 5000)
                TriggerClientEvent('QBCore:Notify', source, "You revoked a license", "success", 5000)
            end
        else
            TriggerClientEvent('QBCore:Notify', source, "Invalid license type", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', source, "You must be a Sergeant to revoke licenses!", "error")
    end
end)


--[[ QBCore.Commands.Add("firesheriff", "Fire An Officer (sheriff Only)", {{name="id", help="Player ID"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local Myself = QBCore.Functions.GetPlayer(source)
    if Player ~= nil then 
        if (Myself.PlayerData.job.name == "sheriff" and Myself.PlayerData.job.onduty) and IsHighCommand(Myself.PlayerData.citizenid) then
            Player.Functions.SetJob("unemployed")
        end
    end
end) ]]

function IsHighCommand(citizenid)
    local retval = false
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
	if Player.PlayerData.job.grade.level >= 3 then
    	    retval = true
	end
    return retval
end



QBCore.Commands.Add("pobject", "Place/Delete An Object (sheriff Only)", {{name="type", help="Type object you want or 'delete' to delete"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    local type = args[1]:lower()
    if Player.PlayerData.job.name == "sheriff" then
        if type == "pion" then
            TriggerClientEvent("sheriff:client:spawnCone", source)
        elseif type == "barier" then
            TriggerClientEvent("sheriff:client:spawnBarier", source)
        elseif type == "schotten" then
            TriggerClientEvent("sheriff:client:spawnSchotten", source)
        elseif type == "tent" then
            TriggerClientEvent("sheriff:client:spawnTent", source)
        elseif type == "light" then
            TriggerClientEvent("sheriff:client:spawnLight", source)
        elseif type == "delete" then
            TriggerClientEvent("sheriff:client:deleteObject", source)
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("cuff", "Cuff Player (sheriff Only)", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("sheriff:client:CuffPlayer", source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("palert", "Make a sheriff alert", {{name="alert", help="The sheriff alert"}}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if (Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty) then
        if args[1] ~= nil then
            local msg = table.concat(args, " ")
            TriggerClientEvent("chatMessage", -1, "sheriff ALERT", "error", msg)
            TriggerEvent("qb-log:server:CreateLog", "palert", "sheriff alert", "blue", "**"..GetPlayerName(source).."** (CitizenID: "..Player.PlayerData.citizenid.." | ID: "..source..") **Alert:** " ..msg, false)
            TriggerClientEvent('sheriff:PlaySound', -1)
        else
            TriggerClientEvent('chatMessage', source, "SYSTEM", "error", "You must enter message!")
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("escort", "Escort Player", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent("sheriff:client:EscortPlayer", source)
end)

--QBCore.Commands.Add("mdt", "Open MDT (sheriff Only)", {}, false, function(source, args)
--	local Player = QBCore.Functions.GetPlayer(source)
--    if Player.PlayerData.job.name == "sheriff" then
--        TriggerClientEvent("sheriff:client:toggleDatabank", source)
--    else
--        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
--    end
--end)

QBCore.Commands.Add("callsign", "Give Yourself A Callsign", {{name="name", help="Name of your callsign"}}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.SetMetaData("callsign", table.concat(args, " "))
end)

QBCore.Commands.Add("clearcasings", "Clear Area of Casings (sheriff Only)", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("evidence:client:ClearCasingsInArea", source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("jail", "Jail Player (sheriff Only)", {{name="id", help="Player ID"},{name="time", help="Time they have to be in jail"}}, true, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        local playerId = tonumber(args[1])
        local time = tonumber(args[2])
        if time > 0 then
            TriggerClientEvent("sheriff:client:JailCommand", source, playerId, time)
        else
            TriggerClientEvent('chatMessage', source, "SYSTEM", "error", "Time must be higher then 0")
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("unjail", "Unjail Player (sheriff Only)", {{name="id", help="Player ID"}}, true, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        local playerId = tonumber(args[1])
        TriggerClientEvent("prison:client:UnjailPerson", playerId)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("clearblood", "Clear The Area of Blood (sheriff Only)", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("evidence:client:ClearBlooddropsInArea", source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("seizecash", "Seize Cash (sheriff Only)", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty then
        TriggerClientEvent("sheriff:client:SeizeCash", source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("sc", "Soft Cuff (sheriff Only)", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("sheriff:client:CuffPlayerSoft", source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("cam", "View Security Camera (sheriff Only)", {{name="camid", help="Camera ID"}}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("sheriff:client:ActiveCamera", source, tonumber(args[1]))
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("flagplate", "Flag A Plate (sheriff Only)", {{name="plate", help="License"}, {name="reason", help="Reason of flagging the vehicle"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player.PlayerData.job.name == "sheriff" then
        local reason = {}
        for i = 2, #args, 1 do
            table.insert(reason, args[i])
        end
        Plates[args[1]:upper()] = {
            isflagged = true,
            reason = table.concat(reason, " ")
        }
        TriggerClientEvent('QBCore:Notify', source, "Vehicle ("..args[1]:upper()..") is flagged for: "..table.concat(reason, " "))
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("unflagplate", "Unflag A Plate (sheriff Only)", {{name="plate", help="License plate"}}, true, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        if Plates ~= nil and Plates[args[1]:upper()] ~= nil then
            if Plates[args[1]:upper()].isflagged then
                Plates[args[1]:upper()].isflagged = false
                TriggerClientEvent('QBCore:Notify', source, "Vehicle ("..args[1]:upper()..") is unflagged")
            else
                TriggerClientEvent('chatMessage', source, "REPORTING ROOM", "error", "Vehicle is not flagged!")
            end
        else
            TriggerClientEvent('chatMessage', source, "SYSTEM", "error", "Vehicle is not flagged!")
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("plateinfo", "Run A Plate (sheriff Only)", {{name="plate", help="License plate"}}, true, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        if Plates ~= nil and Plates[args[1]:upper()] ~= nil then
            if Plates[args[1]:upper()].isflagged then
                TriggerClientEvent('chatMessage', source, "REPORTING ROOM", "normal", "Vehicle ("..args[1]:upper()..") has been flagged for: "..Plates[args[1]:upper()].reason)
            else
                TriggerClientEvent('chatMessage', source, "SYSTEM", "error", "Vehicle is not flagged!")
            end
        else
            TriggerClientEvent('chatMessage', source, "SYSTEM", "error", "Vehicle is not flagged!")
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("depot", "Impound With Price (sheriff Only)", {{name="price", help="Price for how much the person has to pay (may be empty)"}}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("sheriff:client:ImpoundVehicle", source, false, tonumber(args[1]))
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("impound", "Impound A Vehicle (sheriff Only)", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("sheriff:client:ImpoundVehicle", source, true)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("paytow", "Pay Tow Driver (sheriff, EMS Only)", {{name="id", help="ID of the player"}}, true, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" or Player.PlayerData.job.name == "ambulance" then
        local playerId = tonumber(args[1])
        local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
        if OtherPlayer ~= nil then
            if OtherPlayer.PlayerData.job.name == "tow" then
                OtherPlayer.Functions.AddMoney("bank", 500, "sheriff-tow-paid")
                TriggerClientEvent('chatMessage', OtherPlayer.PlayerData.source, "SYSTEM", "warning", "You received $ 500 for your service!")
                TriggerClientEvent('QBCore:Notify', source, 'You paid a bergnet worker')
            else
                TriggerClientEvent('QBCore:Notify', source, 'Person is not a bergnet worker', "error")
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("paylawyer", "Pay Lawyer (sheriff, Judge Only)", {{name="id", help="ID of the player"}}, true, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" or Player.PlayerData.job.name == "judge" then
        local playerId = tonumber(args[1])
        local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
        if OtherPlayer ~= nil then
            if OtherPlayer.PlayerData.job.name == "lawyer" then
                OtherPlayer.Functions.AddMoney("bank", 500, "sheriff-lawyer-paid")
                TriggerClientEvent('chatMessage', OtherPlayer.PlayerData.source, "SYSTEM", "warning", "You received $ 500 for your pro bono case!")
                TriggerClientEvent('QBCore:Notify', source, 'You paid a lawyer')
            else
                TriggerClientEvent('QBCore:Notify', source, 'Person is not a lawyer', "error")
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("radar", "Enable sheriff Radar (sheriff Only)", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("wk:toggleRadar", source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Functions.CreateUseableItem("handcuffs", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.GetItemBySlot(item.slot) ~= nil then
        TriggerClientEvent("sheriff:client:CuffPlayerSoft", source)
    end
end)

QBCore.Commands.Add("911", "Send a report to emergency services", {{name="message", help="Message you want to send"}}, true, function(source, args)
    local message = table.concat(args, " ")
    local Player = QBCore.Functions.GetPlayer(source)

    if Player.Functions.GetItemByName("phone") ~= nil then
        TriggerClientEvent("sheriff:client:SendEmergencyMessage", source, message)
        TriggerEvent("qb-log:server:CreateLog", "911", "911 alert", "blue", "**"..GetPlayerName(source).."** (CitizenID: "..Player.PlayerData.citizenid.." | ID: "..source..") **Alert:** " ..message, false)
    else
        TriggerClientEvent('QBCore:Notify', source, 'You dont have a phone', 'error')
    end
end)

QBCore.Commands.Add("911a", "Send an anonymous report to emergency services (gives no location)", {{name="message", help="Message you want to send"}}, true, function(source, args)
    local message = table.concat(args, " ")
    local Player = QBCore.Functions.GetPlayer(source)

    if Player.Functions.GetItemByName("phone") ~= nil then
        TriggerClientEvent("sheriff:client:CallAnim", source)
        TriggerClientEvent('sheriff:client:Send112AMessage', -1, message)
    else
        TriggerClientEvent('QBCore:Notify', source, 'You dont have a phone', 'error')
    end
end)

QBCore.Commands.Add("911r", "Send a message back to a alert", {{name="id", help="ID of the alert"}, {name="message", help="Message you want to send"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    local OtherPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
    table.remove(args, 1)
    local message = table.concat(args, " ")
    local Prefix = "sheriff"
    if (Player.PlayerData.job.name == "ambulance" or Player.PlayerData.job.name == "doctor") then
        Prefix = "AMBULANCE"
    end
    if OtherPlayer ~= nil then 
        TriggerClientEvent('chatMessage', OtherPlayer.PlayerData.source, "("..Prefix..") " ..Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, "error", message)
        TriggerClientEvent("sheriff:client:EmergencySound", OtherPlayer.PlayerData.source)
        TriggerClientEvent("sheriff:client:CallAnim", source)
    end
end)

QBCore.Commands.Add("anklet", "Attach Tracking Anklet (sheriff Only)", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player.PlayerData.job.name == "sheriff" then
        TriggerClientEvent("sheriff:client:CheckDistance", source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("ankletlocation", "Get the location of a persons anklet", {{"csn", "CSN of the person"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player.PlayerData.job.name == "sheriff" then
        if args[1] ~= nil then
            local citizenid = args[1]
            local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)

            if Target ~= nil then
                if Target.PlayerData.metadata["tracker"] then
                    TriggerClientEvent("sheriff:client:SendTrackerLocation", Target.PlayerData.source, source)
                else
                    TriggerClientEvent('QBCore:Notify', source, 'This person doesn\'t have an anklet on.', 'error')
                end
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("removeanklet", "Remove Tracking Anklet (sheriff Only)", {{"bsn", "BSN of person"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player.PlayerData.job.name == "sheriff" then
        if args[1] ~= nil then
            local citizenid = args[1]
            local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)

            if Target ~= nil then
                if Target.PlayerData.metadata["tracker"] then
                    TriggerClientEvent("sheriff:client:SendTrackerLocation", Target.PlayerData.source, source)
                else
                    TriggerClientEvent('QBCore:Notify', source, 'This person does not have an anklet', 'error')
                end
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Emergency Services Only', 'error')
    end
end)

QBCore.Commands.Add("ebutton", "Respond To A Call (sheriff, EMS, Mechanic Only)", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if ((Player.PlayerData.job.name == "sheriff" or Player.PlayerData.job.name == "ambulance" or Player.PlayerData.job.name == "doctor") and Player.PlayerData.job.onduty) then
        TriggerClientEvent("sheriff:client:SendsheriffEmergencyAlert", source)
    end
end)

QBCore.Commands.Add("takedrivinglicense", "Seize Drivers License (sheriff Only)", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if ((Player.PlayerData.job.name == "sheriff") and Player.PlayerData.job.onduty) then
        TriggerClientEvent("sheriff:client:SeizeDriverLicense", source)
    end
end)

QBCore.Commands.Add("takedna", "Take a DNA sanple from a person (empty evidence bag needed) (sheriff Only)", {{"id", "ID of the person"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    local OtherPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if ((Player.PlayerData.job.name == "sheriff") and Player.PlayerData.job.onduty) and OtherPlayer ~= nil then
        if Player.Functions.RemoveItem("empty_evidence_bag", 1) then
            local info = {
                label = "DNA Sample",
                type = "dna",
                dnalabel = DnaHash(OtherPlayer.PlayerData.citizenid),
            }
            if Player.Functions.AddItem("filled_evidence_bag", 1, false, info) then
                TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["filled_evidence_bag"], "add")
            end
        else
            TriggerClientEvent('QBCore:Notify', source, "You must have an empty evidence bag with you", "error")
        end
    end
end)

QBCore.Functions.CreateUseableItem("moneybag", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.Functions.GetItemBySlot(item.slot) ~= nil then
        if item.info ~= nil and item.info ~= "" then
            if Player.PlayerData.job.name ~= "sheriff" then
                if Player.Functions.RemoveItem("moneybag", 1, item.slot) then
                    Player.Functions.AddMoney("cash", tonumber(item.info.cash), "used-moneybag")
                end
            end
        end
    end
end)

function GetCurrentCops()
    local amount = 0
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.onduty) then
                amount = amount + 1
            end
        end
    end
    return amount
end

QBCore.Functions.CreateCallback('sheriff:server:IssheriffForcePresent', function(source, cb)
    local retval = false
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if Player.PlayerData.job.name == "sheriff" and Player.PlayerData.job.grade.level >= 2 then
	    	retval = true
	    	break
            end
        end
    end
    cb(retval)
end)

function DnaHash(s)
    local h = string.gsub(s, ".", function(c)
		return string.format("%02x", string.byte(c))
	end)
    return h
end

RegisterServerEvent('sheriff:server:SyncSpikes')
AddEventHandler('sheriff:server:SyncSpikes', function(table)
    TriggerClientEvent('sheriff:client:SyncSpikes', -1, table)
end)
