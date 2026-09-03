--!strict

local requireAny = require :: any
local LuneRequireTransform = requireAny("./lib/luneRequireTransform")
local Roblox = requireAny("@lune/roblox")
local Vector3 = Roblox.Vector3

local packageHandle = LuneRequireTransform.write({
	packageRoot = "src",
	tempDir = ".voxel-grid-lune-runtime",
})
local VoxelGrid = packageHandle.requireModule("init.luau") :: any
packageHandle.cleanup()

type TestCase = {
	name: string,
	run: () -> (),
}

local tests: { TestCase } = {}

local function test(name: string, run: () -> ()): ()
	tests[#tests + 1] = {
		name = name,
		run = run,
	}
end

local function fail(message: string): never
	error(message, 2)
end

local function assertEqual<T>(actual: T, expected: T, message: string?): ()
	if actual ~= expected then
		fail(message or ("expected " .. tostring(expected) .. ", got " .. tostring(actual)))
	end
end

local function assertTrue(actual: boolean, message: string?): ()
	if not actual then
		fail(message or "expected true")
	end
end

local function assertSetEqual(
	actual: { [any]: true },
	expected: { [any]: true },
	message: string
): ()
	for value in expected do
		if actual[value] ~= true then
			fail(message .. ": missing " .. tostring(value))
		end
	end
	for value in actual do
		if expected[value] ~= true then
			fail(message .. ": unexpected " .. tostring(value))
		end
	end
end

local function listToSet(values: { any }): { [any]: true }
	local result: { [any]: true } = {}
	for _, value in values do
		result[value] = true
	end
	return result
end

test("root initializer resolves the implementation through the source hierarchy", function(): ()
	assertEqual(type(VoxelGrid.new), "function")
end)

test("constructor rejects non-positive cell sizes", function(): ()
	for _, cellSize in { 0, -1 } do
		local ok = pcall(function()
			VoxelGrid.new(cellSize)
		end)
		assertEqual(ok, false)
	end
end)

test("insert and zero-radius queries address the containing cell", function(): ()
	local grid = VoxelGrid.new(10)
	grid:insert("origin", Vector3.new(1, 2, 3))
	grid:insert("negative", Vector3.new(-1, 2, 3))

	assertSetEqual(
		listToSet(grid:query(Vector3.new(1, 2, 3), 0)),
		{ origin = true },
		"origin query"
	)
	assertSetEqual(grid:querySet(Vector3.new(-1, 2, 3), 0), { negative = true }, "negative query")
end)

test("radius queries are voxel broadphase queries", function(): ()
	local grid = VoxelGrid.new(10)
	grid:insert("negative", Vector3.new(-5, 0, 0))
	grid:insert("center", Vector3.new(1, 0, 0))
	grid:insert("adjacent", Vector3.new(15, 0, 0))
	grid:insert("far", Vector3.new(35, 0, 0))

	assertSetEqual(
		grid:querySet(Vector3.new(1, 0, 0), 1),
		{ negative = true, center = true, adjacent = true },
		"one-stud broadphase"
	)
end)

test("update moves an existing id and inserts an unseen id", function(): ()
	local grid = VoxelGrid.new(10)
	grid:insert("moving", Vector3.new(1, 0, 0))
	grid:update("moving", Vector3.new(25, 0, 0))
	grid:update("new", Vector3.new(-25, 0, 0))

	assertSetEqual(grid:querySet(Vector3.new(1, 0, 0), 0), {}, "old cell")
	assertSetEqual(grid:querySet(Vector3.new(25, 0, 0), 0), { moving = true }, "moved cell")
	assertSetEqual(grid:querySet(Vector3.new(-25, 0, 0), 0), { new = true }, "upsert cell")
end)

test("remove is idempotent and clear retires every id", function(): ()
	local grid = VoxelGrid.new(10)
	grid:insert("one", Vector3.new(1, 0, 0))
	grid:insert("two", Vector3.new(2, 0, 0))
	grid:remove("one")
	grid:remove("one")

	assertSetEqual(grid:querySet(Vector3.new(1, 0, 0), 0), { two = true }, "after remove")
	grid:clear()
	assertSetEqual(grid:querySet(Vector3.new(1, 0, 0), 0), {}, "after clear")
end)

test("insert rejects duplicate ids", function(): ()
	local grid = VoxelGrid.new(10)
	grid:insert("duplicate", Vector3.zero)
	local ok = pcall(function()
		grid:insert("duplicate", Vector3.new(20, 0, 0))
	end)
	assertEqual(ok, false)
	assertTrue(grid:querySet(Vector3.zero, 0).duplicate == true, "original membership must survive")
end)

local passed = 0
for _, case in tests do
	local ok, resultOrError = pcall(function(): unknown
		case.run()
		return nil
	end)
	if not ok then
		fail("FAILED: " .. case.name .. "\n" .. tostring(resultOrError))
	end
	passed += 1
	print("PASS: " .. case.name)
end

print("VoxelGrid: " .. tostring(passed) .. " passed")
