--*****************************************************************
--**File	:PriorityQueue.lua
--**Author	:stlnkm(Sean Lin)
--**Date  	:2014/11/11
--**Version	:1.0.1
--*****************************************************************

require("Heap")

PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue.new( cmp, data )
	local obj = {}
	setmetatable(obj, PriorityQueue)

	obj.heap = Heap.new(cmp, data)
	return obj
end

function PriorityQueue:enqueue( value )
	self.heap:insert(value)
end

function PriorityQueue:dequeue(  )
	return self.heap:remove(1)
end

function PriorityQueue:size(  )
	return self.heap:size()
end

function PriorityQueue:debugDump( msg, fmtfunc )
	self.heap:debugDump(msg, fmtfunc)
end