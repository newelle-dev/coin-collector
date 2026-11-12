local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local SIZE = Config.ARENA_SIZE
local HALF = SIZE / 2
local WALL_HEIGHT = 14 -- taller than a jump (about 7 studs)
local WALL_THICKNESS = 2

-- The arena replaces the default grey baseplate.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

local arena = Instance.new("Folder")
arena.Name = "Arena"
arena.Parent = workspace

local function makePart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = arena
end

-- Floor top sits at y = 0, same as the old baseplate.
makePart("Floor", Vector3.new(SIZE, 1, SIZE), Vector3.new(0, -0.5, 0), Color3.fromRGB(110, 160, 90), Enum.Material.Grass)

local wallColor = Color3.fromRGB(150, 130, 110)
local wallY = WALL_HEIGHT / 2
local edge = HALF + WALL_THICKNESS / 2
local wideWall = Vector3.new(SIZE + WALL_THICKNESS * 2, WALL_HEIGHT, WALL_THICKNESS)
local tallWall = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, SIZE)

makePart("WallNorth", wideWall, Vector3.new(0, wallY, -edge), wallColor, Enum.Material.Brick)
makePart("WallSouth", wideWall, Vector3.new(0, wallY, edge), wallColor, Enum.Material.Brick)
makePart("WallEast", tallWall, Vector3.new(edge, wallY, 0), wallColor, Enum.Material.Brick)
makePart("WallWest", tallWall, Vector3.new(-edge, wallY, 0), wallColor, Enum.Material.Brick)
