local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")

local pendingKillQueue = {}

local function GetCreatureRaceForGUID(destGUID)
    if destGUID == UnitGUID("target") then
        return UnitCreatureType("target") or "Unspecified"
    end

    return "Unspecified"
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addOnName = ...
        if addOnName == "KwaKillCounter" then
            MyKillCountTable = MyKillCountTable or {}
        end
    
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, _, _, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
        
        if subevent == "UNIT_DIED" then
            local unitType, _, _, _, _, npcID = strsplit("-", destGUID)
            if (unitType == "Creature" or unitType == "Vehicle") and npcID then
                
                -- 1. Get Race while the unit might still be valid
                local race = "Unspecified"
                if destGUID == UnitGUID("target") then
                    race = UnitCreatureType("target") or "Unspecified"
                elseif destGUID == UnitGUID("mouseover") then
                    race = UnitCreatureType("mouseover") or "Unspecified"
                end

                -- 2. Ensure Table Entry exists
                if not MyKillCountTable[npcID] then
                    MyKillCountTable[npcID] = {count = 0, name = destName, race = race}
                end
                
                local entry = MyKillCountTable[npcID]
                entry.count = entry.count + 1
                entry.name = destName
                
                -- Update race if we managed to find it this time
                if race ~= "Unspecified" then entry.race = race end

                -- 3. Add to queue for XP processing
                table.insert(pendingKillQueue, npcID)
                
                -- Prevent queue from bloating if XP isn't earned (e.g. gray mobs)
                -- If the queue gets too long, we clear the oldest entry
                if #pendingKillQueue > 10 then
                    table.remove(pendingKillQueue, 1)
                end
            end
        end

    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local message = ...
        -- Improved regex to find numbers in localized strings
        local xp = tonumber(message:match("(%d+)"))
        
        if xp and #pendingKillQueue > 0 then
            -- Grab the most recent death (back of the queue) 
            -- or oldest (front). Usually, XP fires immediately after death.
            local npcID = table.remove(pendingKillQueue, 1)
            if MyKillCountTable[npcID] then
                MyKillCountTable[npcID].xp = xp
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

    print(".")
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

-- Function to sort and display top races
local function ShowTopRaces()
    local tempTable = {}
    local raceTotals = {}

    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" and data.race and data.race ~= "Unspecified" then
            raceTotals[data.race] = (raceTotals[data.race] or 0) + (data.count or 0)
        end
    end

    for race, count in pairs(raceTotals) do
        table.insert(tempTable, {race = race, count = count})
    end

    -- Sort: Highest count first
    table.sort(tempTable, function(a, b)
        return a.count > b.count
    end)

    print(".")
    print("|cffffff00Total kills by race|r")
    print("----------------------------")
    
    for _, data in ipairs(tempTable) do
        print(data.race .. ": " .. data.count)
    end
    
    if #tempTable == 0 then
        print("No race kills recorded yet!")
    end
end

-- Register Slash Commands
SLASH_KWAKILLS1 = "/kwakills"
SlashCmdList["KWAKILLS"] = function()
    ShowTopKills()
end

SLASH_KWARACEKILLS1 = "/kwaracekills"
SlashCmdList["KWARACEKILLS"] = function()
    ShowTopRaces()
end