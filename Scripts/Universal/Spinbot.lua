local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local spinEnabled = false
local SPIN_SPEED = 36000 -- keep low to avoid lag

-- toggle
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.V then
		spinEnabled = not spinEnabled
		print("Spinbot:", spinEnabled and "ON" or "OFF")
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	if spinEnabled then
		-- disable roblox auto-rotate (IMPORTANT)
		hum.AutoRotate = false

		-- spin character
		hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SPIN_SPEED * dt), 0)
	else
		-- restore normal behavior
		hum.AutoRotate = true
	end
end)
