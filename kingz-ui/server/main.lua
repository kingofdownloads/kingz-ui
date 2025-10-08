local QBCore = exports['qb-core']:GetCoreObject()
local Pots = {} -- Stores all placed pots: Pots[citizenid] = { potData, ... }

-- When a player connects, send them their existing pots
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    if Pots[citizenid] then
        TriggerClientEvent('kingz-weed:client:syncPots', src, Pots[citizenid])
    end
end)

-- Place a pot
QBCore.Functions.RegisterServerCallback('kingz-weed:server:placePot', function(source, cb, coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return cb(false) end

    local citizenid = Player.PlayerData.citizenid
    Pots[citizenid] = Pots[citizenid] or {}

    if #Pots[citizenid] >= Config.MaxPots then
        TriggerClientEvent('QBCore:Notify', src, 'You have reached the maximum number of pots.', 'error')
        return cb(false)
    end

    if Player.Functions.RemoveItem(Config.PotItem, 1) then
        local potId = 'pot_' .. citizenid .. '_' .. (#Pots[citizenid] + 1)
        local newPot = {
            id = potId,
            coords = coords,
            isPlanted = false,
            plantType = nil,
            growthFinishTime = nil,
        }
        table.insert(Pots[citizenid], newPot)
        
        TriggerClientEvent('kingz-weed:client:syncPots', src, Pots[citizenid])
        TriggerClientEvent('QBCore:Notify', src, 'You placed a pot.', 'success')
        cb(true)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have a plant pot.', 'error')
        cb(false)
    end
end)

-- Pick up a pot
RegisterNetEvent('kingz-weed:server:pickupPot', function(potId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not Pots[citizenid] then return end

    for i, pot in ipairs(Pots[citizenid]) do
        if pot.id == potId then
            if pot.isPlanted then
                TriggerClientEvent('QBCore:Notify', src, 'You must harvest or destroy the plant first.', 'error')
                return
            end

            if Player.Functions.AddItem(Config.PotItem, 1) then
                table.remove(Pots[citizenid], i)
                TriggerClientEvent('kingz-weed:client:syncPots', -1, Pots[citizenid])
                TriggerClientEvent('QBCore:Notify', src, 'You picked up the pot.', 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Your inventory is full.', 'error')
            end
            return
        end
    end
end)

-- Get available seeds from player's inventory
QBCore.Functions.RegisterServerCallback('kingz-weed:server:getSeeds', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local seeds = {}
    if not Player then return cb(seeds) end

    for itemName, _ in pairs(Config.Seeds) do
        local item = Player.Functions.GetItemByName(itemName)
        if item and item.amount > 0 then
            table.insert(seeds, {
                name = item.name,
                label = item.label,
                amount = item.amount
            })
        end
    end
    cb(seeds)
end)

-- Plant a seed
RegisterNetEvent('kingz-weed:server:plantSeed', function(potId, seedName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not Pots[citizenid] then return end

    for i, pot in ipairs(Pots[citizenid]) do
        if pot.id == potId then
            if pot.isPlanted then
                TriggerClientEvent('QBCore:Notify', src, 'There is already a plant here.', 'error')
                return
            end

            if Player.Functions.RemoveItem(seedName, 1) then
                pot.isPlanted = true
                pot.plantType = seedName
                pot.growthFinishTime = os.time() + Config.GrowthTime
                
                TriggerClientEvent('kingz-weed:client:syncPots', -1, Pots[citizenid])
                TriggerClientEvent('QBCore:Notify', src, 'You planted a ' .. QBCore.Shared.Items[seedName].label, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'You do not have that seed.', 'error')
            end
            return
        end
    end
end)

-- Harvest a plant
RegisterNetEvent('kingz-weed:server:harvestPlant', function(potId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not Pots[citizenid] then return end

    for i, pot in ipairs(Pots[citizenid]) do
        if pot.id == potId then
            if not pot.isPlanted or os.time() < pot.growthFinishTime then
                TriggerClientEvent('QBCore:Notify', src, 'The plant is not ready to harvest.', 'error')
                return
            end

            local harvestItem = Config.Seeds[pot.plantType]
            local amount = math.random(Config.HarvestAmount.min, Config.HarvestAmount.max)

            if Player.Functions.AddItem(harvestItem, amount) then
                pot.isPlanted = false
                pot.plantType = nil
                pot.growthFinishTime = nil

                TriggerClientEvent('kingz-weed:client:syncPots', -1, Pots[citizenid])
                TriggerClientEvent('QBCore:Notify', src, 'You harvested ' .. amount .. 'x ' .. QBCore.Shared.Items[harvestItem].label, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Your inventory is full.', 'error')
            end
            return
        end
    end
end)

-- Destroy a plant
RegisterNetEvent('kingz-weed:server:destroyPlant', function(potId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not Pots[citizenid] then return end

    for i, pot in ipairs(Pots[citizenid]) do
        if pot.id == potId then
            if not pot.isPlanted then return end

            pot.isPlanted = false
            pot.plantType = nil
            pot.growthFinishTime = nil

            TriggerClientEvent('kingz-weed:client:syncPots', -1, Pots[citizenid])
            TriggerClientEvent('QBCore:Notify', src, 'You destroyed the plant.', 'success')
            return
        end
    end
end)

-- Admin command to give a pot
QBCore.Commands.Add('givepot', 'Give yourself a plant pot (Admin Only)', {}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        Player.Functions.AddItem(Config.PotItem, 1)
        TriggerClientEvent('QBCore:Notify', source, 'You received a plant pot.', 'success')
    end
end, 'admin')
