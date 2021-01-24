ESX = nil

local vehicles = {}
local searchedVehicles = {}
local pickedVehicled = {}
local hasCheckedOwnedVehs = false
local lockDisable = false
local pixelTimer = 5000
local pcoords = nil
local pixelMark = false
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
end)
local vehicleTest = {}
function givePlayerKeys(plate)
    local vehPlate = plate
    table.insert(vehicles, vehPlate)
    vehicleTest[vehPlate] = vehPlate
end      

--[[RegisterNetEvent('giveKeys')
AddEventHandler('giveKeys', function(source)
    if IsPedSittingInAnyVehicle(PlayerPedId()) then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local plate = GetVehicleNumberPlateText(vehicle)
        ESX.TriggerServerCallback('esx_outlawalert:isVehicleOwnerSecondary', function(owner)
            if owner then
                givePlayerKeys(plate)
            end
        end,plate, source)
    else
        local vehicle, distance = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        if vehicle > -1 or distance > 1.5 then
            local plate = GetVehicleNumberPlateText(vehicle)
            ESX.TriggerServerCallback('esx_outlawalert:isVehicleOwnerSecondary', function(owner)
                if owner then
                    givePlayerKeys(plate)
                end
            end,plate,source)
        end
    end
end)]]--

RegisterNetEvent('giveKeys')
AddEventHandler('giveKeys', function(source,carPlate)
    if carPlate ~= nil then
        givePlayerKeys(carPlate)
    end
end)

RegisterCommand('aracanahtar', function()
    local carPlate = nil
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if IsPedSittingInAnyVehicle(PlayerPedId()) then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local plate = GetVehicleNumberPlateText(vehicle)
        if vehicleTest[plate] == plate then
            if closestPlayer > -1 or closestDistance > 1.5 then

            carPlate = plate
            exports['mythic_notify']:DoHudText('inform', 'Araç anahtarları verildi')
        else
            exports['mythic_notify']:DoHudText('inform', 'Aracın anahtarı yok')

        end
    end
    else
        local vehicle, distance = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        if vehicle > -1 or distance > 1.5 then
            local plate = GetVehicleNumberPlateText(vehicle)
                if vehicleTest[plate] == plate then
                    if closestPlayer > -1 or closestDistance > 1.5 then

                    carPlate = plate
                    exports['mythic_notify']:DoHudText('inform', 'Araç anahtarları verildi')
                else
                    exports['mythic_notify']:DoHudText('inform', 'Aracın anahtarı yok')
                end
            end
        end
    end
    Citizen.Wait(150)
    if closestPlayer > -1 or closestDistance > 1.5 then
        TriggerServerEvent('server-givekeys', GetPlayerServerId(closestPlayer),carPlate)
    end
end)


function hasToggledLock()
    lockDisable = true
    Wait(100)
    lockDisable = false
end

function playLockAnim(vehicle)
    local dict = "anim@mp_player_intmenu@key_fob@"
    RequestAnimDict(dict)

    local veh = vehicle

    while not HasAnimDictLoaded do
        Citizen.Wait(0)
    end

    if not IsPedInAnyVehicle(GetPlayerPed(-1), true) then
        TaskPlayAnim(PlayerPedId(), dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
    end
end

function toggleLock(vehicle)
    local veh = vehicle

    local plate = GetVehicleNumberPlateText(veh)
    local lockStatus = GetVehicleDoorLockStatus(veh)
    if hasKeys(plate) and not lockDisable then
        playLockAnim()
        if lockStatus == 1 then
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleDoorsLockedForAllPlayers(veh, true)
            exports['mythic_notify']:DoHudText('inform', 'Araç Kilitlendi')
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 4.0, 'car_lock', 0.35)

           
        
        elseif lockStatus == 2 then
            SetVehicleDoorsLocked(veh, 1)
            SetVehicleDoorsLockedForAllPlayers(veh, false)
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 4.0, 'car_unlock', 0.35)

            exports['mythic_notify']:DoHudText('inform', 'Araç Açıldı')
        
        
        else
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleDoorsLockedForAllPlayers(veh, true)
            exports['mythic_notify']:DoHudText('inform', 'Araç Kilitlendi')
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 4.0, 'car_lock', 0.35)
        
        end
    end
end

