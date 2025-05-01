local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/main/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "The Rake: Fan Remake",
    SubTitle = "Player Tab",
    TabWidth = 160,
    Size = UDim2.fromOffset(530, 400),
    Acrylic = true,
    Theme = "Dark",
    Center = true,
    IsDraggable = true
})

local PlayerTab = Window:AddTab({ Title = "Player", Icon = "" })

-- WalkSpeed Slider
PlayerTab:AddSlider("WalkSpeed", {
    Title = "WalkSpeed",
    Description = "Change how fast you walk",
    Min = 16,
    Max = 300,
    Default = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

-- JumpPower Slider
PlayerTab:AddSlider("JumpPower", {
    Title = "Jump Power",
    Description = "Change how high you jump",
    Min = 50,
    Max = 300,
    Default = 50,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
    end
})

-- Field of View Slider
PlayerTab:AddSlider("FOV", {
    Title = "Field of View",
    Description = "Change your camera's field of view",
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(value)
        game.Workspace.CurrentCamera.FieldOfView = value
    end
})

-- Infinite Jump
PlayerTab:AddSwitch("InfiniteJump", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(enabled)
        if enabled then
            InfiniteJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
                local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        elseif InfiniteJumpConn then
            InfiniteJumpConn:Disconnect()
        end
    end
})

-- Noclip Toggle
PlayerTab:AddSwitch("Noclip", {
    Title = "Noclip",
    Default = false,
    Callback = function(enabled)
        if NoclipConn then NoclipConn:Disconnect() end
        if enabled then
            NoclipConn = game:GetService("RunService").Stepped:Connect(function()
                local char = game.Players.LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
})

-- Fullbright Toggle
local Lighting = game:GetService("Lighting")
local originalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ShadowSoftness = Lighting.ShadowSoftness,
    GlobalShadows = Lighting.GlobalShadows
}

PlayerTab:AddSwitch("Fullbright", {
    Title = "Fullbright",
    Default = false,
    Description = "Toggle enhanced lighting (visual only)",
    Callback = function(enabled)
        if enabled then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
            Lighting.ShadowSoftness = 0
            Lighting.GlobalShadows = false
        else
            Lighting.Ambient = originalLighting.Ambient
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            Lighting.Brightness = originalLighting.Brightness
            Lighting.ShadowSoftness = originalLighting.ShadowSoftness
            Lighting.GlobalShadows = originalLighting.GlobalShadows
        end
    end
})

return Window

local ESPTab = Window:AddTab({ Title = "ESP", Icon = "" })

-- Label
ESPTab:AddLabel("Players")

-- State and Utilities
local lplr = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local espEnabled = false
local tracerEnabled = false
local espConnections = {}
local tracerConnections = {}

_G.TeamCheck = false

-- Box ESP
local function createBoxEsp(v)
    local BoxOutline = Drawing.new("Square")
    BoxOutline.Color = Color3.new(0, 0, 0)
    BoxOutline.Thickness = 3
    BoxOutline.Transparency = 1
    BoxOutline.Filled = false
    BoxOutline.Visible = false

    local Box = Drawing.new("Square")
    Box.Color = Color3.new(0, 1, 0)
    Box.Thickness = 1
    Box.Transparency = 1
    Box.Filled = false
    Box.Visible = false

    local conn = RunService.RenderStepped:Connect(function()
        if not espEnabled then
            BoxOutline.Visible = false
            Box.Visible = false
            return
        end

        if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local RootPart = v.Character.HumanoidRootPart
            local HeadOff = Vector3.new(0, 0.5, 0)
            local LegOff = Vector3.new(0, 3, 0)

            local RootPos, onScreen = camera:WorldToViewportPoint(RootPart.Position)
            local HeadPos = camera:WorldToViewportPoint(RootPart.Position + HeadOff)
            local LegPos = camera:WorldToViewportPoint(RootPart.Position - LegOff)

            if onScreen then
                local sizeX = 1000 / RootPos.Z
                local sizeY = HeadPos.Y - LegPos.Y
                local pos = Vector2.new(RootPos.X - sizeX / 2, RootPos.Y - sizeY / 2)

                BoxOutline.Size = Vector2.new(sizeX, sizeY)
                BoxOutline.Position = pos
                BoxOutline.Visible = true

                Box.Size = Vector2.new(sizeX, sizeY)
                Box.Position = pos
                Box.Visible = true
            else
                BoxOutline.Visible = false
                Box.Visible = false
            end
        else
            BoxOutline.Visible = false
            Box.Visible = false
        end
    end)

    table.insert(espConnections, conn)
end

-- Tracer ESP
local function createTracer(v)
    local Tracer = Drawing.new("Line")
    Tracer.Color = v.TeamColor and v.TeamColor.Color or Color3.new(0, 1, 0)
    Tracer.Thickness = 1
    Tracer.Transparency = 1
    Tracer.Visible = false

    local conn = RunService.RenderStepped:Connect(function()
        if not tracerEnabled then
            Tracer.Visible = false
            return
        end

        if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v ~= lplr and v.Character.Humanoid.Health > 0 then
            local vector, onScreen = camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)

            if onScreen then
                Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                Tracer.To = Vector2.new(vector.X, vector.Y)

                if _G.TeamCheck and v.TeamColor == lplr.TeamColor then
                    Tracer.Visible = false
                else
                    Tracer.Visible = true
                end
            else
                Tracer.Visible = false
            end
        else
            Tracer.Visible = false
        end
    end)

    table.insert(tracerConnections, conn)
