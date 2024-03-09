-- cl_init.lua

local missionList = {}
local selectedMission = "" -- Variable to store the selected mission name

net.Receive("StartMission", function()
    local npc = net.ReadEntity() -- Get the NPC entity from the server

    -- Add mission information to the list
    local missionName = GetConVar("my_tool_mission_name"):GetString()
    local missionDescription = GetConVar("my_tool_mission_description"):GetString()

    if missionName ~= "" then
        missionList[missionName] = missionDescription
    end

    -- Refresh the UI with the updated mission list
    UpdateMissionListUI()
end)

concommand.Add("open_mission_selector", function()
    local frame = vgui.Create("DFrame")                                                        -- Create a new frame
    frame:SetSize(500, 300)                                                                    -- Set the size of the frame
    frame:Center()                                                                             -- Center the frame on the screen
    frame:SetTitle("Select a Mission")                                                         -- Set the title of the frame
    frame:MakePopup()                                                                          -- Make the frame appear

    local listview = vgui.Create("DListView", frame)                                           -- Create a new list view
    listview:SetSize(480, 150)                                                                 -- Set the size of the list view
    listview:SetPos(10, 50)                                                                    -- Set the position of the list view
    listview:AddColumn("Mission")                                                              -- Add a column to the list view

    local descriptionLabel = vgui.Create("DLabel", frame)                                      -- Create a new label
    descriptionLabel:SetSize(480, 50)                                                          -- Set the size of the label
    descriptionLabel:SetPos(10, 210)                                                           -- Set the position of the label

    local files = file.Find("missions/*.txt", "DATA")                                          -- Find all mission files
    for _, file in ipairs(files) do                                                            -- For each file...
        local missionName = string.gsub(file, "_npcpos.txt", "")                               -- Get the mission name from the file name
        local missionFile = file.Read("missions/" .. selectedMission .. "_npcpos.txt", "DATA") -- Read the mission file                 -- Read the mission file
        local missionDescription = missionFile and missionFile:match("^(.-)\n") or
            ""                                                                                 -- Get the mission description from the file
        listview:AddLine(missionName)                                                          -- Add the mission to the list view
    end

    local startButton = vgui.Create("DButton", frame) -- Create a new button
    startButton:SetSize(480, 30)                      -- Set the size of the button
    startButton:SetPos(10, 260)                       -- Set the position of the button
    startButton:SetText("Start Mission")              -- Set the text of the button
    startButton:SetEnabled(false)                     -- Disable the button by default

    -- Update the function to handle mission selection
    listview.OnRowSelected = function(lst, index, pnl)
        selectedMission = pnl:GetColumnText(1)                                                 -- Get the selected mission name from the row
        local missionFile = file.Read("missions/" .. selectedMission .. "_npcpos.txt", "DATA") -- Read the mission file
        local missionDescription = missionFile:match("^(.-)\n")                                -- Get the mission description from the file
        descriptionLabel:SetText("Description: " .. missionDescription)                        -- Set the text of the label to the mission description
        startButton:SetEnabled(true)                                                           -- Enable the button when a mission is selected
    end

    startButton.DoClick = function()
        if selectedMission ~= "" then
            -- Request the server to start the selected mission
            net.Start("StartMission")
            net.WriteString(selectedMission)
            net.SendToServer()
        end
    end
end)

function UpdateMissionListUI()
    -- Update the UI with the mission list
    listview:Clear()

    for missionName, missionDescription in pairs(missionList) do
        listview:AddLine(missionName)
    end
end

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
            -- Remove the line from the list view
            line:Remove()

            -- Remove the NPC data from missionTable
            for i, data in ipairs(missionTable.npcs) do
                if data == npcData then
                    table.remove(missionTable.npcs, i)
                    break
                end
            end

            -- Save the updated missionTable to the mission file
            local missionData = util.TableToJSON(missionTable)
            file.Write(getMissionFilePath(getMissionName()), missionData)

            -- Refresh the list view in real-time
            listView:Clear()
            for _, npcData in ipairs(missionTable.npcs) do
                local newLine = listView:AddLine(npcData.class, npcData.model, npcData.weapon, npcData.health,
                    npcData.pos)
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
            npcData.health = healthEntry:GetValue()

            -- Update the list view
            line:SetColumnText(1, npcData.class)
            line:SetColumnText(2, npcData.model)
            line:SetColumnText(3, npcData.weapon)
            line:SetColumnText(4, npcData.health)

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

        -- Create a frame
        local DPanel = vgui.Create("DPanel")
        DPanel:SetSize(1200, 550)
        DPanel:Center()
        DPanel:MakePopup()

        -- Add a list view to the frame to show NPC spawn positions
        local listView = vgui.Create("DListView", DPanel)
        listView:SetSize(1050, 500)
        listView:SetPos(10, 10)
        listView:AddColumn("NPC Class")
        listView:AddColumn("NPC Model")
        listView:AddColumn("NPC Weapon")
        listView:AddColumn("NPC Health")
        listView:AddColumn("NPC Position")

        -- Add a close button to the frame
        local closeButton = vgui.Create("DButton", DPanel)
        closeButton:SetText("Close")
        closeButton:SetSize(100, 30)
        closeButton:SetPos(DPanel:GetWide() - 110, 10) -- Position the button at the top right corner
        closeButton.DoClick = function()
            DPanel:Remove()
        end

        -- Add a modify button to the frame
        local modifyButton = vgui.Create("DButton", DPanel)
        modifyButton:SetText("Modify")
        modifyButton:SetSize(100, 30)
        modifyButton:SetPos(DPanel:GetWide() - 110, 50) -- Position the button below the close button
        modifyButton:SetEnabled(false)                  -- Disable the button by default

        local selectedNpcData = nil
        local selectedLine = nil

        for _, npcData in ipairs(missionTable.npcs) do
            local line = listView:AddLine(npcData.class, npcData.model, npcData.weapon, npcData.health, npcData.pos)
            line.npcData = npcData            -- Store npcData in the line
            listView.OnRowSelected = function(lst, index, pnl)
                selectedNpcData = pnl.npcData -- Get npcData from the selected line
                selectedLine = pnl
                modifyButton:SetEnabled(true) -- Enable the button when a row is selected
            end
        end

        modifyButton.DoClick = function()
            if selectedNpcData and selectedLine then
                openModifyDialog(selectedNpcData, selectedLine, missionTable, listView)
            end
        end
    end

    -- Call the main function
    main()
end)