RegisterNetEvent('onyx:pickDoor')
AddEventHandler('onyx:pickDoor', function()
    -- TODO: Lockpicking vehicle doors to gain access
end)

-- Locking vehicles
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local pos = GetEntityCoords(GetPlayerPed(-1))
        if IsControlJustReleased(0, 182) then
            if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                local veh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
                toggleLock(veh)
            else
                local veh,distance = ESX.Game.GetClosestVehicle(pos)
                if DoesEntityExist(veh) then
                    toggleLock(veh)
                end
            end
        end

        -- TODO: Unable to gain access to vehicles without a lockpick or keys
        -- local enteringVeh = GetVehiclePedIsTryingToEnter(GetPlayerPed(-1))
        -- local enteringPlate = GetVehicleNumberPlateText(enteringVeh)

        -- if not hasKeys(entertingPlate) then
        --     SetVehicleDoorsLocked(enteringVeh, 2)
        -- end
    end
end)

local isSearching = false
local isHotwiring = false

-- Has entered vehicle without keys
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = GetPlayerPed(-1)
        if IsPedInAnyVehicle(ped, false) then
    
            local veh = GetVehiclePedIsIn(ped)
            local driver = GetPedInVehicleSeat(veh, -1)
            local plate = GetVehicleNumberPlateText(veh)
          
            if not IsEntityAMissionEntity(veh) then
                if GetVehicleClass(veh) ~= 7 and GetVehicleClass(veh) ~= 10 and GetVehicleClass(veh) ~= 20 and GetVehicleClass(veh) ~= 6 then
             
                    if driver == ped then
                        if not hasKeys(plate) and not isHotwiring and not isSearching then
                            local pos = GetEntityCoords(ped)
                            if hasBeenSearched(plate) then
                                DrawText3Ds(pos.x, pos.y, pos.z + 0.2, '~y~[H]~w~ - Maymuncuk | ~y~[E]~w~ - Düz Kontak')
                            else
                                DrawText3Ds(pos.x, pos.y, pos.z + 0.2, '~y~[H]~w~ - Maymuncuk | ~y~[E]~w~ - Düz Kontak | ~g~[G]~w~ - Ara')
                            end
                            SetVehicleEngineOn(veh, false, true, true)
                            -- Searching
                            if IsControlJustReleased(0, 47) and not isSearching and not hasBeenSearched(plate) then -- G
                                if hasBeenSearched(plate) then
                                    isSearching = true
                                    exports["np-taskbar"]:taskBar(5000, "Araç Aranıyor.")

                                    isSearching = false
                                    exports['mythic_notify']:DoHudText('error', 'Aracı aradın ve bir şey bulamadın')
                                else
                                    local rnd = math.random(1, 8)
                                    if rnd == 4 then
                                        isSearching = true
                                        exports["np-taskbar"]:taskBar(6000, "Araç Aranıyor.")
                                        isSearching = false
                                        exports['mythic_notify']:DoHudText('inform', " [" .. plate .. '] Plakalı aracın anahtarını buldun')

                                        table.insert(vehicles, plate)
                                        TriggerServerEvent('onyx:updateSearchedVehTable', plate)
                                        table.insert(searchedVehicles, plate)
                                    else
                                        isSearching = true
                                        exports["np-taskbar"]:taskBar(6000, "Araç Aranıyor.")

                                        isSearching = false
                                        exports['mythic_notify']:DoHudText('error', 'Aracı aradın ve bir şey bulamadın')

                                        -- Update veh table so other players cant search the same vehicle
                                        TriggerServerEvent('onyx:updateSearchedVehTable', plate)
                                        table.insert(searchedVehicles, plate)
                                    end
                                end
                            end
                            -- Hotwiring
                            if IsControlJustReleased(0, 74) and not isHotwiring then -- E
                                TriggerServerEvent('onyx:reqHotwiring', plate)
                            end
                            if IsControlJustPressed(0,38) and not isHotwiring then
                                TriggerEvent('onyx:beginHotwire2', plate)
                            end
                        else
                        end
                    end
                else
          

                    if not IsEntityAMissionEntity(veh) then
                        if driver == ped then
                            if not hasKeys(plate) and not isHotwiring and not isSearching then
                                local pos = GetEntityCoords(ped)
                                if hasBeenSearched(plate) then
                                    DrawText3Ds(pos.x, pos.y, pos.z + 0.2, '~y~[H]~w~ - Gelismis Maymuncuk')
                                else
                                    DrawText3Ds(pos.x, pos.y, pos.z + 0.2, '~y~[H]~w~ - Gelismis Maymuncuk |  ~g~[G]~w~ - Ara')
                                end
                                SetVehicleEngineOn(veh, false, true, true)
                                -- Searching
                                if IsControlJustReleased(0, 47) and not isSearching and not hasBeenSearched(plate) then -- G
                                    if hasBeenSearched(plate) then
                                        isSearching = true
                                        exports["np-taskbar"]:taskBar(5000, "Araç Aranıyor.")
    
                                        isSearching = false
                                        exports['mythic_notify']:DoHudText('error', 'Aracı aradın ve bir şey bulamadın')
                                    else
                                        local rnd = math.random(1, 8)
                                        if rnd == 4 then
                                            isSearching = true
                                            exports["np-taskbar"]:taskBar(6000, "Araç Aranıyor.")
                                            isSearching = false
                                            exports['mythic_notify']:DoHudText('inform', " [" .. plate .. '] Plakalı aracın anahtarını buldun')
    
                                            table.insert(vehicles, plate)
                                            TriggerServerEvent('onyx:updateSearchedVehTable', plate)
                                            table.insert(searchedVehicles, plate)
                                        else
                                            isSearching = true
                                            exports["np-taskbar"]:taskBar(6000, "Araç Aranıyor.")
    
                                            isSearching = false
                                            exports['mythic_notify']:DoHudText('error', 'Aracı aradın ve bir şey bulamadın')
    
                                            -- Update veh table so other players cant search the same vehicle
                                            TriggerServerEvent('onyx:updateSearchedVehTable', plate)
                                            table.insert(searchedVehicles, plate)
                                        end
                                    end
                                end
                                -- Hotwiring
                                if IsControlJustReleased(0, 74) and not isHotwiring then -- E
                                    TriggerServerEvent('onyx:reqHotwiring3', plate)
                                end
                      
                            else
                            end
                        end
                    end
                end
                else

                    if not GetIsVehicleEngineRunning(veh) then
                        if driver == ped then
                            if not hasKeys(plate) and not isHotwiring and not isSearching then
                                local pos = GetEntityCoords(ped)
                                if hasBeenSearched(plate) then
                                    DrawText3Ds(pos.x, pos.y, pos.z + 0.2, '~y~[H]~w~ - Maymuncuk | ~y~[E]~w~ - Düz Kontak')
                                else
                                    DrawText3Ds(pos.x, pos.y, pos.z + 0.2, '~y~[H]~w~ - Maymuncuk | ~y~[E]~w~ - Düz Kontak | ~g~[G]~w~ - Ara')
                                end
                                SetVehicleEngineOn(veh, false, true, true)
                                -- Searching
                                if IsControlJustReleased(0, 47) and not isSearching and not hasBeenSearched(plate) then -- G
                                    if hasBeenSearched(plate) then
                                        isSearching = true
                                        exports["np-taskbar"]:taskBar(5000, "Araç Aranıyor.")
    
                                        isSearching = false
                                        exports['mythic_notify']:DoHudText('error', 'Aracı aradın ve bir şey bulamadın')
                                    else
                                        local rnd = math.random(1, 8)
                                        if rnd == 4 then
                                            isSearching = true
                                            exports["np-taskbar"]:taskBar(6000, "Araç Aranıyor.")
                                            isSearching = false
                                            exports['mythic_notify']:DoHudText('inform', " [" .. plate .. '] Plakalı aracın anahtarını buldun')
    
                                            table.insert(vehicles, plate)
                                            TriggerServerEvent('onyx:updateSearchedVehTable', plate)
                                            table.insert(searchedVehicles, plate)
                                        else
                                            isSearching = true
                                            exports["np-taskbar"]:taskBar(6000, "Araç Aranıyor.")
    
                                            isSearching = false
                                            exports['mythic_notify']:DoHudText('error', 'Aracı aradın ve bir şey bulamadın')
    
                                            -- Update veh table so other players cant search the same vehicle
                                            TriggerServerEvent('onyx:updateSearchedVehTable', plate)
                                            table.insert(searchedVehicles, plate)
                                        end
                                    end
                                end
                                -- Hotwiring
                                if IsControlJustReleased(0, 74) and not isHotwiring then -- E
                                    TriggerServerEvent('onyx:reqHotwiring', plate)
                                end
                                if IsControlJustPressed(0,38) and not isHotwiring then
                                    TriggerEvent('onyx:beginHotwire2', plate)
                                end
                            else
                            end
                        end
                    end
                end
        
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isHotwiring then
            DisableControlAction(0, 75, true)  -- Disable exit vehicle
            DisableControlAction(0, 74, true)  -- Lights
        end
    end
