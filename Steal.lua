-- VibeX Cheat Menu для Steal a Brainrot (No-Clip и Teleport, PC/Mobile)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")

-- Mock Remote Calls для обхода античита
local function mockRemoteCall(remote, ...)
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        end
    end)
    return success and result or nil
end

-- Настройка CollisionGroup для No-Clip
local function setupCollisionGroup()
    pcall(function()
        PhysicsService:CreateCollisionGroup("NoClip")
        PhysicsService:CollisionGroupSetCollidable("NoClip", "Default", false)
    end)
end
setupCollisionGroup()

-- Основные функции
local Functions = {}

-- No-Clip (несколько методов)
Functions.noClip = function(active)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local Clipon = false
    local lastPosition = character.HumanoidRootPart.CFrame
    local methods = {
        function() -- Метод 1: Отключение CanCollide
            for _, v in pairs(character:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end,
        function() -- Метод 2: CollisionGroup
            for _, v in pairs(character:GetChildren()) do
                if v:IsA("BasePart") then
                    pcall(function()
                        PhysicsService:SetPartCollisionGroup(v, "NoClip")
                    end)
                end
            end
        end,
        function() -- Метод 3: BodyVelocity для игнорирования коллизий
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.Parent = character.HumanoidRootPart
        end
    }

    if active then
        Clipon = true
        Functions.noClipConnection = RunService.Stepped:Connect(function()
            if Clipon and character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
                for i, method in ipairs(methods) do
                    local success, _ = pcall(method)
                    if success then break end
                    if i == #methods then
                        print("Все методы No-Clip заблокированы античитом")
                    end
                end
                local currentPosition = character.HumanoidRootPart.CFrame
                local distanceMoved = (currentPosition.Position - lastPosition.Position).Magnitude
                if distanceMoved > 3 and not UserInputService:IsKeyDown(Enum.KeyCode.W) and not UserInputService:IsKeyDown(Enum.KeyCode.S) and not UserInputService:IsKeyDown(Enum.KeyCode.A) and not UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    character.HumanoidRootPart.CFrame = lastPosition
                end
                lastPosition = currentPosition
            else
                if Functions.noClipConnection then
                    Functions.noClipConnection:Disconnect()
                    Functions.noClipConnection = nil
                end
            end
        end)
    else
        Clipon = false
        if Functions.noClipConnection then
            Functions.noClipConnection:Disconnect()
            Functions.noClipConnection = nil
            for _, v in pairs(character:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                    pcall(function()
                        PhysicsService:SetPartCollisionGroup(v, "Default")
                    end)
                    local bodyVelocity = v:FindFirstChildOfClass("BodyVelocity")
                    if bodyVelocity then
                        bodyVelocity:Destroy()
                    end
                end
            end
        end
    end
end

-- Teleport (на свою или вражескую базу, несколько методов)
Functions.teleport = function(active)
    if not active then
        if Functions.teleportConnection then
            Functions.teleportConnection:Disconnect()
            Functions.teleportConnection = nil
        end
        return
    end

    local function teleportToBase(base)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not base or not base:IsA("Model") then return false end
        local targetPos = base:FindFirstChild("HumanoidRootPart") and base.HumanoidRootPart.Position or base:GetModelCFrame().Position
        local methods = {
            function() -- Метод 1: Прямая смена CFrame
                character.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
                return true
            end,
            function() -- Метод 2: PathfindingService
                local path = PathfindingService:CreatePath()
                local success, _ = pcall(function()
                    path:ComputeAsync(character.HumanoidRootPart.Position, targetPos)
                end)
                if success and path.Status == Enum.PathStatus.Success then
                    local waypoints = path:GetWaypoints()
                    for _, waypoint in ipairs(waypoints) do
                        character.Humanoid:MoveTo(waypoint.Position)
                        character.Humanoid.MoveToFinished:Wait()
                    end
                    return true
                end
                return false
            end,
            function() -- Метод 3: BodyVelocity
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.Velocity = (targetPos - character.HumanoidRootPart.Position).Unit * 50
                bodyVelocity.Parent = character.HumanoidRootPart
                wait(1)
                bodyVelocity:Destroy()
                return true
            end
        }

        for i, method in ipairs(methods) do
            local success = pcall(method)
            if success then return true end
            if i == #methods then
                print("Все методы телепортации заблокированы античитом")
                return false
            end
        end
    end

    Functions.teleportConnection = RunService.Stepped:Connect(function()
        local myBase = Workspace:FindFirstChild(LocalPlayer.Name .. "Base")
        local enemyBases = {}
        for _, base in pairs(Workspace:GetChildren()) do
            if base.Name:match("Base$") and base.Name ~= LocalPlayer.Name .. "Base" then
                table.insert(enemyBases, base)
            end
        end
        if myBase and teleportToBase(myBase) then
            -- Телепорт на свою базу успешен
        else
            for _, enemyBase in ipairs(enemyBases) do
                if enemyBase:FindFirstChildOfClass("Model") then
                    teleportToBase(enemyBase)
                    break
                end
            end
        end
    end)
end

-- GUI
local function initGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VibeXCheatMenu"
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) or game.CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000

    local scalingStrength = 1
    local borderThickness = 10

    local IconButton = Instance.new("TextButton")
    IconButton.Name = "VibeIcon"
    IconButton.Size = UDim2.new(0, 40, 0, 40)
    IconButton.Position = UDim2.new(0, 50, 0, 50)
    IconButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
    IconButton.Text = ""
    IconButton.Parent = ScreenGui
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 10)
    IconCorner.Parent = IconButton

    local function createPetal(size, position)
        local Petal = Instance.new("Frame")
        Petal.Size = size
        Petal.Position = position
        Petal.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        Petal.BorderSizePixel = 0
        Petal.Parent = IconButton
        local PetalCorner = Instance.new("UICorner")
        PetalCorner.CornerRadius = UDim.new(0, 5)
        PetalCorner.Parent = Petal
    end
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 0, 5))
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 1, -15))
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(0, 5, 0.5, -5))
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(1, -15, 0.5, -5))
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 0.5, -5))

    local draggingIcon, dragStartIcon, startPosIcon
    IconButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingIcon = true
            dragStartIcon = input.Position
            startPosIcon = IconButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingIcon = false
                end
            end)
        end
    end)
    IconButton.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and draggingIcon then
            local delta = input.Position - dragStartIcon
            local newX = startPosIcon.X.Offset + delta.X
            local newY = startPosIcon.Y.Offset + delta.Y
            if newX < 0 then newX = 0 end
            if newY < 0 then newY = 0 end
            if newX + IconButton.Size.X.Offset > Camera.ViewportSize.X then newX = Camera.ViewportSize.X - IconButton.Size.X.Offset end
            if newY + IconButton.Size.Y.Offset > Camera.ViewportSize.Y then newY = Camera.ViewportSize.Y - IconButton.Size.Y.Offset end
            IconButton.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    local Camera = game.Workspace.CurrentCamera
    local screenSize = Camera.ViewportSize
    local menuWidth, menuHeight = 300, 250
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "VibeX"
    MainFrame.Size = UDim2.new(0, menuWidth, 0, menuHeight)
    MainFrame.Position = UDim2.new(0.5, -menuWidth/2, 0.5, -menuHeight/2)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local bordersActive = false
    local function createBorder(name, size, position, cursor)
        local Border = Instance.new("Frame")
        Border.Name = name
        Border.Size = size
        Border.Position = position
        Border.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        Border.BackgroundTransparency = 0.5
        Border.BorderSizePixel = 0
        Border.ZIndex = 2
        Border.Visible = bordersActive
        Border.Parent = MainFrame
        Border.MouseEnter:Connect(function()
            game:GetService("GuiService"):ChangeCursor(cursor)
        end)
        Border.MouseLeave:Connect(function()
            game:GetService("GuiService"):ChangeCursor("Arrow")
        end)
        return Border
    end

    local borders = {
        TopLeft = createBorder("TopLeft", UDim2.new(0, borderThickness, 0, borderThickness), UDim2.new(0, -borderThickness/2, 0, -borderThickness/2), "TopLeftBottomRight"),
        TopRight = createBorder("TopRight", UDim2.new(0, borderThickness, 0, borderThickness), UDim2.new(1, -borderThickness/2, 0, -borderThickness/2), "TopRightBottomLeft"),
        BottomLeft = createBorder("BottomLeft", UDim2.new(0, borderThickness, 0, borderThickness), UDim2.new(0, -borderThickness/2, 1, -borderThickness/2), "TopRightBottomLeft"),
        BottomRight = createBorder("BottomRight", UDim2.new(0, borderThickness, 0, borderThickness), UDim2.new(1, -borderThickness/2, 1, -borderThickness/2), "TopLeftBottomRight"),
        Top = createBorder("Top", UDim2.new(1, -2*borderThickness, 0, borderThickness), UDim2.new(0, borderThickness, 0, -borderThickness/2), "SizeY"),
        Bottom = createBorder("Bottom", UDim2.new(1, -2*borderThickness, 0, borderThickness), UDim2.new(0, borderThickness, 1, -borderThickness/2), "SizeY"),
        Left = createBorder("Left", UDim2.new(0, borderThickness, 1, -2*borderThickness), UDim2.new(0, -borderThickness/2, 0, borderThickness), "SizeX"),
        Right = createBorder("Right", UDim2.new(0, borderThickness, 1, -2*borderThickness), UDim2.new(1, -borderThickness/2, 0, borderThickness), "SizeX")
    }

    local function updateBorders()
        borders.TopLeft.Size = UDim2.new(0, borderThickness, 0, borderThickness)
        borders.TopLeft.Position = UDim2.new(0, -borderThickness/2, 0, -borderThickness/2)
        borders.TopRight.Size = UDim2.new(0, borderThickness, 0, borderThickness)
        borders.TopRight.Position = UDim2.new(1, -borderThickness/2, 0, -borderThickness/2)
        borders.BottomLeft.Size = UDim2.new(0, borderThickness, 0, borderThickness)
        borders.BottomLeft.Position = UDim2.new(0, -borderThickness/2, 1, -borderThickness/2)
        borders.BottomRight.Size = UDim2.new(0, borderThickness, 0, borderThickness)
        borders.BottomRight.Position = UDim2.new(1, -borderThickness/2, 1, -borderThickness/2)
        borders.Top.Size = UDim2.new(1, -2*borderThickness, 0, borderThickness)
        borders.Top.Position = UDim2.new(0, borderThickness, 0, -borderThickness/2)
        borders.Bottom.Size = UDim2.new(1, -2*borderThickness, 0, borderThickness)
        borders.Bottom.Position = UDim2.new(0, borderThickness, 1, -borderThickness/2)
        borders.Left.Size = UDim2.new(0, borderThickness, 1, -2*borderThickness)
        borders.Left.Position = UDim2.new(0, -borderThickness/2, 0, borderThickness)
        borders.Right.Size = UDim2.new(0, borderThickness, 1, -2*borderThickness)
        borders.Right.Position = UDim2.new(1, -borderThickness/2, 0, borderThickness)
    end

    for name, border in pairs(borders) do
        local resizing, resizeStart, startSize, startPos
        border.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeStart = input.Position
                startSize = MainFrame.Size
                startPos = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizing = false
                    end
                end)
            end
        end)
        border.InputChanged:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and resizing then
                local delta = input.Position - resizeStart
                local scaledDeltaX = delta.X * scalingStrength * 3
                local scaledDeltaY = delta.Y * scalingStrength * 3
                local newSize = startSize
                local newPos = startPos
                if name:find("TopLeft") or name:find("TopRight") or name:find("BottomLeft") or name:find("BottomRight") then
                    local aspectRatio = startSize.X.Offset / startSize.Y.Offset
                    local scaleFactor = math.max(scaledDeltaX / startSize.X.Offset, scaledDeltaY / startSize.Y.Offset)
                    local newWidth = math.max(200, startSize.X.Offset + startSize.X.Offset * scaleFactor)
                    local newHeight = newWidth / aspectRatio
                    if newHeight < 200 then
                        newHeight = 200
                        newWidth = newHeight * aspectRatio
                    end
                    newSize = UDim2.new(0, newWidth, 0, newHeight)
                    if name == "TopLeft" then
                        newPos = UDim2.new(0, startPos.X.Offset - scaledDeltaX, 0, startPos.Y.Offset - scaledDeltaY)
                    elseif name == "BottomLeft" then
                        newPos = UDim2.new(0, startPos.X.Offset - scaledDeltaX, 0, startPos.Y.Offset)
                    elseif name == "TopRight" then
                        newPos = UDim2.new(0, startPos.X.Offset, 0, startPos.Y.Offset - scaledDeltaY)
                    end
                elseif name == "Top" then
                    newSize = UDim2.new(startSize.X.Scale, startSize.X.Offset, startSize.Y.Scale, math.max(200, startSize.Y.Offset - scaledDeltaY))
                    newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + scaledDeltaY)
                elseif name == "Bottom" then
                    newSize = UDim2.new(startSize.X.Scale, startSize.X.Offset, startSize.Y.Scale, math.max(200, startSize.Y.Offset + scaledDeltaY))
                elseif name == "Left" then
                    newSize = UDim2.new(startSize.X.Scale, math.max(200, startSize.X.Offset - scaledDeltaX), startSize.Y.Scale, startSize.Y.Offset)
                    newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + scaledDeltaX, startPos.Y.Scale, startPos.Y.Offset)
                elseif name == "Right" then
                    newSize = UDim2.new(startSize.X.Scale, math.max(200, startSize.X.Offset + scaledDeltaX), startSize.Y.Scale, startSize.Y.Offset)
                end
                MainFrame.Size = newSize
                MainFrame.Position = newPos
            end
        end)
    end

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 40)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Text = "VibeX"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 20
    TitleLabel.Parent = MainFrame

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -80)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 45)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.ScrollingEnabled = true
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.Parent = MainFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = ScrollFrame

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.Position = UDim2.new(1, -35, 0, 5)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    MinimizeButton.Text = "−"
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeButton.Font = Enum.Font.SourceSansBold
    MinimizeButton.TextSize = 20
    MinimizeButton.Parent = MainFrame
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinimizeButton
    MinimizeButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)

    local dragging, dragStart, startPos
    TitleLabel.InputBegan:Connect(function(input)
        if input.UserInputTyp
