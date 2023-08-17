-- { Services & References } --
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local RS = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local Configuration = require(script.Parent:WaitForChild("Configuration"))

-- { Variables } --
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local root = Character:WaitForChild("HumanoidRootPart")
local x = 32

local Camera = game.Workspace.CurrentCamera

--dash  motion generator handler
local attachment = Instance.new("Attachment")
attachment.Name = "DashAttachment0"
attachment.Parent = root

local linearVelocity = Instance.new("LinearVelocity")
linearVelocity.Attachment0 = attachment
linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
linearVelocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
linearVelocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)
linearVelocity.MaxForce = math.huge
linearVelocity.Enabled = false
linearVelocity.Parent = root

--animation handler
local runAni = script.Animations:WaitForChild("Run")
local runPlay = Humanoid:LoadAnimation(runAni)
runPlay.Priority = Enum.AnimationPriority.Action
local shiftkeyP = false
local dashAni = script.Animations:WaitForChild("DashAnimation")
local dashPlay = Humanoid:LoadAnimation(dashAni)
dashPlay.Priority = Enum.AnimationPriority.Action3
dashPlay:AdjustSpeed(dashPlay.Length / Configuration.dashDuration)
local dashSound = script.Animations:WaitForChild("DashSound")
local flipJumpAni = script.Animations:WaitForChild("FlipJump")
local flipJumpPlay = Humanoid:LoadAnimation(flipJumpAni)
flipJumpPlay.Priority = Enum.AnimationPriority.Action2

local doubleJumpCount = 0

local remoteEvent = RS.VFX.DashEffect1:WaitForChild("dashVFXEvent")
local jumpEvent = RS.VFX.JumpEffect:WaitForChild("jumpVFXEvent")

local function Start(Input, GPE)
	if GPE then
		return
	end
	if Input.KeyCode ~= Configuration.RunKey then
		return
	end

	shiftkeyP = true
	if Configuration.IsDashAllowed() then
		Configuration.dashCD = true
		task.spawn(Configuration.HandleCooldown)

		local dashVelocity = Configuration.GetDashVelocity(root, Camera)

		remoteEvent:FireServer(root, Vector3.new(dashVelocity.X, 0, dashVelocity.Y) * 1000, Configuration.dashDuration)
		Humanoid.AutoRotate = false
		root.CFrame = CFrame.new(root.Position, Vector3.new(dashVelocity.X, 0, dashVelocity.Y) * 1000)

		linearVelocity.PlaneVelocity = dashVelocity
		linearVelocity.Enabled = true

		dashPlay:Play()
		dashPlay:AdjustSpeed(dashPlay.Length / Configuration.dashDuration)
		dashSound:Play()
		Configuration.dashTween(Camera)

		task.wait(Configuration.dashDuration)
		linearVelocity.Enabled = false
		Humanoid.AutoRotate = true
	end

	Configuration.runTween(Camera)

	Humanoid.WalkSpeed = Configuration.RunSpeed
end

local function End(Input, GPE)
	if GPE then
		return
	end
	if Input.KeyCode ~= Configuration.RunKey then
		return
	end

	runPlay:Stop()
	shiftkeyP = false
	Humanoid.WalkSpeed = Configuration.WalkSpeed

	Configuration.walkTween(Camera)
end

local function UpdateNotMovingState()
	if not Configuration.IsWalking(Humanoid) and runPlay.IsPlaying then
		runPlay:Stop() -- Trigger the event when not moving
	elseif shiftkeyP and Configuration.IsWalking(Humanoid) and not runPlay.IsPlaying then
		runPlay:Play()
	end
end

local function airJump()
	if doubleJumpCount < 1 then
		print("AirJump")
		if Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			jumpEvent:FireServer(root)
			flipJumpPlay:Play()
			flipJumpPlay:AdjustSpeed(flipJumpPlay.Length / 0.3)
			task.spawn(function()
				doubleJumpCount = 1
			end)
		end
	end
end

Humanoid.StateChanged:Connect(function(_oldState, newState)
	if newState == Enum.HumanoidStateType.Freefall then
		wait(0.2)
		CAS:BindAction("airJump", airJump, false, Enum.KeyCode.Space)
	end
	if newState == Enum.HumanoidStateType.Landed then
		CAS:UnbindAction("airJump")
		doubleJumpCount = 0
	end
end)

-- { Events } --
UIS.InputBegan:Connect(Start)
UIS.InputEnded:Connect(End)
runService.Heartbeat:Connect(UpdateNotMovingState)
