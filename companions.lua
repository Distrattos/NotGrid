local AllCompanionMap = {  }
local YourCompanionMap = {  }

NotGridClientToServer = CreateFrame("Frame",nil,UIParent)
NotGridServerToClient = CreateFrame("Frame",nil,UIParent) -- create a frame that will listen for events
NotGridServerToClient:RegisterEvent("CHAT_MSG_ADDON") -- register what events do you want the frame to listen for - in our case we want to listen to messages from the server
NotGridServerToClient:RegisterEvent("PARTY_MEMBERS_CHANGED")
NotGridServerToClient:RegisterEvent("PLAYER_ENTERING_WORLD")

-- GRINFO:ALL:NAMES
-- GRINFO:SELF:NAMES
function NotGriend_ClientRequest()
    -- It's necessary to call an OnUpdate function from a frame in order to SendAddonMessages to the server
    NotGridClientToServer:SetScript("OnUpdate", function()

        -- Send the message request to the server
        SendAddonMessage("nexus", "GRINFO:ALL:NAMES", "BATTLEGROUND")
        SendAddonMessage("nexus", "GRINFO:SELF:NAMES", "BATTLEGROUND")

        -- Clear the OnUpdate script after it finishes because the job's done and we don't want to spam the server
        NotGridClientToServer:SetScript("OnUpdate", nil)

    end)
end

function NotGridServerToClient:OnEvent()
    -- print("SMSG:" .. arg1 .. " arg2:" .. arg2 .. " CHANNEL:" .. arg3 .. " SENDER:" .. arg4)
    -- print(arg1)

    if event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        NotGriend_ClientRequest()
    end

    -- We are only interested in capturing messages from the server on the addon channel, which is invisible to the players
    if event ~= "CHAT_MSG_ADDON" then
        return
    end

    -- Check if the message starts with [nexus]
    local startPos, endPos = string.find(arg1, "%[nexus%]")

    -- If no [nexus] tag is found, or the channel is different than the server one, or the sender is not this player, then do nothing
    if startPos == nil or arg3 ~= "UNKNOWN" or arg4 ~= UnitName("player") then
        return
    end

    -- Extract the part of the instruction after the [nexus] tag
    -- This instruction is the same as the one you've sent in ClientRequest(arg), like for example: GRINFO:ALL:FULL
    -- The server is sending back for which instruction it gives the answer, so you know how to process the answer
    local serverResponse = string.sub(arg1, endPos + 2) -- +2 to skip the space after [nexus]

    -- Find the first colon (:) in the instruction to get the mainInstruction
    local firstColon = string.find(serverResponse, ":")
    if not firstColon then return end -- If there's no colon, return

    -- Get the main instruction (e.g., GRINFO)
    local instruction = string.sub(serverResponse, 1, firstColon - 1)

    -- Find the second colon to get the scope (e.g., ALL or SELF)
    local secondColon = string.find(serverResponse, ":", firstColon + 1)
    if not secondColon then return end -- If there's no second colon, return

    -- Get the scope (e.g., ALL, SELF)
    local scope = string.sub(serverResponse, firstColon + 1, secondColon - 1)

    -- Get the detail (e.g., FULL, NAMES)
    local spacePos = string.find(serverResponse, " ", secondColon + 1)
    local detail

    -- If no space is found, the detail is the rest of the string
    if spacePos == nil then
        detail = string.sub(serverResponse, secondColon + 1)
        spacePos = 0
    else
        detail = string.sub(serverResponse, secondColon + 1, spacePos - 1)
    end

    -- Check the main instruction and process accordingly
    if instruction == "GRINFO" then

        if (scope == "ALL" or scope == "SELF") and detail == "NAMES" then

            -- Extract the actual response after the instruction, ie. remove "GRINFO:ALL:NAMES"
            local companionInfo = string.sub(serverResponse, spacePos + 1)

            -- Initialize an empty table to store names
            local names = {}

            -- Loop through the message and extract each name and insert into the names array
            local nameStart = 1
            local nameEnd = string.find(companionInfo, " ", nameStart)
            while nameEnd do
                local name = string.sub(companionInfo, nameStart, nameEnd - 1)
                table.insert(names, name)
                nameStart = nameEnd + 1
                nameEnd = string.find(companionInfo, " ", nameStart)
            end

            -- Insert the last name after the last space
            local lastName = string.sub(companionInfo, nameStart)
            table.insert(names, lastName)

            for _, name in ipairs(names) do
                if name and name ~= "" then
                    if scope == "ALL" then
                        AllCompanionMap[name] = true  -- Add all companions to AllCompanionMap
                        DEFAULT_CHAT_FRAME:AddMessage("Adding to AllCompanionMap: " .. name) -- Add debug print
                    elseif scope == "SELF" then
                        YourCompanionMap[name] = true -- Add your companions to YourCompanionMap
                        DEFAULT_CHAT_FRAME:AddMessage("Adding to YourCompanionMap: " .. name) -- Add debug print
                    end
                end
            end
        end
    end
