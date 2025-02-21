local results = {
	fail = {},
	pass = {}
}

local function displayResults()
	local failures, passes = #results.fail, #results.pass
	local totalTests = failures + passes

	local buildFailure = false

	print(`{totalTests} tests ran`)
	if passes > 0 then
		print(`{passes} tests passed`)
	end
	if failures > 0 then
		buildFailure = true
		for _, reason in results.fail do
			print(reason)
		end
	end

	if buildFailure then
		print("build failure")
	else
		print("build success")
	end
end

local function it(should: string, func: () -> ())
	local success, errorMessage = pcall(func)
	if success then
		table.insert(results.pass, `"{should}" PASSED`)
	else
		table.insert(results.fail, `"{should}" FAILED: {errorMessage}`)
	end
end

local function matchesTable(x, y)
	for k, v in x do
		if not y[k] then
			return false
		else
			if y[k] ~= v then
				return false
			end
		end
	end

	for k, v in y do
		if not x[k] then
			return false
		else
			if x[k] ~= v then
				return false
			end
		end
	end

	return true
end

local function doesMatch(x, y)
	local xType = typeof(x)
	local yType = typeof(y)
	if xType ~= yType then
		error("input types do not match")
	end

	if xType == "table" then
		if not matchesTable(x, y) then
			error(`expected {y}, got {x}`)
		end
	elseif xType == "buffer" then
		if buffer.len(x) ~= buffer.len(y) then
			error(`expected {y}, got {x}`)
		end
	elseif xType == "CFrame" then 
		if not x:FuzzyEq(y, 1e-3) then
			error(`expected ({table.concat(table.pack(y:ToOrientation()), ", ")}), got ({table.concat(table.pack(x:ToOrientation()), ", ")})`)
		end
	else
		if x ~= y then
			error(`expected {y}, got {x}`)
		end
	end
end

local function doesNotMatch(x, y)
	local xType = typeof(x)
	local yType = typeof(y)
	if xType ~= yType then
		error("input types do not match")
	end

	if xType == "table" then
		if matchesTable(x, y) then
			error(`expected {y}, got {x}`)
		end
	elseif xType == "buffer" then
		if buffer.len(x) == buffer.len(y) then
			error(`expected length {y}, got length {x}`)
		end
	elseif xType == "CFrame" then 
		if x:FuzzyEq(y, 1e-3) then
			error(`expected ({table.concat(table.pack(y:ToOrientation()), ", ")}), got ({table.concat(table.pack(x:ToOrientation()), ", ")})`)
		end
	else
		if x == y then
			error(`expected {y}, got {x}`)
		end
	end
end

local t = require("./ByteWorks")

local function commonTestCase(tType, expectedSize, toTest)
	local size = tType.size(toTest)
	doesMatch(size, expectedSize)
	local buff = buffer.create(size)
	local offset = tType.ser(buff, 0, toTest)
	doesMatch(offset, expectedSize)
	local des
	offset, des = tType.des(buff, 0)
	doesMatch(offset, expectedSize)
	doesMatch(des, toTest)
end

do
	it("should ser/des vlq correctly", function()
		commonTestCase(t.vlq, 1, 127)
		commonTestCase(t.vlq, 2, 128)
	end)
	it("should ser/des svlq correctly", function()
		commonTestCase(t.svlq, 1, 63)
		commonTestCase(t.svlq, 2, 64)
		commonTestCase(t.svlq, 1, -64)
		commonTestCase(t.svlq, 2, -65)
	end)
	it("should ser/des string correctly", function()
		commonTestCase(t.string(5), 5, "abcde")
	end)
	it("should ser/des vstring correctly", function()
		commonTestCase(t.vstring, 11, string.rep("a", 10))
		commonTestCase(t.vstring, 1, string.rep("a", 0))
		commonTestCase(t.vstring, 130, string.rep("a", 128)) --uses vlq for length
	end)
	it("should ser/des buffer correctly", function()
		commonTestCase(t.buffer(10), 10, buffer.create(10))
	end)
	it("should ser/des vbuffer correctly", function()
		commonTestCase(t.vbuffer, 11, buffer.create(10))
		commonTestCase(t.vbuffer, 1, buffer.create(0))
		commonTestCase(t.vbuffer, 130, buffer.create(128)) --uses vlq for length
	end)
	it("should ser/des cframe correctly", function()
		commonTestCase(t.cframe, 18, CFrame.new(10000, -10000.252, 235235.235325) * CFrame.fromOrientation(math.pi, 0, -math.pi))
	end)
	it("should ser/des vector3 correctly", function()
		commonTestCase(t.vector3(t.f32), 12, Vector3.new(1000, -1000, 0))
	end)
end

displayResults()

return 0