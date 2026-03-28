-- ===== UNIVERSAL ESP (PLAYERS + NPCs) =====

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local CHAMS_COLOR = Color3.fromRGB(255, 0, 0)
local SKELETON_COLOR = Color3.fromRGB(180, 0, 255)
local TRACER_COLOR = Color3.fromRGB(255, 255, 255)

local SKELETON_THICKNESS = 0.3

-- bones
local Bones = {
	{"Head","UpperTorso"},
	{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},
	{"LeftUpperArm","LeftLowerArm"},
	{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},
	{"RightUpperArm","RightLowerArm"},
	{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},
	{"LeftUpperLeg","LeftLowerLeg"},
	{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},
	{"RightUpperLeg","RightLowerLeg"},
	{"RightLowerLeg","RightFoot"},
}

local ESP = {}

-- cleanup
local function clear(model)
	if ESP[model] then
		for _,obj in pairs(ESP[model]) do
			if typeof(obj) == "Instance" then
				pcall(function() obj:Destroy() end)
			elseif typeof(obj) == "table" then
				for _,i in pairs(obj) do
					pcall(function() i:Destroy() end)
				end
			end
		end
	end
	ESP[model] = nil
end

-- apply esp
local function apply(model)
	if not model:IsA("Model") then return end
	if not model:FindFirstChildOfClass("Humanoid") then return end
	if model == LocalPlayer.Character then return end
	if ESP[model] then return end

	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	ESP[model] = {}

	-- 🔴 CHAMS
	local hl = Instance.new("Highlight")
	hl.Name = "ESP_Chams"
	hl.FillColor = CHAMS_COLOR
	hl.OutlineColor = CHAMS_COLOR
	hl.FillTransparency = 0.4
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = model
	table.insert(ESP[model], hl)

	-- 🟣 SKELETON
	local beams = {}
	for _,pair in ipairs(Bones) do
		local p0 = model:FindFirstChild(pair[1])
		local p1 = model:FindFirstChild(pair[2])
		if p0 and p1 then
			local a0 = Instance.new("Attachment", p0)
			local a1 = Instance.new("Attachment", p1)

			local beam = Instance.new("Beam")
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Width0 = SKELETON_THICKNESS
			beam.Width1 = SKELETON_THICKNESS
			beam.FaceCamera = true
			beam.Color = ColorSequence.new(SKELETON_COLOR)
			beam.LightEmission = 1
			beam.Parent = model

			table.insert(beams, beam)
		end
	end
	ESP[model].Skeleton = beams

	-- 🔗 TRACER
	local camAttach = Instance.new("Attachment")
	camAttach.Parent = Camera
	camAttach.Position = Vector3.new(0, -Camera.ViewportSize.Y / 2, 0)

	local hrpAttach = Instance.new("Attachment", hrp)

	local tracer = Instance.new("Beam")
	tracer.Attachment0 = camAttach
	tracer.Attachment1 = hrpAttach
	tracer.Width0 = 0.12
	tracer.Width1 = 0.12
	tracer.FaceCamera = true
	tracer.Color = ColorSequence.new(TRACER_COLOR)
	tracer.LightEmission = 1
	tracer.Parent = model

	table.insert(ESP[model], tracer)

	-- auto cleanup on death
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Connect(function()
			clear(model)
		end)
	end
end

-- INITIAL SCAN (like your original script)
for _,obj in pairs(Workspace:GetDescendants()) do
	apply(obj)
end

-- NEW SPAWNS (players + NPCs)
Workspace.DescendantAdded:Connect(function(desc)
	task.wait(0.1)
	apply(desc)
end)

print("✅ ESP ACTIVE (Players + NPCs)")