end)

RegisterNetEvent('onyx:updatePlates')
AddEventHandler('onyx:updatePlates', function(plate)
    table.insert(vehicles, plate)
end)
local streetName,street2
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(3000)

		local playerCoords = GetEntityCoords(PlayerPedId())
		streetName,street2 = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
		streetName = GetStreetNameFromHashKey(streetName)..' | '..GetStreetNameFromHashKey(street2)
	end
end)
RegisterNetEvent('onyx:beginHotwire2')
AddEventHandler('onyx:beginHotwire2', function(plate)
    local veh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    local vehicleLabel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    vehicleLabel = GetLabelText(vehicleLabel)
    local inVeh = {'Yaya', ''}

    TriggerServerEvent('esx_outlawalert:carJackInProgress', {
        x = ESX.Math.Round(playerCoords.x, 1),
        y = ESX.Math.Round(playerCoords.y, 1),
        z = ESX.Math.Round(playerCoords.z, 1)
    }, streetName, vehicleLabel, "Bilinmiyor",inVeh)
    RequestAnimDict("veh@std@ds@base")
    pixelMark = true
    pixelTimer = 500
    pcoords = playerCoords
    while not HasAnimDictLoaded("veh@std@ds@base") do
        Citizen.Wait(100)
	end
    local time = 3500 -- in ms

    local vehPlate = plate
    isHotwiring = true

    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleLights(veh, 0)
    
    if Config.HotwireAlarmEnabled then
        local alarmChance = math.random(1, Config.HotwireAlarmChance)

        if alarmChance == 1 then
            SetVehicleAlarm(veh, true)
            StartVehicleAlarm(veh)
        end
    end
    TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.3, true, true, true)
    exports["np-taskbar"]:taskBar(time, "[Aşama 1]")
    local finished = exports['reload-skillbar']:taskBar(2800,math.random(3,8))
    if finished ~= 100 then
        exports['mythic_notify']:DoHudText('error', 'Başarısız oldun')
        StopAnimTask(PlayerPedId(), 'veh@std@ds@base', 'hotwire', 1.0)
        ClearPedTasks(PlayerPedId())
        isHotwiring = false
        --TriggerEvent('notification', 'Failed', 2)
    else
        --local finished2 = exports["reload-skillbar"]:taskBar(6000,math.random(5,15))
        TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.4, true, true, true)
        exports["np-taskbar"]:taskBar(time, "[Aşama 2]")
        local finished2 = exports['reload-skillbar']:taskBar(2800,math.random(3,8))
        if finished2 ~= 100 then
            exports['mythic_notify']:DoHudText('error', 'Başarısız oldun')
            StopAnimTask(PlayerPedId(), 'veh@std@ds@base', 'hotwire', 1.0)
            ClearPedTasks(PlayerPedId())
            isHotwiring = false

            --TriggerEvent('notification', 'Failed', 2)
        else
            --local finished3 = exports["reload-skillbar"]:taskBar(6000,math.random(5,15))
            TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.6, true, true, true)
            exports["np-taskbar"]:taskBar(time, "[Aşama 3]")
            local finished3 = exports['reload-skillbar']:taskBar(2800,math.random(3,8))
            if finished3 ~= 100 then
                exports['mythic_notify']:DoHudText('error', 'Başarısız oldun')
                StopAnimTask(PlayerPedId(), 'veh@std@ds@base', 'hotwire', 1.0)
                ClearPedTasks(PlayerPedId())
                isHotwiring = false
                --TriggerEvent('notification', 'Failed', 2)
            else
       
                table.insert(vehicles, vehPlate)
                exports['mythic_notify']:DoHudText('inform', 'Aracın anahtarlarını aldın')
                isHotwiring = false
                SetVehicleEngineOn(veh, true, true, false)
                StopAnimTask(PlayerPedId(), 'veh@std@ds@base', 'hotwire', 1.0)
                ClearPedTasks(PlayerPedId())
            end
        end
    end




