local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local TREE_COUNT = 12
local ROCK_COUNT = 14
local EDGE = Config.ARENA_SIZE / 2 - 4 -- keep clear of the walls
local KEEP_CLEAR = Config.SPAWN_RADIUS + 2 -- coins spawn inside this radius
local rng = Random.new(7) -- fixed seed: same layout every run

local scenery = Instance.new("Folder")
scenery.Name = "Scenery"
scenery.Parent = workspace

-- A random spot in the arena corners, outside the coin area.
local function cornerSpot(): (number, number)
	while true do
		local x = rng:NextNumber(-EDGE, EDGE)
		local z = rng:NextNumber(-EDGE, EDGE)
		if math.sqrt(x * x + z * z) >= KEEP_CLEAR then
			return x, z
		end
	end
end

local function makeTree(x: number, z: number)
	local model = Instance.new("Model")
	model.Name = "Tree"

	local height = rng:NextNumber(7, 11)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder -- lies along X, so rotate upright
	trunk.Size = Vector3.new(height, 1.6, 1.6)
	trunk.CFrame = CFrame.new(x, height / 2, z) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Color = Color3.fromRGB(110, 75, 45)
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.Parent = model

	local leafColor = Color3.fromRGB(rng:NextInteger(50, 80), rng:NextInteger(130, 170), rng:NextInteger(50, 70))
	for i, size in { 9, 7, 5 } do -- three stacked blobs, big to small
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.one * size
		leaves.Position = Vector3.new(x, height + (i - 1) * 2.5, z)
		leaves.Color = leafColor
		leaves.Material = Enum.Material.Grass
		leaves.Anchored = true
		leaves.CanCollide = false -- walk and camera pass through the foliage
		leaves.Parent = model
	end

	model.Parent = scenery
end

local function makeRock(x: number, z: number)
	local width = rng:NextNumber(2, 5)
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Size = Vector3.new(width, width * rng:NextNumber(0.6, 1), width * rng:NextNumber(0.8, 1.2))
	rock.CFrame = CFrame.new(x, rock.Size.Y / 2 - 0.3, z)
		* CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 2 * math.pi), rng:NextNumber(-0.2, 0.2))
	local gray = rng:NextInteger(100, 140)
	rock.Color = Color3.fromRGB(gray, gray, gray + 5)
	rock.Material = Enum.Material.Slate
	rock.Anchored = true
	rock.Parent = scenery
end

for _ = 1, TREE_COUNT do
	makeTree(cornerSpot())
end
for _ = 1, ROCK_COUNT do
	makeRock(cornerSpot())
end
