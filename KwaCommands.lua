local addonName, KKK = ...

-- Expose KKK to global for WeakAuras if needed, or keep it private
-- For now, we'll keep MyKillCountTable global as it's a SavedVariable
-- but we'll put shared functions into KKK

function KKK.ShowTopKills()
    local tempTable = {}
    local totalKills = 0
    
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" then
            table.insert(tempTable, {name = data.name, count = data.count})
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

function KKK.ShowTopRaces()
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

function KKK.FindItemSource(msg)
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
            for item, dropCount in pairs(data.items) do
                local match = false
                if itemID then
                    -- Search by ID
                    if tostring(item) == itemID then
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
                    local rate = 0
                    local totalSamples = data.looted or data.count or 0
                    if totalSamples > 0 then
                        rate = (dropCount / totalSamples) * 100
                    end
                    table.insert(foundSources, {name = data.name or ("NPC " .. id), rate = rate})
                    break
                end
            end
        end
    end

    print("----------------------------")
    print("|cffffff00Sources for:|r " .. displayItemName)
    print("----------------------------")
    if #foundSources > 0 then
        table.sort(foundSources, function(a, b) return a.rate > b.rate end)
        for _, source in ipairs(foundSources) do
            print(string.format("- %s [%.1f%%]", source.name, source.rate))
        end
    else
        print("No recorded drops for this item yet.")
    end
end

function KKK.ShowTopVendor()
    local tempTable = {}
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" and (data.count or 0) >= 10 and data.avgLootValue and data.avgLootValue > 0 then
            table.insert(tempTable, {name = data.name, value = data.avgLootValue})
        end
    end

    table.sort(tempTable, function(a, b) return a.value > b.value end)

    print("----------------------------")
    print("|cff00ff00Top 10 Most Profitable (Vendor, min 10 kills):|r")
    print("----------------------------")
    for i = 1, 10 do
        if tempTable[i] then
            print(i .. ". " .. tempTable[i].name .. ": " .. GetCoinTextureString(tempTable[i].value))
        else
            if i == 1 then print("No loot data with at least 10 kills recorded yet!") end
            break
        end
    end
end

function KKK.ShowTopAuction()
    local tempTable = {}
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" and (data.count or 0) >= 10 and data.looted and data.looted > 0 then
            local val = KKK.GetDynamicAuctionValue(id)
            if val > 0 then
                table.insert(tempTable, {name = data.name, value = val})
            end
        end
    end

    table.sort(tempTable, function(a, b) return a.value > b.value end)

    print("----------------------------")
    print("|cff00ff00Top 10 Most Profitable (Auction, min 10 kills):|r")
    print("----------------------------")
    for i = 1, 10 do
        if tempTable[i] then
            print(i .. ". " .. tempTable[i].name .. ": " .. GetCoinTextureString(tempTable[i].value))
        else
            if i == 1 then print("No auction data with at least 10 kills recorded (or Auctionator not found)!") end
            break
        end
    end
end

function KKK.ShowHelp()
    print("----------------------------")
    print("|cffffff00KwaKillCounter Commands:|r")
    print("----------------------------")
    print("- /kwakills: Top 5 most killed NPCs.")
    print("- /kwaracekills: Kills categorized by race.")
    print("- /kwafind [Item]: Search for drop sources.")
    print("- /kwatopvendor: Top 10 most profitable (Vendor).")
    print("- /kwatopauction: Top 10 most profitable (Auction).")
    print("- /kwapurge: Clear loot data (keeps kill counts).")
    print("- /kwahelp: Shows this list.")
    print("----------------------------")
end

function KKK.PurgeData()
    local count = 0
    for id, data in pairs(MyKillCountTable) do
        if type(data) == "table" then
            data.looted = 0
            data.items = {}
            data.avgLootValue = 0
            data.totalVendorValue = 0
            count = count + 1
        end
    end
    print("|cffff0000[KwaKillCounter] Purged loot and value data for " .. count .. " NPCs. (Kill counts preserved)|r")
end

SLASH_KWAKILLS1 = "/kwakills"
SlashCmdList["KWAKILLS"] = KKK.ShowTopKills

SLASH_KWARACEKILLS1 = "/kwaracekills"
SlashCmdList["KWARACEKILLS"] = KKK.ShowTopRaces

SLASH_KWAFIND1 = "/kwafind"
SlashCmdList["KWAFIND"] = KKK.FindItemSource

SLASH_KWATOPVENDOR1 = "/kwatopvendor"
SlashCmdList["KWATOPVENDOR"] = KKK.ShowTopVendor

SLASH_KWATOPAUCTION1 = "/kwatopauction"
SlashCmdList["KWATOPAUCTION"] = KKK.ShowTopAuction

SLASH_KWAPURGE1 = "/kwapurge"
SlashCmdList["KWAPURGE"] = KKK.PurgeData

SLASH_KWAHELP1 = "/kwahelp"
SlashCmdList["KWAHELP"] = KKK.ShowHelp