end

-- Toggle: Box ESP
ESPTab:AddSwitch("BoxESP", {
    Title = "Box ESP",
    Default = false,
    Callback = function(state)
        espEnabled = state

        if state then
            for _, v in ipairs(game.Players:GetPlayers()) do
                if v ~= lplr then
                    createBoxEsp(v)
                end
            end

            game.Players.PlayerAdded:Connect(function(player)
                if player ~= lplr then
                    createBoxEsp(player)
                end
            end)
        else
            for _, conn in ipairs(espConnections) do
                if conn.Disconnect then
                    conn:Disconnect()
                end
            end
            espConnections = {}
        end
    end
})

-- Toggle: Tracers
ESPTab:AddSwitch("Tracers", {
    Title = "Tracers",
    Default = false,
    Callback = function(state)
        tracerEnabled = state

        if state then
            for _, v in ipairs(game.Players:GetPlayers()) do
                if v ~= lplr then
                    createTracer(v)
                end
            end

            game.Players.PlayerAdded:Connect(function(player)
                if player ~= lplr then
                    createTracer(player)
                end
            end)
        else
            for _, conn in ipairs(tracerConnections) do
                if conn.Disconnect then
                    conn:Disconnect()
                end
            end
            tracerConnections = {}
        end
    end
})

-- Label for Rake ESP
ESPTab:AddLabel("The Rake")

-- Variables
local rakeBoxESPEnabled = false
local rakeTracerESPEnabled = false
local rakeConnections = {}

-- Rake Box ESP
local function createRakeBoxESP()
    local Box = Drawing.new("Square")
    Box.Color = Color3.new(1, 0, 0) -- Red
    Box.Thickness = 2
    Box.Transparency = 1
    Box.Filled = false
    Box.Visible = false

    local conn = RunService.RenderStepped:Connect(function()
        local rake = workspace:FindFirstChild("Rake")
        if not rakeBoxESPEnabled or not rake then
            Box.Visible = false
            return
        end

        local hrp = rake:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos, onscreen = camera:WorldToViewportPoint(hrp.Position)
            if onscreen then
                local size = 1000 / pos.Z
                Box.Size = Vector2.new(size, size * 2)
                Box.Position = Vector2.new(pos.X - size / 2, pos.Y - size)
                Box.Visible = true
            else
                Box.Visible = false
            end
        else
            Box.Visible = false
        end
    end)

    table.insert(rakeConnections, conn)
end

-- Rake Tracer ESP
local function createRakeTracerESP()
    local Tracer = Drawing.new("Line")
    Tracer.Color = Color3.new(1, 0, 0) -- Red
    Tracer.Thickness = 1
    Tracer.Transparency = 1
    Tracer.Visible = false

    local conn = RunService.RenderStepped:Connect(function()
        local rake = workspace:FindFirstChild("Rake")
        if not rakeTracerESPEnabled or not rake then
            Tracer.Visible = false
            return
        end

        local hrp = rake:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                Tracer.To = Vector2.new(vector.X, vector.Y)
                Tracer.Visible = true
            else
                Tracer.Visible = false
            end
        else
            Tracer.Visible = false
        end
    end)

    table.insert(rakeConnections, conn)
end

-- Toggle: Rake Box ESP
ESPTab:AddSwitch("RakeBoxESP", {
    Title = "Box ESP (Rake)",
    Default = false,
    Callback = function(state)
        rakeBoxESPEnabled = state
        if state then
            createRakeBoxESP()
        end
    end
})

-- Toggle: Rake Tracers
ESPTab:AddSwitch("RakeTracerESP", {
    Title = "Tracers (Rake)",
    Default = false,
    Callback = function(state)
        rakeTracerESPEnabled = state
        if state then
            createRakeTracerESP()
        end
    end
})
-- Label for Rake ESP
ESPTab:AddLabel("The Rake")

-- Variables
local rakeBoxESPEnabled = false
local rakeTracerESPEnabled = false
local rakeConnections = {}

