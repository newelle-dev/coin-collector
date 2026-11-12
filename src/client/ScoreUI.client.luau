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

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.fromOffset(160, 40)
timerLabel.Position = UDim2.new(0.5, 0, 0, 20)
timerLabel.AnchorPoint = Vector2.new(0.5, 0)
timerLabel.BackgroundTransparency = 0.4
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.Text = "--"
timerLabel.Parent = gui

-- Counts down to the round end the server publishes on the workspace.
task.spawn(function()
	while gui.Parent do
		local remaining = math.max(0, (workspace:GetAttribute("RoundEndsAt") or 0) - os.time())
		timerLabel.Text = string.format("%d:%02d", remaining // 60, remaining % 60)
		task.wait(0.25)
	end
end)

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

local lastScore = nil -- nil until the first update, so loading saved coins doesn't pop
local gotScore = false
ReplicatedStorage:WaitForChild("ScoreUpdate").OnClientEvent:Connect(function(score)
	gotScore = true
	label.Text = "Coins: " .. score
	if lastScore and score > lastScore then
		pickupSound:Play()
		showPopup(score - lastScore)
	end
	lastScore = score
end)

-- Ask for the saved score until it arrives, so a join-time update can't be missed.
local requestScore = ReplicatedStorage:WaitForChild("RequestScore")
task.spawn(function()
	while not gotScore do
		requestScore:FireServer()
		task.wait(1)
	end
end)
