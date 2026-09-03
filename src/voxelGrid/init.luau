--!strict
--!optimize 2
--!native

local VoxelGridData = require(script.data.shared.voxelGrid)
local Types = require(script.types)

export type VoxelGrid<T> = Types.VoxelGrid<T>

type VoxelGridModule = {
	new: <T>(cellSize: number) -> Types.VoxelGrid<T>,
}

return VoxelGridData :: VoxelGridModule
