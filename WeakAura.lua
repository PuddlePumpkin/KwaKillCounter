-- [[ CONSOLIDATED WEAKAURA FUNCTION ]]
-- Copy the ENTIRE block below (from 'function()' to the last 'end') 
-- into the "Custom Function" text box in your WeakAura.

function()
    -- [[ CONFIGURATION ]]
    -- Set these to true or false to show/hide specific lines in the WeakAura
    local SHOW_KILLS = true
    local SHOW_AVG_VENDOR = true
    local SHOW_AVG_AH = true
    local SHOW_KILLS_TO_LEVEL = true

    if WeakAuras.IsOptionsOpen() then 
        return "Kills: 666\nAvg Vendor: 1s 20c\nAvg AH: 2s 50c\nTo Level: 42" 
    end

    local guid = UnitGUID("target")
    if not guid then return "" end

    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if not (unitType == "Creature" or unitType == "Vehicle") or not npcID then return "" end

    local data = MyKillCountTable and MyKillCountTable[npcID]
    if not data then return "" end

    local lines = {}

    -- 1. Kills Count
    if SHOW_KILLS then
        local count = data.count or 0
        table.insert(lines, string.format("Kills: %d", count))
    end

    -- 2. Average Vendor Value
    if SHOW_AVG_VENDOR and data.avgLootValue and data.avgLootValue > 0 then
        table.insert(lines, "Avg Vendor: " .. GetCoinTextureString(math.floor(data.avgLootValue)))
    end

    -- 3. Average Auction Value
    if SHOW_AVG_AH and GetDynamicAuctionValue then
        local val = GetDynamicAuctionValue(npcID)
        if val and val > 0 then
            table.insert(lines, "Avg AH: " .. GetCoinTextureString(math.floor(val)))
        end
    end

    -- 4. Kills to Level
    if SHOW_KILLS_TO_LEVEL and data.xp and data.xp > 0 then
        local currentXP = UnitXP("player")
        local maxXP = UnitXPMax("player")
        local xpNeeded = maxXP - currentXP
        if xpNeeded > 0 then
            local killsToLevel = math.ceil(xpNeeded / data.xp)
            table.insert(lines, "To Level: " .. killsToLevel)
        end
    end

    return table.concat(lines, "\n")
end
