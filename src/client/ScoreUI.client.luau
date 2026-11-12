local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

ReplicatedStorage:WaitForChild("ScoreUpdate").OnClientEvent:Connect(function(score)
	label.Text = "Coins: " .. score
end)