end

-- Attach the OnEvent() function to the frame that will execute when the event is triggered. This needs to be done after you've defined the OnEvent() function.
NotGridServerToClient:SetScript("OnEvent", NotGridServerToClient.OnEvent)

--local HookRefreshUnit = pfUI.uf.RefreshUnit
--function pfUI.uf:RefreshUnit(unit, component)
--    local pos = string.upper(C.EliteOverlay.position)
--    local invert = C.EliteOverlay.position == "right" and 1 or -1
--    local unitstr = ( unit.label or "" ) .. ( unit.id or "" )
--
--    local size = unit:GetWidth() / 1.5
--    local elite = UnitClassification(unitstr)
--
--    -- Use UnitName() to get the actual player or companion name
--    local playerName = UnitName(unitstr)
--
--    -- Companion check using the global maps
--    local isYourCompanion = YourCompanionMap[playerName]
--    local isCompanion = AllCompanionMap[playerName]
--
--    -- print (isYourCompanion)
--    -- print ("INFO: " .. (playerName or "Unknown"))
--
--    unit.dragonTop = unit.dragonTop or unit:CreateTexture(nil, "OVERLAY")
--    unit.dragonBottom = unit.dragonBottom or unit:CreateTexture(nil, "OVERLAY")
--
--    if unitstr == "" or C.EliteOverlay.position == "off" then
--        unit.dragonTop:Hide()
--        unit.dragonBottom:Hide()
--    else
--        unit.dragonTop:ClearAllPoints()
--        unit.dragonTop:SetWidth(size)
--        unit.dragonTop:SetHeight(size)
--        unit.dragonTop:SetPoint("TOP"..pos, unit, "TOP"..pos, invert*size/5, size/7)
--        unit.dragonTop:SetParent(unit.hp.bar)
--
--        unit.dragonBottom:ClearAllPoints()
--        unit.dragonBottom:SetWidth(size)
--        unit.dragonBottom:SetHeight(size)
--        unit.dragonBottom:SetPoint("BOTTOM"..pos, unit, "BOTTOM"..pos, invert*size/5.2, -size/2.98)
--        unit.dragonBottom:SetParent(unit.hp.bar)
--
--        if isYourCompanion or elite == "worldboss" then
--            unit.dragonTop:SetTexture(addonpath.."\\img\\TOP_GOLD_"..pos)
--            unit.dragonTop:Show()
--            unit.dragonTop:SetVertexColor(.85,.15,.15,1)
--            unit.dragonBottom:SetTexture(addonpath.."\\img\\BOTTOM_GOLD_"..pos)
--            unit.dragonBottom:Show()
--            unit.dragonBottom:SetVertexColor(.85,.15,.15,1)
--        elseif isCompanion or elite == "rareelite" then
--            unit.dragonTop:SetTexture(addonpath.."\\img\\TOP_GOLD_"..pos)
--            unit.dragonTop:Show()
--            unit.dragonTop:SetVertexColor(1,1,1,1)
--            unit.dragonBottom:SetTexture(addonpath.."\\img\\BOTTOM_GOLD_"..pos)
--            unit.dragonBottom:Show()
--            unit.dragonBottom:SetVertexColor(1,1,1,1)
--        elseif elite == "elite" then
--            unit.dragonTop:SetTexture(addonpath.."\\img\\TOP_GOLD_"..pos)
--            unit.dragonTop:Show()
--            unit.dragonTop:SetVertexColor(.75,.6,0,1)
--            unit.dragonBottom:SetTexture(addonpath.."\\img\\BOTTOM_GOLD_"..pos)
--            unit.dragonBottom:Show()
--            unit.dragonBottom:SetVertexColor(.75,.6,0,1)
--        elseif elite == "rare" then
--            unit.dragonTop:SetTexture(addonpath.."\\img\\TOP_GRAY_"..pos)
--            unit.dragonTop:Show()
--            unit.dragonTop:SetVertexColor(.8,.8,.8,1)
--            unit.dragonBottom:SetTexture(addonpath.."\\img\\BOTTOM_GRAY_"..pos)
--            unit.dragonBottom:Show()
--            unit.dragonBottom:SetVertexColor(.8,.8,.8,1)
--        else
--            unit.dragonTop:Hide()
--            unit.dragonBottom:Hide()
--        end
--    end
--
--    HookRefreshUnit(this, unit, component)
--end

function NotGrid:GetAllCompanionsMap()
    self.AllCompanionMap = AllCompanionMap
end

function NotGrid:GetYourCompanionsMap()
    self.YourCompanionMap = YourCompanionMap
end
