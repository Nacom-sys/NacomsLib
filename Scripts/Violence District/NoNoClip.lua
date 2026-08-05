--AutoSkillCheck--
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP        = Players.LocalPlayer
local PG        = LP:WaitForChild("PlayerGui")
local CheckGui  = PG:WaitForChild("SkillCheckPromptGui")
local Check     = CheckGui:WaitForChild("Check")
local Line      = Check:WaitForChild("Line")
local Goal      = Check:WaitForChild("Goal")

local HeartbeatConn = nil

local function PressSpace()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait(0.01)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

local function LineInGoal()
    local lr = Line.Rotation % 360
    local gr = Goal.Rotation % 360
    local gs = (gr + 104) % 360
    local ge = (gr + 114) % 360

    if gs > ge then
        return lr >= gs or lr <= ge
    else
        return lr >= gs and lr <= ge
    end
end

local function HeartbeatCheck()
    if LP.Team and LP.Team.Name == "Survivors" then
        if LineInGoal() then
            PressSpace()
            if HeartbeatConn then
                HeartbeatConn:Disconnect()
            end
        end
    elseif HeartbeatConn then
        HeartbeatConn:Disconnect()
        HeartbeatConn = nil
    end
end

local function OnCheckVisible()
    if LP.Team and LP.Team.Name == "Survivors" then
        if Check.Visible then
            if HeartbeatConn then HeartbeatConn:Disconnect() end
            HeartbeatConn = RunService.Heartbeat:Connect(HeartbeatCheck)
        elseif HeartbeatConn then
            HeartbeatConn:Disconnect()
            HeartbeatConn = nil
        end
    elseif HeartbeatConn then
        HeartbeatConn:Disconnect()
        HeartbeatConn = nil
    end
end

Check:GetPropertyChangedSignal("Visible"):Connect(OnCheckVisible)
--ViolenceScript--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CAMERA = workspace.CurrentCamera
local MAP = workspace:FindFirstChild("Map") or workspace

local function getCamera()
    return workspace.CurrentCamera or CAMERA
end

-- SECTION: UTILS
local function safe_disconnect(conn)
    if conn then
        pcall(function()
            conn:Disconnect()
        end)
    end
end
local function clear_instances(mapTable)
    for k, v in pairs(mapTable) do
        if typeof(v) == "Instance" then
            pcall(function()
                v:Destroy()
            end)
        end
        mapTable[k] = nil
    end
end
local function make_controller()
    local self = {
        running = false,
        _conns = {}
    }
    function self:connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(self._conns, c)
        return c
    end
    function self:stop_all()
        for _, c in ipairs(self._conns) do
            safe_disconnect(c)
        end
        table.clear(self._conns)
        self.running = false
    end
    return self
end

-- SECTION: CONTROLLERS (Logic remains exactly the same)

