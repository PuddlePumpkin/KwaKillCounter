local addonName, KKK = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("LOOT_READY")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local pendingKillQueue = {}
local processedGUIDs = {}
local processedItemGUIDs = {}
-- Pattern to capture: "MobName dies, you gain %d experience."
local xpKillPattern = _G["COMBATLOG_XPGAIN_FIRSTPERSON"]:gsub("%%s", ".-"):gsub("%%d", "(%%d+)")

local function UpdateLootValue()
    local numItems = GetNumLootItems()
    local lootData = {} -- guid -> { totalMoney = 0, items = {}, complete = true }

    if numItems == 0 then
        -- Even if empty, we want to count the loot event for the current target
        local targetGUID = UnitGUID("target")
        if targetGUID and UnitIsDead("target") then
            lootData[targetGUID] = { totalMoney = 0, items = {}, complete = true }
        end
    else
        for i = 1, numItems do
            local guid = GetLootSourceInfo(i)
            if not guid then
                local targetGUID = UnitGUID("target")
                if targetGUID and UnitIsDead("target") then
                    guid = targetGUID
                end
            end

            if guid and (not processedGUIDs[guid] or not processedItemGUIDs[guid]) then
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
                            local _, _, quantity = GetLootSlotInfo(i)
                            quantity = quantity or 1

                            local itemID = itemLink:match("item:(%d+)")
                            table.insert(lootData[guid].items, itemID or itemName)

                            if price then
                                lootData[guid].totalMoney = lootData[guid].totalMoney + (price * quantity)
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
    end
    
    for guid, data in pairs(lootData) do
        local unitType, _, _, _, _, npcID = strsplit("-", guid)
        if (unitType == "Creature" or unitType == "Vehicle") and npcID then
            if MyKillCountTable[npcID] then
                local entry = MyKillCountTable[npcID]
                entry.items = entry.items or {}
                
                -- Always update item counts if we haven't for this GUID
                if not processedItemGUIDs[guid] then
                    processedItemGUIDs[guid] = true
                    entry.looted = (entry.looted or 0) + 1
                    
                    -- Use a local set to only count each unique item once per loot window
                    local uniqueItems = {}
                    for _, itemID in ipairs(data.items) do
                        uniqueItems[itemID] = true
                    end
                    
                    for itemID, _ in pairs(uniqueItems) do
                        entry.items[itemID] = (entry.items[itemID] or 0) + 1
                    end
                end

                -- Only update average value if we have all prices for this window
                if data.complete and not processedGUIDs[guid] then
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

-- Dynamic Auction Value Calculation
function GetDynamicAuctionValue(npcID)
    local data = MyKillCountTable and MyKillCountTable[npcID]
    if not data or not data.items or not data.looted or data.looted == 0 then return 0 end

    local totalValue = 0
    for itemID, dropCount in pairs(data.items) do
        local ahPrice = 0
        if Auctionator and Auctionator.API and Auctionator.API.v1 then
            ahPrice = Auctionator.API.v1.GetAuctionPriceByItemLink("KwaKillCounter", "item:" .. itemID) or 0
        end
        totalValue = totalValue + (ahPrice * dropCount)
    end

    return totalValue / data.looted
end

-- Share it with the namespace if needed, but keep it global for WeakAuras for now
KKK.GetDynamicAuctionValue = GetDynamicAuctionValue

local function MigrateData()
    if not MyKillCountTable then return end
    
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" then
            -- Migrate items from list to map with counts
            if data.items and #data.items > 0 then
                local newItems = {}
                for _, item in ipairs(data.items) do
                    newItems[tostring(item)] = 1
                end
                data.items = newItems
            end
            
            data.items = data.items or {}
            data.avgLootValue = data.avgLootValue or 0
            data.xp = data.xp or 0
            data.looted = data.looted or 0
        end
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            MyKillCountTable = MyKillCountTable or {}
            MigrateData()
        end
    
    elseif event == "PLAYER_ENTERING_WORLD" then
        processedGUIDs = {}
        processedItemGUIDs = {}

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
                    MyKillCountTable[npcID] = {count = 0, looted = 0, name = destName, race = race, xp = 0, avgLootValue = 0, items = {}}
                end
                
                local entry = MyKillCountTable[npcID]
                entry.items = entry.items or {}
                entry.count = (entry.count or 0) + 1
                entry.looted = entry.looted or 0
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

-- Tooltip Integration
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    if not IsShiftKeyDown() then return end

    local _, link = self:GetItem()
    if not link then return end

    local itemID = link:match("item:(%d+)")
    if not itemID then return end

    local sources = {}
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" and data.items then
            for item, dropCount in pairs(data.items) do
                if tostring(item) == itemID then
                    local rate = 0
                    local totalSamples = data.looted or data.count or 0
                    if totalSamples > 0 then
                        rate = (dropCount / totalSamples) * 100
                    end
                    table.insert(sources, {name = data.name or ("NPC " .. id), rate = rate})
                    break
                end
            end
        end
    end

    if #sources > 0 then
        table.sort(sources, function(a, b) return a.rate > b.rate end)
        self:AddLine(" ") -- Spacer
        self:AddLine("|cffffff00Dropped by:|r")
        for i = 1, math.min(3, #sources) do
            local source = sources[i]
            self:AddLine(string.format("- %s [%.1f%%]", source.name, source.rate))
        end
        if #sources > 3 then
            self:AddLine("...")
        end
        self:Show()
    end
end)
