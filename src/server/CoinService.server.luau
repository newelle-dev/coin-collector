local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

-- Server tells each client its score through this event.
local scoreUpdate = Instance.new("RemoteEvent")
scoreUpdate.Name = "ScoreUpdate"
scoreUpdate.Parent = ReplicatedStorage

local coinsFolder = Instance.new("Folder")
coinsFolder.Name = "Coins"
coinsFolder.Parent = workspace

local spawnCoins

local function spawnCoin(position)
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(1, 4, 4)
	coin.Anchored = true
	coin.CanCollide = false
	coin.Color = Color3.fromRGB(255, 200, 0)
	coin.Material = Enum.Material.Neon
	coin.CFrame = CFrame.new(position) -- cylinder axis is X, so it stands on edge
	coin.Parent = coinsFolder

	coin.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		-- Touched can fire more than once; only the first pickup counts.
		if not player or not coin.Parent then
			return
		end
		coin:Destroy()

		local coins = player.leaderstats.Coins
		coins.Value += Config.COIN_VALUE
		scoreUpdate:FireClient(player, coins.Value)

		if #coinsFolder:GetChildren() == 0 then
			spawnCoins()
		end
	end)
end

spawnCoins = function()
	for _ = 1, Config.COIN_COUNT do
		local angle = math.random() * 2 * math.pi
		local distance = math.random() * Config.SPAWN_RADIUS
		spawnCoin(Vector3.new(math.cos(angle) * distance, 3, math.sin(angle) * distance))
	end
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
end)

spawnCoins()