end)

Citizen.CreateThread(function()
	while true do
		if pixelMark then
			pixelTimer = pixelTimer-1
			if(IsControlJustPressed(0, 206)) then
				SetNewWaypoint(pcoords.x, pcoords.y)
				PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
				pixelMark = false
				pixelTimer = 0
			end
			if(pixelTimer == 0) then 
				pixelMark = false
			end
		end
		Citizen.Wait(1)
	end
end)


RegisterNetEvent('onyx:beginHotwire3')
AddEventHandler('onyx:beginHotwire3', function(plate)
    local veh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicle = GetVehiclePedIsIn(playerPed, true)
    local vehicleLabel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    vehicleLabel = GetLabelText(vehicleLabel)
    TriggerServerEvent('esx_outlawalert:carJackInProgress', {
        x = ESX.Math.Round(playerCoords.x, 1),
        y = ESX.Math.Round(playerCoords.y, 1),
        z = ESX.Math.Round(playerCoords.z, 1)
    }, streetName, vehicleLabel, "Bilinmiyor")
    RequestAnimDict("veh@std@ds@base")
    pixelMark = true
    pixelTimer = 500
    pcoords = playerCoords
    while not HasAnimDictLoaded("veh@std@ds@base") do
        Citizen.Wait(100)
	end
    local time = 6000 -- in ms

    local vehPlate = plate
    isHotwiring = true

    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleLights(veh, 0)
    
    if Config.HotwireAlarmEnabled then
        local alarmChance = math.random(1, Config.HotwireAlarmChance)

        if alarmChance == 1 then
            SetVehicleAlarm(veh, true)
            StartVehicleAlarm(veh)
        end
    end
    TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.3, true, true, true)
    exports["np-taskbar"]:taskBar(time, "[Aşama 1]")
    TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.6, true, true, true)

    exports["np-taskbar"]:taskBar(time, "[Aşama 2]")
    TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.4, true, true, true)
    exports["np-taskbar"]:taskBar(time, "[Aşama 3]")
    table.insert(vehicles, vehPlate)
    StopAnimTask(PlayerPedId(), 'veh@std@ds@base', 'hotwire', 1.0)
    ClearPedTasks(PlayerPedId())
    isHotwiring = false
    SetVehicleEngineOn(veh, true, true, false)
