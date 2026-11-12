local RunService = game:GetService("RunService")

local SPIN_SPEED = 2 -- radians per second
local BOB_HEIGHT = 0.5 -- studs
local BOB_SPEED = 2

-- Visual only: the server's coin position never changes, so pickups still work.
local basePositions: { [BasePart]: Vector3 } = {}
local coinsFolder = workspace:WaitForChild("Coins")

local function track(coin: Instance)
	if coin:IsA("BasePart") then
		basePositions[coin] = coin.Position
	end
end

for _, coin in coinsFolder:GetChildren() do
	track(coin)
end
coinsFolder.ChildAdded:Connect(track)
coinsFolder.ChildRemoved:Connect(function(coin)
	basePositions[coin :: BasePart] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local bob = Vector3.new(0, math.sin(t * BOB_SPEED) * BOB_HEIGHT, 0)
	for coin, base in basePositions do
		coin.CFrame = CFrame.new(base + bob) * CFrame.Angles(0, t * SPIN_SPEED, 0)
	end
end)
