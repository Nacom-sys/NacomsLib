task.spawn(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local player = Players.LocalPlayer

	local currentHumanoid = nil

	local function setup(char)
		currentHumanoid = char:WaitForChild("Humanoid")

		player.CameraMode = Enum.CameraMode.Classic
		currentHumanoid.AutoRotate = true
	end

	-- run on spawn
	player.CharacterAdded:Connect(setup)

	if player.Character then
		setup(player.Character)
	end

	-- 🔁 CONSTANT LOOP (this is the key part)
	RunService.RenderStepped:Connect(function()
		local char = player.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		currentHumanoid = hum

		-- enforce camera settings every frame (anti-reset)
		player.CameraMode = Enum.CameraMode.Classic

		hum.CameraOffset = Vector3.new(0, 1, 0)

		player.CameraMinZoomDistance = 9
		player.CameraMaxZoomDistance = 11

		hum.AutoRotate = true
	end)
end)
task.spawn(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Nacom-sys/NacomsLib/refs/heads/main/Scripts/Universal/Aimbot.lua"))()
	
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local LocalPlayer = Players.LocalPlayer
	local Camera = workspace:WaitForChild("Camera")

	local ESP = {}

	-- =========================
	-- TEAM CHECK
	-- =========================
	local function isEnemy(plr)
		if not LocalPlayer.Team or not plr.Team then return true end
		return plr.Team ~= LocalPlayer.Team
	end

	-- =========================
	-- CREATE ESP OBJECT
	-- =========================
	local function create(plr)
		if plr == LocalPlayer then return end

		local esp = {
			Box = Drawing.new("Square"),
			Name = Drawing.new("Text"),
			Tracer = Drawing.new("Line"),
			Highlight = nil,
			_alive = true
		}

		esp.Box.Thickness = 1
		esp.Box.Filled = false

		esp.Name.Size = 14
		esp.Name.Center = true
		esp.Name.Outline = true

		esp.Tracer.Thickness = 1

		ESP[plr] = esp
	end

	-- =========================
	-- FAST CLEANUP (IMMEDIATE)
	-- =========================
	local function remove(plr)
		local esp = ESP[plr]
		if not esp then return end

		esp._alive = false

		-- instant hide (removes flicker)
		for _,v in pairs(esp) do
			pcall(function()
				if typeof(v) == "Instance" then
					v:Destroy()
				elseif v.Remove then
					v:Remove()
				elseif v.Visible ~= nil then
					v.Visible = false
				end
			end)
		end

		ESP[plr] = nil
	end

	-- =========================
	-- CHAMS
	-- =========================
	local function applyChams(char, esp)
		if not char or esp.Highlight then return end

		local hl = Instance.new("Highlight")
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.FillColor = Color3.fromRGB(255, 0, 0)
		hl.OutlineColor = Color3.fromRGB(255, 0, 0)
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = char

		esp.Highlight = hl

		-- instant cleanup if character disappears
		char.AncestryChanged:Connect(function(_, parent)
			if not parent and esp.Highlight then
				esp.Highlight:Destroy()
				esp.Highlight = nil
			end
		end)
	end

	-- =========================
	-- TRACK
	-- =========================
	local function track(plr)
		create(plr)

		plr.CharacterAdded:Connect(function(char)
			task.wait(0.1)

			local esp = ESP[plr]
			if not esp then return end

			if isEnemy(plr) then
				applyChams(char, esp)
			end
		end)

		if plr.Character then
			task.delay(0.1, function()
				local esp = ESP[plr]
				if esp and isEnemy(plr) then
					applyChams(plr.Character, esp)
				end
			end)
		end
	end

	for _,p in pairs(Players:GetPlayers()) do
		track(p)
	end

	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(remove)

	-- =========================
	-- MAIN LOOP
	-- =========================
	RunService.RenderStepped:Connect(function()

		local myChar = LocalPlayer.Character
		if not myChar then return end

		local myHRP = myChar:FindFirstChild("HumanoidRootPart")
		if not myHRP then return end

		local myPos = Camera:WorldToViewportPoint(myHRP.Position)

		for plr,esp in pairs(ESP) do

			if not esp._alive then continue end
			if plr == LocalPlayer then continue end
			if not isEnemy(plr) then continue end

			local char = plr.Character
			if not char then continue end

			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

			if not onScreen then
				esp.Box.Visible = false
				esp.Name.Visible = false
				esp.Tracer.Visible = false
				continue
			end

			-- BOX
			local top = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,3,0))
			local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))

			local height = math.abs(top.Y - bottom.Y)
			local width = height * 0.5

			local x = pos.X - width/2
			local y = pos.Y - height/2

			esp.Box.Size = Vector2.new(width, height)
			esp.Box.Position = Vector2.new(x, y)
			esp.Box.Color = Color3.fromRGB(255,0,0)
			esp.Box.Visible = true

			-- NAME
			esp.Name.Text = plr.Name
			esp.Name.Position = Vector2.new(pos.X, y - 15)
			esp.Name.Color = Color3.fromRGB(255,0,0)
			esp.Name.Visible = true

			-- TRACER (enemy → you)
			esp.Tracer.From = Vector2.new(x + width/2, y + height)
			esp.Tracer.To = Vector2.new(myPos.X, myPos.Y)
			esp.Tracer.Color = Color3.fromRGB(255,0,0)
			esp.Tracer.Visible = true
		end
	end)

	print("✅ CLEAN ESP LOADED (FAST CLEAN + CHAMS + NO HEALTH)")

