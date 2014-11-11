--*****************************************************************
--**File	:Heap.lua
--**Author	:stlnkm(Sean Lin)
--**Date  	:2014/11/11
--**Version	:1.0.1
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
		if data[c+1] and cmp(data[c+1], data[c]) then
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

function Heap:debugDump( msg, fmtfunc )
	local item = {msg or ""}
	for i,v in ipairs(self.data) do
		if fmtfunc ~= nil then
			table.insert(item, fmtfunc(i, v))
		else
			table.insert(item, string.format("{[INDEX]:%d [VALUE]:%s}", i, tostring(v)))
		end
	end
	print(table.concat(item))
end

local function testHeap(  )
	local data = {25, 12, 36, 27, 45, 2, 89, 21, 36, 45, 32, 6, 7}
	local function lt( a, b )
		return a > b
	end
	local heap = Heap.new(lt, data)
	heap:debugDump("HEAP:")
	heap:remove(6)
	heap:debugDump("HEAP:")
	heap:insert(100)
	heap:debugDump("HEAP:")
end
-- testHeap()