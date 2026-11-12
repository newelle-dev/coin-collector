local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local SPIN_SPEED = 2 -- radians per second
local BOB_HEIGHT = 0.5 -- studs
local BOB_SPEED = 2

-- Visual only: the server's coin position never changes, so pickups still work.
local basePositions: { [BasePart]: Vector3 } = {}
local coinsFolder = workspace:WaitForChild("Coins")

-- Burst of sparks where a coin was collected or cleared.
local function sparkle(position: Vector3, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Lifetime = NumberRange.new(0.4, 0.7)
	emitter.Speed = NumberRange.new(6, 10)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.6)
	emitter.LightEmission = 1
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(20)

	Debris:AddItem(anchor, 1)
end

local function track(coin: Instance)
	if coin:IsA("BasePart") then
		basePositions[coin] = coin.Position

		-- Soft glow in the coin's own color.
		local light = Instance.new("PointLight")
		light.Color = coin.Color
		light.Range = 8
		light.Brightness = 1
		light.Parent = coin
	end
end

for _, coin in coinsFolder:GetChildren() do
	track(coin)
end
coinsFolder.ChildAdded:Connect(track)
coinsFolder.ChildRemoved:Connect(function(coin)
	if coin:IsA("BasePart") then
		sparkle(coin.Position, coin.Color)
	end
	basePositions[coin :: BasePart] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local bob = Vector3.new(0, math.sin(t * BOB_SPEED) * BOB_HEIGHT, 0)
	for coin, base in basePositions do
		coin.CFrame = CFrame.new(base + bob) * CFrame.Angles(0, t * SPIN_SPEED, 0)
	end
end)
