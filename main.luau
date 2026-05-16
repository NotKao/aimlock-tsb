--// TSB STYLE CAMERA LOCK
--// LocalScript -> StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Enabled = false
local Target = nil

-- SETTINGS
local TOGGLE_KEY = Enum.KeyCode.E
local MAX_DISTANCE = 500

-- Big target area
local FOV = 320

-- SUPER STRONG CAMERA LOCK
local CAMERA_ASSIST = 0.995

-- Normal Roblox zoom
Player.CameraMinZoomDistance = 0.5
Player.CameraMaxZoomDistance = 128

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

			local root = plr.Character:FindFirstChild("HumanoidRootPart")

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
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model")
			and obj ~= Player.Character
			and not Players:GetPlayerFromCharacter(obj)
			and IsAlive(obj) then

			local root = obj:FindFirstChild("HumanoidRootPart")

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

-- TOGGLE CAMERA LOCK
UIS.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end

	if input.KeyCode == TOGGLE_KEY then

		-- DISABLE
		if Enabled then
			Enabled = false
			Target = nil
			print("Camera Lock Disabled")

		else

			-- ENABLE ON WHO YOU LOOK AT
			local newTarget = GetClosestTarget()

			if newTarget then
				Enabled = true
				Target = newTarget
				print("Locked:", Target.Name)
			end
		end
	end
end)

-- CAMERA LOCK ONLY
RunService.RenderStepped:Connect(function()

	if not Enabled then
		return
	end

	if not Target or not IsAlive(Target) then
		Enabled = false
		Target = nil
		return
	end

	local torso =
		Target:FindFirstChild("UpperTorso")
		or Target:FindFirstChild("Torso")
		or Target:FindFirstChild("HumanoidRootPart")

	if torso then

		local myChar = Player.Character
		local head = myChar and myChar:FindFirstChild("Head")

		if head then

			-- REAL TSB / SHIFTLOCK STYLE CAMERA OFFSET
			local shoulderOffset =
				Vector3.new(2.2, 1.2, 0)

			-- keep current zoom
			local zoomDistance =
				(Camera.CFrame.Position - Camera.Focus.Position).Magnitude

			-- right shoulder camera
			local basePos =
				head.Position
				+ (Camera.CFrame.RightVector * shoulderOffset.X)
				+ Vector3.new(0, shoulderOffset.Y, 0)

			local camDirection =
				(Camera.CFrame.Position - Camera.Focus.Position).Unit

			local camPos =
				basePos + camDirection * zoomDistance

			-- smooth target look
			local targetCF =
				CFrame.new(
					camPos,
					torso.Position + Vector3.new(0, 1.5, 0)
				)

			Camera.CFrame = Camera.CFrame:Lerp(
				targetCF,
				CAMERA_ASSIST
			)
		end
	end
end)
print("executed")
