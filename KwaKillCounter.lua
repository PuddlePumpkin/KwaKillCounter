local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function GetCreatureRaceForGUID(destGUID)
    if destGUID == UnitGUID("target") then
        return UnitCreatureType("target") or "Unspecified"
    end

    return "Unspecified"
end

frame:SetScript("OnEvent", function(self, event, addOnName)
    if event == "ADDON_LOADED" and addOnName == "KwaKillCounter" then
        MyKillCountTable = MyKillCountTable or {}
        
        -- DATA MIGRATION
        for id, data in pairs(MyKillCountTable) do
            if type(data) == "number" then
                MyKillCountTable[id] = {count = data, name = "Unknown (ID: "..id..")", race = "Unspecified"}
            elseif type(data) == "table" and not data.race then
                data.race = "Unspecified"
            end
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
        if subevent == "UNIT_DIED" and destGUID and destName then
            local unitType, _, _, _, _, npcID = strsplit("-", destGUID)
            if (unitType == "Creature" or unitType == "Vehicle") and npcID then
                local race = GetCreatureRaceForGUID(destGUID, destName)
                local entry = MyKillCountTable[npcID]

                if type(entry) == "number" then
                    entry = {count = entry, name = destName, race = race}
                end

                if type(entry) ~= "table" then
                    entry = {count = 0, name = destName, race = race}
                end

                entry.count = (entry.count or 0) + 1
                entry.name = destName
                if not entry.race or entry.race == "Unspecified" then
                    entry.race = race
                end
                MyKillCountTable[npcID] = entry
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