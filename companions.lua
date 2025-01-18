local AllCompanionMap = {  }
local YourCompanionMap = {  }

NotGridClientToServer = CreateFrame("Frame",nil,UIParent)
NotGridServerToClient = CreateFrame("Frame",nil,UIParent) -- create a frame that will listen for events
NotGridServerToClient:RegisterEvent("CHAT_MSG_ADDON") -- register what events do you want the frame to listen for - in our case we want to listen to messages from the server
NotGridServerToClient:RegisterEvent("PARTY_MEMBERS_CHANGED")
NotGridServerToClient:RegisterEvent("PLAYER_ENTERING_WORLD")
NotGridServerToClient:RegisterEvent("CHAT_MSG_MONSTER_WHISPER") -- Used for transfer/follow from other players
NotGridServerToClient:RegisterEvent("CHAT_MSG_SYSTEM")

-- GRINFO:ALL:NAMES
-- GRINFO:SELF:NAMES
function NotGriend_ClientRequest()
    -- It's necessary to call an OnUpdate function from a frame in order to SendAddonMessages to the server
    NotGridClientToServer:SetScript("OnUpdate", function()
        --DEFAULT_CHAT_FRAME:AddMessage("Requesting ALL companion update from server")
        -- Send the message request to the server
        AllCompanionMap = { }
        YourCompanionMap = { }
        SendAddonMessage("nexus", "GRINFO:ALL:NAMES", "BATTLEGROUND")
        SendAddonMessage("nexus", "GRINFO:SELF:NAMES", "BATTLEGROUND")

        -- Clear the OnUpdate script after it finishes because the job's done and we don't want to spam the server
        NotGridClientToServer:SetScript("OnUpdate", nil)

    end)
end

function NotGriend_UpdateYourCompanions()
    -- It's necessary to call an OnUpdate function from a frame in order to SendAddonMessages to the server
    NotGridClientToServer:SetScript("OnUpdate", function()
        --DEFAULT_CHAT_FRAME:AddMessage("Requesting YOUR companion update from server")
        -- Send the message request to the server
        YourCompanionMap = { }
        SendAddonMessage("nexus", "GRINFO:SELF:NAMES", "BATTLEGROUND")

        -- Clear the OnUpdate script after it finishes because the job's done and we don't want to spam the server
        NotGridClientToServer:SetScript("OnUpdate", nil)
    end)
end

-- Removes color codes from string, credit to ArkInventory mentioned here : https://us.forums.blizzard.com/en/wow/t/stripping-text-color-from-gametooltip/382517/2
function StripColorCodes( txt )
    local txt = txt or ""
    txt = string.gsub( txt, "|c%x%x%x%x%x%x%x%x", "" )
    txt = string.gsub( txt, "|c%x%x %x%x%x%x%x", "" ) -- the trading parts colour has a space instead of a zero for some weird reason
    txt = string.gsub( txt, "|r", "" )
    return txt
end

function NotGridServerToClient:OnEvent()
    -- print("SMSG:" .. arg1 .. " arg2:" .. arg2 .. " CHANNEL:" .. arg3 .. " SENDER:" .. arg4)
    -- print(arg1)

    if event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        NotGriend_ClientRequest()
    end

    if event == "CHAT_MSG_MONSTER_WHISPER" then
        --DEFAULT_CHAT_FRAME:AddMessage("Monster whisper: Arg1: " .. tostring(arg1) .. " - Arg2: " .. tostring(arg2)) -- Add debug print
        local name = arg2
        if AllCompanionMap[name] ~= nil then
            NotGriend_ClientRequest()
        end
    end

    if event == "CHAT_MSG_SYSTEM" then
        --It might be possible to update the AllCompanionMap and YourCompanionMap more directly by parsing these events
        --The transfer/untransfer would have to update both tables, while follow/unfollow would only need your companions
        if arg1 then
            stripArg1 = StripColorCodes(arg1)

            if string.find(stripArg1, "has transferred to") or string.find(stripArg1, "has transferred back to you") then
                --DEFAULT_CHAT_FRAME:AddMessage("We found transfer event")
                NotGriend_ClientRequest()
            end

            -- Match "All Companions will follow [Name]"
            -- "Companions" and "follow" are colored, preventing direct match
            if string.find(stripArg1, "All Companions will follow") then
                --DEFAULT_CHAT_FRAME:AddMessage("We found .z follow event")
                NotGriend_UpdateYourCompanions()
            end

            if string.find(stripArg1, "All Companions are back to following you") then
                --DEFAULT_CHAT_FRAME:AddMessage("We found .z unfollow event")
                NotGriend_UpdateYourCompanions()
            end
        end
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
                        --DEFAULT_CHAT_FRAME:AddMessage("Adding to AllCompanionMap: " .. name) -- Add debug print
                    elseif scope == "SELF" then
                        YourCompanionMap[name] = true -- Add your companions to YourCompanionMap
                        --DEFAULT_CHAT_FRAME:AddMessage("Adding to YourCompanionMap: " .. name) -- Add debug print
                    end
                end
            end

            for unitid,_ in NotGrid.UnitFrames do
                NotGrid:UNIT_BORDER(unitid)
            end
        end
    end
end

-- Attach the OnEvent() function to the frame that will execute when the event is triggered. This needs to be done after you've defined the OnEvent() function.
NotGridServerToClient:SetScript("OnEvent", NotGridServerToClient.OnEvent)

function NotGrid:GetAllCompanionsMap()
    self.AllCompanionMap = AllCompanionMap
end

function NotGrid:GetYourCompanionsMap()
    self.YourCompanionMap = YourCompanionMap
end

function NotGrid:IsPlayingWithCompanions()
    return GetRealmName() == "Microbot Vanilla"
end