end)

RegisterNetEvent('onyx:beginHotwire')
AddEventHandler('onyx:beginHotwire', function(plate)
    local veh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicle = GetVehiclePedIsIn(playerPed, true)
    local vehicleLabel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    vehicleLabel = GetLabelText(vehicleLabel)
    TriggerServerEvent('esx_outlawalert:carJackInProgress', {
        x = ESX.Math.Round(playerCoords.x, 1),
        y = ESX.Math.Round(playerCoords.y, 1),
        z = ESX.Math.Round(playerCoords.z, 1)
    }, streetName, vehicleLabel, "Bilinmiyor")
    RequestAnimDict("veh@std@ds@base")
    pixelMark = true
    pixelTimer = 500
    pcoords = playerCoords
    while not HasAnimDictLoaded("veh@std@ds@base") do
        Citizen.Wait(100)
	end
    local time = 6000 -- in ms

    local vehPlate = plate
    isHotwiring = true

    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleLights(veh, 0)
    
    if Config.HotwireAlarmEnabled then
        local alarmChance = math.random(1, Config.HotwireAlarmChance)

        if alarmChance == 1 then
            SetVehicleAlarm(veh, true)
            StartVehicleAlarm(veh)
        end
    end
    TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.3, true, true, true)
    exports["np-taskbar"]:taskBar(time, "[Aşama 1]")
    TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.6, true, true, true)

    exports["np-taskbar"]:taskBar(time, "[Aşama 2]")
    TaskPlayAnim(PlayerPedId(), "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0.4, true, true, true)
    exports["np-taskbar"]:taskBar(time, "[Aşama 3]")
    table.insert(vehicles, vehPlate)
    StopAnimTask(PlayerPedId(), 'veh@std@ds@base', 'hotwire', 1.0)
    ClearPedTasks(PlayerPedId())
    isHotwiring = false
    SetVehicleEngineOn(veh, true, true, false)
end)

