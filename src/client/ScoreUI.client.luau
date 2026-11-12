local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ScoreGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(200, 50)
label.Position = UDim2.fromOffset(20, 20)
label.BackgroundTransparency = 0.4
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.new(1, 1, 1)
label.Text = "Coins: 0"
label.Parent = gui

local pickupSound = Instance.new("Sound")
pickupSound.SoundId = Config.PICKUP_SOUND_ID
pickupSound.Parent = gui

-- Floats a "+N" label up from the score and fades it out.
local function showPopup(amount)
	local pop = Instance.new("TextLabel")
	pop.Size = UDim2.fromOffset(120, 40)
	pop.Position = label.Position + UDim2.fromOffset(0, 60)
	pop.BackgroundTransparency = 1
	pop.TextScaled = true
	pop.Font = Enum.Font.GothamBold
	pop.TextColor3 = Color3.fromRGB(255, 220, 0)
	pop.Text = "+" .. amount
	pop.Parent = gui

	local tween = TweenService:Create(pop, TweenInfo.new(0.8), {
		Position = pop.Position - UDim2.fromOffset(0, 40),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		pop:Destroy()
	end)
end

local lastScore = 0
ReplicatedStorage:WaitForChild("ScoreUpdate").OnClientEvent:Connect(function(score)
	label.Text = "Coins: " .. score
	if score > lastScore then
		pickupSound:Play()
		showPopup(score - lastScore)
	end
	lastScore = score
end)
