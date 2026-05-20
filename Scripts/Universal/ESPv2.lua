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