local isRobbing = false
local canRob = false
local prevPed = false
local prevCar = false
local pressed = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local foundEnt, aimingEnt = GetEntityPlayerIsFreeAimingAt(PlayerId())
        local entPos = GetEntityCoords(aimingEnt)
        local pos = GetEntityCoords(GetPlayerPed(-1))
        local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, entPos.x, entPos.y, entPos.z, true)

        if foundEnt and prevPed ~= aimingEnt and IsPedInAnyVehicle(aimingEnt, false) and IsPedArmed(PlayerPedId(), 7) and dist < 20.0 and not IsPedInAnyVehicle(PlayerPedId()) then
            if not IsPedAPlayer(aimingEnt) then
                prevPed = aimingEnt
                Wait(math.random(300, 700))
                local dict = "random@mugging3"
                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do
                    Citizen.Wait(0)
                end
                local rand = math.random(1, 10)

           
                    prevCar = GetVehiclePedIsIn(aimingEnt, false)
                    TaskLeaveVehicle(aimingEnt, prevCar)
                    SetVehicleEngineOn(prevCar, false, false, false)
                    while IsPedInAnyVehicle(aimingEnt, false) do
                        Citizen.Wait(0)
                    end
                    SetBlockingOfNonTemporaryEvents(aimingEnt, true)
                    ClearPedTasksImmediately(aimingEnt)
                    TaskPlayAnim(aimingEnt, dict, "handsup_standing_base", 8.0, -8.0, 0.01, 49, 0, 0, 0, 0)
                    ResetPedLastVehicle(aimingEnt)
                    TaskWanderInArea(aimingEnt, 0, 0, 0, 20, 100, 100)
                    canRob = true
                    beginRobTimer(aimingEnt)
             
            end
            
        end
    end
end)

local canTakeKeys = true
local isDoingAction = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isDoingAction and not pressed then
            Citizen.Wait(7000)
            ClearPedTasks(prevPed)
            TaskSmartFleePed(prevPed, PlayerPedId(), 7, 10000,false,false)
        end
    end

end)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if canRob and not IsEntityDead(prevPed) and IsPlayerFreeAiming(PlayerId()) then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local entPos = GetEntityCoords(prevPed)
            
            if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, entPos.x, entPos.y, entPos.z, false) < 3.5 then
                DrawText3Ds(entPos.x, entPos.y, entPos.z, '~y~[E]~w~ - Soy')
                isDoingAction = true
                if IsControlJustReleased(0, 38) then
                    pressed = true
                    local rand = math.random(1, 10)
                    if rand == 1 then
                        Wait(400)
                        exports['mythic_notify']:DoHudText('inform', 'Kaçtı')
                    else
                        local plate = GetVehicleNumberPlateText(prevCar)
                        exports["np-taskbar"]:taskBar(3600, "Anahtarlar Alınıyor")
                        givePlayerKeys(plate)
                        exports['mythic_notify']:DoHudText('inform', 'Anahtarı aldın')
                    end

                    SetBlockingOfNonTemporaryEvents(prevPed, false)
                    canRob = false
                end

            end
        end
    end
end)

function beginRobTimer(entity)
    local timer = 18

    while canRob do
        timer = timer - 1
        if timer == 0 then
            canRob = false
            SetBlockingOfNonTemporaryEvents(entity, false)
        end
        Wait(1000)
    end
end

function isNpc(ped)
    if IsPedAPlayer(ped) then
        return false
    else
        return true
    end
end


RegisterNetEvent('onyx:returnSearchedVehTable')
AddEventHandler('onyx:returnSearchedVehTable', function(plate)
    local vehPlate = plate
    table.insert(searchedVehicles, vehPlate)
end)

function hasBeenSearched(plate)
    local vehPlate = plate
    for k, v in ipairs(searchedVehicles) do
        if v == vehPlate then
            return true
        end
    end
    return false
end

function hasKeys(plate)
    local vehPlate = plate
    for k, v in ipairs(vehicles) do
        if v == vehPlate or v == vehPlate .. ' ' then
            return true
        end
    end
    return false
end

function DrawText3Ds(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local factor = #text / 460
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	
	SetTextScale(0.3, 0.3)
	SetTextFont(6)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 160)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	DrawRect(_x,_y + 0.0115, 0.02 + factor, 0.027, 28, 28, 28, 95)
end