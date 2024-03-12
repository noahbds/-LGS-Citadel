-- cl_init.lua

local missionList = {}
local selectedMission = ""

net.Receive("StartMission", function()
    local npc = net.ReadEntity()

    local missionName = GetConVar("my_tool_mission_name"):GetString()
    local missionDescription = GetConVar("my_tool_mission_description"):GetString()

    if missionName ~= "" then
        missionList[missionName] = missionDescription
    end

    UpdateMissionListUI()
end)

-- user interface to start mission (to do : need to be open from a entity)
concommand.Add("open_mission_selector", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 300)
    frame:Center()
    frame:SetTitle("Select a Mission")
    frame:MakePopup()

    local listview = vgui.Create("DListView", frame)
    listview:SetSize(480, 150)
    listview:SetPos(10, 50)
    listview:AddColumn("Mission")

    local descriptionLabel = vgui.Create("DLabel", frame)
    descriptionLabel:SetSize(480, 50)
    descriptionLabel:SetPos(10, 210)

    local files = file.Find("missions/*.txt", "DATA")
    for _, file in ipairs(files) do
        local missionName = string.gsub(file, "_npcpos.txt", "")
        local missionFile = file.Read("missions/" .. missionName .. "_npcpos.txt", "DATA")
        local missionDescription = missionFile and missionFile:match("^(.-)\n") or
            ""
        listview:AddLine(missionName)
    end

    local startButton = vgui.Create("DButton", frame)
    startButton:SetSize(480, 30)
    startButton:SetPos(10, 260)
    startButton:SetText("Start Mission")
    startButton:SetEnabled(false)

    listview.OnRowSelected = function(lst, index, pnl)
        selectedMission = pnl:GetColumnText(1)
        local missionFile = file.Read("missions/" .. selectedMission .. "_npcpos.txt", "DATA")
        local missionDescription = missionFile:match("^(.-)\n")
        descriptionLabel:SetText("Description: " .. missionDescription)
        startButton:SetEnabled(true)
    end

    startButton.DoClick = function()
        if selectedMission ~= "" then
            net.Start("StartMission")
            net.WriteString(selectedMission)
            net.SendToServer()
        end
    end
end)

function UpdateMissionListUI()
    listview:Clear()

    for missionName, missionDescription in pairs(missionList) do
        listview:AddLine(missionName)
    end
end

-- command to open the mission editor (can be open from the tool panel)
concommand.Add("my_tool_modify_mission", function(ply, cmd, args)
    -- Function to get mission name
    local function getMissionName()
        return GetConVar("my_tool_mission_name"):GetString()
    end

    -- Function to get mission file path
    local function getMissionFilePath(missionName)
        return "missions/" .. missionName .. "_npcpos.txt"
    end

    -- Function to check if file exists
    local function doesFileExist(filePath)
        if not file.Exists(filePath, "DATA") then
            print("Mission file not found.")
            return false
        end
        return true
    end

    -- Function to read mission data
    local function readMissionData(filePath)
        local missionData = file.Read(filePath, "DATA")
        local missionTable = util.JSONToTable(missionData)

        if not missionTable then
            print("Failed to parse mission data.")
            return nil
        end

        return missionTable
    end

    -- Function to open the modify dialog
    local function openModifyDialog(npcData, line, missionTable, listView)
        local editDialog = vgui.Create("DFrame")
        editDialog:SetSize(400, 400)
        editDialog:Center()
        editDialog:SetTitle("Edit NPC Data")

        -- NPC Class
        local classLabel = vgui.Create("DLabel", editDialog)
        classLabel:SetText("NPC Class:")
        classLabel:Dock(TOP)

        local classEntry = vgui.Create("DTextEntry", editDialog)
        classEntry:SetText(npcData.class)
        classEntry:Dock(TOP)

        -- NPC Model
        local modelLabel = vgui.Create("DLabel", editDialog)
        modelLabel:SetText("NPC Model:")
        modelLabel:Dock(TOP)

        local modelEntry = vgui.Create("DTextEntry", editDialog)
        modelEntry:SetText(npcData.model)
        modelEntry:Dock(TOP)

        -- NPC Weapon
        local weaponLabel = vgui.Create("DLabel", editDialog)
        weaponLabel:SetText("NPC Weapon:")
        weaponLabel:Dock(TOP)

        local weaponEntry = vgui.Create("DTextEntry", editDialog)
        weaponEntry:SetText(npcData.weapon)
        weaponEntry:Dock(TOP)

        -- NPC Weapon
        local hostileLabel = vgui.Create("DLabel", editDialog)
        hostileLabel:SetText("NPC Hostile:")
        hostileLabel:Dock(TOP)

        local hostileEntry = vgui.Create("DCheckBoxLabel", editDialog)
        hostileEntry:SetText("Hostile")
        hostileEntry:SetValue(npcData.hostile) -- Set the checkbox state
        hostileEntry:Dock(TOP)

        -- NPC Health
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

            -- Remove the NPC data from missionTable
            for i, data in ipairs(missionTable.npcs) do
                if data == npcData then
                    table.remove(missionTable.npcs, i)
                    break
                end
            end

            -- Save the updated missionTable to the mission file
            local missionData = util.TableToJSON(missionTable, true) -- true for pretty formatting :)
            file.Write(getMissionFilePath(getMissionName()), missionData)

            -- Refresh the list view in real-time
            listView:Clear()
            for _, npcData in ipairs(missionTable.npcs) do
                local newLine = listView:AddLine(npcData.class, npcData.model, npcData.weapon, npcData.health,
                    npcData.hostile, npcData.pos)
                newLine.npcData = npcData
            end

            editDialog:Close()
        end

        local saveButton = vgui.Create("DButton", editDialog)
        saveButton:SetText("Save Changes")
        saveButton:Dock(BOTTOM)
        saveButton.DoClick = function()
            -- Update NPC data and close the dialog
            npcData.class = classEntry:GetValue()
            npcData.model = modelEntry:GetValue()
            npcData.weapon = weaponEntry:GetValue()
            npcData.hostile = hostileEntry:GetChecked()
            npcData.health = healthEntry:GetValue()

            -- Update the list view
            line:SetColumnText(1, npcData.class)
            line:SetColumnText(2, npcData.model)
            line:SetColumnText(3, npcData.weapon)
            line:SetColumnText(4, npcData.hostile)
            line:SetColumnText(5, npcData.health)

            -- Save the updated missionTable to the mission file
            local missionData = util.TableToJSON(missionTable)
            file.Write(getMissionFilePath(getMissionName()), missionData)

            editDialog:Close()
        end

        editDialog:MakePopup()
    end

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
        listView:AddColumn("NPC Hostility")
        listView:AddColumn("NPC Health")
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
            local line = listView:AddLine(npcData.class, npcData.model, npcData.weapon, npcData.health, npcData.hostile,
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