-- Player ESP
local PlayerESP = {}
do
    local C = make_controller()
    local highlights = {}
    local labels = {}

    local function ensure_highlight(plr, adornee)
        local hl = highlights[plr]
        if not hl or not hl.Parent then
            hl = Instance.new("Highlight")
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.3
            hl.OutlineTransparency = 0
            hl.Parent = CAMERA
            highlights[plr] = hl
        end
        hl.Adornee = adornee
        return hl
    end

    local function ensure_label(plr, adornee)
        local lbl = labels[plr]
        if not lbl or not lbl.Parent or not lbl.Parent.Parent then
            local bill = Instance.new("BillboardGui")
            bill.Size = UDim2.new(0, 220, 0, 60)
            bill.StudsOffset = Vector3.new(0, 3.2, 0)
            bill.AlwaysOnTop = true
            bill.Parent = CAMERA

            lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansSemibold
            lbl.TextSize = 14
            lbl.TextStrokeTransparency = 0.3
            lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Parent = bill
            labels[plr] = lbl
        end
        lbl.Parent.Adornee = adornee
        return lbl
    end

    local function update_player(plr)
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        if not char or not head then
            local hl = highlights[plr]
            if hl then
                hl.Adornee = nil
            end
            local lbl = labels[plr]
            if lbl and lbl.Parent then
                lbl.Parent.Adornee = nil
            end
            return
        end

        local team = plr.Team
        local isKiller = team and team.Name == "Killer"
        local isSurvivor = (not isKiller) and team and team.Name == "Survivors"

        local line1, line2, line3 = plr.Name, "", ""
        local color

        if isKiller then
            local killerName = plr:GetAttribute("SelectedKiller") or "Killer"
            line2 = "[" .. killerName .. "]"
            color = Color3.fromRGB(255, 80, 80)
        elseif isSurvivor then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local knocked = char:GetAttribute("Knocked")
            local hooked = char:GetAttribute("IsHooked")
            local item = plr:GetAttribute("EquippedItem")
            if item and item ~= "" and item ~= "None" then
                line2 = "[" .. item .. "]"
            end
            if hooked then
                color = Color3.fromRGB(255, 110, 80)
            elseif knocked then
                color = Color3.fromRGB(255, 170, 80)
            elseif humanoid and humanoid.Health < (humanoid.MaxHealth or 100) then
                color = Color3.fromRGB(255, 255, 120)
            else
                color = Color3.fromRGB(100, 255, 100)
            end
        else
            local item = plr:GetAttribute("EquippedItem")
            if item and item ~= "" and item ~= "None" then
                line2 = "[" .. item .. "]"
            end
            color = Color3.fromRGB(255, 255, 255)
        end

        local my = Players.LocalPlayer.Character
        local myRoot = my and my:FindFirstChild("HumanoidRootPart")
        if myRoot then
            local dist = math.floor((head.Position - myRoot.Position).Magnitude)
            line3 = "[" .. dist .. "m]"
        end

        local hl = ensure_highlight(plr, char)
        hl.FillColor = color
        local lbl = ensure_label(plr, head)
        if line2 ~= "" then
            lbl.Text = string.format("%s %s\n%s", line1, line3, line2)
        else
            lbl.Text = string.format("%s %s", line1, line3)
        end
        lbl.TextColor3 = color
    end

    function PlayerESP.start()
        if C.running then
            return
        end
        C.running = true
        C:connect(RunService.Heartbeat, function()
            if not C.running then
                return
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Players.LocalPlayer then
                    update_player(plr)
                end
            end
        end)
        C:connect(Players.PlayerRemoving, function(plr)
            if highlights[plr] then
                highlights[plr]:Destroy()
            end
            if labels[plr] and labels[plr].Parent then
                labels[plr].Parent:Destroy()
            end
            highlights[plr] = nil
            labels[plr] = nil
        end)
    end

    function PlayerESP.stop()
        if not C.running then
            return
        end
        C:stop_all()
        clear_instances(highlights)
        for plr, lbl in pairs(labels) do
            if lbl and lbl.Parent then
                pcall(function()
                    lbl.Parent:Destroy()
                end)
            end
            labels[plr] = nil
        end
    end

end

