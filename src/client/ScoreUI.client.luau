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
label.Text = "0"
label.Parent = gui

-- Coin icon to the left of the number, and a bounce when the score rises.
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 44)
padding.Parent = label

local icon = Instance.new("Frame")
icon.Size = UDim2.fromOffset(30, 30)
icon.Position = UDim2.fromOffset(8, 10)
icon.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
icon.Parent = label
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = icon
local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(180, 120, 0)
iconStroke.Thickness = 3
iconStroke.Parent = icon

local labelScale = Instance.new("UIScale")
labelScale.Parent = label

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
	label.Text = tostring(score)
	if lastScore and score > lastScore then
		pickupSound:Play()
		showPopup(score - lastScore)
		labelScale.Scale = 1.25
		TweenService:Create(labelScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
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

-- Shop button: the server decides whether the purchase goes through.
local shopBuy = ReplicatedStorage:WaitForChild("ShopBuy")
local boostButton = Instance.new("TextButton")
boostButton.Size = UDim2.fromOffset(240, 50)
boostButton.Position = UDim2.new(0, 20, 1, -70)
boostButton.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
boostButton.TextScaled = true
boostButton.Font = Enum.Font.GothamBold
boostButton.TextColor3 = Color3.new(1, 1, 1)
boostButton.Text = `Speed Boost: {Config.BOOST_PRICE} coins`
boostButton.Parent = gui
boostButton.Activated:Connect(function()
	shopBuy:FireServer()
end)

-- "New round!" banner slides in each time the server starts a round.
local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromOffset(320, 60)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, -80)
banner.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
banner.TextScaled = true
banner.Font = Enum.Font.GothamBold
banner.TextColor3 = Color3.new(1, 1, 1)
banner.Text = "New round!"
banner.Parent = gui

workspace:GetAttributeChangedSignal("RoundEndsAt"):Connect(function()
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, 0, 0, 80),
	}):Play()
	task.delay(1.8, function()
		TweenService:Create(banner, TweenInfo.new(0.4), {
			Position = UDim2.new(0.5, 0, 0, -80),
		}):Play()
	end)
end)
