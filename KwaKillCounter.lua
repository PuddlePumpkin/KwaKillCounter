local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")

local pendingKillQueue = {}
-- Pattern to capture: "MobName dies, you gain %d experience."
local xpKillPattern = _G["COMBATLOG_XPGAIN_FIRSTPERSON"]:gsub("%%s", ".-"):gsub("%%d", "(%%d+)")

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
                
                -- Race detection
                local race = "Unspecified"
                if destGUID == UnitGUID("target") then
                    race = UnitCreatureType("target") or "Unspecified"
                elseif destGUID == UnitGUID("mouseover") then
                    race = UnitCreatureType("mouseover") or "Unspecified"
                end

                -- Table Initialization
                if not MyKillCountTable[npcID] then
                    MyKillCountTable[npcID] = {count = 0, name = destName, race = race, xp = 0}
                end
                
                local entry = MyKillCountTable[npcID]
                entry.count = (entry.count or 0) + 1
                entry.name = destName
                if race ~= "Unspecified" then entry.race = race end

                -- Queue for XP matching (expires in 2 seconds)
                table.insert(pendingKillQueue, { id = npcID, time = GetTime() })
                
                -- Keep queue lean
                if #pendingKillQueue > 10 then table.remove(pendingKillQueue, 1) end
            end
        end

    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local message = ...
        local xpString = message:match(xpKillPattern)
        
        if xpString then
            local xp = tonumber(xpString)
            local now = GetTime()
            
            -- Find the first mob in queue that died within the last 2 seconds
            for i, data in ipairs(pendingKillQueue) do
                if (now - data.time) < 2.0 then
                    local npcID = data.id
                    if MyKillCountTable[npcID] then
                        MyKillCountTable[npcID].xp = xp -- Update to most recent XP
                    end
                    table.remove(pendingKillQueue, i)
                    break
                end
            end
        end
    end
end)

local function ShowTopKills()
    local tempTable = {}
    local totalKills = 0
    
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" then
            table.insert(tempTable, {name = data.name, count = data.count, xp = data.xp})
            totalKills = totalKills + (data.count or 0)
        end
    end

    table.sort(tempTable, function(a, b) return a.count > b.count end)

    print("----------------------------")
    print("|cffffff00Total Kills:|r " .. totalKills)
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

    table.sort(tempTable, function(a, b) return a.count > b.count end)

    print("----------------------------")
    print("|cffffff00Kills by Race:|r")
    print("----------------------------")
    for _, data in ipairs(tempTable) do
        print("- " .. data.race .. ": " .. data.count)
    end
end

SLASH_KWAKILLS1 = "/kwakills"
SlashCmdList["KWAKILLS"] = ShowTopKills

SLASH_KWARACEKILLS1 = "/kwaracekills"
SlashCmdList["KWARACEKILLS"] = ShowTopRaces