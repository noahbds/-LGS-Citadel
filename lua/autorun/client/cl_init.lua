-- cl_init.lua

include(init.lua)

net.Receive("StartMission", function()
    local npc = net.ReadEntity() -- Get the NPC entity from the server
end)

concommand.Add("open_mission_selector", function()
    local frame = vgui.Create("DFrame")                                                    -- Create a new frame
    frame:SetSize(400, 200)                                                                -- Set the size of the frame
    frame:Center()                                                                         -- Center the frame on the screen
    frame:SetTitle("Select a Mission")                                                     -- Set the title of the frame
    frame:MakePopup()                                                                      -- Make the frame appear

    local dropdown = vgui.Create("DComboBox", frame)                                       -- Create a new dropdown menu
    dropdown:SetSize(380, 30)                                                              -- Set the size of the dropdown menu
    dropdown:SetPos(10, 50)                                                                -- Set the position of the dropdown menu
    dropdown:SetValue("Select a mission...")                                               -- Set the default value of the dropdown menu

    local files = file.Find("missions/*.txt", "DATA")                                      -- Find all mission files
    for _, file in ipairs(files) do                                                        -- For each file...
        local missionName = string.gsub(file, "_npcpos.txt", "")                           -- Get the mission name from the file name
        local missionDescription = file.Read("missions/" .. file, "DATA"):match("^(.-)\n") -- Read the mission description from the file
        dropdown:AddChoice(missionName .. " - " .. missionDescription)                     -- Add the mission to the dropdown menu with the description
    end

    local startButton = vgui.Create("DButton", frame)                -- Create a new button
    startButton:SetSize(380, 30)                                     -- Set the size of the button
    startButton:SetPos(10, 130)                                      -- Set the position of the button
    startButton:SetText("Start Mission")                             -- Set the text of the button
    startButton.DoClick = function()                                 -- Set what happens when the button is clicked
        local selectedMission = dropdown:GetValue():match("^(.-) -") -- Get the selected mission name from the dropdown value
        RunConsoleCommand("start_mission", selectedMission)          -- Start the selected mission
    end
end)
