local TS = game:GetService("TweenService")

-- { Variables } --
local RunKey = Enum.KeyCode.LeftShift

local WalkSpeed = 16
local RunSpeed = 25
local dashCDduration = 1
local dashDuration = 0.3
local dashSpeed = 50
local dashCD = false


--Camera configuration
local WalkFov = 70
local RunFov = 80
local DashFov = 95
local TweenFovDuration = 0.2

local Configuration = {}

Configuration.RunKey = RunKey

Configuration.WalkSpeed = WalkSpeed
Configuration.RunSpeed = RunSpeed

Configuration.dashCDduration = dashCDduration
Configuration.dashDuration = dashDuration
--Configuration.dashSpeed = dashSpeed
Configuration.dashCD = dashCD

function Configuration.IsWalking(Humanoid)
	if Humanoid.MoveDirection.Magnitude >= 0.1 then
		return true
	else
		return false
	end
end

function Configuration.runTween(Camera)
	TS:Create(
		Camera, 
		TweenInfo.new(TweenFovDuration, 
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut), 
		{FieldOfView = RunFov}):Play()
end

function Configuration.walkTween(Camera)
	TS:Create(
		Camera, 
		TweenInfo.new(TweenFovDuration, 
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut), 
		{FieldOfView = WalkFov}):Play()
end

function Configuration.dashTween(Camera)
	TS:Create(
		Camera, 
		TweenInfo.new(TweenFovDuration, 
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut), 
		{FieldOfView = DashFov}):Play()
end

function Configuration.IsDashAllowed()

	if Configuration.dashCD then return end
	return true
end

function Configuration.HandleCooldown()
	task.wait(dashCDduration)
	Configuration.dashCD = false
end

function Configuration.GetDashVelocity(root, Camera)

	local vectorMask = Vector3.new(1, 0, 1)
	local direction = root.AssemblyLinearVelocity * vectorMask

	if direction.Magnitude <= 0.1 then
		direction = Camera.CFrame.LookVector * vectorMask
	end

	direction = direction.Unit
	local planeDirection = Vector2.new(direction.X, direction.Z)
	local dashVelocity = planeDirection * dashSpeed
	return dashVelocity
end

return Configuration
