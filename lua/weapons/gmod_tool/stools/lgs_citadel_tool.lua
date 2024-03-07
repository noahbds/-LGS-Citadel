-- lgs_citadel_tool.lua

TOOL.Category   = "[LGS] Citadel"
TOOL.Name       = "Ciatdel Tool"
TOOL.Command    = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.lgs_citadel_tool.name", "Citadel Tool")
    language.Add("tool.lgs_citadel_tool.desc", "LGS Citadel Tool to place NPCs and create missions")
    language.Add("tool.lgs_citadel_tool.0", "By Noahbds")

    local fontParams = { font = "Arial", size = 30, weight = 1000, antialias = true, additive = false }

    surface.CreateFont("CTNV", fontParams)
    surface.CreateFont("CTNV2", fontParams)
end

function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "Mission Settings", Description = "Set the name and description of the mission" })

    panel:AddControl("TextBox", {
        Label = "Mission Name",
        Text = "my_tool_mission_name",
        MaxLenth = "50"
    })

    panel:AddControl("TextBox", {
        Label = "Mission Description",
        Text = "my_tool_mission_description",
        MaxLenth = "100"
    })

    panel:AddControl("Button", {
        Text = "Create Mission",
        Command = "my_tool_create_mission"
    })

    -- Add a condition to check if the mission name is set before showing NPC settings
    local missionName = GetConVarString("my_tool_mission_name")
    if missionName ~= "" then
        panel:AddControl("Header", { Text = "NPC Settings", Description = "Set the class and model of the NPC" })

        panel:AddControl("TextBox", {
            Label = "NPC Class",
            Text = "my_tool_npc_class",
            MaxLenth = "50"
        })

        panel:AddControl("TextBox", {
            Label = "NPC Model",
            Text = "my_tool_npc_model",
            MaxLenth = "50"
        })

        panel:AddControl("TextBox", {
            Label = "NPC Weapon",
            Text = "my_tool_npc_weapon",
            MaxLenth = "50"
        })

        panel:AddControl("TextBox", {
            Label = "NPC Health",
            Text = "my_tool_npc_health",
            MaxLenth = "50"
        })
    end
end

function TOOL:DrawToolScreen(width, height)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, width, height)

    surface.SetFont("CTNV")
    local textWidth, textHeight = surface.GetTextSize("CTNV")
    surface.SetFont("CTNV2")
    local text2Width, text2Height = surface.GetTextSize("By Noahbds")

    draw.SimpleText("addon_name", "CTNV", width / 2, 100, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER)
    draw.SimpleText("By Noahbds", "CTNV2", width / 2, 128 + (textHeight + text2Height) / 2 - 4, Color(224, 224, 224, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    local tr = ply:GetEyeTrace()

    local missionName = GetConVarString("my_tool_mission_name")
    local npcClass = GetConVarString("my_tool_npc_class")
    local npcModel = GetConVarString("my_tool_npc_model")
    local npcWeapon = GetConVarString("my_tool_npc_weapon")
    local npcHealth = GetConVarString("my_tool_npc_health")

    -- Check if mission is created and class and model are provided
    if missionName == "" or npcClass == "" or npcModel == "" or npcWeapon == "" then
        return
    end

    -- Check if class and model are valid
    local validClasses = list.Get("NPC")
    local validWepons = list.Get("Weapon")
    local validModels = list.Get("PlayerOptionsModel")

    if not validClasses[npcClass] or not validModels[npcModel] or not validWepons[npcWeapon] then
        return
    end

    if (tr.Hit) then
        local data = npcClass ..
            " " ..
            npcModel ..
            " " ..
            npcWeapon ..
            " " ..
            npcHealth ..
            " " .. tostring(tr.HitPos.x) .. " " .. tostring(tr.HitPos.y) .. " " .. tostring(tr.HitPos.z) .. "\n"
        file.Append(missionName .. "_npcpos.txt", data)
    end
end
