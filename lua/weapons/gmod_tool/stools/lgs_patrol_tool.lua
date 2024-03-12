-- lgs_patrol_tool.lua

CreateConVar("my_tool_patrol_path_name", "", FCVAR_REPLICATED, "The name of the patrol path")
CreateConVar("my_tool_visualize_points", "0", FCVAR_REPLICATED, "Visualize patrol path points")

-- Tool settings
TOOL.Category     = "[LGS] Patrol"
TOOL.Name         = "Patrol Tool"
TOOL.Command      = nil
TOOL.ConfigName   = ""

-- Store patrol paths
local patrolPaths = {}

-- Create function to save patrol path to file in JSON format
local function SavePatrolPathToFile(patrolPathName, pathPoints)
    local filePath = "missions/" .. patrolPathName .. "_path.txt"
    local pathData = util.TableToJSON(pathPoints)
    file.Write(filePath, pathData)
end

-- Function to draw a path from one point to another
local function DrawPath(startPos, endPos, color)
    local startArea = navmesh.GetNearestNavArea(startPos)
    local endArea = navmesh.GetNearestNavArea(endPos)
    local path = navmesh.FindPath(startArea:GetCenter(), endArea:GetCenter())

    if path then
        for i = 1, #path - 1 do
            render.DrawLine(path[i], path[i + 1], color)
        end
    end
end

-- Function to draw the patrol path points
local function DrawPatrolPath(pathPoints)
    local color = Color(0, 255, 0) -- Green color for the points
    for i, point in ipairs(pathPoints) do
        render.DrawWireframeSphere(point, 10, 8, 8, color)

        -- Draw a path to the next point
        if i < #pathPoints then
            local nextPoint = pathPoints[i + 1]
            DrawPath(point, nextPoint, color)
        end
    end
end

-- Function to visualize all patrol paths
local function VisualizeAllPatrolPaths()
    for _, pathPoints in pairs(patrolPaths) do
        DrawPatrolPath(pathPoints)
    end
end

-- Add a hook to visualize patrol paths
hook.Add("PostDrawOpaqueRenderables", "VisualizePatrolPaths", function()
    -- Check if visualization is active
    if GetConVar("my_tool_visualize_points"):GetBool() then
        VisualizeAllPatrolPaths()
    end
end)

if CLIENT then
    language.Add("tool.lgs_patrol_tool.name", "Patrol Tool")
    language.Add("tool.lgs_patrol_tool.desc", "LGS Patrol Tool to create and manage patrol paths")
    language.Add("tool.lgs_patrol_tool.0", "By Noahbds")

    local fontParams = { font = "Arial", size = 30, weight = 1000, antialias = true, additive = false }
    surface.CreateFont("LGSFONT", fontParams)
    surface.CreateFont("LGSFONT2", fontParams)
end

function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "Patrol Tool", Description = "Create and manage patrol paths" })

    panel:AddControl("TextBox", {
        Label = "Patrol Path Name",
        Command = "my_tool_patrol_path_name"
    })

    panel:AddControl("CheckBox", {
        Label = "Visualize Patrol Points",
        Command = "my_tool_visualize_points"
    })
end

function TOOL:LeftClick(trace)
    local patrolPathName = GetConVar("my_tool_patrol_path_name"):GetString()
    if patrolPathName == "" then
        print("No patrol path selected")
        return
    end

    patrolPaths[patrolPathName] = patrolPaths[patrolPathName] or {}
    table.insert(patrolPaths[patrolPathName], trace.HitPos)

    print("Added patrol point to path " .. patrolPathName)

    -- Save patrol path to file in JSON format
    SavePatrolPathToFile(patrolPathName, patrolPaths[patrolPathName])

    return true
end