-- Rake Box ESP
local function createRakeBoxESP()
    local Box = Drawing.new("Square")
    Box.Color = Color3.new(1, 0, 0) -- Red
    Box.Thickness = 2
    Box.Transparency = 1
    Box.Filled = false
    Box.Visible = false

    local conn = RunService.RenderStepped:Connect(function()
        local rake = workspace:FindFirstChild("Rake")
        if not rakeBoxESPEnabled or not rake then
            Box.Visible = false
            return
        end

        local hrp = rake:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos, onscreen = camera:WorldToViewportPoint(hrp.Position)
            if onscreen then
                local size = 1000 / pos.Z
                Box.Size = Vector2.new(size, size * 2)
                Box.Position = Vector2.new(pos.X - size / 2, pos.Y - size)
                Box.Visible = true
            else
                Box.Visible = false
            end
        else
            Box.Visible = false
        end
    end)

    table.insert(rakeConnections, conn)
end

-- Rake Tracer ESP
local function createRakeTracerESP()
    local Tracer = Drawing.new("Line")
    Tracer.Color = Color3.new(1, 0, 0) -- Red
    Tracer.Thickness = 1
    Tracer.Transparency = 1
    Tracer.Visible = false

    local conn = RunService.RenderStepped:Connect(function()
        local rake = workspace:FindFirstChild("Rake")
        if not rakeTracerESPEnabled or not rake then
            Tracer.Visible = false
            return
        end

        local hrp = rake:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                Tracer.To = Vector2.new(vector.X, vector.Y)
                Tracer.Visible = true
            else
                Tracer.Visible = false
            end
        else
            Tracer.Visible = false
        end
    end)

    table.insert(rakeConnections, conn)
end

-- Toggle: Rake Box ESP
ESPTab:AddSwitch("RakeBoxESP", {
    Title = "Box ESP (Rake)",
    Default = false,
    Callback = function(state)
        rakeBoxESPEnabled = state
        if state then
            createRakeBoxESP()
        end
    end
})

-- Toggle: Rake Tracers
ESPTab:AddSwitch("RakeTracerESP", {
    Title = "Tracers (Rake)",
    Default = false,
    Callback = function(state)
        rakeTracerESPEnabled = state
        if state then
            createRakeTracerESP()
        end
    end
})

ESPTab:AddLabel("Objects")

ESPTab:AddLabel("Crates")
-- Crate Box ESP (auto-respawn safe)
local function createCrateBoxESP()
    coroutine.wrap(function()
        local Box = Drawing.new("Square")
        Box.Color = Color3.fromRGB(255, 165, 0)
        Box.Thickness = 2
        Box.Transparency = 1
        Box.Filled = false
        Box.Visible = false

        while crateBoxESPEnabled do
            local crate = workspace:FindFirstChild("Crate")
            if crate then
                local pos, onScreen = camera:WorldToViewportPoint(crate.Position)
                if onScreen then
                    local size = 1000 / pos.Z
                    Box.Size = Vector2.new(size, size)
                    Box.Position = Vector2.new(pos.X - size / 2, pos.Y - size / 2)
                    Box.Visible = true
                else
                    Box.Visible = false
                end
            else
                Box.Visible = false
            end
            task.wait()
        end
        Box:Remove()
    end)()
end

-- Crate Tracer ESP (auto-respawn safe)
local function createCrateTracerESP()
    coroutine.wrap(function()
        local Tracer = Drawing.new("Line")
        Tracer.Color = Color3.fromRGB(255, 165, 0)
        Tracer.Thickness = 1
        Tracer.Transparency = 1
        Tracer.Visible = false

        while crateTracerESPEnabled do
            local crate = workspace:FindFirstChild("Crate")
            if crate then
                local pos, onScreen = camera:WorldToViewportPoint(crate.Position)
                if onScreen then
                    Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    Tracer.To = Vector2.new(pos.X, pos.Y)
                    Tracer.Visible = true
                else
                    Tracer.Visible = false
                end
            else
                Tracer.Visible = false
            end
            task.wait()
        end
        Tracer:Remove()
    end)()
end

-- Label for Flare Gun ESP
ESPTab:AddLabel("Flare Guns")

-- Variables
local flareGunBoxESPEnabled = false
local flareGunTracerESPEnabled = false
local flareGunConnections = {}

