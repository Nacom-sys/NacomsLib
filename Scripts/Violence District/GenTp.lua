local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TARGET_KEY = Enum.KeyCode.G

-- Visual Configuration
local GLOW_COLOR = Color3.fromRGB(160, 0, 255)
local MAX_SELECTION_DISTANCE = 2000 
local SCAN_INTERVAL = 30 -- Alle 30 Sekunden neu scannen

local currentTargetGen = nil
local cachedGenerators = {}

-- Setup the Highlight Instance
local targetHighlight = Instance.new("Highlight")
targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
targetHighlight.FillColor = GLOW_COLOR
targetHighlight.FillTransparency = 0.5
targetHighlight.OutlineColor = GLOW_COLOR
targetHighlight.OutlineTransparency = 0
targetHighlight.Adornee = nil
targetHighlight.Parent = workspace.CurrentCamera

-- Fast filter to check if an object is a generator
local function isGenerator(obj)
	return (obj:IsA("BasePart") or obj:IsA("Model")) and (obj.Name:find("Generator") or obj.Name:match("GeneratorPoint%d+"))
end

-- Der optimierte Background-Scanner
local function updateGeneratorCache()
	local tempCache = {}
	local map = workspace:FindFirstChild("Map") or workspace
	
	-- Scannt die Map nach Generatoren
	for _, obj in ipairs(map:GetDescendants()) do
		if isGenerator(obj) then
			table.insert(tempCache, obj)
		end
	end
	
	-- Cache sicher im Hintergrund austauschen
	cachedGenerators = tempCache
	print("🔄 Generator-Cache aktualisiert! Gefundene Objekte: " .. #cachedGenerators)
end

-- 1. Sofortige Ausführung beim Start
updateGeneratorCache()

-- 2. Loop, der exakt alle 30 Sekunden im Hintergrund läuft
task.spawn(function()
	while true do
		task.wait(SCAN_INTERVAL)
		pcall(updateGeneratorCache)
	end
end)

-- High-Performance Screen Center Targeting Engine
local function updateTargetedGenerator()
	local closestToCenterGen = nil
	local smallestScreenDistance = math.huge
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	
	-- Loop läuft nur noch über die bereits gefilterten Generatoren
	for _, gen in ipairs(cachedGenerators) do
		if gen and gen.Parent then 
			local part = gen:IsA("BasePart") and gen or gen:FindFirstChildWhichIsA("BasePart", true)
			if part then
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				
				if onScreen then
					local distanceToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					local worldDist = playerRoot and (playerRoot.Position - part.Position).Magnitude or 0
					
					if distanceToCenter < smallestScreenDistance and worldDist < MAX_SELECTION_DISTANCE then
						smallestScreenDistance = distanceToCenter
						closestToCenterGen = gen
					end
				end
			end
		end
	end
	
	-- Update Highlight
	if closestToCenterGen then
		currentTargetGen = closestToCenterGen
		targetHighlight.Adornee = closestToCenterGen
	else
		currentTargetGen = nil
		targetHighlight.Adornee = nil
	end
end

-- Teleport execution logic
local function teleportToTarget()
	if not currentTargetGen then return end
	
	local targetPart = currentTargetGen:IsA("BasePart") and currentTargetGen or currentTargetGen:FindFirstChildWhichIsA("BasePart", true)
	if targetPart and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		local offset = Vector3.new(math.random(-3, 3), 2, math.random(-3, 3))
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(targetPart.Position + offset)
	end
end

-- Kamera-Tracking jeden Frame (sehr leichtgewichtig ohne GetDescendants)
RunService.RenderStepped:Connect(function()
	pcall(updateTargetedGenerator)
end)

-- Key listener
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == TARGET_KEY then
		teleportToTarget()
	end
end)
