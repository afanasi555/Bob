-- VibeX Cheat Menu with No-Clip and Teleport Functions

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Scaling and Border Thickness
local scalingStrength = 1
local borderThickness = 10

-- Remove Existing GUI
local function clearExistingGUI()
    local existingGui = LocalPlayer.PlayerGui:FindFirstChild("VibeXCheatMenu")
    if existingGui then
        existingGui:Destroy()
    end
end

-- Cheat Functions
local Functions = {}

Functions.noClip = function(active)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local Clipon = false
    if active then
        Clipon = true
        Functions.noClipConnection = RunService.Stepped:Connect(function()
            if Clipon and character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
                for _, v in pairs(character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
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
                end
            end
        end
    end
end

Functions.autoTeleportWhenSteal = function(active)
    if active then
        Functions.autoTeleportStealConnection = RunService.Stepped:Connect(function()
            local brainrot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Brainrot")
            if brainrot then
                local base = Workspace:FindFirstChild(LocalPlayer.Name .. "Base")
                if base and base:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = base.HumanoidRootPart.CFrame
                end
            end
        end)
    else
        if Functions.autoTeleportStealConnection then
            Functions.autoTeleportStealConnection:Disconnect()
            Functions.autoTeleportStealConnection = nil
        end
    end
end

Functions.autoTeleportEnemyBase = function(active)
    if active then
        Functions.autoTeleportEnemyBaseConnection = RunService.Stepped:Connect(function()
            local myBase = Workspace:FindFirstChild(LocalPlayer.Name .. "Base")
            if myBase and myBase:FindFirstChild("Timer") and myBase.Timer.Value < 20 then return end
            for _, base in pairs(Workspace:GetChildren()) do
                if base.Name:match("Base$") and base.Name ~= LocalPlayer.Name .. "Base" then
                    if base:FindFirstChild("Timer") and base.Timer.Value <= 10 and base.Timer.Value > 0 then
                        local brainrot = base:FindFirstChildOfClass("Model")
                        if brainrot and not brainrot:FindFirstChild("StolenTag") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = base.HumanoidRootPart.CFrame
                            break
                        end
                    end
                end
            end
        end)
    else
        if Functions.autoTeleportEnemyBaseConnection then
            Functions.autoTeleportEnemyBaseConnection:Disconnect()
            Functions.autoTeleportEnemyBaseConnection = nil
        end
    end
end

-- Main GUI Creation
local function initGUI()
    clearExistingGUI()

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VibeXCheatMenu"
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) or game.CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000

    -- Icon (Yellow Flower on Blue Background)
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

    -- Flower (5 petals + center)
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
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 0, 5)) -- Top
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 1, -15)) -- Bottom
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(0, 5, 0.5, -5)) -- Left
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(1, -15, 0.5, -5)) -- Right
    createPetal(UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 0.5, -5)) -- Center

    -- Draggable Icon
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

    -- Main Frame (VibeX, Centered)
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

    -- Resize Borders
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

    -- Minimize Button
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

    -- Draggable Menu
    local dragging, dragStart, startPos
    TitleLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    TitleLabel.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
            if newX < 0 then newX = 0 end
            if newY < 0 then newY = 0 end
            if newX + MainFrame.Size.X.Offset > screenSize.X then newX = screenSize.X - MainFrame.Size.X.Offset end
            if newY + MainFrame.Size.Y.Offset > screenSize.Y then newY = screenSize.Y - MainFrame.Size.Y.Offset end
            MainFrame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    -- Button Creation Function
    local function createButton(parent, name, isSubButton)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, -10, 0, 40)
        Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Text = isSubButton and name or name .. " ◀️"
        Button.Font = Enum.Font.SourceSans
        Button.TextSize = 18
        Button.BorderSizePixel = 0
        Button.Parent = parent
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 6)
        UICorner.Parent = Button
        return Button
    end

    -- Cheat Buttons
    local CheatButton1 = createButton(ScrollFrame, "No-Clip", true)
    local CheatButton2 = createButton(ScrollFrame, "Teleport to Own Base", true)
    local CheatButton3 = createButton(ScrollFrame, "Teleport to Enemy Base", true)

    local noClipActive = false
    CheatButton1.MouseButton1Click:Connect(function()
        noClipActive = not noClipActive
        CheatButton1.Text = "No-Clip " .. (noClipActive and "✅" or "❌")
        CheatButton1.BackgroundColor3 = noClipActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
        CheatButton1.TextColor3 = noClipActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        Functions.noClip(noClipActive)
    end)

    local teleportOwnBaseActive = false
    CheatButton2.MouseButton1Click:Connect(function()
        teleportOwnBaseActive = not teleportOwnBaseActive
        CheatButton2.Text = "Teleport to Own Base " .. (teleportOwnBaseActive and "✅" or "❌")
        CheatButton2.BackgroundColor3 = teleportOwnBaseActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
        CheatButton2.TextColor3 = teleportOwnBaseActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        Functions.autoTeleportWhenSteal(teleportOwnBaseActive)
    end)

    local teleportEnemyBaseActive = false
    CheatButton3.MouseButton1Click:Connect(function()
        teleportEnemyBaseActive = not teleportEnemyBaseActive
        CheatButton3.Text = "Teleport to Enemy Base " .. (teleportEnemyBaseActive and "✅" or "❌")
        CheatButton3.BackgroundColor3 = teleportEnemyBaseActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60,
