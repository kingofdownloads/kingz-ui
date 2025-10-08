local QBCore = exports['qb-core']:GetCoreObject()
local isPlacing = false
local currentPots = {}

-- Function to start the pot placement process
function StartPotPlacement()
    if isPlacing then return end

    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if not hasItem then
            QBCore.Functions.Notify('You do not have a plant pot.', 'error')
            return
        end

        isPlacing = true
        local playerPed = PlayerPedId()
        
        RequestModel(Config.PotModel)
        while not HasModelLoaded(Config.PotModel) do Wait(10) end

        local coords = GetEntityCoords(playerPed)
        local previewPot = CreateObject(Config.PotModel, coords, false, false, false)
        SetEntityAlpha(previewPot, 150, false)
        SetEntityCollision(previewPot, false, true)
        AttachEntityToEntity(previewPot, playerPed, GetPedBoneIndex(playerPed, 60309), 0.0, 1.0, -0.2, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

        QBCore.Functions.Notify('Press [E] to Place, [G] to Cancel.', 'primary', 7000)

        CreateThread(function()
            while isPlacing do
                Wait(0)
                local placePos, placeRot
                local playerPos = GetEntityCoords(playerPed)
                local forward = GetEntityForwardVector(playerPed)
                local dest = playerPos + (forward * 1.5)
                
                local ray = StartShapeTestRay(playerPos.x, playerPos.y, playerPos.z, dest.x, dest.y, dest.z - 1.0, -1, playerPed, 0)
                local _, hit, endPos, _, _ = GetShapeTestResult(ray)

                if hit then
                    placePos = endPos
                    placeRot = GetEntityRotation(playerPed)
                    DrawMarker(2, placePos.x, placePos.y, placePos.z + 0.2, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 50, 255, 50, 100, false, true, 2, nil, nil, false)
                end

                if IsControlJustReleased(0, 38) and placePos then -- [E]
                    QBCore.Functions.TriggerCallback('kingz-weed:server:placePot', function(success)
                        if success then isPlacing = false end
                    end, {x = placePos.x, y = placePos.y, z = placePos.z, h = placeRot.z})
                end

                if IsControlJustReleased(0, 47) then -- [G]
                    isPlacing = false
                    QBCore.Functions.Notify('Placement cancelled.', 'error')
                end
            end

            -- Cleanup
            DetachEntity(previewPot, true, true)
            DeleteEntity(previewPot)
        end)
    end, Config.PotItem)
end

-- Register the /placepot command
RegisterCommand('placepot', StartPotPlacement, false)
TriggerEvent('chat:addSuggestion', '/placepot', 'Place down a plant pot.')

-- Register the pot as a usable item
RegisterNetEvent('QBCore:Client:OnUseItem', function(itemName)
    if itemName == Config.PotItem then
        StartPotPlacement()
    end
end)

-- Function to open the seed selection menu
function OpenSeedMenu(potId)
    QBCore.Functions.TriggerCallback('kingz-weed:server:getSeeds', function(seeds)
        if #seeds == 0 then
            QBCore.Functions.Notify('You do not have any seeds.', 'error')
            return
        end

        local menu = {
            {
                header = 'Select a Seed',
                isMenuHeader = true
            }
        }
        for _, seed in ipairs(seeds) do
            table.insert(menu, {
                header = seed.label,
                txt = 'Amount: ' .. seed.amount,
                params = {
                    event = 'kingz-weed:server:plantSeed',
                    args = {
                        potId = potId,
                        seedName = seed.name
                    }
                }
            })
        end
        exports['qb-menu']:openMenu(menu)
    end)
end

-- Event to receive and sync pots from the server
RegisterNetEvent('kingz-weed:client:syncPots', function(potData)
    -- Clear old pots first
    for _, pot in pairs(currentPots) do
        if pot.obj and DoesEntityExist(pot.obj) then
            exports['qb-target']:RemoveTargetEntity(pot.obj)
            DeleteEntity(pot.obj)
        end
        if pot.plantObj and DoesEntityExist(pot.plantObj) then
            DeleteEntity(pot.plantObj)
        end
    end
    currentPots = {}

    -- Create new pots and plants
    for _, pot in pairs(potData) do
        RequestModel(Config.PotModel)
        while not HasModelLoaded(Config.PotModel) do Wait(10) end
        
        local potObj = CreateObject(Config.PotModel, pot.coords.x, pot.coords.y, pot.coords.z, true, false, false)
        SetEntityHeading(potObj, pot.coords.h)
        FreezeEntityPosition(potObj, true)
        
        pot.obj = potObj
        currentPots[pot.id] = pot

        local targetOptions = {}

        if pot.isPlanted then
            local isReady = os.time() >= pot.growthFinishTime
            
            RequestModel(Config.PlantModel)
            while not HasModelLoaded(Config.PlantModel) do Wait(10) end
            
            local plantObj = CreateObject(Config.PlantModel, pot.coords.x, pot.coords.y, pot.coords.z, true, false, false)
            SetEntityHeading(plantObj, pot.coords.h)
            FreezeEntityPosition(plantObj, true)
            pot.plantObj = plantObj

            if isReady then
                -- Plant is ready to harvest
                table.insert(targetOptions, {
                    icon = 'fas fa-cannabis',
                    label = 'Harvest Plant',
                    action = function()
                        QBCore.Functions.Progressbar('harvest_plant', 'Harvesting...', 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                        }, {}, {}, {}, function() -- Done
                            TriggerServerEvent('kingz-weed:server:harvestPlant', pot.id)
                        end, function() -- Cancel
                            QBCore.Functions.Notify('Harvest cancelled.', 'error')
                        end)
                    end
                })
            else
                -- Plant is still growing
                table.insert(targetOptions, {
                    icon = 'fas fa-hourglass-half',
                    label = 'Growing... (' .. math.ceil((pot.growthFinishTime - os.time()) / 60) .. ' mins left)',
                    action = function()
                        QBCore.Functions.Notify('The plant is not ready yet.', 'primary')
                    end
                })
                table.insert(targetOptions, {
                    icon = 'fas fa-trash-alt',
                    label = 'Destroy Plant',
                    action = function()
                        TriggerServerEvent('kingz-weed:server:destroyPlant', pot.id)
                    end
                })
            end
        else
            -- Pot is empty
            table.insert(targetOptions, {
                icon = 'fas fa-seedling',
                label = 'Plant Seed',
                action = function()
                    OpenSeedMenu(pot.id)
                end
            })
            table.insert(targetOptions, {
                icon = 'fas fa-hand-rock',
                label = 'Pick Up Pot',
                action = function()
                    TriggerServerEvent('kingz-weed:server:pickupPot', pot.id)
                end
            })
        end

        exports['qb-target']:AddTargetEntity(potObj, {
            options = targetOptions,
            distance = 1.5
        })
    end
end)
