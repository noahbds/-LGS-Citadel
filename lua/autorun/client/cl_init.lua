-- cl_init.lua

include(init.lua)

net.Receive("StartMission", function()
    local npc = net.ReadEntity() -- Get the NPC entity from the server
end)

concommand.Add("open_mission_selector", function()
    local frame = vgui.Create("DFrame")                                                    -- Create a new frame
    frame:SetSize(500, 300)                                                                -- Set the size of the frame
    frame:Center()                                                                         -- Center the frame on the screen
    frame:SetTitle("Select a Mission")                                                     -- Set the title of the frame
    frame:MakePopup()                                                                      -- Make the frame appear

    local listview = vgui.Create("DListView", frame)                                       -- Create a new list view
    listview:SetSize(480, 150)                                                             -- Set the size of the list view
    listview:SetPos(10, 50)                                                                -- Set the position of the list view
    listview:AddColumn("Mission")                                                          -- Add a column to the list view

    local descriptionLabel = vgui.Create("DLabel", frame)                                  -- Create a new label
    descriptionLabel:SetSize(480, 50)                                                      -- Set the size of the label
    descriptionLabel:SetPos(10, 210)                                                       -- Set the position of the label

    local files = file.Find("missions/*.txt", "DATA")                                      -- Find all mission files
    for _, file in ipairs(files) do                                                        -- For each file...
        local missionName = string.gsub(file, "_npcpos.txt", "")                           -- Get the mission name from the file name
        local missionDescription = file.Read("missions/" .. file, "DATA"):match("^(.-)\n") -- Read the mission description from the file
        listview:AddLine(missionName)                                                      -- Add the mission to the list view
    end

    local startButton = vgui.Create("DButton", frame)                                          -- Create a new button
    startButton:SetSize(480, 30)                                                               -- Set the size of the button
    startButton:SetPos(10, 260)                                                                -- Set the position of the button
    startButton:SetText("Start Mission")                                                       -- Set the text of the button
    startButton:SetEnabled(false)                                                              -- Disable the button by default

    listview.OnRowSelected = function(lst, index, pnl)                                         -- Set what happens when a row is selected
        local selectedMission = pnl:GetColumnText(1)                                           -- Get the selected mission name from the row
        local missionFile = file.Read("missions/" .. selectedMission .. "_npcpos.txt", "DATA") -- Read the mission file
        local missionDescription = missionFile:match("^(.-)\n")                                -- Get the mission description from the file
        descriptionLabel:SetText("Description: " .. missionDescription)                        -- Set the text of the label to the mission description
        startButton:SetEnabled(true)                                                           -- Enable the button when a mission is selected
    end

    startButton.DoClick = function()                                                              -- Set what happens when the button is clicked
        if listview:GetSelectedLine() then                                                        -- Check if a mission is selected
            local selectedMission = listview:GetLine(listview:GetSelectedLine()):GetColumnText(1) -- Get the selected mission name from the list view
            RunConsoleCommand("start_mission", selectedMission)                                   -- Start the selected mission
        end
    end
end)
