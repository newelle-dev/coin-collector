local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local CoinStore = require(script.Parent.CoinStore)

-- Server tells each client its score through this event.
local scoreUpdate = Instance.new("RemoteEvent")
scoreUpdate.Name = "ScoreUpdate"
scoreUpdate.Parent = ReplicatedStorage

-- Client asks for its score once it is ready to show it.
local scoreRequest = Instance.new("RemoteEvent")
scoreRequest.Name = "RequestScore"
scoreRequest.Parent = ReplicatedStorage

local coinsFolder = Instance.new("Folder")
coinsFolder.Name = "Coins"
coinsFolder.Parent = workspace

local spawnCoins

local function spawnCoin(position, value, color)
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(1, 4, 4)
	coin.Anchored = true
	coin.CanCollide = false
	coin.Color = color
	coin.Material = Enum.Material.Neon
	coin.CFrame = CFrame.new(position) -- cylinder axis is X, so it stands on edge
	coin:SetAttribute("Value", value)

	-- Embossed symbol on both flat faces (cylinder axis is X: Right/Left).
	for _, face in { Enum.NormalId.Right, Enum.NormalId.Left } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.Parent = coin
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = if value == Config.GOLD_VALUE then "★" else "$"
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.fromRGB(150, 90, 0)
		label.Parent = gui
	end

	coin.Parent = coinsFolder

	coin.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		-- Touched can fire more than once; only the first pickup counts.
		if not player or not coin.Parent then
			return
		end
		local amount = coin:GetAttribute("Value")
		coin:Destroy()

		local coins = player.leaderstats.Coins
		coins.Value += amount
		scoreUpdate:FireClient(player, coins.Value)

		if #coinsFolder:GetChildren() == 0 then
			spawnCoins()
		end
	end)
end

spawnCoins = function()
	coinsFolder:ClearAllChildren()
	for _ = 1, Config.COIN_COUNT do
		local angle = math.random() * 2 * math.pi
		local distance = math.random() * Config.SPAWN_RADIUS
		local position = Vector3.new(math.cos(angle) * distance, 3, math.sin(angle) * distance)
		if math.random() < Config.GOLD_CHANCE then
			spawnCoin(position, Config.GOLD_VALUE, Color3.fromRGB(255, 120, 0))
		else
			spawnCoin(position, Config.COIN_VALUE, Color3.fromRGB(255, 200, 0))
		end
	end
end

-- Each round restarts the coins and tells clients when it ends.
local function startRound()
	spawnCoins()
	workspace:SetAttribute("RoundEndsAt", os.time() + Config.ROUND_SECONDS)
end

task.spawn(function()
	while true do
		startRound()
		task.wait(Config.ROUND_SECONDS)
	end
end)

scoreRequest.OnServerEvent:Connect(function(player)
	if not player:GetAttribute("CoinsLoaded") then
		return
	end
	local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
	if coins then
		scoreUpdate:FireClient(player, coins.Value)
	end
end)

-- Shop: the server checks the price and cooldown, so the client can't cheat.
local shopBuy = Instance.new("RemoteEvent")
shopBuy.Name = "ShopBuy"
shopBuy.Parent = ReplicatedStorage

shopBuy.OnServerEvent:Connect(function(player)
	if player:GetAttribute("Boosted") or not player:GetAttribute("CoinsLoaded") then
		return
	end
	local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not coins or not humanoid or coins.Value < Config.BOOST_PRICE then
		return
	end

	coins.Value -= Config.BOOST_PRICE
	scoreUpdate:FireClient(player, coins.Value)

	local normalSpeed = humanoid.WalkSpeed
	player:SetAttribute("Boosted", true)
	humanoid.WalkSpeed = Config.BOOST_SPEED

	-- Blue trail behind the player while boosted, visible to everyone.
	local boostParts = {}
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local top = Instance.new("Attachment")
		top.Position = Vector3.new(0, 1, 0)
		top.Parent = root
		local bottom = Instance.new("Attachment")
		bottom.Position = Vector3.new(0, -1, 0)
		bottom.Parent = root
		local trail = Instance.new("Trail")
		trail.Attachment0 = top
		trail.Attachment1 = bottom
		trail.Lifetime = 0.4
		trail.Color = ColorSequence.new(Color3.fromRGB(80, 170, 255))
		trail.Transparency = NumberSequence.new(0, 1)
		trail.LightEmission = 1
		trail.Parent = root
		boostParts = { top, bottom, trail }
	end

	task.delay(Config.BOOST_SECONDS, function()
		for _, part in boostParts do
			part:Destroy()
		end
		player:SetAttribute("Boosted", nil)
		local current = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if current then
			current.WalkSpeed = normalSpeed
		end
	end)
end)

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local saved = CoinStore.load(player.UserId)
	if not saved then
		player:Kick("Couldn't load your coins. Please rejoin.")
		return
	end
	-- Player may have left while we were loading.
	if not player.Parent then
		CoinStore.release(player.UserId)
		return
	end
	coins.Value = saved
	player:SetAttribute("CoinsLoaded", true)
end)

Players.PlayerRemoving:Connect(function(player)
	local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
	if coins then
		CoinStore.save(player.UserId, coins.Value)
	end
	CoinStore.release(player.UserId)
end)

-- Save everyone when the server shuts down.
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
		if coins then
			CoinStore.save(player.UserId, coins.Value)
		end
	end
end)
