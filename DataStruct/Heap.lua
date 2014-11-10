--*****************************************************************
--**File	:Heap.lua
--**Author	:stlnkm(Sean Lin)
--**Date  	:2014/11/11
--**Version	:1.0.0
--*****************************************************************

Heap = {}
Heap.__index = Heap

function Heap.new( cmp, data )
	local obj = {}
	setmetatable(obj, Heap)

	obj.cmp = cmp
	obj.data = {}
	if data ~= nil then
		for _,v in ipairs(data) do
			obj:insert(v)
		end
	end
	return obj
end

function Heap:insert( value )
	local idx = #self.data+1
	self.data[idx] = value
	self:siftUp(idx)
end

function Heap:remove( idx )
	assert(idx >= 1 and idx <= #self.data)
	local value = self.data[idx]
	local n = #self.data
	self.data[idx] = self.data[n]
	self.data[n] = nil
	self:siftDown(idx)
	return value
end

function Heap:at( idx )
	assert(idx >= 1 and idx <= #self.data)
	return self.data[idx]
end

function Heap:size(  )
	return #self.data
end

function Heap:siftUp( idx )
	local data = self.data
	local cmp = self.cmp
	local c, p = idx, math.floor(idx/2)
	while p >= 1 do
		if cmp(data[c], data[p]) then
			data[c], data[p] = data[p], data[c]
			c, p = p, math.floor(p/2)
		else
			break
		end
	end
end

function Heap:siftDown( idx )
	local data = self.data
	local cmp = self.cmp
	local n = #data
	local c, p = 2*idx, idx
	while c <= n do
		if cmp(data[c+1], data[c]) then
			c = c + 1
		end
		if cmp(data[c], data[p]) then
			data[c], data[p] = data[p], data[c]
			c,p = 2*c, c
		else
			break
		end
	end
end

local function testHeap(  )
	local function dump( h )
		local data = {}
		for i = 1, h:size() do
			table.insert(data, h:at(i))
		end
		print(unpack(data))
	end
	local data = {25, 12, 36, 27, 45, 2, 89, 21, 36, 45, 32, 6}
	local function lt( a, b )
		return a < b
	end
	local heap = Heap.new(lt, data)
	dump(heap)
	heap:remove(1)
	dump(heap)
	heap:insert(100)
	dump(heap)
end
-- testHeap()