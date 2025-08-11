-- VibeX Cheat для Steal a Brainrot (Мобильная версия: No Clip, Teleport to My Base, Anti-Hindrance)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkClient = game:GetService("NetworkClient")
local DataStoreService = game:GetService("DataStoreService")
local ConfigStore = DataStoreService:GetDataStore("VibeXConfig")

-- Конфигурация
local config = {
    noClip = false,
    antiHindrance = false
}

-- Загрузка конфига
local function loadConfig()
    local success, savedConfig = pcall(function()
        return ConfigStore:GetAsync(LocalPlayer.UserId .. "_VibeX")
    end)
    if success and savedConfig then
        config = savedConfig
    end
    print("Конфиг загружен:", config.noClip, config.antiHindrance)
end

-- Сохранение конфига
local function saveConfig()
    pcall(function()
        ConfigStore:SetAsync(LocalPlayer.UserId .. "_VibeX", config)
    end)
    print("Конфиг сохранен")
end

-- Безопасный вызов Remote
local function mockRemoteCall(remote, ...)
    local methods = {
        function() -- Метод 1: Прямой вызов
            if remote:IsA("RemoteEvent") then
                remote:FireServer(...)
            elseif remote:IsA("RemoteFunction") then
                return remote:InvokeServer(...)
            end
        end,
        function() -- Метод 2: Обфускация через временный Instance
            local temp = Instance.new("Folder")
            temp.Parent = game
            local success, result = pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(...)
                elseif remote:IsA("RemoteFunction") then
                    return remote:InvokeServer(...)
                end
            end)
            temp:Destroy()
            return success and result
        end,
        function() -- Метод 3: Подмена сетевого пакета
            local connection = NetworkClient.ChildRemoved:Connect(function() end)
            local success, result = pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(...)
                elseif remote:IsA("RemoteFunction") then
                    return remote:InvokeServer(...)
                end
            end)
            connection:Disconnect()
            return success and result
        end
    }
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success then
            print("Remote вызов успешен, метод:", i)
            return result
        end
        print("Remote вызов не удался, метод:", i)
        wait(0.1)
    end
    print("Все методы Remote вызова провалились")
    return nil
end

