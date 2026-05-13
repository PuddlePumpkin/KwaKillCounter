function()
    -- 1. Check if the WeakAuras Options menu is open
    if WeakAuras.IsOptionsOpen() then
        return "Kills: 666\nKills to level: 42"
    end
    
    -- 2. Normal Logic
    local guid = UnitGUID("target")
    if not guid then return "" end
    
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    
    if unitType == "Creature" or unitType == "Vehicle" then
        local data = MyKillCountTable and MyKillCountTable[npcID]
        local count = 0
        local xpPerKill = 0
        
        if data then
            if type(data) == "table" then
                count = tonumber(data.count) or 0
                xpPerKill = tonumber(data.xp) or 0
            else
                count = tonumber(data) or 0
            end
        end
        
        -- Start with the first line
        local displayStr = string.format("Kills: %d", count)
        
        -- Show average loot value if available
        if data and data.avgLootValue and data.avgLootValue > 0 then
            displayStr = displayStr .. "\nAvg Loot: " .. GetCoinTextureString(math.floor(data.avgLootValue))
        end

        -- Logic for Kills to Level
        -- Only attempt if xpPerKill is greater than 0
        if xpPerKill and xpPerKill > 0 then
            local currentXP = UnitXP("player")
            local maxXP = UnitXPMax("player")
            local xpNeeded = maxXP - currentXP
            
            -- Ensure player isn't at max level (where maxXP might be 0)
            if xpNeeded > 0 then
                local killsToLevel = math.ceil(xpNeeded / xpPerKill)
                displayStr = displayStr .. "\nKills to level: " .. killsToLevel
            end
        end
        
        return displayStr
    end
    
    return ""
end

