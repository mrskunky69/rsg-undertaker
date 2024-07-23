local RSGCore = exports['rsg-core']:GetCoreObject()
local graveBlips = {}
local started = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local sleep = true 

        -- Create blips if they don't exist
        if #graveBlips == 0 then
            for k, v in pairs(Config.grave) do
                local blip = CreateGraveBlip(v.Pos.x, v.Pos.y, v.Pos.z)
                table.insert(graveBlips, blip)
            end
        end

        for k, v in pairs(Config.grave) do
            local holding = Citizen.InvokeNative(0xD806CD2A4F2C2996, PlayerPedId())
            if holding then 
                local isdead = IsEntityDead(holding)
                if isdead then
                    if GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < 2 and not started  then
                        sleep = false
                        DrawText3D(v.Pos.x, v.Pos.y, v.Pos.z, Config.Language.deceased)
                        if whenKeyJustPressed(Config.keys["G"]) then
                            started = true 
                            deceased()
                            Wait(500)
                        end
                    end
                end
            end
        end
        if sleep then 
            Citizen.Wait(500)
        end
    end
end)

function deceased()
    local holding = Citizen.InvokeNative(0xD806CD2A4F2C2996, PlayerPedId())
    local bodyCoords = GetEntityCoords(holding)
    
    -- Start the mourning animation
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_GRAVE_MOURNING_KNEEL"), 20000, true, false, false, false)
    
    -- Notify the player
    RSGCore.Functions.Notify('The pigs are coming...', 'primary')
    
    -- Spawn pigs
    local pigHash = GetHashKey("A_C_Pig_01")
    RequestModel(pigHash)
    
    -- Wait for the model to load
    local attempts = 0
    while not HasModelLoaded(pigHash) and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end
    
    if not HasModelLoaded(pigHash) then
        RSGCore.Functions.Notify('Failed to load pig model', 'error')
        return
    end
    
    local pigs = {}
    for i = 1, 3 do
        local offsetX = math.random(-3, 3)
        local offsetY = math.random(-3, 3)
        local spawnZ = bodyCoords.z  -- Use the same Z coordinate as the body
        
        -- Check if the spawn point is clear
        local _, groundZ = GetGroundZFor_3dCoord(bodyCoords.x + offsetX, bodyCoords.y + offsetY, spawnZ + 1.0, false)
        local pig = CreatePed(pigHash, bodyCoords.x + offsetX, bodyCoords.y + offsetY, groundZ, 0.0, true, true, false, false)
        
        if DoesEntityExist(pig) then
            table.insert(pigs, pig)
            Citizen.InvokeNative(0x283978A15512B2FE, pig, true)  -- Set random outfit variation
			Citizen.InvokeNative(0x18FF3110CF47115D, pig, 2, false)
			Citizen.InvokeNative(0xAEB97D84CDF3C00B, pig, false) 
			
            TaskGoToEntity(pig, holding, -1, 2.0, 2.0, 0, 0)
        else
            RSGCore.Functions.Notify('Failed to spawn pig ' .. i, 'error')
        end
    end
    
    -- Wait for pigs to reach the body
    Citizen.Wait(20000)
    
    -- Simulate feeding
    for _, pig in ipairs(pigs) do
        TaskStartScenarioInPlace(pig, GetHashKey("WORLD_ANIMAL_PIG_EAT"), 20000, true, false, false, false)
    end
    
    -- Wait for feeding to complete
    Citizen.Wait(20000)
    
    -- Remove the body
    DeleteEntity(holding) 
    
    -- Make pigs wander off
    for _, pig in ipairs(pigs) do
        TaskWanderStandard(pig, 10.0, 10)
    end
    
    -- Complete the mourning animation
    Citizen.Wait(5000)
    
    -- Set weapon to unarmed
    SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED'), true)
    
    
    -- Notify the player
    RSGCore.Functions.Notify('The pigs have disposed of the body...', 'success')
	Wait(600)
	
	-- Pay the player
    local payAmount = 10 -- Set this to whatever amount you want to pay
    TriggerServerEvent('disposebody:payplayer', payAmount)
    
    -- Reset the ped's tasks
    Citizen.InvokeNative(0xFCCC886EDE3C63EC, PlayerPedId(), false, true)
    
    -- Reset the started flag
    started = false
    
    -- Remove pigs after a delay
    Citizen.SetTimeout(30000, function()
        for _, pig in ipairs(pigs) do
            DeleteEntity(pig)
        end
    end)
end

function RemoveGraveBlips()
    for _, blip in ipairs(graveBlips) do
        RemoveBlip(blip)
    end
    graveBlips = {}
end



function CreateGraveBlip(x, y, z)
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, x, y, z)
    SetBlipSprite(blip, -1103135225, 1)  -- You may need to change this sprite number to match a grave or relevant icon
    SetBlipScale(blip, 0.2)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, "feed pigs peds")
    return blip
end

function DrawText3D(x, y, z, text)
	local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
	local px,py,pz=table.unpack(GetGameplayCamCoord())  
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
	local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
	if onScreen then
	  SetTextScale(0.30, 0.30)
	  SetTextFontForCurrentCommand(1)
	  SetTextColor(255, 255, 255, 215)
	  SetTextCentre(1)
	  DisplayText(str,_x,_y)
	  local factor = (string.len(text)) / 225
	  DrawSprite("feeds", "hud_menu_4a", _x, _y+0.0125,0.015+ factor, 0.03, 0.1, 35, 35, 35, 190, 0)
	end
end
function whenKeyJustPressed(key)
    if Citizen.InvokeNative(0x580417101DDB492F, 0, key) then
        return true
    else
        return false
    end
end