end)

task.spawn(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local player = Players.LocalPlayer

	-- simple UI
	local gui = Instance.new("ScreenGui")
	gui.Name = "MovementDebug"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 400, 0, 200)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(0, 255, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.Parent = gui

	local function getChar()
		return player.Character
	end

	local function getHum()
		local c = getChar()
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local function getHRP()
		local c = getChar()
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	while true do
		task.wait(1)

		local hum = getHum()
		local hrp = getHRP()

		if not hum or not hrp then
			label.Text = "No character loaded"
			continue
		end

		local velocity = hrp.AssemblyLinearVelocity
		local grounded = hum.FloorMaterial ~= Enum.Material.Air

		local text =
			"=== MOVEMENT DEBUG ===\n" ..
			"WalkSpeed: " .. hum.WalkSpeed .. "\n" ..
			"State: " .. tostring(hum:GetState()) .. "\n" ..
			"Grounded: " .. tostring(grounded) .. "\n" ..
			"Velocity XZ: " .. math.floor(Vector3.new(velocity.X,0,velocity.Z).Magnitude) .. "\n" ..
			"Velocity Y: " .. math.floor(velocity.Y) .. "\n" ..
			"PlatformStand: " .. tostring(hum.PlatformStand)

		label.Text = text

		print("[DEBUG]")
		print(text)
	end
end)

task.spawn(function()
	local Players = game:GetService("Players")

	local player = Players.LocalPlayer

	local function getHum()
		local char = player.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	while true do
		task.wait(0.1)
		local hum = getHum()
		if hum then
			hum.WalkSpeed = 20
		end
	end
end)

task.spawn(function()
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	local player = Players.LocalPlayer

	-- SETTINGS
	local BOOST = 16
	local MAX_SPEED = 95
	local COOLDOWN = 0.06
	local DROP_SPEED = -60
	local SPIN_SPEED = 3600

	-- STATE
	local holdingSpace = false
	local spinEnabled = false
	local bhopActive = false
	local lastJump = 0

	-- INPUT
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end

		if input.KeyCode == Enum.KeyCode.Space then
			holdingSpace = true

			-- BHOP MODE ON (instant)
			bhopActive = true
			spinEnabled = false
		end

		if input.KeyCode == Enum.KeyCode.V then
			spinEnabled = not spinEnabled
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space then
			holdingSpace = false

			-- BHOP OFF + SPIN ON (instant)
			bhopActive = false
			spinEnabled = true
		end
	end)

	UserInputService.JumpRequest:Connect(function() end)

	-- MAIN LOOP
	RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		if not char then return end

		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end

		local grounded = hum.FloorMaterial ~= Enum.Material.Air

		------------------------------------------------
		-- 🐇 BHOP SYSTEM
		------------------------------------------------
		if holdingSpace and grounded then
			if tick() - lastJump < COOLDOWN then return end
			lastJump = tick()

			local vel = hrp.AssemblyLinearVelocity
			local horizontal = Vector3.new(vel.X, 0, vel.Z)

			local dir = hrp.CFrame.LookVector * BOOST
			local newHorizontal = horizontal + Vector3.new(dir.X, 0, dir.Z)

			if newHorizontal.Magnitude > MAX_SPEED then
				newHorizontal = newHorizontal.Unit * MAX_SPEED
			end

			hrp.AssemblyLinearVelocity = Vector3.new(
				newHorizontal.X,
				vel.Y,
				newHorizontal.Z
			)

			hum:ChangeState(Enum.HumanoidStateType.Jumping)

		------------------------------------------------
		-- 🔥 FAST DROP (air control)
		------------------------------------------------
		elseif not grounded then
			local vel = hrp.AssemblyLinearVelocity

			hrp.AssemblyLinearVelocity = Vector3.new(
				vel.X,
				DROP_SPEED,
				vel.Z
			)
		end

		------------------------------------------------
		-- 🌀 SPIN SYSTEM
		------------------------------------------------
		if bhopActive then
			hum.AutoRotate = true
			return
		end

		if spinEnabled then
			hum.AutoRotate = false
			hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SPIN_SPEED * dt), 0)
		else
			hum.AutoRotate = true
		end
	end)
end)
