-- This file contains three separate functions for use in WeakAuras
-- Copy each function into its own "Custom Text" provider in the WeakAura Options.

-- [%c1] Kills Count
function()
    if WeakAuras.IsOptionsOpen() then return "Kills: 666" end
    local guid = UnitGUID("target")
    if not guid then return "" end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" then
        local data = MyKillCountTable and MyKillCountTable[npcID]
        local count = 0
        if data then
            count = type(data) == "table" and (tonumber(data.count) or 0) or (tonumber(data) or 0)
        end
        return string.format("Kills: %d", count)
    end
    return ""
end

-- [%c2] Average Loot Value
function()
    if WeakAuras.IsOptionsOpen() then return "Avg Loot: 1s 20c" end
    local guid = UnitGUID("target")
    if not guid then return "" end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" then
        local data = MyKillCountTable and MyKillCountTable[npcID]
        if data and type(data) == "table" and data.avgLootValue and data.avgLootValue > 0 then
            return "Avg Loot: " .. GetCoinTextureString(math.floor(data.avgLootValue))
        end
    end
    return ""
end

-- [%c3] Kills to Level
function()
    if WeakAuras.IsOptionsOpen() then return "To Level: 42" end
    local guid = UnitGUID("target")
    if not guid then return "" end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" then
        local data = MyKillCountTable and MyKillCountTable[npcID]
        if data and type(data) == "table" and data.xp and data.xp > 0 then
            local currentXP = UnitXP("player")
            local maxXP = UnitXPMax("player")
            local xpNeeded = maxXP - currentXP
            if xpNeeded > 0 then
                local killsToLevel = math.ceil(xpNeeded / data.xp)
                return "To Level: " .. killsToLevel
            end
        end
    end
    return ""
end
