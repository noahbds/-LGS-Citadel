-- cl_init.lua

include(init.lua)

net.Receive("StartMission", function()
    local npc = net.ReadEntity() -- Get the NPC entity from the server
end)

concommand.Add("open_mission_selector", function()
    local frame = vgui.Create("DFrame")                          -- Create a new frame
    frame:SetSize(300, 150)                                      -- Set the size of the frame
    frame:Center()                                               -- Center the frame on the screen
    frame:SetTitle("Select a Mission")                           -- Set the title of the frame
    frame:MakePopup()                                            -- Make the frame appear

    local dropdown = vgui.Create("DComboBox", frame)             -- Create a new dropdown menu
    dropdown:SetSize(280, 30)                                    -- Set the size of the dropdown menu
    dropdown:SetPos(10, 50)                                      -- Set the position of the dropdown menu
    dropdown:SetValue("Select a mission...")                     -- Set the default value of the dropdown menu

    local files = file.Find("missions/*.txt", "DATA")            -- Find all mission files
    for _, file in ipairs(files) do                              -- For each file...
        local missionName = string.gsub(file, "_npcpos.txt", "") -- Get the mission name from the file name
        dropdown:AddChoice(missionName)                          -- Add the mission to the dropdown menu
    end

    local startButton = vgui.Create("DButton", frame)       -- Create a new button
    startButton:SetSize(280, 30)                            -- Set the size of the button
    startButton:SetPos(10, 90)                              -- Set the position of the button
    startButton:SetText("Start Mission")                    -- Set the text of the button
    startButton.DoClick = function()                        -- Set what happens when the button is clicked
        local selectedMission = dropdown:GetValue()         -- Get the selected mission
        RunConsoleCommand("start_mission", selectedMission) -- Start the selected mission
    end
end)
