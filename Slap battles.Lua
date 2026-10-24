if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

local isRunning = true
local farmPart = nil

localPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

local function getHRP()
    local char = localPlayer.Character
    if char then 
        return char:FindFirstChild("HumanoidRootPart") 
    end 
    return nil
end

local function setupPlatform()
    local hrp = getHRP()
    if not hrp then return end
    
    if not farmPart or not farmPart.Parent then
        farmPart = Instance.new("Part")
        farmPart.Name = "AFK_Platform"
        farmPart.Size = Vector3.new(2000, 2, 2000)
        farmPart.Anchored = true
        farmPart.CanCollide = true
        farmPart.Transparency = 1
        farmPart.Position = Vector3.new(10000, 10000, 10000)
        farmPart.Parent = workspace
    end
    
    if (hrp.Position - farmPart.Position).Magnitude > 50 then
        hrp.CFrame = CFrame.new(10000, 10002, 10000)
    end
end

local gui = localPlayer:WaitForChild("PlayerGui"):FindFirstChild("LagGui")
if gui then gui:Destroy() end

gui = Instance.new("ScreenGui")
gui.Name = "LagGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local bg = Instance.new("Frame", gui)
bg.Size = UDim2.fromScale(1,1)
bg.BackgroundColor3 = Color3.fromRGB(80,80,80)
bg.BackgroundTransparency = 0.15

local subtitle = Instance.new("TextLabel", bg)
subtitle.Size = UDim2.new(1,0,0,60)
subtitle.Position = UDim2.new(0,0,0.45,0)
subtitle.BackgroundTransparency = 1
subtitle.TextScaled = true
subtitle.Font = Enum.Font.GothamBold
subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
subtitle.Text = ""

task.spawn(function()
    task.wait(0.5)
    if workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Teleport1") then
        local hrp = getHRP()
        if hrp then hrp.CFrame = workspace.Lobby.Teleport1.CFrame + Vector3.new(0,3,0) end
    end
    task.wait(0.8)
    setupPlatform()
end)

local function pullCandies()
    if not isRunning then return end
    local hrp = getHRP()
    if not hrp then return end
    setupPlatform()

    local foldersToCheck = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj.Name == "CandyCorns" or obj.Name == "CandyCorn") and (obj:IsA("Folder") or obj:IsA("Model")) then
            table.insert(foldersToCheck, obj)
        end
    end

    for _, folder in ipairs(foldersToCheck) do
        for _, v in ipairs(folder:GetDescendants()) do
            if v:IsA("BasePart") then
                pcall(function()
                    v.CFrame = hrp.CFrame
                end)
            end
        end
    end
end

local loopConnection = RunService.Heartbeat:Connect(function()
    if isRunning then
        pullCandies()
    end
end)

localPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    setupPlatform()
end)

local HOP_TIME = 3

local function doServerHop()
    subtitle.Text = ""

    local parsedData = nil
    local reqSuccess = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local raw = game:HttpGet(url)
        parsedData = HttpService:JSONDecode(raw)
    end)

    if reqSuccess and parsedData and parsedData.data then
        local validServers = {}
        for _, s in ipairs(parsedData.data) do
            if type(s) == "table" and s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                table.insert(validServers, s.id)
            end
        end

        if #validServers > 0 then
            local targetServer = validServers[math.random(1, #validServers)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer, localPlayer)
            return
        end
    end

    subtitle.Text = ""
    TeleportService:Teleport(game.PlaceId, localPlayer)
end

task.spawn(function()
    local timeLeft = HOP_TIME
    while timeLeft > 0 do
        subtitle.Text = ""
        task.wait(1)
        timeLeft = timeLeft - 1
    end

    while true do
        doServerHop()
        task.wait(3)
    end
end)
