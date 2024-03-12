-- init.lua

-- store the NPCs of a mission
local missionNPCs = {}

resource.AddFile("weapons/tool_gun.lua") -- Add the tool gun to the list of available weapons

if not file.Exists("missions", "DATA") then
    file.CreateDir("missions")
end

util.AddNetworkString("StartMission")

util.AddNetworkString("VisualizeMission")

concommand.Add("visualize_mission", function(ply, cmd, args)
    local missionName = args
        [1]                                                                            -- Get the mission name from the arguments
    local missionData = file.Read("missions/" .. missionName .. "_npcpos.txt", "DATA") -- Read the mission data from a file

    if missionData then
        local missionTable = util.JSONToTable(missionData) -- Convert the mission data from JSON to a table

        for _, npcData in ipairs(missionTable.npcs) do
            net.Start("VisualizeMission")
            net.WriteTable(npcData)
            net.Send(ply) -- Send the NPC data to the player
        end
    end
end)

function StartMission(ply, cmd, args)
    local missionName = args
        [1]                                                                            -- Get the mission name from the arguments
    local missionData = file.Read("missions/" .. missionName .. "_npcpos.txt", "DATA") -- Read the mission data from a file

    if missionData then
        local missionTable = util.JSONToTable(missionData) -- Convert the mission data from JSON to a table
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


            -- If tied to a patrol, make the NPC walk to each point
            if missionTable.patrolPath then
                local patrolPathName = missionTable.patrolPath
                local patrolData = file.Read("missions/" .. patrolPathName .. "_path.txt", "DATA")

                -- Make the NPC open a door
                local doors = ents.FindByClass("func_door")            -- Find all rotating door entities
                for _, door in ipairs(doors) do
                    if door:GetPos():Distance(npc:GetPos()) < 200 then -- If the door is within 200 units of the NPC
                        door:Fire("Open")                              -- Open the door
                    end
                end

                if patrolData then
                    local patrolPoints = util.JSONToTable(patrolData)

                    if patrolPoints then
                        -- Check if the drawn path is available
                        local startArea = navmesh.GetNearestNavArea(patrolPoints[1])
                        local endArea = navmesh.GetNearestNavArea(patrolPoints[#patrolPoints])
                        local path = navmesh.FindPath(startArea:GetCenter(), endArea:GetCenter())

                        if path then
                            -- Make the NPC follow the drawn path
                            MakeNPCFollowPath(npc, path)
                        else
                            -- Make the NPC follow the patrol points
                            local i = 1

                            local function moveToNextPoint()
                                local point = patrolPoints[i]
                                npc:MoveToPos(point, 50) -- Adjust the speed (50) as needed

                                -- Check if the NPC is close to a player
                                local players = ents.FindByClass("player")
                                for _, player in ipairs(players) do
                                    if npc:GetPos():Distance(player:GetPos()) < 200 then
                                        npc:StopMoving()
                                        npc:FaceEntity(player)
                                        timer.Simple(2, function() npc:MoveToPos(point, 50) end) -- Resume walking after 2 seconds
                                        return
                                    end
                                end

                                -- Check if the NPC has reached the final point
                                if i == #patrolPoints then
                                    -- Check if the final point is close to the first point
                                    if point:Distance(patrolPoints[1]) < 200 then
                                        i = 1    -- Continue walking to the first point
                                    else
                                        npc:Remove() -- Despawn the NPC if the final point is not close to the first point
                                        return
                                    end
                                else
                                    i = i + 1
                                end

                                -- Call the function recursively for the next point
                                timer.Simple(1, moveToNextPoint)
                            end

                            -- Start the patrol by moving to the first point
                            moveToNextPoint()
                        end
                    else
                        print("Invalid patrol path data for: " .. patrolPathName)
                    end
                else
                    print("Patrol path file not found for: " .. patrolPathName)
                end
            end

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
