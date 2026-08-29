--!strict
--!optimize 2
--!native

local VoxelGrid = require(script.voxelGrid)

export type VoxelGrid<T> = VoxelGrid.VoxelGrid<T>

return VoxelGrid
