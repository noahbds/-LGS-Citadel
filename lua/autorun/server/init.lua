-- init.lua

local missionNPCs = {}

resource.AddFile("weapons/tool_gun.lua")
if not file.Exists("missions", "DATA") then
    file.CreateDir("missions")
end

util.AddNetworkString("StartMission")

util.AddNetworkString("VisualizeMission")

concommand.Add("visualize_mission", function(ply, cmd, args)
    local missionName = args
        [1]
    local missionData = file.Read("missions/" .. missionName .. "_npcpos.txt", "DATA")
    if missionData then
        local missionTable = util.JSONToTable(missionData)

        for _, npcData in ipairs(missionTable.npcs) do
            net.Start("VisualizeMission")
            net.WriteTable(npcData)
            net.Send(ply)
        end
    end
end)

concommand.Add("StopVisualizeMission", function(ply, cmd, args)
    net.Start("StopVisualizeMission")
    net.Send(ply)
end)

function createNPC(npcData)
    local npcClass = npcData.class
    local npcModel = npcData.model
    local npcWeapon = npcData.weapon or "weapon_default"
    local npcPos = util.StringToType(npcData.pos, "Vector")
    local npcHealth = npcData.health or 100
    local isHostile = npcData.hostile
    local npcWeaponProficiency = npcData.weaponProficiency

    local npc

    if _G["NPC_CLASSES"] and (_G["NPC_CLASSES"][npcClass] or scripted_ents.Get(npcClass)) then
        npc = ents.Create(npcClass)
    elseif list.Get("NPC")[npcClass] or scripted_ents.IsBasedOn(npcClass, "nb_base") or scripted_ents.IsBasedOn(npcClass, "npc_*") then
        npc = ents.Create(npcClass)
        npc:SetCustomCollisionCheck(true)
        npc:SetModel(npcModel)
        npc:SetPos(npcPos)
        npc:Spawn()

        for _, otherNpc in ipairs(ents.FindByClass("npc_*")) do
            if IsValid(otherNpc) and otherNpc ~= npc then
                npc:AddEntityRelationship(otherNpc, D_NU, 99)
                otherNpc:AddEntityRelationship(npc, D_NU, 99)
            end
        end
    else
        print("NPC class not supported:", npcClass)
        return nil
    end

    npc:SetModel(npcModel)
    npc:SetPos(npcPos)

    if npcWeapon == nil then
        npcWeapon = "default_weapon"
    end

    npc:Give(npcWeapon)
    npc:SetCurrentWeaponProficiency(npcWeaponProficiency)
    npc:SetHealth(npcHealth)

    if isHostile then
        npc:AddRelationship("player D_HT 99")
    else
        npc:AddRelationship("player D_LI 99")
    end

    return npc
end

function StartMission(player, command, arguments)
    local missionName = arguments[1]
    local missionData = file.Read("missions/" .. missionName .. "_npcpos.txt", "DATA")

    if not missionData then
        print("Mission data not found for:", missionName)
        return
    end

    -- Get the current map name
    local currentMap = game.GetMap()

    -- Convert the mission data from JSON to a Lua table
    local missionTable = util.JSONToTable(missionData)

    -- Check if the map in the mission data matches the current map
    if missionTable.map ~= currentMap then
        print("The mission cannot be started because the map does not match.")
        return
    end

    local missionName = missionTable.name
    local missionDescription = missionTable.description

    print("Mission Name: " .. missionName)
    print("Mission Description: " .. missionDescription)

    missionNPCs[missionName] = missionNPCs[missionName] or {}

    for _, npcData in ipairs(missionTable.npcs) do
        local npc = createNPC(npcData)

        if npc then
            for _, otherNpc in ipairs(missionNPCs[missionName]) do
                if IsValid(otherNpc) and otherNpc ~= npc then
                    npc:AddEntityRelationship(otherNpc, D_NU, 99)
                    otherNpc:AddEntityRelationship(npc, D_NU, 99)
                end
            end

            npc:Spawn()
            net.Start("StartMission")
            net.WriteEntity(npc)
            net.Send(player)

            table.insert(missionNPCs[missionName], npc)
        end
    end
end

concommand.Add("start_mission", StartMission)

concommand.Add("list_missions", function(ply, cmd, args)
    for missionName, _ in pairs(missionNPCs) do
        print("Active mission:", missionName)
    end
end)

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
    if not file.Exists("missions", "DATA") then
        file.CreateDir("missions")
    end

    local missionName = GetConVar("my_tool_mission_name"):GetString()

    if missionName == "" then
        print("The mission name is not defined.")
        return
    end

    local missionData = {}

    local missionDataJson = util.TableToJSON(missionData)

    file.Write("missions/" .. missionName .. "_npcpos.txt", missionDataJson)
end)