-- No Clip
local function noClip(active)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        print("Персонаж или HumanoidRootPart не найдены")
        return
    end
    local Clipon = false
    local lastPosition = character.HumanoidRootPart.CFrame
    if active then
        Clipon = true
        if not NewFunctions.noClipConnection then
            NewFunctions.noClipConnection = RunService.Stepped:Connect(function()
                if not Clipon or not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
                    if NewFunctions.noClipConnection then
                        NewFunctions.noClipConnection:Disconnect()
                        NewFunctions.noClipConnection = nil
                    end
                    print("No Clip отключен: персонаж недоступен")
                    return
                end
                local methods = {
                    function() -- Метод 1: Прямое отключение коллизии
                        for _, v in pairs(character:GetChildren()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end
                        end
                    end,
                    function() -- Метод 2: Манипуляция физикой
                        local humanoid = character.Humanoid
                        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                        for _, v in pairs(character:GetChildren()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                                v.Velocity = Vector3.new(0, 0, 0)
                            end
                        end
                    end
                }
                for i, method in ipairs(methods) do
                    local success = pcall(method)
                    if success then
                        print("No Clip активен, метод:", i)
                        break
                    end
                    print("No Clip не удался, метод:", i)
                    wait(0.1)
                end
                local currentPosition = character.HumanoidRootPart.CFrame
                local distanceMoved = (currentPosition.Position - lastPosition.Position).Magnitude
                if distanceMoved > 3 and not UserInputService:IsKeyDown(Enum.KeyCode.W) and not UserInputService:IsKeyDown(Enum.KeyCode.S) and not UserInputService:IsKeyDown(Enum.KeyCode.A) and not UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    character.HumanoidRootPart.CFrame = lastPosition
                    print("No Clip: возврат на последнюю позицию")
                end
                lastPosition = currentPosition
            end)
        end
    else
        Clipon = false
        if NewFunctions.noClipConnection then
            NewFunctions.noClipConnection:Disconnect()
            NewFunctions.noClipConnection = nil
            for _, v in pairs(character:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                end
            end
            print("No Clip отключен")
        end
    end
end

-- Teleport to My Base
local function teleportToBase(active)
    if active then
        local myBase = Workspace:FindFirstChild(LocalPlayer.Name .. "Base")
        if not myBase or not myBase:FindFirstChild("HumanoidRootPart") then
            print("База не найдена:", LocalPlayer.Name .. "Base")
            return
        end
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            print("Персонаж или HumanoidRootPart не найдены")
            return
        end
        local methods = {
            function() -- Метод 1: Прямой телепорт
                character.HumanoidRootPart.CFrame = myBase.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
            end,
            function() -- Метод 2: Использование Remote
                mockRemoteCall(ReplicatedStorage.TeleportEvent, myBase.HumanoidRootPart.Position)
            end,
            function() -- Метод 3: Манипуляция физикой
                character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                character.HumanoidRootPart.CFrame = CFrame.new(myBase.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
            end
        }
        for i, method in ipairs(methods) do
            local success = pcall(method)
            if success then
                print("Телепорт на базу успешен, метод:", i)
                break
            end
            print("Телепорт на базу не удался, метод:", i)
            wait(0.1)
        end
    end
end

-- Anti-Hindrance
local function antiHindrance(active)
    if active then
        NewFunctions.antiHindranceConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                local methods = {
                    function() -- Метод 1: Отключение анимаций и эффектов
                        humanoid.Sit = false
                        humanoid.PlatformStand = false
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            if track.Name:lower():find("dance") or track.Name:lower():find("boogie") then
                                track:Stop()
                            end
                        end
                        for _, effect in pairs(Lighting:GetChildren()) do
                            if effect:IsA("PostEffect") or effect.Name:lower():find("bee") or effect.Name:lower():find("medusa") then
                                effect.Enabled = false
                            end
                        end
                    end,
                    function() -- Метод 2: Сброс состояния
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                        humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, 16)
                        humanoid.JumpPower = math.max(humanoid.JumpPower, 50)
                    end
                }
                for i, method in ipairs(methods) do
                    local success = pcall(method)
                    if success then
                        print("Anti-Hindrance активен, метод:", i)
                        break
                    end
                    print("Anti-Hindrance не удался, метод:", i)
                    wait(0.1)
                end
                if humanoid.MoveDirection ~= Vector3.new(0, 0, 0) then
                    local intendedDirection = humanoid.MoveDirection
                    character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(intendedDirection * 0.1)
                end
            else
                print("Персонаж или Humanoid не найдены")
            end
        end)
    else
        if NewFunctions.antiHindranceConnection then
            NewFunctions.antiHindranceConnection:Disconnect()
            NewFunctions.antiHindranceConnection = nil
            print("Anti-Hindrance отключен")
        end
    end
end

-- Инициализация функций
local NewFunctions = {}
NewFunctions.noClipConnection = nil
NewFunctions.antiHindranceConnection = nil

-- Создание сенсорного интерфейса
local function initGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VibeXCheatMobile"
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) or game.CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000

    local function createButton(name, position, toggle, func)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 100, 0, 40)
        Button.Position = position
        Button.BackgroundColor3 = toggle and (config[name] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)) or Color3.fromRGB(60, 60, 60)
        Button.TextColor3 = toggle and (config[name] and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(255, 255, 255)
        Button.Text = name
        Button.Font = Enum.Font.SourceSansBold
        Button.TextSize = 16
        Button.Parent = ScreenGui
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Button
        Button.MouseButton1Click:Connect(function()
            if toggle then
                config[name] = not config[name]
                Button.BackgroundColor3 = config[name] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
                Button.TextColor3 = config[name] and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                func(config[name])
                saveConfig()
                print(name .. ":", config[name])
            else
                Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Button.TextColor3 = Color3.fromRGB(0, 0, 0)
                func(true)
                wait(0.5)
                Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end)
    end

    createButton("noClip", UDim2.new(0, 10, 0, 10), true, noClip)
    createButton("Teleport", UDim2.new(0, 10, 0, 60), false, teleportToBase)
    createButton("antiHindrance", UDim2.new(0, 10, 0, 110), true, antiHindrance)
end

-- Инициализация
local success, errorMsg = pcall(function()
    loadConfig()
    initGUI()
    noClip(config.noClip)
    antiHindrance(config.antiHindrance)
    print("VibeX Cheat Mobile успешно загружен")
end)
if not success then
    print("Ошибка загрузки VibeX Cheat Mobile: " .. tostring(errorMsg))
end
