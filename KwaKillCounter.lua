local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

frame:SetScript("OnEvent", function(self, event, addOnName)
    if event == "ADDON_LOADED" and addOnName == "KwaKillCounter" then
        MyKillCountTable = MyKillCountTable or {}
        
        -- DATA MIGRATION
        for id, data in pairs(MyKillCountTable) do
            if type(data) == "number" then
                MyKillCountTable[id] = {count = data, name = "Unknown (ID: "..id..")"}
            end
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
        if subevent == "UNIT_DIED" and destGUID and destName then
            local unitType, _, _, _, _, npcID = strsplit("-", destGUID)
            if (unitType == "Creature" or unitType == "Vehicle") and npcID then
                -- Initialize table if it doesn't exist
                MyKillCountTable[npcID] = MyKillCountTable[npcID] or {count = 0, name = destName}
                
                -- Migration: If the existing data is just a number, move it into the table
                if type(MyKillCountTable[npcID]) == "number" then
                    local oldCount = MyKillCountTable[npcID]
                    MyKillCountTable[npcID] = {count = oldCount, name = destName}
                end
                
                -- Increment
                MyKillCountTable[npcID].count = MyKillCountTable[npcID].count + 1
                -- Update name in case it was recorded as "Unknown" previously
                MyKillCountTable[npcID].name = destName
            end
        end
    end
end)

-- Function to sort and display top 5 + Total
local function ShowTopKills()
    local tempTable = {}
    local totalKills = 0
    
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" then
            table.insert(tempTable, {name = data.name, count = data.count})
            -- Add to the running total
            totalKills = totalKills + (data.count or 0)
        end
    end

    -- Sort: Highest count first
    table.sort(tempTable, function(a, b)
        return a.count > b.count
    end)

    print("|cffffff00Total Kills Across All Mobs:|r " .. totalKills)
    print("----------------------------")
    print("|cff00ff00Top 5 Most Killed:|r")
    
    for i = 1, 5 do
        if tempTable[i] then
            local mob = tempTable[i]
            print(i .. ". " .. mob.name .. " (" .. mob.count .. ")")
        else
            if i == 1 and totalKills == 0 then print("No kills recorded yet!") end
            break
        end
    end
end

-- Register Slash Command
SLASH_KWAKILLS1 = "/kwakills"
SlashCmdList["KWAKILLS"] = function()
    ShowTopKills()
end