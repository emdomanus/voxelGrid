--!strict
--!optimize 2
--!native

local bit32 = bit32
local VoxelGridTypes = require(script.Parent.Parent.types.voxelGrid)

type VoxelGrid<T> = VoxelGridTypes.VoxelGrid<T>
type VoxelGridImpl<T> = VoxelGridTypes.VoxelGridImpl<T>

type VoxelGridModule = {
	new: <T>(cellSize: number) -> VoxelGrid<T>,
}

local VoxelGrid = {}
VoxelGrid.__index = VoxelGrid

-- Packed integer key: 10 bits per axis, 30 bits total.
local AXIS_BITS = 10
local AXIS_MASK = bit32.lshift(1, AXIS_BITS) - 1
local Y_SHIFT = AXIS_BITS
local X_SHIFT = AXIS_BITS * 2

local function packKey(cx: number, cy: number, cz: number): number
	cx = bit32.band(cx, AXIS_MASK)
	cy = bit32.band(cy, AXIS_MASK)
	cz = bit32.band(cz, AXIS_MASK)

	return bit32.bor(bit32.lshift(cx, X_SHIFT), bit32.lshift(cy, Y_SHIFT), cz)
end

local function toCell(position: Vector3, cellSize: number): (number, number, number)
	return math.floor(position.X / cellSize),
		math.floor(position.Y / cellSize),
		math.floor(position.Z / cellSize)
end

local function toPackedKey(position: Vector3, cellSize: number): number
	local cx, cy, cz = toCell(position, cellSize)
	return packKey(cx, cy, cz)
end

function VoxelGrid.new<T>(cellSize: number): VoxelGrid<T>
	assert(cellSize > 0, "VoxelGrid: cellSize must be > 0")
	return (
		setmetatable({
			_cellSize = cellSize,
			_cells = {},
			_entityCell = {},
		}, VoxelGrid) :: any
	) :: VoxelGrid<T>
end

function VoxelGrid.insert<T>(self: VoxelGridImpl<T>, id: T, position: Vector3)
	assert(self._entityCell[id] == nil, "VoxelGrid: entity already inserted, call update instead")

	local key = toPackedKey(position, self._cellSize)
	local cell = self._cells[key]

	if not cell then
		cell = {}
		self._cells[key] = cell
	end

	cell[id] = true
	self._entityCell[id] = key
end

function VoxelGrid.remove<T>(self: VoxelGridImpl<T>, id: T)
	local key = self._entityCell[id]
	if not key then
		return
	end

	local cell = self._cells[key]
	if cell then
		cell[id] = nil
		if next(cell) == nil then
			self._cells[key] = nil
		end
	end

	self._entityCell[id] = nil
end

function VoxelGrid.update<T>(self: VoxelGridImpl<T>, id: T, position: Vector3)
	local newKey = toPackedKey(position, self._cellSize)
	local oldKey = self._entityCell[id]

	if oldKey == newKey then
		return
	end

	if oldKey then
		local oldCell = self._cells[oldKey]
		if oldCell then
			oldCell[id] = nil
			if next(oldCell) == nil then
				self._cells[oldKey] = nil
			end
		end
	end

	local newCell = self._cells[newKey]
	if not newCell then
		newCell = {}
		self._cells[newKey] = newCell
	end

	newCell[id] = true
	self._entityCell[id] = newKey
end

function VoxelGrid.query<T>(self: VoxelGridImpl<T>, position: Vector3, radius: number): { T }
	local cellSize = self._cellSize
	local span = math.ceil(radius / cellSize)
	local cx, cy, cz = toCell(position, cellSize)

	local result: { T } = {}
	local count = 0

	for dx = -span, span do
		for dy = -span, span do
			for dz = -span, span do
				local key = packKey(cx + dx, cy + dy, cz + dz)
				local cell = self._cells[key]
				if cell then
					for id in cell do
						count += 1
						result[count] = id
					end
				end
			end
		end
	end

	return result
end

function VoxelGrid.querySet<T>(
	self: VoxelGridImpl<T>,
	position: Vector3,
	radius: number
): { [T]: true }
	local cellSize = self._cellSize
	local span = math.ceil(radius / cellSize)
	local cx, cy, cz = toCell(position, cellSize)

	local result: { [T]: true } = {}

	for dx = -span, span do
		for dy = -span, span do
			for dz = -span, span do
				local key = packKey(cx + dx, cy + dy, cz + dz)
				local cell = self._cells[key]
				if cell then
					for id in cell do
						result[id] = true
					end
				end
			end
		end
	end

	return result
end

function VoxelGrid.clear<T>(self: VoxelGridImpl<T>)
	self._cells = {}
	self._entityCell = {}
end

return (VoxelGrid :: any) :: VoxelGridModule
