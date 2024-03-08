-- init.lua

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
            npc:Spawn()                                          -- Spawn the NPC
            net.Start("StartMission")
            net.WriteEntity(npc)
            net.Send(ply) -- Send the NPC entity to the player
        end
    end
end

concommand.Add("start_mission", StartMission) -- Add the start_mission command
