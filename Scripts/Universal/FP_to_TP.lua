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
task.s
