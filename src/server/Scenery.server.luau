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

local function addPart(parent: Instance, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, collide: boolean)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = collide
	p.Parent = parent
	return p
end

local function jitter(c: Color3, amount: number): Color3
	local k = 1 + rng:NextNumber(-amount, amount)
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

local BARK = Color3.fromRGB(110, 75, 45)

-- Round tree: tapered trunk, 4-6 lumpy foliage blobs in slightly different greens.
local function makeRoundTree(model: Model, x: number, z: number)
	local height = rng:NextNumber(7, 11)
	-- Cylinder lies along X, so rotate upright.
	addPart(model, Enum.PartType.Cylinder, Vector3.new(height, 1.6, 1.6), CFrame.new(x, height / 2, z) * CFrame.Angles(0, 0, math.rad(90)), BARK, Enum.Material.Wood, true)
	addPart(model, Enum.PartType.Cylinder, Vector3.new(1.2, 2.4, 2.4), CFrame.new(x, 0.6, z) * CFrame.Angles(0, 0, math.rad(90)), BARK, Enum.Material.Wood, false) -- root flare

	local base = Color3.fromRGB(rng:NextInteger(50, 80), rng:NextInteger(130, 170), rng:NextInteger(50, 70))
	for i = 1, rng:NextInteger(4, 6) do
		local size = rng:NextNumber(4, 8)
		local pos = Vector3.new(x + rng:NextNumber(-2, 2), height + rng:NextNumber(0, 5), z + rng:NextNumber(-2, 2))
		addPart(model, Enum.PartType.Ball, Vector3.one * size, CFrame.new(pos), jitter(base, 0.12), Enum.Material.Grass, false) -- walk and camera pass through foliage
	end
end

-- Pine: tall thin trunk with flattened tiers shrinking toward the top.
local function makePine(model: Model, x: number, z: number)
	local height = rng:NextNumber(9, 13)
	addPart(model, Enum.PartType.Cylinder, Vector3.new(height, 1.2, 1.2), CFrame.new(x, height / 2, z) * CFrame.Angles(0, 0, math.rad(90)), BARK, Enum.Material.Wood, true)
	local base = Color3.fromRGB(35, rng:NextInteger(95, 120), 55)
	local tiers = 5
	for i = 1, tiers do
		local w = 9 - (i - 1) * 1.6
		addPart(model, Enum.PartType.Ball, Vector3.new(w, 3, w), CFrame.new(x, 3 + (i - 1) * 2.2, z), jitter(base, 0.08), Enum.Material.Grass, false)
	end
end

local function makeTree(x: number, z: number)
	local model = Instance.new("Model")
	model.Name = "Tree"
	if rng:NextNumber() < 0.4 then
		makePine(model, x, z)
	else
		makeRoundTree(model, x, z)
	end
	model.Parent = scenery
end

-- A cluster of 1-3 rocks; some wear a moss cap.
local function makeRock(x: number, z: number)
	local model = Instance.new("Model")
	model.Name = "Rock"
	for i = 1, rng:NextInteger(1, 3) do
		local width = if i == 1 then rng:NextNumber(2.5, 5) else rng:NextNumber(1, 2.2)
		local size = Vector3.new(width, width * rng:NextNumber(0.6, 1), width * rng:NextNumber(0.8, 1.2))
		local ox = if i == 1 then 0 else rng:NextNumber(-3, 3)
		local oz = if i == 1 then 0 else rng:NextNumber(-3, 3)
		local cf = CFrame.new(x + ox, size.Y / 2 - 0.3, z + oz)
			* CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 2 * math.pi), rng:NextNumber(-0.2, 0.2))
		local gray = rng:NextInteger(100, 140)
		addPart(model, Enum.PartType.Block, size, cf, Color3.fromRGB(gray, gray, gray + 5), Enum.Material.Slate, true)
		if rng:NextNumber() < 0.4 then -- moss on top
			addPart(model, Enum.PartType.Block, Vector3.new(size.X * 0.8, 0.3, size.Z * 0.8), cf * CFrame.new(0, size.Y / 2, 0), Color3.fromRGB(70, 120, 50), Enum.Material.Grass, false)
		end
	end
	model.Parent = scenery
end

for _ = 1, TREE_COUNT do
	makeTree(cornerSpot())
end
for _ = 1, ROCK_COUNT do
	makeRock(cornerSpot())
end