-- Hooks ESP
local HookESP = (function()
    local C = make_controller()
    local highlights = {}
    local labels = {}
    local tracked = {}

    -- find the root of a hook
    local function getHookRoot(inst)
        local m = inst:IsA("Model") and inst or inst:FindFirstAncestorOfClass("Model")
        while m do
            local lname = m.Name:lower()
            if lname == "hook" then
                return m
            end
            local parent = m.Parent
            if parent and parent:IsA("Model") then
                m = parent
            else
                m = nil
            end
        end
        return nil
    end

    local function pickPart(root)
        if root.PrimaryPart and root.PrimaryPart:IsA("BasePart") then
            return root.PrimaryPart
        end
        local hb = root:FindFirstChild("HitBox", true)
        if hb and hb:IsA("BasePart") then
            return hb
        end
        return root:FindFirstChildWhichIsA("BasePart", true)
    end

    local function cleanup(root)
        if highlights[root] then
            highlights[root]:Destroy()
        end
        if labels[root] then
            local p = labels[root].Parent
            if p then
                p:Destroy()
            end
        end
        highlights[root] = nil
        labels[root] = nil
        tracked[root] = nil
    end

    local function ensure(root)
        if not root or not root.Parent then
            if root and tracked[root] then
                cleanup(root)
            end
            return
        end
        tracked[root] = true

        local part = pickPart(root)
        if not part then
            return
        end

        local cam = getCamera()
        if not cam then
            return
        end

        -- Highlight
        local hl = highlights[root]
        if not hl or not hl.Parent then
            hl = Instance.new("Highlight")
            hl.Parent = cam
            hl.Adornee = root
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.6
            hl.FillColor = Color3.fromRGB(255, 80, 80)
            hl.OutlineColor = Color3.fromRGB(255, 0, 0)
            highlights[root] = hl
        else
            hl.Adornee = root
        end

        -- Billboard “Hook”
        local txt = labels[root]
        if not txt or not txt.Parent then
            local bill = Instance.new("BillboardGui")
            bill.Parent = cam
            bill.Adornee = part
            bill.Size = UDim2.new(0, 120, 0, 28)
            bill.StudsOffset = Vector3.new(0, 4, 0)
            bill.AlwaysOnTop = true

            txt = Instance.new("TextLabel")
            txt.Parent = bill
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextScaled = false
            txt.TextSize = 14
            txt.Font = Enum.Font.SourceSansSemibold
            txt.TextStrokeTransparency = 0.4
            txt.TextStrokeColor3 = Color3.new(0, 0, 0)
            labels[root] = txt
        end

        txt.Parent.Adornee = part
        txt.Text = "Hook"
        txt.TextColor3 = Color3.fromRGB(255, 100, 100)
    end

    function C:start()
        if self.running then
            return
        end
        self.running = true

        -- catch new hooks that appear
        self:connect(MAP.DescendantAdded, function(inst)
            if not self.running then
                return
            end
            local root = getHookRoot(inst)
            if root then
                tracked[root] = true
                ensure(root)
            end
        end)

        -- cleanup when removed
        self:connect(MAP.DescendantRemoving, function(inst)
            local root = getHookRoot(inst)
            if root and tracked[root] then
                cleanup(root)
            end
        end)

        -- initial scan
        task.spawn(function()
            task.wait(0.5)
            if not self.running then
                return
            end
            for _, inst in ipairs(MAP:GetDescendants()) do
                local root = getHookRoot(inst)
                if root and not tracked[root] then
                    tracked[root] = true
                    ensure(root)
                end
            end
        end)
    end

    function C:stop()
        if not self.running then
            return
        end
        self:stop_all()
        for root in pairs(tracked) do
            cleanup(root)
        end
    end

    return C

end)()

