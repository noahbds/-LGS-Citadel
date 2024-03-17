---@diagnostic disable: undefined-global
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
    elseif list.Get("NPC")[npcClass] or scripted_ents.IsBasedOn(npcClass, "nb_base") or scripted_ents.IsBasedOn(npcClass, "npc_vj_*") then
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
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: Mission data not found for: " .. missionName)
        return
    end

    local currentMap = game.GetMap()

    local missionTable = util.JSONToTable(missionData)

    if missionTable.map ~= currentMap then
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: The mission cannot be started because the map does not match.")
        return
    end

    local missionName = missionTable.name
    local missionDescription = missionTable.description

    ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ", Color(255, 165, 0),
        "Citadel: Mission Name: " .. missionName)
    ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ", Color(255, 165, 0),
        "Citadel: Mission Description: " .. missionDescription)

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

-- Cancel a mission (New Method - Not Tested Yet)
concommand.Add("cancel_mission", function(ply, cmd, args)
    local missionName = args[1]
    if not missionName then
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: No mission name provided.")
        return
    end

    local missionNpcs = missionNPCs[missionName]
    if not missionNpcs then
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: No active mission found with name: " .. missionName)
        return
    end

    for _, npc in ipairs(missionNpcs) do
        if IsValid(npc) then
            if npc:IsNextBot() then
                npc:BecomeRagdoll()
            elseif string.StartWith(npc:GetClass(), "npc_vj_") then
                npc:Remove()
            else
                npc:Remove()
            end
        end
    end

    missionNPCs[missionName] = nil
    ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ", Color(255, 165, 0),
        "Citadel: Mission cancelled: " .. missionName)
end)

concommand.Add("my_tool_create_mission", function(ply, cmd, args)
    if not file.Exists("missions", "DATA") then
        file.CreateDir("missions")
    end

    local missionName = GetConVar("my_tool_mission_name"):GetString()

    if missionName == "" then
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: The mission name is not defined.")
        return
    end

    local missionData = {}

    local missionDataJson = util.TableToJSON(missionData)

    file.Write("missions/" .. missionName .. "_npcpos.txt", missionDataJson)
end)
