-- lgs_citadel_tool.lua

CreateConVar("my_tool_mission_name", "", FCVAR_REPLICATED, "The name of the mission")
CreateConVar("my_tool_mission_description", "", FCVAR_REPLICATED, "The description of the mission")
CreateConVar("my_tool_npc_class", "", FCVAR_REPLICATED, "The class of the NPC")
CreateConVar("my_tool_npc_model", "", FCVAR_REPLICATED, "The model of the NPC")
CreateConVar("my_tool_npc_weapon", "", FCVAR_REPLICATED, "The weapon of the NPC")
CreateConVar("my_tool_npc_health", "", FCVAR_REPLICATED, "The health of the NPC")

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
    surface.CreateFont("CTNV", fontParams)
    surface.CreateFont("CTNV2", fontParams)
end

-- Build the control panel for the tool
function TOOL.BuildCPanel(panel)
    -- Add a ListBox for the missions
    panel:AddControl("Header", { Text = "Missions", Description = "List of created missions" })

    local listBox = vgui.Create("DListBox", panel)
    listBox:SetSize(200, 200)
    listBox:SetPos(10, 400) -- Set the position of the ListBox

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
    end

    -- Update the ListBox immediately
    updateMissions()

    -- Set up a timer to update the ListBox every second
    timer.Create("UpdateMissionsTimer", 1, 0, updateMissions)


    -- Create a custom button
    local deleteButton = vgui.Create("DButton", panel)
    deleteButton:SetText("Delete Mission")
    deleteButton:SetSize(100, 30) -- Set the size of the button
    deleteButton:SetPos(10, 350)  -- Set the position of the button

    -- Set up the button click action
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

        -- Update the ListBox
        updateMissions()
    end

    -- Rest of your code...
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

    panel:AddControl("TextBox", {
        Label = "NPC Health",
        Command = "my_tool_npc_health",
        MaxLength = "50"
    })

    panel:AddControl("Button", {
        Text = "Modify NPC",
        Command = "my_tool_modify_mission"
    })
end

-- Draw the tool screen
function TOOL:DrawToolScreen(width, height)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, width, height)

    surface.SetFont("CTNV")
    local textWidth, textHeight = surface.GetTextSize("CTNV")
    surface.SetFont("CTNV2")
    local text2Width, text2Height = surface.GetTextSize("By Noahbds")

    draw.SimpleText("addon_name", "CTNV", width / 2, 100, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("By Noahbds", "CTNV2", width / 2, 128 + (textHeight + text2Height) / 2 - 4, Color(224, 224, 224, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Handle the primary attack (placing NPCs)
function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    local tr = ply:GetEyeTrace()

    local missionName = GetConVar("my_tool_mission_name"):GetString()
    local missionDescription = GetConVar("my_tool_mission_description"):GetString()
    local npcClass = GetConVar("my_tool_npc_class"):GetString()
    local npcModel = GetConVar("my_tool_npc_model"):GetString()
    local npcWeapon = GetConVar("my_tool_npc_weapon"):GetString()
    local npcHealth = GetConVar("my_tool_npc_health"):GetString()

    -- Check if mission is created and class and model are provided
    if missionName == "" or npcClass == "" or npcModel == "" or npcWeapon == "" then
        print("Invalid input. Please fill in all fields.")
        return
    end

    -- Check if mission folder exists
    if not file.Exists("missions", "DATA") then
        file.CreateDir("missions")
    end

    if tr.Hit then
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

        -- Add NPC data to the mission
        local npcData = {
            class = npcClass,
            model = npcModel,
            weapon = npcWeapon,
            health = npcHealth,
            pos = tostring(tr.HitPos)
        }

        -- Ensure "npcs" key exists and is an array
        missionData.npcs = missionData.npcs or {}
        table.insert(missionData.npcs, npcData)

        -- Convert mission data to JSON
        local missionDataJson = util.TableToJSON(missionData)

        -- Call the base class's PrimaryAttack function to create the laser beam effect
        self.BaseClass.PrimaryAttack(self)

        -- Write the JSON data to the mission file
        file.Write(missionFilePath, missionDataJson)
        print("NPC spawn position added for mission: " .. missionName)
    end
end
