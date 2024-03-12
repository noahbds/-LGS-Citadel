-- init.lua

-- store the NPCs of a mission
local missionNPCs = {}

resource.AddFile("weapons/tool_gun.lua") -- Add the tool gun to the list of available weapons

if not file.Exists("missions", "DATA") then
    file.CreateDir("missions")
end

util.AddNetworkString("StartMission") -- Used to communicate between the server and the client

function StartMission(ply, cmd, args)
    local missionName = args
        [1]                                                                            -- Get the mission name from the arguments
    local missionData = file.Read("missions/" .. missionName .. "_npcpos.txt", "DATA") -- Read the mission data from a file
    if missionData then
        local missionTable = util.JSONToTable(missionData)                             -- Convert the mission data from JSON to a table
        local missionName = missionTable.name
        local missionDescription = missionTable.description

        -- Output mission name and description
        print("Mission Name: " .. missionName)
        print("Mission Description: " .. missionDescription)

        for _, npcData in ipairs(missionTable.npcs) do
            local npc = ents.Create(npcData.class)               -- Create an NPC of the specified class
            npc:SetModel(npcData.model)                          -- Set the model of the NPC
            npc:SetPos(util.StringToType(npcData.pos, "Vector")) -- Set the spawn position of the NPC
            npc:Give(npcData.weapon)                             -- Give the NPC the specified weapon
            npc:SetHealth(npcData.health)                        -- Set the health of the NPC
            if npcData.hostile then
                npc:AddRelationship("player D_HT 99")
            end
            npc:Spawn() -- Spawn the NPC
            net.Start("StartMission")
            net.WriteEntity(npc)
            net.Send(ply) -- Send the NPC entity to the player

            -- Add the NPC to the missionNPCs table
            missionNPCs[missionName] = missionNPCs[missionName] or {}
            table.insert(missionNPCs[missionName], npc)
        end
    end
end

concommand.Add("start_mission", StartMission) -- Add the start_mission command

-- Add the cancel_mission command
concommand.Add("cancel_mission", function(ply, cmd, args)
    local missionName = args[1] -- Get the mission name from the arguments

    -- Check if the mission exists
    if not missionNPCs[missionName] then
        print("The mission does not exist or is not active.")
        return
    end

    -- Remove all NPCs of the mission
    for _, npc in ipairs(missionNPCs[missionName]) do
        if IsValid(npc) then
            npc:Remove()
        end
    end

    -- Clear the missionNPCs table for the mission
    missionNPCs[missionName] = nil

    print("Mission " .. missionName .. " has been cancelled.")
end)

concommand.Add("my_tool_create_mission", function(ply, cmd, args)
    -- Ensure that the "missions" folder exists
    if not file.Exists("missions", "DATA") then
        file.CreateDir("missions")
    end

    local missionName = GetConVar("my_tool_mission_name"):GetString() -- Get the mission name from the ConVar

    -- Check if the mission name is defined
    if missionName == "" then
        print("The mission name is not defined.")
        return
    end

    -- Initialize an empty table for mission data
    local missionData = {}

    -- Convert the mission data to JSON
    local missionDataJson = util.TableToJSON(missionData)

    -- Write the mission data to a file
    file.Write("missions/" .. missionName .. "_npcpos.txt", missionDataJson)
end)
