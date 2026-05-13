local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("LOOT_READY")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local pendingKillQueue = {}
local processedGUIDs = {}
-- Pattern to capture: "MobName dies, you gain %d experience."
local xpKillPattern = _G["COMBATLOG_XPGAIN_FIRSTPERSON"]:gsub("%%s", ".-"):gsub("%%d", "(%%d+)")

local function UpdateLootValue()
    local numItems = GetNumLootItems()
    if numItems == 0 then return end

    local lootData = {} -- guid -> { totalMoney = 0, items = {}, complete = true }
    
    for i = 1, numItems do
        local guid = GetLootSourceInfo(i)
        if not guid then
            local targetGUID = UnitGUID("target")
            if targetGUID and UnitIsDead("target") then
                guid = targetGUID
            end
        end

        if guid and not processedGUIDs[guid] then
            if not lootData[guid] then
                lootData[guid] = { totalMoney = 0, items = {}, complete = true }
            end
            
            local slotType = GetLootSlotType(i)
            if slotType == 1 then -- Item
                local itemLink = GetLootSlotLink(i)
                if itemLink then
                    local itemName, _, _, _, _, _, _, _, _, _, price = GetItemInfo(itemLink)
                    
                    -- Record item even if price is missing (we'll just mark it incomplete for average value)
                    if itemName then
                        if not itemName:lower():find(" of the ") then
                            local itemID = itemLink:match("item:(%d+)")
                            table.insert(lootData[guid].items, itemID or itemName)
                        end
                        
                        if price then
                            local _, _, quantity = GetLootSlotInfo(i)
                            lootData[guid].totalMoney = lootData[guid].totalMoney + (price * (quantity or 1))
                        else
                            lootData[guid].complete = false
                        end
                    else
                        lootData[guid].complete = false
                    end
                else
                    lootData[guid].complete = false
                end
            elseif slotType == 2 then -- Money
                local _, _, quantity = GetLootSlotInfo(i)
                lootData[guid].totalMoney = lootData[guid].totalMoney + (quantity or 0)
            end
        end
    end
    
    for guid, data in pairs(lootData) do
        local unitType, _, _, _, _, npcID = strsplit("-", guid)
        if (unitType == "Creature" or unitType == "Vehicle") and npcID then
            if MyKillCountTable[npcID] then
                local entry = MyKillCountTable[npcID]
                entry.items = entry.items or {}
                
                -- Always update items if we found any
                for _, newItem in ipairs(data.items) do
                    local exists = false
                    for _, existingItem in ipairs(entry.items) do
                        if existingItem == newItem then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        table.insert(entry.items, newItem)
                    end
                end

                -- Only update average value if we have all prices for this window
                if data.complete then
                    processedGUIDs[guid] = true
                    local totalValue = data.totalMoney
                    if entry.avgLootValue and entry.avgLootValue > 0 then
                        entry.avgLootValue = (entry.avgLootValue + totalValue) / 2
                    else
                        entry.avgLootValue = totalValue
                    end
                end
            end
        end
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addOnName = ...
        if addOnName == "KwaKillCounter" then
            MyKillCountTable = MyKillCountTable or {}
            
            -- Migration: Ensure all existing entries have proper fields
            for id, data in pairs(MyKillCountTable) do
                if type(data) == "table" then
                    data.items = data.items or {}
                    data.avgLootValue = data.avgLootValue or 0
                    data.xp = data.xp or 0
                end
            end
        end
    
    elseif event == "PLAYER_ENTERING_WORLD" then
        processedGUIDs = {}

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
                    MyKillCountTable[npcID] = {count = 0, name = destName, race = race, xp = 0, avgLootValue = 0, items = {}}
                end
                
                local entry = MyKillCountTable[npcID]
                entry.items = entry.items or {}
                entry.count = (entry.count or 0) + 1
                entry.name = destName
                if race ~= "Unspecified" then entry.race = race end
                if not entry.avgLootValue then entry.avgLootValue = 0 end

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

    elseif event == "LOOT_OPENED" or event == "LOOT_READY" then
        UpdateLootValue()
    end
end)

local function ShowTopKills()
    local tempTable = {}
    local totalKills = 0
    
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" then
            table.insert(tempTable, {name = data.name, count = data.count, xp = data.xp, avgLootValue = data.avgLootValue})
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
            local lootText = ""
            if mob.avgLootValue and mob.avgLootValue > 0 then
                lootText = " | Avg Loot: " .. GetCoinTextureString(math.floor(mob.avgLootValue))
            end
            print(i .. ". " .. mob.name .. " (" .. mob.count .. ")" .. lootText)
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

local function FindItemSource(msg)
    if not msg or msg == "" then
        print("|cffff0000Usage: /kwafind [Item Link] OR /kwafind Item Name|r")
        return
    end

    local itemID = msg:match("item:(%d+)")
    local itemNameFromLink = msg:match("%[(.+)%]")
    
    local searchKey = itemID or msg:lower()
    local displayItemName = itemNameFromLink or msg

    if itemID then
        local name = GetItemInfo(itemID)
        if name then displayItemName = name end
    end

    local foundSources = {}

    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" and data.items then
            for _, item in ipairs(data.items) do
                local match = false
                if itemID then
                    -- Search by ID
                    if item == itemID then
                        match = true
                    end
                else
                    -- Search by Name (case-insensitive)
                    if type(item) == "string" then
                        -- If stored as name, check directly
                        if item:lower() == searchKey then
                            match = true
                        else
                            -- If stored as ID, try to get name for comparison
                            local storedName = GetItemInfo(item)
                            if storedName and storedName:lower() == searchKey then
                                match = true
                            end
                        end
                    end
                end

                if match then
                    table.insert(foundSources, data.name or ("NPC " .. id))
                    break
                end
            end
        end
    end

    print("----------------------------")
    print("|cffffff00Sources for:|r " .. displayItemName)
    print("----------------------------")
    if #foundSources > 0 then
        for _, name in ipairs(foundSources) do
            print("- " .. name)
        end
    else
        print("No recorded drops for this item yet.")
    end
end

SLASH_KWAKILLS1 = "/kwakills"
SlashCmdList["KWAKILLS"] = ShowTopKills

SLASH_KWARACEKILLS1 = "/kwaracekills"
SlashCmdList["KWARACEKILLS"] = ShowTopRaces

SLASH_KWAFIND1 = "/kwafind"
SlashCmdList["KWAFIND"] = FindItemSource