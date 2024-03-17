-- cl_init.lua

local missionList = {}
local selectedMission = ""

-- start mission
net.Receive("StartMission", function()
    local npc = net.ReadEntity()

    local missionName = GetConVar("my_tool_mission_name"):GetString()
    local missionDescription = GetConVar("my_tool_mission_description"):GetString()

    if missionName ~= "" then
        missionList[missionName] = missionDescription
    end
    UpdateMissionListUI()
end)


local listview -- déclaration de la variable globale

concommand.Add("open_mission_selector", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 500) -- Taille augmentée de la fenêtre
    frame:Center()
    frame:SetTitle("Select a Mission")
    frame:MakePopup()

    local panel = vgui.Create("DPanel", frame)
    panel:Dock(FILL)
    panel:SetBackgroundColor(Color(50, 50, 50, 200))

    local listview = vgui.Create("DListView", panel)
    listview:Dock(LEFT)
    listview:SetWide(350)      -- Largeur de la liste augmentée
    listview:SetHeaderText("Mission")
    listview:SetDataHeight(30) -- Hauteur des lignes augmentée
    listview:AddColumn("Mission")

    local descriptionPanel = vgui.Create("DPanel", panel)
    descriptionPanel:Dock(FILL)
    descriptionPanel:SetBackgroundColor(Color(70, 70, 70, 200))

    local descriptionLabel = vgui.Create("DLabel", descriptionPanel)
    descriptionLabel:Dock(FILL)
    descriptionLabel:SetContentAlignment(7) -- Centre l'alignement du texte
    descriptionLabel:SetTextColor(Color(255, 255, 255))
    descriptionLabel:SetFont("DermaDefaultBold")
    descriptionLabel:SetText("Select a mission to view description")

    local startButton = vgui.Create("DButton", frame)
    startButton:Dock(BOTTOM)
    startButton:DockMargin(0, 10, 0, 0)
    startButton:SetText("Start Mission")
    startButton:SetTextColor(Color(255, 255, 255))
    startButton:SetFont("DermaDefaultBold")
    startButton:SetColor(Color(0, 100, 0))
    startButton:SetDisabled(true)

    local missionFiles = file.Find("missions/*.txt", "DATA")
    for _, missionFile in ipairs(missionFiles) do
        local missionName = string.gsub(missionFile, "_npcpos.txt", "")
        listview:AddLine(missionName)
    end

    listview.OnRowSelected = function(lst, index, pnl)
        local selectedMission = pnl:GetColumnText(1)
        local missionContent = file.Read("missions/" .. selectedMission .. "_npcpos.txt", "DATA")
        descriptionLabel:SetText(missionContent)
        startButton:SetDisabled(false)
        startButton.DoClick = function()
            RunConsoleCommand("start_mission", selectedMission)
            frame:Close()
        end
    end
end)

function UpdateMissionListUI()
    if listview then -- vérifie si listview est défini
        listview:Clear()

        for missionName, missionDescription in pairs(missionList) do
            listview:AddLine(missionName)
        end
    end
end

