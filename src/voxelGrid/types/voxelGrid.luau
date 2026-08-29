--!strict
--!optimize 2
--!native

export type VoxelGrid<T> = {
	insert: (self: VoxelGrid<T>, id: T, position: Vector3) -> (),
	remove: (self: VoxelGrid<T>, id: T) -> (),
	update: (self: VoxelGrid<T>, id: T, position: Vector3?) -> (),

	query: (self: VoxelGrid<T>, position: Vector3, radius: number) -> { T },
	querySet: (self: VoxelGrid<T>, position: Vector3, radius: number) -> { [T]: true },

	clear: (self: VoxelGrid<T>) -> (),
}

export type VoxelGridImpl<T> = VoxelGrid<T> & {
	_cellSize: number,
	_cells: { [number]: { [T]: true } },
	_entityCell: { [T]: number },
}

return {}
