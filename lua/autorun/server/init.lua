-- init.lua

resource.AddFile("weapons/tool_gun.lua") -- Add the tool gun to the list of available weapons

util.AddNetworkString("StartMission")    -- Used to communicate between the server and the client

function StartMission(ply, cmd, args)
    local missionName = args[1]                                                        -- Get the mission name from the arguments
    local missionData = file.Read("missions/" .. missionName .. "_npcpos.txt", "DATA") -- Read the mission data from a file
    if missionData then
        local missionTable = util.JSONToTable(missionData)                             -- Convert the mission data from JSON to a table
        for _, npcData in ipairs(missionTable) do
            local npc = ents.Create(npcData.npcClass)                                  -- Create an NPC of the specified class
            npc:SetModel(npcData.npcModel)                                             -- Set the model of the NPC
            npc:SetPos(npcData.spawnPos)                                               -- Set the spawn position of the NPC
            npc:SelectWeapon(npcData.npcWeapon)                                        -- Give the NPC the specified weapon
            npc:SetHealth(npcData.npcHealth)                                           -- Set the health of the NPC
            npc:Spawn()                                                                -- Spawn the NPC
            net.Start("StartMission")
            net.WriteEntity(npc)
            net.Send(ply) -- Send the NPC entity to the player
        end
    end
end

concommand.Add("start_mission", StartMission) -- Add the start_mission command
