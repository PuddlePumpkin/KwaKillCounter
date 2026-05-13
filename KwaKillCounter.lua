local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addOnName)
    if addOnName == "KwaKillCounter" then
        MyKillCountTable = MyKillCountTable or {}
        
        -- DATA MIGRATION
        for id, data in pairs(MyKillCountTable) do
            if type(data) == "number" then
                MyKillCountTable[id] = {count = data, name = "Unknown (ID: "..id..")"}
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