-- command to open mission editor
concommand.Add("my_tool_modify_mission", function(ply, cmd, args)
    local function getMissionName()
        return GetConVar("my_tool_mission_name"):GetString()
    end

    local function getMissionFilePath(missionName)
        return "missions/" .. missionName .. "_npcpos.txt"
    end

    local function doesFileExist(filePath)
        if not file.Exists(filePath, "DATA") then
            print("Mission file not found.")
            return false
        end
        return true
    end

    local function readMissionData(filePath)
        local missionData = file.Read(filePath, "DATA")
        local missionTable = util.JSONToTable(missionData)

        if not missionTable then
            print("Failed to parse mission data.")
            return nil
        end

        return missionTable
    end

    -- Frame to edit npc
    local function openModifyDialog(npcData, line, missionTable, listView)
        local editDialog = vgui.Create("DFrame")
        editDialog:SetSize(400, 400)
        editDialog:Center()
        editDialog:SetTitle("Edit NPC Data")

        local classLabel = vgui.Create("DLabel", editDialog)
        classLabel:SetText("NPC Class:")
        classLabel:Dock(TOP)

        local classEntry = vgui.Create("DTextEntry", editDialog)
        classEntry:SetText(npcData.class)
        classEntry:Dock(TOP)

        local modelLabel = vgui.Create("DLabel", editDialog)
        modelLabel:SetText("NPC Model:")
        modelLabel:Dock(TOP)

        local modelEntry = vgui.Create("DTextEntry", editDialog)
        modelEntry:SetText(npcData.model)
        modelEntry:Dock(TOP)

        local weaponLabel = vgui.Create("DLabel", editDialog)
        weaponLabel:SetText("NPC Weapon:")
        weaponLabel:Dock(TOP)

        local weaponEntry = vgui.Create("DTextEntry", editDialog)
        weaponEntry:SetText(npcData.weapon)
        weaponEntry:Dock(TOP)

        local weaponproficiencyLabel = vgui.Create("DLabel", editDialog)
        weaponproficiencyLabel:SetText("NPC Weapon Proficiency:")
        weaponproficiencyLabel:Dock(TOP)

        local weaponproficiencyEntry = vgui.Create("DTextEntry", editDialog)
        weaponproficiencyEntry:SetText(npcData.weaponProficiency)
        weaponproficiencyEntry:Dock(TOP)

        local hostileLabel = vgui.Create("DLabel", editDialog)
        hostileLabel:SetText("NPC Hostile:")
        hostileLabel:Dock(TOP)

        local hostileEntry = vgui.Create("DCheckBoxLabel", editDialog)
        hostileEntry:SetText("Hostile")
        hostileEntry:SetValue(npcData.hostile)
        hostileEntry:Dock(TOP)

        local healthLabel = vgui.Create("DLabel", editDialog)
        healthLabel:SetText("NPC Health:")
        healthLabel:Dock(TOP)

        local healthEntry = vgui.Create("DTextEntry", editDialog)
        healthEntry:SetText(npcData.health)
        healthEntry:Dock(TOP)

        local deleteButton = vgui.Create("DButton", editDialog)
        deleteButton:SetText("Delete NPC")
        deleteButton:Dock(BOTTOM)
        deleteButton.DoClick = function()
            line:Remove()

            for i, data in ipairs(missionTable.npcs) do
                if data == npcData then
                    table.remove(missionTable.npcs, i)
                    break
                end
            end

            local missionData = util.TableToJSON(missionTable, true)
            file.Write(getMissionFilePath(getMissionName()), missionData)

            listView:Clear()
            for _, npcData in ipairs(missionTable.npcs) do
                local newLine = listView:AddLine(npcData.class, npcData.model, npcData.weapon, npcData.weaponProficiency,
                    npcData.health,
                    npcData.hostile, npcData.pos)
                newLine.npcData = npcData
            end

            editDialog:Close()
        end

        local saveButton = vgui.Create("DButton", editDialog)
        saveButton:SetText("Save Changes")
        saveButton:Dock(BOTTOM)
        saveButton.DoClick = function()
            npcData.class = classEntry:GetValue()
            npcData.model = modelEntry:GetValue()
            npcData.weapon = weaponEntry:GetValue()
            npcData.weaponProficiency = weaponproficiencyEntry:GetValue()
            npcData.hostile = hostileEntry:GetChecked()
            npcData.health = healthEntry:GetValue()

            line:SetColumnText(1, npcData.class)
            line:SetColumnText(2, npcData.model)
            line:SetColumnText(3, npcData.weapon)
            line:SetColumnText(4, npcData.weaponProficiency)
            line:SetColumnText(5, npcData.health)
            line:SetColumnText(6, npcData.hostile)

            local missionData = util.TableToJSON(missionTable)
            file.Write(getMissionFilePath(getMissionName()), missionData)

            editDialog:Close()
        end

        editDialog:MakePopup()
    end

    -- Modify Mission Interface
    local function main()
        local missionName = getMissionName()
        local missionFilePath = getMissionFilePath(missionName)
        print("Checking file: " .. missionFilePath)
        if not doesFileExist(missionFilePath) then
            return
        end
        local missionTable = readMissionData(missionFilePath)
        if not missionTable or next(missionTable) == nil then
            print("Mission data is empty.")
            return
        end

        local DPanel = vgui.Create("DPanel")
        DPanel:SetSize(1200, 550)
        DPanel:Center()
        DPanel:MakePopup()

        local listView = vgui.Create("DListView", DPanel)
        listView:SetSize(1050, 500)
        listView:SetPos(10, 10)
        listView:AddColumn("NPC Class")
        listView:AddColumn("NPC Model")
        listView:AddColumn("NPC Weapon")
        listView:AddColumn("NPC Weapon Proficiency")
        listView:AddColumn("NPC Health")
        listView:AddColumn("NPC Hostility")
        listView:AddColumn("NPC Position")

        local closeButton = vgui.Create("DButton", DPanel)
        closeButton:SetText("Close")
        closeButton:SetSize(100, 30)
        closeButton:SetPos(DPanel:GetWide() - 110, 10)
        closeButton.DoClick = function()
            DPanel:Remove()
        end

        local modifyButton = vgui.Create("DButton", DPanel)
        modifyButton:SetText("Modify")
        modifyButton:SetSize(100, 30)
        modifyButton:SetPos(DPanel:GetWide() - 110, 50)
        modifyButton:SetEnabled(false)

        local selectedNpcData = nil
        local selectedLine = nil

        for _, npcData in ipairs(missionTable.npcs) do
            local line = listView:AddLine(npcData.class, npcData.model, npcData.weapon, npcData.weaponProficiency,
                npcData.health, npcData.hostile,
                npcData.pos)
            line.npcData = npcData
            listView.OnRowSelected = function(lst, index, pnl)
                selectedNpcData = pnl.npcData
                selectedLine = pnl
                modifyButton:SetEnabled(true)
            end
        end

        modifyButton.DoClick = function()
            if selectedNpcData and selectedLine then
                openModifyDialog(selectedNpcData, selectedLine, missionTable, listView)
            end
        end
    end

    main()
end)

