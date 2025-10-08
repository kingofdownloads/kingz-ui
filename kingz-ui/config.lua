Config = {}

-- The item name for the plant pot in your shared/items.lua
Config.PotItem = 'plant_pot'

-- Prop models
Config.PotModel = `bkr_prop_weed_plantpot_01a`
Config.PlantModel = `prop_weed_01` -- A grown weed plant prop

-- The maximum number of pots a player can place
Config.MaxPots = 10

-- Time in seconds for a plant to grow
Config.GrowthTime = 300 -- 300 seconds = 5 minutes

-- How much weed you get from a harvest (a random amount between min and max)
Config.HarvestAmount = {
    min = 2,
    max = 5
}

-- Define the seeds from kingz-drugs and what they produce
-- Format: ['seed_item_name'] = 'harvest_item_name'
Config.Seeds = {
    ['cannabis_seed_ogkush'] = 'cannabis_ogkush',
    ['cannabis_seed_amnesia'] = 'cannabis_amnesia',
    ['cannabis_seed_purplehaze'] = 'cannabis_purplehaze',
    ['cannabis_seed_skunk'] = 'cannabis_skunk',
    ['cannabis_seed_whitewidow'] = 'cannabis_whitewidow',
}
