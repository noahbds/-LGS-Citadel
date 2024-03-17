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
    -- Mission Settings Form
    local missionSettingsForm = vgui.Create("DForm", panel)
    missionSettingsForm:SetName("Mission Settings")
    missionSettingsForm:Dock(TOP)
    missionSettingsForm:SetTall(150)

    local missionNameEntry = missionSettingsForm:TextEntry("Mission Name", "my_tool_mission_name")
    missionNameEntry:SetTall(30)
    missionNameEntry:SetTooltip("Enter the name of the mission (max 50 characters)")


    local missionDescEntry = missionSettingsForm:TextEntry("Mission Description", "my_tool_mission_description")
    missionDescEntry:SetTall(60)
    missionDescEntry:SetTooltip("Enter the description of the mission (max 100 characters)")

    local createMissionButton = missionSettingsForm:Button("Create Mission", "my_tool_create_mission")
    createMissionButton:SetTall(30)

    missionNameEntry:OnTextChanged(function()
        local missionName = missionNameEntry:GetValue()
        if missionName ~= "" and missionDescEntry:GetValue() ~= "" then
            -- Vérifiez si le fichier de mission existe déjà
            if file.Exists("missions/" .. missionName .. "_npcpos.txt", "DATA") then
                createMissionButton:SetEnabled(false)
                ply:ChatAddText(Color(255, 0, 0), "[LGS] Citadel : Une mission avec ce nom existe déjà.")
            else
                createMissionButton:SetEnabled(true)
            end
        else
            createMissionButton:SetEnabled(false)
        end
    end)

    missionDescEntry:OnTextChanged(function()
        if missionNameEntry:GetValue() ~= "" and missionDescEntry:GetValue() ~= "" then
            createMissionButton:SetEnabled(true)
        else
            createMissionButton:SetEnabled(false)
        end
    end)

    createMissionButton.DoClick(function()
        createMissionButton:SetEnabled(false)
    end)

    local listBox = vgui.Create("DListBox", panel)
    listBox:SetSize(200, 200)
    listBox:SetPos(10, 460)

    -- Function to update the ListBox with the current missions
    local function updateMissions()
        listBox:Clear()

        local files, _ = file.Find("missions/*", "DATA")
        for _, file in ipairs(files) do
            local missionName = string.gsub(file, "_npcpos.txt", "")
            local item = listBox:AddItem(missionName)

            item.DoClick = function()
                RunConsoleCommand("my_tool_mission_name", missionName)
            end
        end

        local missionName = GetConVar("my_tool_mission_name"):GetString()
        deleteButton:SetEnabled(missionName ~= "")
        startButton:SetEnabled(missionName ~= "")
        cancelButton:SetEnabled(missionName ~= "")
        visualizeButton:SetEnabled(missionName ~= "")
    end

    deleteButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: No mission name provided.")
            return
        end

        local missionFilePath = "missions/" .. missionName .. "_npcpos.txt"
        if not file.Exists(missionFilePath, "DATA") then
            ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: Mission not found: " .. missionName)
            return
        end

        file.Delete(missionFilePath)
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: Mission deleted: " .. missionName)

        updateMissions()
    end

    startButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: No mission name provided.")
            return
        end
        local missionFilePath = "missions/" .. missionName .. "_npcpos.txt"
        if not file.Exists(missionFilePath, "DATA") then
            ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: Mission not found: " .. missionName)
            return
        end

        RunConsoleCommand("start_mission", missionName)
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: Mission started: " .. missionName)
    end

    cancelButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: No mission name provided.")
            return
        end
        local missionFilePath = "missions/" .. missionName .. "_npcpos.txt"
        if not file.Exists(missionFilePath, "DATA") then
            ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: Mission not found: " .. missionName)
            return
        end

        RunConsoleCommand("cancel_mission", missionName)
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: Mission cancelled: " .. missionName)
    end

    visualizeButton.DoClick = function()
        local missionName = GetConVar("my_tool_mission_name"):GetString()
        if missionName == "" then
            ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
                Color(255, 165, 0), "Citadel: No mission name provided.")
            return
        end

        RunConsoleCommand("visualize_mission", missionName)
        ply:ChatAddText(Color(255, 255, 255), "[", Color(255, 0, 0), "LGS", Color(255, 255, 255), "] ",
            Color(255, 165, 0), "Citadel: Mission visualized: " .. missionName)
    end

    -- Update the ListBox immediately
    updateMissions()

    -- Set up a timer to update the ListBox every second
    timer.Create("UpdateMissionsTimer", 1, 0, updateMissions)

    -- NPC Settings Form
    local npcSettingsForm = vgui.Create("DForm", panel)
    npcSettingsForm:SetName("NPC Settings")
    npcSettingsForm:Dock(TOP)
    npcSettingsForm:SetTall(200)

    local npcClassEntry = npcSettingsForm:TextEntry("NPC Class", "my_tool_npc_class")
    npcClassEntry:SetTall(30)
    npcClassEntry:SetTooltip("Enter the class of the NPC (max 50 characters)")

    local npcModelEntry = npcSettingsForm:TextEntry("NPC Model", "my_tool_npc_model")
    npcModelEntry:SetTall(30)
    npcModelEntry:SetTooltip("Enter the model of the NPC (max 50 characters)")

    local npcWeaponEntry = npcSettingsForm:TextEntry("NPC Weapon", "my_tool_npc_weapon")
    npcWeaponEntry:SetTall(30)
    npcWeaponEntry:SetTooltip("Enter the weapon of the NPC (max 50 characters)")

    local npcHealthEntry = npcSettingsForm:TextEntry("NPC Health", "my_tool_npc_health")
    npcHealthEntry:SetTall(30)
    npcHealthEntry:SetTooltip("Enter the health of the NPC")

    local npcProficiencySlider = npcSettingsForm:Slider("Weapon Proficiency", "my_tool_npc_weapon_proficiency", 0, 4)
    npcProficiencySlider:SetTall(50)
    npcProficiencySlider:SetTooltip("Select the weapon proficiency of the NPC")

    local npcHostileCheckbox = npcSettingsForm:CheckBox("NPC Hostile", "my_tool_npc_hostile")
    npcHostileCheckbox:SetTooltip("Check if the NPC should be hostile")

    -- Button Panel
    local buttonPanel = vgui.Create("DPanel", panel)
    buttonPanel:Dock(TOP)
    buttonPanel:SetTall(40)
    buttonPanel.Paint = function() end -- Remove default panel background

    local modifyMissionButton = vgui.Create("DButton", buttonPanel)
    modifyMissionButton:SetText("Modify NPC")
    modifyMissionButton:Dock(RIGHT)
    modifyMissionButton:SetWide(90)
    modifyMissionButton:DockMargin(5, 0, 0, 0)

    local visualizeButton = vgui.Create("DButton", buttonPanel)
    visualizeButton:SetText("Visualize Mission")
    visualizeButton:Dock(RIGHT)
    visualizeButton:SetWide(120)
    visualizeButton:DockMargin(5, 0, 0, 0)

    local cancelButton = vgui.Create("DButton", buttonPanel)
    cancelButton:SetText("Cancel Mission")
    cancelButton:Dock(RIGHT)
    cancelButton:SetWide(90)
    cancelButton:DockMargin(5, 0, 0, 0)

    local startButton = vgui.Create("DButton", buttonPanel)
    startButton:SetText("Start Mission")
    startButton:Dock(RIGHT)
    startButton:SetWide(90)
    startButton:DockMargin(5, 0, 0, 0)

    local deleteButton = vgui.Create("DButton", buttonPanel)
    deleteButton:SetText("Delete Mission")
    deleteButton:Dock(RIGHT)
    deleteButton:SetWide(110)
    deleteButton:DockMargin(5, 0, 0, 0)
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
    local npcWeaponProficiency = GetConVar("my_tool_npc_weapon_proficiency"):GetFloat()

    -- Check if mission is created and class and model are provided
    if missionName == "" or npcClass == "" or npcModel == "" then
        ply:ChatAddText(Color(255, 0, 0), "[LGS] Citadel : Invalid input. Please fill in all fields.")
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
        ply:ChatAddText(Color(0, 255, 0), "[LGS] Citadel : NPC spawn position added for mission: " .. missionName)
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
