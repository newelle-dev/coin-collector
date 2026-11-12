local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage.Shared.Config)

-- Daytime sky with light haze.
Lighting.ClockTime = 14
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(90, 90, 100)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Haze = 1.5
atmosphere.Color = Color3.fromRGB(199, 225, 255)
atmosphere.Parent = Lighting

-- Grassy ground instead of the default grey baseplate.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate.Color = Color3.fromRGB(110, 160, 90)
	baseplate.Material = Enum.Material.Grass
end

-- Looping background music, local to each player.
local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.SoundId = Config.MUSIC_ID
music.Looped = true
music.Volume = Config.MUSIC_VOLUME
music.Parent = SoundService
music:Play()

-- Rounded corners on the HUD, including buttons added later.
local function roundCorners(obj)
	if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and not obj:FindFirstChildOfClass("UICorner") then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = obj
	end
end

local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScoreGui")
for _, obj in gui:GetDescendants() do
	roundCorners(obj)
end
gui.DescendantAdded:Connect(roundCorners)