-- visualize missionNPCs with phantoms
local phantoms = {}
local panelWidth = 350
local panelHeight = 180

net.Receive("VisualizeMission", function(len)
    local npcData = net.ReadTable()

    local phantom = ents.CreateClientProp(npcData.model)
    phantom:SetPos(util.StringToType(npcData.pos, "Vector"))
    phantom:SetRenderMode(RENDERMODE_TRANSALPHA)
    phantom:SetLocalAngles(Angle(0, 0, 0))
    phantom:SetRenderFX(kRenderFxPulseFast)
    phantom:SetColor(Color(255, 255, 255, 100))
    phantom:Spawn()

    phantom:SetMoveType(MOVETYPE_NONE)
    phantom:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    table.insert(phantoms, { phantom = phantom, npcData = npcData })

    -- 3d2d panel for npc data that spawn at phantom position
    hook.Add("PostDrawOpaqueRenderables", "DrawFrame", function()
        for _, data in ipairs(phantoms) do
            local phantom = data.phantom
            local npcData = data.npcData

            if IsValid(phantom) and npcData then
                local playerPos = LocalPlayer():GetPos()
                local phantomPos = phantom:GetPos()
                local distance = playerPos:Distance(phantomPos)

                if distance <= 100 then
                    local pos = phantomPos + Vector(0, 0, 50)
                    local ang = Angle(0, LocalPlayer():EyeAngles().yaw - 90, 90)

                    surface.SetFont("DermaDefaultBold")
                    local panelWidth = 0
                    local panelHeight = 10
                    local textSpacing = 2

                    local offsetY = 0

                    local function drawTextLine(label, value)
                        if value and value ~= "" then
                            local text = label .. ": " .. value
                            local textWidth, textHeight = surface.GetTextSize(text)
                            panelWidth = math.max(panelWidth, textWidth + 20)
                            panelHeight = panelHeight + textHeight + textSpacing
                            return true, text, textHeight
                        end
                        return false, nil, 0
                    end

                    local linesToDraw = {}
                    local yPos = 5

                    local shouldDraw, text, textHeight = drawTextLine("NPC Class", npcData.class)
                    if shouldDraw then
                        table.insert(linesToDraw, { text, yPos })
                        yPos = yPos + textHeight + textSpacing
                    end

                    shouldDraw, text, textHeight = drawTextLine("NPC Weapon", npcData.weapon)
                    if shouldDraw then
                        table.insert(linesToDraw, { text, yPos })
                        yPos = yPos + textHeight + textSpacing
                    end

                    shouldDraw, text, textHeight = drawTextLine("NPC Weapon Proficiency", npcData.weaponProficiency)
                    if shouldDraw then
                        table.insert(linesToDraw, { text, yPos })
                        yPos = yPos + textHeight + textSpacing
                    end

                    shouldDraw, text, textHeight = drawTextLine("NPC Model", npcData.model)
                    if shouldDraw then
                        table.insert(linesToDraw, { text, yPos })
                        yPos = yPos + textHeight + textSpacing
                    end

                    shouldDraw, text, textHeight = drawTextLine("NPC Health", npcData.health)
                    if shouldDraw then
                        table.insert(linesToDraw, { text, yPos })
                        yPos = yPos + textHeight + textSpacing
                    end

                    shouldDraw, text, textHeight = drawTextLine("NPC Hostile", npcData.hostile and "Yes" or "No")
                    if shouldDraw then
                        table.insert(linesToDraw, { text, yPos })
                        yPos = yPos + textHeight + textSpacing
                    end

                    shouldDraw, text, textHeight = drawTextLine("NPC Spawn Pos", npcData.pos)
                    if shouldDraw then
                        table.insert(linesToDraw, { text, yPos })
                        yPos = yPos + textHeight + textSpacing
                    end

                    local offsetX = -panelWidth / 2
                    offsetY = -panelHeight / 2

                    cam.Start3D2D(pos, ang, 0.1)
                    surface.SetDrawColor(50, 50, 50, 200)
                    surface.DrawRect(offsetX, offsetY, panelWidth, panelHeight)

                    for _, lineData in ipairs(linesToDraw) do
                        local line, yPos = unpack(lineData)
                        draw.SimpleText(line, "DermaDefaultBold", offsetX + 10, offsetY + yPos, Color(255, 255, 255),
                            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    end

                    cam.End3D2D()
                end
            end
        end
    end)
end)
