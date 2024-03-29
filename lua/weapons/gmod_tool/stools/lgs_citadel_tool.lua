-- lgs_citadel_tool.lua

CreateConVar("my_tool_mission_name", "", FCVAR_REPLICATED, "The name of the mission")
CreateConVar("my_tool_mission_description", "", FCVAR_REPLICATED, "The description of the mission")
CreateConVar("my_tool_npc_class", "", FCVAR_REPLICATED, "The class of the NPC")
CreateConVar("my_tool_npc_model", "", FCVAR_REPLICATED, "The model of the NPC")
CreateConVar("my_tool_npc_weapon", "", FCVAR_REPLICATED, "The weapon of the NPC")
CreateConVar("my_tool_npc_health", "", FCVAR_REPLICATED, "The health of the NPC")
CreateConVar("my_tool_npc_hostile", "0", FCVAR_ARCHIVE, "Is the NPC hostile?")
CreateConVar("my_tool_npc_weapon_proficiency", "0", FCVAR_ARCHIVE, "Weapon proficiency of the NPC")

-- Tool settings
TOOL.Category   = "[LGS] Citadel"
TOOL.Name       = "Citadel Tool"
TOOL.Command    = nil
TOOL.ConfigName = ""

if CLIENT then
    -- Localization
    language.Add("tool.lgs_citadel_tool.name", "Citadel Tool")
    language.Add("tool.lgs_citadel_tool.desc", "LGS Citadel Tool to place NPCs and create missions")
    language.Add("tool.lgs_citadel_tool.0", "By Noahbds")

    -- Fonts
    local fontParams = { font = "Arial", size = 30, weight = 1000, antialias = true, additive = false }
    surface.CreateFont("LGSFONT", fontParams)
    surface.CreateFont("LGSFONT2", fontParams)
end

function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "Missions", Description = "List of created missions" })

    local listBox = vgui.Create("DListBox", panel)
    listBox:SetSize(200, 200)
    listBox:SetPos(10, 460)

    local deleteButton = vgui.Create("DButton", panel)
    deleteButton:SetText("Delete Mission")
    deleteButton:SetSize(90, 30) -- Réduire la taille du bouton
    deleteButton:SetPos(10, 420)

    local startButton = vgui.Create("DButton", panel)
    startButton:SetText("Start Mission")
    startButton:SetSize(90, 30)  -- Réduire la taille du bouton
    startButton:SetPos(110, 420) -- Ajuster la position du bouton

    local cancelButton = vgui.Create("DButton", panel)
    cancelButton:SetText("Cancel Mission")
    cancelButton:SetSize(90, 30)  -- Réduire la taille du bouton
    cancelButton:SetPos(210, 420) -- Ajuster la position du bouton

    local visualizeButton = vgui.Create("DButton", panel)
    visualizeButton:SetText("Visualize Mission")
    visualizeButton:SetSize(90, 30)  -- Réduire la taille du bouton
    visualizeButton:SetPos(310, 420) -- Ajuster la position du bouton

    -- Function to update the ListBox with the current missions
    local function updateMissions()
        listBox:Clear()

        local files, _ = file.Find("missions/*", "DATA")
        for _, file in ipairs(files) do
            local missionName = string.gsub(file, "_npcpos.txt", "")
            local item = listBox:AddItem(missionName) -- Get the item panel

            -- Set up the OnSelect functionality
            item.DoClick = function()
                RunConsoleCommand("my_tool_mission_name", missionName)
            end
        end

        -- Disable or enable buttons based on whether a mission name is provided
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        deleteButton:SetEnabled(missionName ~= "")
        startButton:SetEnabled(missionName ~= "")
        cancelButton:SetEnabled(missionName ~= "")
        visualizeButton:SetEnabled(missionName ~= "")
    end

    deleteButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            print("No mission name provided.")
            return
        end

        local missionFilePath = "missions/" .. missionName .. "_npcpos.txt"
        if not file.Exists(missionFilePath, "DATA") then
            print("Mission not found: " .. missionName)
            return
        end

        file.Delete(missionFilePath)
        print("Mission deleted: " .. missionName)

        updateMissions()
    end

    deleteButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: No mission name provided.")
            return
        end

        local missionFilePath = "missions/" .. missionName .. "_npcpos.txt"
        if not file.Exists(missionFilePath, "DATA") then
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: Mission not found: " .. missionName)
            return
        end

        file.Delete(missionFilePath)
        chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: Mission deleted: " .. missionName)

        updateMissions()
    end

    startButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: No mission name provided.")
            return
        end
        local missionFilePath = "missions/" .. missionName .. "_npcpos.txt"
        if not file.Exists(missionFilePath, "DATA") then
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: Mission not found: " .. missionName)
            return
        end

        RunConsoleCommand("start_mission", missionName)
        chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: Mission started: " .. missionName)
    end

    cancelButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: No mission name provided.")
            return
        end
        local missionFilePath = "missions/" .. missionName .. "_npcpos.txt"
        if not file.Exists(missionFilePath, "DATA") then
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: Mission not found: " .. missionName)
            return
        end

        RunConsoleCommand("cancel_mission", missionName)
        chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: Mission cancelled: " .. missionName)
    end

    visualizeButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: No mission name provided.")
            return
        end
        -- Check if a mission is already being visualized
        if isVisualizing then
            RunConsoleCommand("StopVisualizeMission", missionName)
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: Mission visualization stopped: " .. missionName)
            isVisualizing = false
        else
            RunConsoleCommand("visualize_mission", missionName)
            chat.AddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: Mission visualized: " .. missionName)
            isVisualizing = true
        end
    end

    -- Update the ListBox immediately
    updateMissions()

    -- Set up a timer to update the ListBox every second
    timer.Create("UpdateMissionsTimer", 1, 0, updateMissions)

    panel:AddControl("Header", { Text = "Mission Settings", Description = "Set the name and description of the mission" })

    panel:AddControl("TextBox", {
        Label = "Mission Name",
        Command = "my_tool_mission_name",
        MaxLength = "50"
    })

    panel:AddControl("TextBox", {
        Label = "Mission Description",
        Command = "my_tool_mission_description",
        MaxLength = "100"
    })

    panel:AddControl("Button", {
        Text = "Create Mission",
        Command = "my_tool_create_mission"
    })

    -- Add NPC settings controls
    panel:AddControl("Header", { Text = "NPC Settings", Description = "Set the class and model of the NPC" })

    panel:AddControl("TextBox", {
        Label = "NPC Class",
        Command = "my_tool_npc_class",
        MaxLength = "50"
    })

    panel:AddControl("TextBox", {
        Label = "NPC Model",
        Command = "my_tool_npc_model",
        MaxLength = "50"
    })

    panel:AddControl("TextBox", {
        Label = "NPC Weapon",
        Command = "my_tool_npc_weapon",
        MaxLength = "50"
    })

    panel:AddControl("Slider", {
        Label = "Weapon Proficiency",
        Command = "my_tool_npc_weapon_proficiency",
        Type = "Integer",
        Min = 0,
        Max = 4,
        Help = "0: Poor, 1: Average, 2: Good, 3: Very Good, 4: Perfect"
    })

    panel:AddControl("CheckBox", {
        Label = "NPC Hostile",
        Command = "my_tool_npc_hostile"
    })

    panel:AddControl("TextBox", {
        Label = "NPC Health",
        Command = "my_tool_npc_health",
        MaxLength = "50"
    })

    local modifymission = vgui.Create("DButton")
    modifymission:SetPos(420, 420) -- Set the position of the button
    modifymission:SetText("Modify NPC")
    modifymission.DoClick = function()
        RunConsoleCommand("my_tool_modify_mission")
    end
    panel:AddItem(modifymission)