-- Generic Model ESP
local function make_model_esp(opts)
    local C = make_controller()
    local labels, highlights, tracked = {}, {}, {}

    local function is_target(inst)
        if not inst:IsA("Model") then
            return false
        end
        local n = inst.Name:lower()
        for _, pat in ipairs(opts.nameContains or {}) do
            if n:find(pat) then
                return true
            end
        end
        return false
    end

    local function pick_part(model)
        if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
            return model.PrimaryPart
        end
        local main = model:FindFirstChild("Main", true)
        if main and main:IsA("BasePart") then
            return main
        end
        return model:FindFirstChildWhichIsA("BasePart", true)
    end

    local function ensure(model)
        if not tracked[model] then
            tracked[model] = true
        end
        local part = pick_part(model)
        if not part then
            return
        end

        -- Get the current camera every time (important when changing map/round)
        local cam = getCamera()

        if not highlights[model] or not highlights[model].Parent then
            local hl = Instance.new("Highlight")
            hl.Parent = cam
            hl.Adornee = part
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            highlights[model] = hl
        end
        local hl = highlights[model]
        hl.Adornee = part
        hl.FillColor = opts.fillColor or Color3.new(1, 1, 1)
        hl.OutlineColor = opts.outlineColor or Color3.new(1, 1, 1)

        if opts.labelText then
            if not labels[model] or not labels[model].Parent then
                local bill = Instance.new("BillboardGui")
                bill.Parent = cam
                bill.Adornee = part
                bill.Size = UDim2.new(0, 140, 0, 28)
                bill.StudsOffset = Vector3.new(0, 3, 0)
                bill.AlwaysOnTop = true
                local txt = Instance.new("TextLabel", bill)
                txt.Size = UDim2.new(1, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.TextSize = 14
                txt.Font = Enum.Font.SourceSansSemibold
                txt.TextStrokeTransparency = 0.4
                txt.TextStrokeColor3 = Color3.new(0, 0, 0)
                labels[model] = txt
            end
            local txt = labels[model]
            txt.Parent.Adornee = part
            txt.Text = opts.labelText(model)
            txt.TextColor3 = opts.textColor or Color3.new(1, 1, 1)
        end
    end

    local function cleanup(model)
        if highlights[model] then
            highlights[model]:Destroy()
        end
        if labels[model] then
            local p = labels[model].Parent;
            if p then
                p:Destroy()
            end
        end
        highlights[model] = nil
        labels[model] = nil
        tracked[model] = nil
    end

    function C:start()
        if self.running then
            return
        end
        self.running = true
        self:connect(RunService.Heartbeat, function()
            for mdl in pairs(tracked) do
                if mdl and mdl.Parent then
                    ensure(mdl)
                end
            end
        end)
        self:connect(MAP.DescendantAdded, function(child)
            if not self.running then
                return
            end
            if child:IsA("Model") then
                task.defer(function()
                    if not self.running then
                        return
                    end
                    if is_target(child) then
                        tracked[child] = true
                        ensure(child)
                    end
                end)
            end
        end)
        self:connect(MAP.DescendantRemoving, function(child)
            if tracked[child] then
                cleanup(child)
            end
        end)
        task.spawn(function()
            task.wait(0.5)
            if not self.running then
                return
            end
            for _, obj in ipairs(MAP:GetDescendants()) do
                if obj:IsA("Model") and is_target(obj) then
                    tracked[obj] = true
                    ensure(obj)
                end
            end
        end)
    end

    function C:stop()
        if not self.running then
            return
        end
        self:stop_all()
        for mdl in pairs(tracked) do
            cleanup(mdl)
        end
    end

    return C

end

local GateESP = make_model_esp({
    nameContains = {"gate", "exitlever"},
    labelText = function()
        return "Gate"
    end,
    fillColor = Color3.fromRGB(160, 0, 255),
    outlineColor = Color3.fromRGB(200, 120, 255),
    textColor = Color3.fromRGB(200, 180, 255)
})

local GeneratorESP = (function()
    local C = make_controller()
    local labels, highlights, tracked = {}, {}, {}
    local function attach_for(model)
        return model:FindFirstChild("defaultMaterial") or model.PrimaryPart or
                   model:FindFirstChildWhichIsA("BasePart", true)
    end
    local function ensure(model)
        local attach = attach_for(model)
        if not attach then
            return
        end
        if not highlights[model] or not highlights[model].Parent then
            local hl = Instance.new("Highlight", CAMERA)
            hl.Adornee = attach
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            highlights[model] = hl
        end
        if not labels[model] or not labels[model].Parent then
            local bill = Instance.new("BillboardGui", CAMERA)
            bill.Adornee = attach
            bill.Size = UDim2.new(0, 170, 0, 38)
            bill.StudsOffset = Vector3.new(0, 4, 0)
            bill.AlwaysOnTop = true
            local txt = Instance.new("TextLabel", bill)
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextSize = 14
            txt.Font = Enum.Font.SourceSansSemibold
            txt.TextStrokeTransparency = 0.4
            txt.TextStrokeColor3 = Color3.new(0, 0, 0)
            labels[model] = txt
        end
        local progress = model:GetAttribute("RepairProgress") or 0
        local repairing = model:GetAttribute("PlayersRepairingCount") or 0
        local full = progress >= 100
        local hl = highlights[model]
        local txt = labels[model]
        if full then
            hl.FillColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineColor = Color3.fromRGB(0, 255, 0)
            txt.Text = "Generator\n100.0%"
            txt.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            local g = math.clamp(progress / 100, 0, 1)
            local color = Color3.new(1 - g * 0.7, 1, 1 - g * 0.7)
            if repairing > 0 then
                txt.Text = string.format("Generator\n%.1f%% [%d]", progress, repairing)
            else
                txt.Text = string.format("Generator\n%.1f%%", progress)
            end
            txt.TextColor3 = color
            hl.FillColor = Color3.new(1, 1, 1)
            hl.OutlineColor = Color3.new(1, 1, 1)
        end
    end
    local function cleanup(model)
        if highlights[model] then
            highlights[model]:Destroy()
        end
        if labels[model] then
            local p = labels[model].Parent;
            if p then
                p:Destroy()
            end
        end
        highlights[model] = nil
        labels[model] = nil
        tracked[model] = nil
    end
    function C:start()
        if self.running then
            return
        end
        self.running = true
        self:connect(RunService.Heartbeat, function()
            for mdl in pairs(tracked) do
                if mdl and mdl.Parent then
                    ensure(mdl)
                end
            end
        end)
        self:connect(MAP.DescendantAdded, function(child)
            if not self.running then
                return
            end
            if child:IsA("Model") and child:GetAttribute("RepairProgress") ~= nil then
                tracked[child] = true
                ensure(child)
            end
        end)
        self:connect(MAP.DescendantRemoving, function(child)
            if tracked[child] then
                cleanup(child)
            end
        end)
        task.spawn(function()
            task.wait(0.5)
            if not self.running then
                return
            end
            for _, obj in ipairs(MAP:GetDescendants()) do
                if obj:IsA("Model") and obj:GetAttribute("RepairProgress") ~= nil then
                    tracked[obj] = true
                    ensure(obj)
                end
            end
        end)
    end
    function C:stop()
        if not self.running then
            return
        end
        self:stop_all()
        for mdl in pairs(tracked) do
            cleanup(mdl)
        end
    end
    return C
end)()

local WindowESP = (function()
    local C = make_controller()
    local labels, tracked = {}, {}
    local function is_window_bottom(inst)
        if not inst:IsA("BasePart") then
            return false
        end
        if inst.Name ~= "Bottom" then
            return false
        end
        local p = inst.Parent
        return p and p.Name:lower():find("window") ~= nil
    end
    local function ensure(part)
        if not labels[part] or not labels[part].Parent then
            local bill = Instance.new("BillboardGui", CAMERA)
            bill.Adornee = part
            bill.Size = UDim2.new(0, 120, 0, 28)
            bill.StudsOffset = Vector3.new(0, 3, 0)
            bill.AlwaysOnTop = true
            local txt = Instance.new("TextLabel", bill)
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextSize = 14
            txt.Font = Enum.Font.SourceSansSemibold
            txt.TextStrokeTransparency = 0.4
            txt.TextStrokeColor3 = Color3.new(0, 0, 0)
            txt.AutoLocalize = false
            labels[part] = txt
        end
        local txt = labels[part]
        txt.Parent.Adornee = part
        txt.Text = "Window"
        txt.TextColor3 = Color3.fromRGB(180, 230, 255)
    end
    local function cleanup(part)
        if labels[part] then
            local p = labels[part].Parent;
            if p then
                p:Destroy()
            end
        end
        labels[part] = nil
        tracked[part] = nil
    end
    function C:start()
        if self.running then
            return
        end
        self.running = true
        self:connect(MAP.DescendantAdded, function(child)
            if not self.running then
                return
            end
            if child:IsA("BasePart") and child.Name == "Bottom" then
                task.defer(function()
                    if is_window_bottom(child) then
                        tracked[child] = true;
                        ensure(child)
                    end
                end)
            end
        end)
        self:connect(MAP.DescendantRemoving, function(child)
            if tracked[child] then
                cleanup(child)
            end
        end)
        task.spawn(function()
            task.wait(0.5)
            if not self.running then
                return
            end
            for _, inst in ipairs(MAP:GetDescendants()) do
                if inst:IsA("BasePart") and is_window_bottom(inst) then
                    tracked[inst] = true
                    ensure(inst)
                end
            end
        end)
    end
    function C:stop()
        if not self.running then
            return
        end
        self:stop_all()
        for k in pairs(tracked) do
            cleanup(k)
        end
    end
    return C
end)()

-- Pallet ESP
local PalletESP = (function()
    local C = make_controller()
    local highlights = {}
    local labels = {}
    local tracked = {}

    -- check if model is a Palletwrong
    local function isPallet(model)
        if not model:IsA("Model") then
            return false
        end

        local lname = model.Name:lower()
        -- Find Name "Pallet", "Palletwrong"
        if lname:find("pallet") then
            return true
        end

        return false
    end

    -- Create ESP for Pallet
    local function setupPallet(model)
        if tracked[model] then
            return
        end
        if not isPallet(model) then
            return
        end

        -- Find part to attach Billboard
        local attach

        if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
            attach = model.PrimaryPart
        else
            -- Try to find HumanoidRootPart first
            local hrp = model:FindFirstChild("HumanoidRootPart", true)
            if hrp and hrp:IsA("BasePart") then
                attach = hrp
            else
                attach = model:FindFirstChildWhichIsA("BasePart", true)
            end
        end

        if not attach then
            return
        end

        local cam = getCamera()

        -- Highlight
        local hl = Instance.new("Highlight")
        hl.Parent = cam
        hl.Adornee = model
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.FillColor = Color3.fromRGB(255, 200, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 0)

        highlights[model] = hl

        -- Billboard + Text
        local bill = Instance.new("BillboardGui")
        bill.Parent = cam
        bill.Adornee = attach
        bill.Size = UDim2.new(0, 120, 0, 28)
        bill.StudsOffset = Vector3.new(0, 3, 0)
        bill.AlwaysOnTop = true

        local txt = Instance.new("TextLabel")
        txt.Parent = bill
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextScaled = false
        txt.TextSize = 14
        txt.Font = Enum.Font.SourceSansSemibold
        txt.TextStrokeTransparency = 0.4
        txt.TextStrokeColor3 = Color3.new(0, 0, 0)
        txt.Text = "Pallet"
        txt.TextColor3 = Color3.fromRGB(255, 230, 80)

        labels[model] = txt
        tracked[model] = true
    end

    -- Cleanup ESP
    local function cleanup(model)
        if highlights[model] then
            highlights[model]:Destroy()
            highlights[model] = nil
        end
        if labels[model] then
            local bill = labels[model].Parent
            if bill then
                bill:Destroy()
            end
            labels[model] = nil
        end
        tracked[model] = nil
    end

    function C:start()
        if self.running then
            return
        end
        self.running = true

        -- cleanup when removed from Map
        self:connect(MAP.DescendantRemoving, function(child)
            if tracked[child] then
                cleanup(child)
            end
        end)

        -- Scan Map with GetDescendants periodically
        task.spawn(function()
            task.wait(1)
            while self.running do
                local cam = getCamera()
                if not cam then
                    task.wait(1)
                else
                    for _, obj in ipairs(MAP:GetDescendants()) do
                        if obj:IsA("Model") and isPallet(obj) then
                            setupPallet(obj)
                        end
                    end

                    task.wait(1) -- scan again every 1 second
                end
            end
        end)
    end

    function C:stop()
        if not self.running then
            return
        end
        self:stop_all()
        self.running = false
        for m in pairs(tracked) do
            cleanup(m)
        end
    end

    return C

end)()

-- Sprint
local Sprint = {}
do
    local C = make_controller()
    local NORMAL = 1.0
    local BOOST = 1.05
    local sprinting = false
    local function get_character()
        local lp = Players.LocalPlayer
        local char = lp and lp.Character
        if char and char.Parent then
            return char
        end
        return workspace:FindFirstChild(lp.Name)
    end
    local function set_boost(v)
        local char = get_character()
        if not char then
            return
        end
        if char:GetAttribute("speedboost") ~= v then
            char:SetAttribute("speedboost", v)
        end
    end
    local function update()
        set_boost(sprinting and BOOST or NORMAL)
    end
    function Sprint.setBoost(v)
        BOOST = tonumber(v) or BOOST;
        update()
    end
    function Sprint.start()
        if C.running then
            return
        end
        C.running = true
        C:connect(UserInputService.InputBegan, function(input, gp)
            if gp then
                return
            end
            if input.KeyCode == Enum.KeyCode.g then
                sprinting = true;
                update()
            end
        end)
        C:connect(UserInputService.InputEnded, function(input)
            if input.KeyCode == Enum.KeyCode.g then
                sprinting = false;
                update()
            end
        end)
        C:connect(RunService.Heartbeat, update)
    end
    function Sprint.stop()
        if not C.running then
            return
        end
        C:stop_all();
        sprinting = false;
        update()
    end
end

-- SECTION: UI (Single Page)
local function make_ui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "VDistrictUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 9e6
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.AutoLocalize = false

    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(sg)
        end
    end)
    local parented = false
    pcall(function()
        if gethui then
            sg.Parent = gethui();
            parented = true
        end
    end)
    if not parented then
        local ok, core = pcall(game.GetService, game, "CoreGui")
        if ok and core then
            local ok2 = pcall(function()
                sg.Parent = core
            end)
            parented = ok2 and sg.Parent ~= nil
        end
    end
    if not parented then
        sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ====== CONFIG STATE ======
    local toggleKey = Enum.KeyCode.RightControl -- default keybind
    local listeningForKey = false -- waiting for new key press

    local function keycode_to_str(key)
        local s = tostring(key) -- "Enum.KeyCode.RightControl"
        return s:match("KeyCode%.(.+)") or s
    end

    -- Size Config
    local WIDTH = 250
    local HEADER_H = 30
    local CONTENT_H = 430
    local FULL_H = HEADER_H + CONTENT_H

    local root = Instance.new("Frame", sg)
    root.Name = "Root"
    root.Size = UDim2.new(0, WIDTH, 0, FULL_H)
    root.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    root.BackgroundTransparency = 0.25 -- more transparent than before
    root.BorderSizePixel = 0
    root.Active = true
    Instance.new("UICorner", root).CornerRadius = UDim.new(0, 8)

    -- Center on screen
    local vs = CAMERA and CAMERA.ViewportSize or Vector2.new(1280, 720)
    local startX = math.max(0, math.floor((vs.X - WIDTH) / 2))
    local startY = math.max(0, math.floor((vs.Y - FULL_H) / 2))
    root.Position = UDim2.fromOffset(startX, startY)

    -- Header
    local header = Instance.new("Frame", root)
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1
    header.Active = true

    local title = Instance.new("TextLabel", header)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Font = Enum.Font.SourceSansSemibold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Violence District"
    title.TextColor3 = Color3.fromRGB(235, 235, 240)

    local minimize = Instance.new("TextButton", header)
    minimize.Text = "-"
    minimize.Size = UDim2.new(0, 20, 0, 20)
    minimize.Position = UDim2.new(1, -26, 0.5, -10)
    minimize.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    minimize.TextColor3 = Color3.fromRGB(200, 200, 210)
    minimize.AutoButtonColor = true
    minimize.Font = Enum.Font.SourceSansSemibold
    minimize.TextSize = 14
    Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 6)

    -- Content Container
    local content = Instance.new("Frame", root)
    content.Name = "Content"
    content.Position = UDim2.new(0, 10, 0, HEADER_H + 5)
    content.Size = UDim2.new(1, -20, 1, -(HEADER_H + 15))
    content.BackgroundTransparency = 1

    local list = Instance.new("UIListLayout", content)
    list.FillDirection = Enum.FillDirection.Vertical
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    -- Controls Utils
    local function make_switch(labelText)
        local row = Instance.new("Frame", content)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", row)
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.SourceSansSemibold
        label.TextSize = 12
        label.TextColor3 = Color3.fromRGB(220, 220, 230)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Text = labelText

        local sw = Instance.new("TextButton", row)
        sw.Size = UDim2.new(0, 40, 0, 20)
        sw.Position = UDim2.new(1, -40, 0.5, -10)
        sw.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
        sw.Text = ""
        sw.AutoButtonColor = true
        sw.BorderSizePixel = 0
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", sw)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
        knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = false
        local function apply()
            sw.BackgroundColor3 = state and Color3.fromRGB(55, 115, 75) or Color3.fromRGB(60, 60, 68)
            knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        end
        local function set_state(v)
            state = v and true or false;
            apply()
        end
        apply()

        sw.MouseButton1Click:Connect(function()
            set_state(not state)
        end)
        return {
            get = function()
                return state
            end,
            set = set_state
        }
    end

    local function make_slider(labelText, min, max, default)
        local frame = Instance.new("Frame", content)
        frame.Size = UDim2.new(1, 0, 0, 42)
        frame.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", frame)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.SourceSansSemibold
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.Text = labelText .. string.format(" (%.2f)", default)

        local bar = Instance.new("Frame", frame)
        bar.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
        bar.Size = UDim2.new(1, 0, 0, 6)
        bar.Position = UDim2.new(0, 0, 0, 24)
        bar.BorderSizePixel = 0
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

        local fill = Instance.new("Frame", bar)
        fill.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

        local val = default
        local function set_value(v)
            v = math.clamp(v, min, max)
            val = v
            local alpha = (v - min) / (max - min)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            lbl.Text = labelText .. string.format(" (%.2f)", v)
        end

        local dragging = false
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local absPos = bar.AbsolutePosition.X
                local absSize = bar.AbsoluteSize.X
                local x = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
                set_value(min + x * (max - min))
            end
        end)
        return {
            get = function()
                return val
            end,
            set = set_value
        }
    end

    local function make_divider(text)
        local d = Instance.new("TextLabel", content)
        d.Size = UDim2.new(1, 0, 0, 20)
        d.BackgroundTransparency = 1
        d.Text = text
        d.Font = Enum.Font.SourceSansBold
        d.TextSize = 12
        d.TextColor3 = Color3.fromRGB(150, 150, 160)
        d.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- Populate UI
    make_divider("VISUALS")
    local swPlayer = make_switch("Players")
    local swGate = make_switch("Gates")
    local swGen = make_switch("Generators")
    local swWin = make_switch("Windows")
    local swPal = make_switch("Pallets")
    local swHook = make_switch("Hooks")

    make_divider("MOVEMENT")
    local swSprint = make_switch("Sprint Speed")
    local sprintSlider = make_slider("Sprint Speed", 1.0, 2.0, 1.05)

    make_divider("SETTINGS")

    -- SETTINGS row: show current keybind + change button
    local settingsRow = Instance.new("Frame", content)
    settingsRow.Size = UDim2.new(1, 0, 0, 24)
    settingsRow.BackgroundTransparency = 1

    local info = Instance.new("TextLabel", settingsRow)
    info.Size = UDim2.new(1, -80, 1, 0)
    info.Position = UDim2.new(0, 0, 0, 0)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.SourceSansItalic
    info.TextSize = 11
    info.TextColor3 = Color3.fromRGB(120, 120, 130)
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Text = "Toggle Menu: " .. keycode_to_str(toggleKey)

    local changeKeyBtn = Instance.new("TextButton", settingsRow)
    changeKeyBtn.Size = UDim2.new(0, 70, 0, 20)
    changeKeyBtn.Position = UDim2.new(1, -72, 0.5, -10)
    changeKeyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    changeKeyBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    changeKeyBtn.Font = Enum.Font.SourceSansSemibold
    changeKeyBtn.TextSize = 11
    changeKeyBtn.Text = "Change"
    changeKeyBtn.AutoButtonColor = true
    changeKeyBtn.BorderSizePixel = 0
    Instance.new("UICorner", changeKeyBtn).CornerRadius = UDim.new(0, 6)

    changeKeyBtn.MouseButton1Click:Connect(function()
        listeningForKey = true
        info.Text = "Press a key..."
    end)

    -- Logic Wiring
    local function wire_switch(sw, onStart, onStop)
        local last = sw.get()
        local function apply(new)
            if new then
                onStart()
            else
                onStop()
            end
        end
        apply(last)
        sw.set(last)
        RunService.Heartbeat:Connect(function()
            local cur = sw.get()
            if cur ~= last then
                last = cur;
                apply(cur)
            end
        end)
    end

    wire_switch(swPlayer, function()
        PlayerESP.start()
    end, function()
        PlayerESP.stop()
    end)
    wire_switch(swGate, function()
        GateESP:start()
    end, function()
        GateESP:stop()
    end)
    wire_switch(swGen, function()
        GeneratorESP:start()
    end, function()
        GeneratorESP:stop()
    end)
    wire_switch(swWin, function()
        WindowESP:start()
    end, function()
        WindowESP:stop()
    end)
    wire_switch(swPal, function()
        PalletESP:start()
    end, function()
        PalletESP:stop()
    end)
    wire_switch(swHook, function()
        HookESP:start()
    end, function()
        HookESP:stop()
    end)

    -- Sprint Logic
    local prevSprint = swSprint.get()
    RunService.Heartbeat:Connect(function()
        local cur = swSprint.get()
        if cur ~= prevSprint then
            prevSprint = cur
            if cur then
                Sprint.start()
            else
                Sprint.stop()
            end
        end
        Sprint.setBoost(sprintSlider.get())
    end)

    -- Toggle Keybind + Key Picker
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then
            return
        end

        -- waiting for new key press
        if listeningForKey and input.UserInputType == Enum.UserInputType.Keyboard then
            listeningForKey = false
            toggleKey = input.KeyCode
            info.Text = "Toggle Menu: " .. keycode_to_str(toggleKey)
            return
        end

        -- Toggle menu according to current keybind
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
            sg.Enabled = not sg.Enabled
        end
    end)

    -- Window Behavior (Minimize/Drag)
    local collapsed = false
    local function apply_collapse()
        content.Visible = not collapsed
        root.Size = collapsed and UDim2.new(0, WIDTH, 0, HEADER_H) or UDim2.new(0, WIDTH, 0, FULL_H)
        minimize.Text = collapsed and "+" or "-"
    end
    minimize.MouseButton1Click:Connect(function()
        collapsed = not collapsed;
        apply_collapse()
    end)

    local dragging = false
    local dragOffset
    local function updateFromMouse()
        local m = UserInputService:GetMouseLocation()
        local newX = m.X - dragOffset.X
        local newY = m.Y - dragOffset.Y
        root.Position = UDim2.fromOffset(newX, newY)
    end
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local m = UserInputService:GetMouseLocation()
            dragOffset = Vector2.new(m.X - root.AbsolutePosition.X, m.Y - root.AbsolutePosition.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end)

end

make_ui()
