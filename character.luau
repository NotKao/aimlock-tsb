--// TSB STYLE CHARACTER LOCK
--// LocalScript -> StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local HumanoidStateType = Enum.HumanoidStateType

local Enabled = false
local Target = nil

-- SETTINGS
local TOGGLE_KEY = Enum.KeyCode.E
local MAX_DISTANCE = 500
local FOV = 320

--================================--

local function IsAlive(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")

	return hum and root and hum.Health > 0
end

local function GetClosestTarget()
	local bestTarget = nil
	local bestMagnitude = math.huge

	local screenCenter = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	-- PLAYERS
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character and IsAlive(plr.Character) then

			local root =
				plr.Character:FindFirstChild("HumanoidRootPart")

			if root then

				local pos, visible =
					Camera:WorldToViewportPoint(root.Position)

				if visible then

					local magnitude =
						(Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude

					local distance =
						(root.Position - Camera.CFrame.Position).Magnitude

					if magnitude < bestMagnitude
						and magnitude <= FOV
						and distance <= MAX_DISTANCE then

						bestMagnitude = magnitude
						bestTarget = plr.Character
					end
				end
			end
		end
	end

	-- DUMMIES / NPCS
	for _, obj in pairs(workspace:GetDescendants()) do

		if obj:IsA("Model")
			and obj ~= Player.Character
			and not Players:GetPlayerFromCharacter(obj)
			and IsAlive(obj) then

			local root =
				obj:FindFirstChild("HumanoidRootPart")

			if root then

				local pos, visible =
					Camera:WorldToViewportPoint(root.Position)

				if visible then

					local magnitude =
						(Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude

					local distance =
						(root.Position - Camera.CFrame.Position).Magnitude

					if magnitude < bestMagnitude
						and magnitude <= FOV
						and distance <= MAX_DISTANCE then

						bestMagnitude = magnitude
						bestTarget = obj
					end
				end
			end
		end
	end

	return bestTarget
end

-- TOGGLE
UIS.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end

	if input.KeyCode == TOGGLE_KEY then

		-- DISABLE
		if Enabled then
			Enabled = false
			Target = nil

			local char = Player.Character

			if char then
				local hum =
					char:FindFirstChildOfClass("Humanoid")

				if hum then
					hum.AutoRotate = true
				end
			end

			print("Character Lock Disabled")

		else

			-- ENABLE
			local newTarget = GetClosestTarget()

			if newTarget then
				Enabled = true
				Target = newTarget

				local char = Player.Character

				if char then
					local hum =
						char:FindFirstChildOfClass("Humanoid")

					if hum then
						hum.AutoRotate = false
					end
				end

				print("Locked:", Target.Name)
			end
		end
	end
end)

-- CHARACTER SNAP LOCK
RunService.RenderStepped:Connect(function()

	if not Enabled then
		return
	end

	if not Target or not IsAlive(Target) then
		Enabled = false
		Target = nil
		return
	end

	local myChar = Player.Character

	if not myChar then
		return
	end

	local hum =
		myChar:FindFirstChildOfClass("Humanoid")

	local myRoot =
		myChar:FindFirstChild("HumanoidRootPart")

	local torso =
		Target:FindFirstChild("UpperTorso")
		or Target:FindFirstChild("Torso")
		or Target:FindFirstChild("HumanoidRootPart")

	if hum then
		hum.AutoRotate = false

		local state = hum:GetState()

		-- DON'T ROTATE DURING RAGDOLL / PHYSICS
		if state == HumanoidStateType.Physics
		or state == HumanoidStateType.FallingDown
		or state == HumanoidStateType.Ragdoll then
			return
		end
	end

	if myRoot and torso then

		local currentPos = myRoot.Position

		-- ONLY ROTATE HORIZONTALLY
		local lookPosition = Vector3.new(
			torso.Position.X,
			currentPos.Y,
			torso.Position.Z
		)

		-- VERY STRONG ROTATION
		local targetCF =
			CFrame.new(currentPos, lookPosition)

		myRoot.CFrame = myRoot.CFrame:Lerp(
			targetCF,
			0.9
		)

		-- STOP RANDOM SPINNING
		myRoot.AssemblyAngularVelocity = Vector3.zero
	end
end)