end

function TOOL:LeftClick(trace)
    local ply = self:GetOwner()

    local missionName = GetConVar("my_tool_mission_name"):GetString()
    local missionDescription = GetConVar("my_tool_mission_description"):GetString()
    local npcClass = GetConVar("my_tool_npc_class"):GetString()
    local npcModel = GetConVar("my_tool_npc_model"):GetString()
    local npcWeapon = GetConVar("my_tool_npc_weapon"):GetString()
    local npcHealth = GetConVar("my_tool_npc_health"):GetString()
    local npcHostile = GetConVar("my_tool_npc_hostile"):GetBool()
    local npcWeaponProficiency = GetConVar("my_tool_npc_weapon_proficiency"):GetInt()

    -- Check if mission is created and class and model are provided
    if missionName == "" or npcClass == "" or npcModel == "" then
        print("Invalid input. Please fill in all fields.")
        return
    end

    -- Check if mission folder exists
    if not file.Exists("missions", "DATA") then
        file.CreateDir("missions")
    end

    if trace.Hit then
        -- Get the existing mission data or initialize an empty one
        local missionFilePath = "missions/" .. missionName .. "_npcpos.txt"
        local missionData = {}

        if file.Exists(missionFilePath, "DATA") then
            local existingData = file.Read(missionFilePath, "DATA")
            missionData = util.JSONToTable(existingData) or {}
        end

        -- Add mission metadata if not already present
        missionData.name = missionData.name or missionName
        missionData.description = missionData.description or missionDescription

        -- Add the map name to the mission data
        missionData.map = game.GetMap()

        -- Add NPC data to the mission
        local npcData = {
            class = npcClass,
            model = npcModel,
            weapon = npcWeapon,
            health = npcHealth,
            hostile = npcHostile,
            pos = tostring(trace.HitPos),
            weaponProficiency = npcWeaponProficiency
        }

        -- Ensure "npcs" key exists and is an array
        missionData.npcs = missionData.npcs or {}
        table.insert(missionData.npcs, npcData)

        -- Convert mission data to JSON
        local missionDataJson = util.TableToJSON(missionData, true)

        -- Write the JSON data to the mission file
        file.Write(missionFilePath, missionDataJson)
        print("NPC spawn position added for mission: " .. missionName)

        -- Play a sound effect when an NPC spawn position is added
        ply:EmitSound("ui/buttonclick.wav")
    end
end

function TOOL:DrawToolScreen(width, height)
    local ply = self:GetOwner()

    local missionName = GetConVar("my_tool_mission_name"):GetString()
    local npcClass = GetConVar("my_tool_npc_class"):GetString()
    local npcModel = GetConVar("my_tool_npc_model"):GetString()

    local canUseLeftClick = missionName ~= "" and npcClass ~= "" and npcModel ~= ""

    local color = canUseLeftClick and Color(0, 255, 0, 255) or Color(255, 0, 0, 255)

    surface.SetDrawColor(color)
    surface.DrawRect(0, 0, width, height)

    surface.SetFont("LGSFONT")
    local textWidth, textHeight = surface.GetTextSize("[LGS] Auto Citadel")
    surface.SetFont("LGSFONT2")
    local text2Width, text2Height = surface.GetTextSize("By Noahbds")

    draw.SimpleText("[LGS] Auto Citadel", "LGSFONT", width / 2, 100, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER)
    draw.SimpleText("By Noahbds", "LGSFONT2", width / 2, 128 + (textHeight + text2Height) / 2 - 4,
        Color(224, 224, 224, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