-- Flare Gun Box ESP (auto-respawn safe)
local function createFlareGunBoxESP()
    coroutine.wrap(function()
        local Box = Drawing.new("Square")
        Box.Color = Color3.fromRGB(255, 105, 180) -- Pink
        Box.Thickness = 2
        Box.Transparency = 1
        Box.Filled = false
        Box.Visible = false

        while flareGunBoxESPEnabled do
            local flareGun = workspace.Collectibles:FindFirstChild("FlareGun")
            if flareGun then
                local pos, onScreen = camera:WorldToViewportPoint(flareGun.Position)
                if onScreen then
                    local size = 1000 / pos.Z
                    Box.Size = Vector2.new(size, size)
                    Box.Position = Vector2.new(pos.X - size / 2, pos.Y - size / 2)
                    Box.Visible = true
                else
                    Box.Visible = false
                end
            else
                Box.Visible = false
            end
            task.wait()
        end
        Box:Remove()
    end)()
end

-- Flare Gun Tracer ESP (auto-respawn safe)
local function createFlareGunTracerESP()
    coroutine.wrap(function()
        local Tracer = Drawing.new("Line")
        Tracer.Color = Color3.fromRGB(255, 105, 180) -- Pink
        Tracer.Thickness = 1
        Tracer.Transparency = 1
        Tracer.Visible = false

        while flareGunTracerESPEnabled do
            local flareGun = workspace.Collectibles:FindFirstChild("FlareGun")
            if flareGun then
                local pos, onScreen = camera:WorldToViewportPoint(flareGun.Position)
                if onScreen then
                    Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    Tracer.To = Vector2.new(pos.X, pos.Y)
                    Tracer.Visible = true
                else
                    Tracer.Visible = false
                end
            else
                Tracer.Visible = false
            end
            task.wait()
        end
        Tracer:Remove()
    end)()
end

-- Toggle: Flare Gun Box ESP
ESPTab:AddSwitch("FlareGunBoxESP", {
    Title = "Flare Gun Boxes",
    Default = false,
    Callback = function(state)
        flareGunBoxESPEnabled = state
        if state then
            createFlareGunBoxESP()
        end
    end
})

-- Toggle: Flare Gun Tracer ESP
ESPTab:AddSwitch("FlareGunTracerESP", {
    Title = "Flare Gun Tracers",
    Default = false,
    Callback = function(state)
        flareGunTracerESPEnabled = state
        if state then
            createFlareGunTracerESP()
        end
    end
})

-- Label for Scrap ESP
ESPTab:AddLabel("Scraps")

-- Variables
local scrapBoxESPEnabled = false
local scrapTracerESPEnabled = false

-- Scrap Box ESP (auto-respawn safe)
local function createScrapBoxESP()
    coroutine.wrap(function()
        local Box = Drawing.new("Square")
        Box.Color = Color3.fromRGB(139, 69, 19) -- Brown color
        Box.Thickness = 2
        Box.Transparency = 1
        Box.Filled = false
        Box.Visible = false

        while scrapBoxESPEnabled do
            -- Find Scrap objects within the Collectibles folder
            for _, scrap in pairs(workspace.Collectibles:GetChildren()) do
                if scrap.Name == "Scrap" then
                    local pos, onScreen = camera:WorldToViewportPoint(scrap.Position)
                    if onScreen then
                        local size = 1000 / pos.Z
                        Box.Size = Vector2.new(size, size)
                        Box.Position = Vector2.new(pos.X - size / 2, pos.Y - size / 2)
                        Box.Visible = true
                    else
                        Box.Visible = false
                    end
                end
            end
            task.wait()
        end
        Box:Remove()
    end)()
end

-- Scrap Tracer ESP (auto-respawn safe)
local function createScrapTracerESP()
    coroutine.wrap(function()
        local Tracer = Drawing.new("Line")
        Tracer.Color = Color3.fromRGB(139, 69, 19) -- Brown color
        Tracer.Thickness = 1
        Tracer.Transparency = 1
        Tracer.Visible = false

        while scrapTracerESPEnabled do
            -- Find Scrap objects within the Collectibles folder
            for _, scrap in pairs(workspace.Collectibles:GetChildren()) do
                if scrap.Name == "Scrap" then
                    local pos, onScreen = camera:WorldToViewportPoint(scrap.Position)
                    if onScreen then
                        Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                        Tracer.To = Vector2.new(pos.X, pos.Y)
                        Tracer.Visible = true
                    else
                        Tracer.Visible = false
                    end
                end
            end
            task.wait()
        end
        Tracer:Remove()
    end)()
end

-- Toggle: Scrap Box ESP
ESPTab:AddSwitch("ScrapBoxESP", {
    Title = "Scrap Boxes",
    Default = false,
    Callback = function(state)
        scrapBoxESPEnabled = state
        if state then
            createScrapBoxESP()
        end
    end
})

-- Toggle: Scrap Tracer ESP
ESPTab:AddSwitch("ScrapTracerESP", {
    Title = "Scrap Tracers",
    Default = false,
    Callback = function(state)
        scrapTracerESPEnabled = state
        if state then
            createScrapTracerESP()
        end
    end
})
