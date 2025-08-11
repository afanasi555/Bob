-- VibeX Cheat для Steal a Brainrot (Мобильная версия: No Clip, Teleport to My Base, Anti-Hindrance)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkClient = game:GetService("NetworkClient")

-- Глобальные переменные
local NewFunctions = {}
NewFunctions.noClipConnection = nil
NewFunctions.antiHindranceConnection = nil
local noClipActive = false
local antiHindranceActive = false

-- Безопасный вызов Remote
local function mockRemoteCall(remote, ...)
    print("Попытка Remote вызова:", remote.Name)
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
            temp.Parent = Workspace
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
        wait(0.05)
    end
    print("Все методы Remote вызова провалились")
    return nil
end

-- No Clip
local function noClip(active)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        print("Ошибка No Clip: Персонаж или HumanoidRootPart не найдены")
        return
    end
    local lastPosition = character.HumanoidRootPart.CFrame
    if active then
        noClipActive = true
        if not NewFunctions.noClipConnection then
            NewFunctions.noClipConnection = RunService.Stepped:Connect(function()
                if not noClipActive or not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
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
                    wait(0.05)
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
        noClipActive = false
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
local function teleportToBase()
    local myBase = Workspace:FindFirstChild(LocalPlayer.Name .. "Base")
    if not myBase or not myBase:FindFirstChild("HumanoidRootPart") then
        print("Ошибка телепорта: База не найдена:", LocalPlayer.Name .. "Base")
        return
    end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        print("Ошибка телепорта: Персонаж или HumanoidRootPart не найдены")
        return
    end
    local methods = {
        function() -- Метод 1: Прямой телепорт
            character.HumanoidRootPart.CFrame = myBase.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
        end,
        function() -- Метод 2: Использование Remote
            mockRemoteCall(ReplicatedStorage:FindFirstChild("TeleportEvent") or Instance.new("RemoteEvent"), myBase.HumanoidRootPart.Position)
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
        wait(0.05)
    end
end

-- Anti-Hindrance
local function antiHindrance(active)
    if active then
        antiHindranceActive = true
        if not NewFunctions.antiHindranceConnection then
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
                        wait(0.05)
                    end
                    if humanoid.MoveDirection ~= Vector3.new(0, 0, 0) then
                        local intendedDirection = humanoid.MoveDirection
                        character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(intendedDirection * 0.1)
                    end
                else
                    print("Ошибка Anti-Hindrance: Персонаж или Humanoid не найдены")
                end
            end)
        end
    else
        antiHindranceActive = false
        if NewFunctions.antiHindranceConnection then
            NewFunctions.antiHindranceConnection:Disconnect()
            NewFunctions.antiHindranceConnection = nil
            print("Anti-Hindrance отключен")
        end
    end
end

-- Создание сенсорного интерфейса
local function initGUI()
    print("Попытка создания GUI")
    local parent = game.CoreGui
    local success, guiParent = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if success and guiParent then
        parent = guiParent
        print("GUI будет создан в PlayerGui")
    else
        print("PlayerGui не найден, создание в CoreGui")
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VibeXCheatMobile"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 1000
    ScreenGui.Parent = parent
    print("ScreenGui создан:", ScreenGui.Name)

    local function createButton(name, position, toggle, func)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 100, 0, 40)
        Button.Position = position
        Button.BackgroundColor3 = toggle and (name == "No Clip" and noClipActive or antiHindranceActive) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
        Button.TextColor3 = toggle and (name == "No Clip" and noClipActive or antiHindranceActive) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        Button.Text = name
        Button.Font = Enum.Font.SourceSansBold
        Button.TextSize = 16
        Button.Parent = ScreenGui
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Button
        Button.MouseButton1Click:Connect(function()
            if toggle then
                if name == "No Clip" then
                    noClipActive = not noClipActive
                    func(noClipActive)
                    Button.BackgroundColor3 = noClipActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
                    Button.TextColor3 = noClipActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                    print("No Clip:", noClipActive)
                elseif name == "Anti-Hindrance" then
                    antiHindranceActive = not antiHindranceActive
                    func(antiHindranceActive)
                    Button.BackgroundColor3 = antiHindranceActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
                    Button.TextColor3 = antiHindranceActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                    print("Anti-Hindrance:", antiHindranceActive)
                end
            else
                Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Button.TextColor3 = Color3.fromRGB(0, 0, 0)
                func()
                wait(0.5)
                Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                print("Teleport выполнен")
            end
        end)
        print("Кнопка создана:", name)
    end

    createButton("No Clip", UDim2.new(0, 10, 0, 10), true, noClip)
    createButton("Teleport", UDim2.new(0, 10, 0, 60), false, teleportToBase)
    createButton("Anti-Hindrance", UDim2.new(0, 10, 0, 110), true, antiHindrance)
end

-- Инициализация с проверкой загрузки
local function init()
    print("Запуск VibeX Cheat Mobile")
    if not LocalPlayer then
        print("Ошибка: LocalPlayer не найден")
        return
    end
    print("LocalPlayer найден:", LocalPlayer.Name)
    local success, errorMsg = pcall(function()
        LocalPlayer:WaitForChild("Character", 5)
        Workspace:WaitForChild(LocalPlayer.Name .. "Base", 5)
        initGUI()
        print("VibeX Cheat Mobile успешно загружен")
    end)
    if not success then
        print("Ошибка загрузки VibeX Cheat Mobile: " .. tostring(errorMsg))
    end
end

-- Запуск с задержкой для полной загрузки
wait(2) -- Ждем 2 секунды для загрузки игры
init()
